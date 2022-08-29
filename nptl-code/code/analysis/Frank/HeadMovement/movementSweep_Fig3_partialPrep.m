%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.12.10',{[2 3 4 5 6 7 8 9]},{'RightLeft'},[2];
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'Fig3'];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%         
    bNums = horzcat(datasets{d,2}{:});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 3.5, datasets{d,4}, filtOpts );

    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            if strcmp(datasets{d,1}(1:2),'t5')
                R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
            end
        end
        allR = [allR, R{x}];
    end

    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
    timeWindow = [-1000,2000];
    binMS = 20;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
 
    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 0.5;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
        
    movCodeTrl = alignDat.currentMovement(alignDat.eventIdx);
    nothingTrl = movCodeTrl==218;
  
    %%
    smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);
    dPCA_all = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx, ...
        movCodeTrl, [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );

    cWindow = 30:50;
    idxSets = {1:4,5:8,9:12}; 
    simMatrix = plotCorrMat( dPCA_all.featureAverages(:,1:(end-1),:), cWindow, [], idxSets, idxSets);
    
    %saveas(gcf, [outDir filesep 'CorrMat_' datasets{d,3}{blockSetIdx} '.png'],'png');
   
    %%
%       LEFT_WRIST_EXT_BOTH(1)
%       LEFT_HAND_CLOSE_BOTH(2)
%       RIGHT_WRIST_EXT_BOTH(3)
%       RIGHT_HAND_CLOSE_BOTH(4)
%       
%       LEFT_WRIST_EXT_EFF(5)
%       LEFT_HAND_CLOSE_EFF(6)
%       RIGHT_WRIST_EXT_EFF(7)
%       RIGHT_HAND_CLOSE_EFF(8)
%       
%       LEFT_WRIST_EXT_MOV(9)
%       LEFT_HAND_CLOSE_MOV(10)
%       RIGHT_WRIST_EXT_MOV(11)
%       RIGHT_HAND_CLOSE_MOV(12)

    %movement, laterality
%     factorTable = [1, 1, 1;
%         2, 2, 1;
%         3, 1, 2;
%         4, 2, 2;
%         5, 1, 1;
%         6, 2, 1;
%         7, 1, 2;
%         8, 2, 2;
%         9, 1, 1;
%         10, 2, 1;
%         11, 1, 2;
%         12, 2, 2;];
    factorTable = [1, 1, 1;
        2, 2, 1;
        3, 1, 2;
        4, 2, 2;];

    newFactors = nan(length(movCodeTrl),2);
    for t=1:length(movCodeTrl)
        tableIdx = find(factorTable(:,1)==movCodeTrl(t));
        if isempty(tableIdx)
            continue;
        end
        newFactors(t,:) = factorTable(tableIdx,2:3);
    end

    %%
    for prepWindow=1:1 
        if prepWindow==1
            timeWindowAxes = [-1000, 0];
            xLimits = [-0.8, 0];
            saveTitle = 'prep';
            nPerMarg = 1;
            fPos = [135   828   929   240];
            marg_w = [0.25 0.10];
        else
            timeWindowAxes = [-1000, 1000];
            xLimits = [-0.8, 0.8];
            saveTitle = 'prepAndMove';
            nPerMarg = 2;
            fPos = [135   686   929   382];
            marg_w = [0.15 0.10];
        end
        
        trlIdx = find(~isnan(newFactors(:,1)));
        dPCA_full = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
            newFactors(trlIdx,:), timeWindowAxes/binMS, binMS/1000, {'Movement','Laterality','CI','MxL Interaction'} );

        timeWindowDisplay = [-1200,1200];
        %trlIdx = find(~nothingTrl);
        trlIdx = 1:length(movCodeTrl);
        dPCA_all = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
            movCodeTrl(trlIdx,:), timeWindowDisplay/binMS, binMS/1000, {'CD','CI'} );

        fa = dPCA_all.featureAverages;
        fv = dPCA_all.featureVals;

        lineArgs = cell(length(12),1);
        colors = [0.8 0.3 0.3;
            0.3 0.3 0.8;
            1.0 0.8 0.8;
            0.8 0.8 1.0;];
        ls = {'-',':','--'};

        globalIdx = 1;
        for prepIdx=1:3
            for conIdx=1:4
                lineArgs{globalIdx} = {'Color',colors(conIdx,:),'LineStyle',ls{prepIdx},'LineWidth',2};
                globalIdx = globalIdx + 1;
            end
        end
        lineArgs{13} = {'Color','k','LineStyle','-','LineWidth',2};

        %similarity matrix across movements using projection
        dPCA_newAx = dPCA_all;
        dPCA_newAx.Z = zeros(size(dPCA_full.W,2),size(dPCA_newAx.Z,2),size(dPCA_newAx.Z,3));
        dPCA_newAx.dimCI = zeros(size(dPCA_newAx.Z,1), size(dPCA_newAx.Z,2), size(dPCA_newAx.Z,3), 2);
        allST = cell(size(dPCA_newAx.featureAverages,2),1);
        for x=1:size(dPCA_newAx.featureAverages,2)
            dPCA_newAx.Z(:,x,:) = (squeeze(dPCA_newAx.featureAverages(:,x,:))'*dPCA_full.W)';

            tmp = squeeze(fv(:,x,:,:));
            stProj = zeros(20,size(tmp,2),size(tmp,3));
            for t=1:size(tmp,3)
                stProj(:,:,t) = (squeeze(tmp(:,:,t))'*dPCA_full.W)';
            end

            for dimIdx=1:size(stProj,1)
                tmp = squeeze(stProj(dimIdx,:,:))';
                tmp = tmp(~isnan(tmp(:,1)),:);
                [mn,~,CI] = normfit(tmp);

                dPCA_newAx.dimCI(dimIdx,x,:,:) = CI';
            end
            
            allST{x} = stProj;
        end

        dPCA_newAx.whichMarg = dPCA_full.whichMarg;

        timeAxis = ((timeWindowDisplay(1)/binMS):(timeWindowDisplay(2)/binMS))/(1000/binMS);
        layout.gap = [0.01 0.01];
        layout.marg_h = [0.05 0.01];
        layout.marg_w = marg_w;
        layout.fPos = fPos;
        layout.nPerMarg = nPerMarg;
        layout.textLoc = [0.7 0.9];
        layout.colorFactor = 1;
        layout.plotLayout = 'horizontal';
        layout.verticalBars = [0];
        colorsCI = [colors;
            colors;
            colors;
            0 0 0];

        [yAxesFinal, allAxHandles] = general_dPCA_plot( dPCA_newAx, timeAxis, lineArgs, {'Movement','Laterality','CI','MxL Interaction'}, ...
            'sameAxes', [], [-3 3], dPCA_newAx.dimCI, colorsCI, layout);

        for x=1:length(allAxHandles)
            for y=1:length(allAxHandles{x})
                set(allAxHandles{x}(y),'XLim',xLimits);
            end
        end
        axes(allAxHandles{1}(1));
        ylabel('Dim 1 (SD)');
        if prepWindow==2
            axes(allAxHandles{1}(2));
            ylabel('Dim 2 (SD)');
        end
        
        saveas(gcf, [outDir filesep 'prepDPC_' saveTitle '.png'],'png');
        saveas(gcf, [outDir filesep 'prepDPC_' saveTitle '.svg'],'svg');
        
        axIdx_mov = find(dPCA_newAx.whichMarg==1);
        axIdx_mov = axIdx_mov(1);
        
        axIdx_lat = find(dPCA_newAx.whichMarg==2);
        axIdx_lat = axIdx_lat(1);
        
        cLoc = 60;
        
        figure('Position',[680   872   359   226]);
        hold on
        for c=1:12
            xPoint = squeeze(dPCA_newAx.Z(axIdx_mov,c,cLoc));
            yPoint = squeeze(dPCA_newAx.Z(axIdx_lat,c,cLoc));
            if c<5
                symbol = 'o';
            elseif c<9
                symbol = 'd';
            elseif c<13
                symbol = 's';
            else
                symbol = 'd';
            end
            
            xCI = squeeze(dPCA_newAx.dimCI(axIdx_mov,c,cLoc,:));
            yCI = squeeze(dPCA_newAx.dimCI(axIdx_lat,c,cLoc,:));
            plot(xCI, [yPoint, yPoint],'-k','LineWidth',1);
            plot([xPoint, xPoint], yCI,'-k','LineWidth',1);
            
            plot(xPoint, yPoint,symbol, 'Color', lineArgs{c}{2}, 'MarkerFaceColor', lineArgs{c}{2}, 'MarkerSize', 12);
            
            %tmp_x = squeeze(allST{c}(axIdx_mov,:,:));
            %tmp_x = nanmean(tmp_x(cWindow,:),1);
            %tmp_y = squeeze(allST{c}(axIdx_lat,:,:));
            %tmp_y = nanmean(tmp_y(cWindow,:),1);
            %plot(tmp_x, tmp_y, symbol, 'Color', lineArgs{c}{2}, 'MarkerFaceColor', lineArgs{c}{2}, 'MarkerSize', 5);
        end
        axis equal;
        set(gca,'LineWidth',2,'FontSize',16,'XTick',[-1,0,1],'YTick',[-1,0,1]);
        xlabel('Movement Dimension (SD)');
        ylabel('Laterality Dimension (SD)');
        saveas(gcf, [outDir filesep 'prepSpace.png'],'png');
        saveas(gcf, [outDir filesep 'prepSpace.svg'],'svg');
        
        %%
        %side-by-side plot
%         colors = [0.8 0.3 0.3;
%             0.3 0.3 0.8;
%             0.8 0.3 0.3;
%             0.3 0.3 0.8;];
%         symbols = {'d','d','o','o'};

        titles = {'Full Prep','Side Prep','Movmt. Prep'};
        colors = [0.8 0.3 0.3;
            0.3 0.3 0.8;
            1.0 0.8 0.8;
            0.8 0.8 1.0;];
        
        conSetIdx = {1:4,5:8,9:12};
        axList = [axIdx_mov, axIdx_lat];
        spacing = linspace(-0.1,0.1,4);
        
        figure('Position',[260   892   447   213]);
        for conSet=1:3
            subtightplot(1,3,conSet,[0.01 0.01],[0.3 0.1],[0.1 0.1]);
            hold on;
            
            for dimIdx=1:2
                for c=1:length(conSetIdx{conSet})
                    cIdx = conSetIdx{conSet}(c);
                    yPoint = squeeze(dPCA_newAx.Z(axList(dimIdx),cIdx,cLoc));
                    yCI = squeeze(dPCA_newAx.dimCI(axList(dimIdx),cIdx,cLoc,:));
                    
                    plot([dimIdx+spacing(c), dimIdx+spacing(c)], yCI,'-k','LineWidth',1);
                    plot(dimIdx+spacing(c), yPoint, 'o', 'Color', colors(c,:),'MarkerSize',8,'LineWidth',2,...
                        'MarkerFaceColor',colors(c,:));
                end
            end
            xlim([0.5,2.5]);
            ylim([-1.5,1.5]);
            
            if conSet>1
                set(gca,'YTickLabel',[]);
            else
                ylabel('Rate (SD)');
            end
            set(gca,'XTick',[1 2],'XTickLabel',{'Movmt.','Side'},'XTickLabelRotation',45,'FontSize',16,'LineWidth',2);
            title(titles{conSet});
        end
        saveas(gcf, [outDir filesep 'prepBars.png'],'png');
        saveas(gcf, [outDir filesep 'prepBars.svg'],'svg');
        
        %%
        %side-by-side plot
%         colors = [0.8 0.3 0.3;
%             0.3 0.3 0.8;
%             0.8 0.3 0.3;
%             0.3 0.3 0.8;];
%         symbols = {'d','d','o','o'};
        avgWindow = 10:60;
        titles = {'Side Dimension','Movmt. Dimension'};
        colors = [0.8 0.3 0.3;
            0.3 0.3 0.8;
            1.0 0.8 0.8;
            0.8 0.8 1.0;];
        
        conSetIdx = {1:4,5:8,9:12};
        axList = [axIdx_lat, axIdx_mov];
        spacing = linspace(-0.1,0.1,4);
        
        xOrder = {[1 2 3],[1 3 2]};
        xLabels = {'Full','Side','Movmt.'};
        
        figure('Position',[295   771   499   214]);
        for dimIdx=1:2
            subplot(1,2,dimIdx);
            hold on;
            
            for conSet=1:3
                for c=1:length(conSetIdx{conSet})
                    cIdx = conSetIdx{xOrder{dimIdx}(conSet)}(c);
                    yPoint = squeeze(mean(dPCA_newAx.Z(axList(dimIdx),cIdx,avgWindow),3));
                    yCI = squeeze(mean(dPCA_newAx.dimCI(axList(dimIdx),cIdx,avgWindow,:),3));
                    
                    plot([conSet+spacing(c), conSet+spacing(c)], yCI,'-k','LineWidth',1);
                    plot(conSet+spacing(c), yPoint, 'o', 'Color', colors(c,:),'MarkerSize',8,'LineWidth',2,...
                        'MarkerFaceColor',colors(c,:));
                end
            end
            xlim([0.5,3.5]);
            ylim([-1.5,1.5]);
            
            if dimIdx==1
                ylabel('Rate (SD)');
            else
                set(gca,'YTickLabel',[]);
            end
            title(titles{dimIdx},'FontWeight','normal');
            set(gca,'XTick',1:3,'XTickLabel',xLabels(xOrder{dimIdx}),'XTickLabelRotation',45,'FontSize',16,'LineWidth',2);
        end
        
        saveas(gcf, [outDir filesep 'prepBars_3.png'],'png');
        saveas(gcf, [outDir filesep 'prepBars_3.svg'],'svg');
        
        %%
        %single trial
        cWindow = 30:61;
        for margIdx=1:2
            axIdx = find(dPCA_newAx.whichMarg==margIdx);
            axIdx = axIdx(1);
            
            figure
            for c=1:12
                subplot(3,4,c);
                tmp = squeeze(allST{c}(axIdx,:,:));
                tmp = nanmean(tmp(cWindow,:),1);
                hist(tmp);
                xlim([-2.0,2.0]);
            end
        end
    end
end