%%
datasets = {
    't5.2018.05.30',{[14 15 16 17 18 19 21 22 23 24]},{'ArmLegDir'},[14];
    't5.2018.06.04',{[10 11 12 13 14 15 16 17 18 19 20 21 22 23]},{'ArmHeadDir'},[10];
    
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 17 18 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
        
    't5.2018.06.18',{[4 6 7 8 9 10 12],[18 19 20 21 22]},{'LArmRArm','EyeRArm'},[4];
};

effNames = {{{'RLeg','RArm'}};
    {{'Head','RArm'}};
    {{'Head','Tongue'},{'LArm','RArm'},{'Head','RArm'},{'LLeg','RLeg'},{'LLeg','RArm'}};
    {{'Head','RArm'},{'RArm','RLeg'}};
    {{'Head','RLeg'},{'Head','LLeg'},{'Head','LArm'},{'LArm','RLeg'},{'LArm','LLeg'},{'LLeg','RLeg'},{'LLeg','RArm'},{'RLeg','RArm'}};
    {{'LArm','RArm'},{'Eyes','RArm'}}};

%%
for d=1:length(datasets)
    
    if any(strcmp(datasets{d,1},{'t5.2018.03.19', 't5.2018.03.21', 't5.2018.04.02'}))
        nDirCon = 2;
    else
        nDirCon = 4;
    end
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = horzcat(datasets{d,2}{:});
    if strcmp(datasets{d,1}(1:2),'t5')
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
    else
        movField = 'glove';
        filtOpts.filtFields = {'glove'};
    end
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 4.5, datasets{d,4}, filtOpts );
    
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
    
    clear R;

    %%
    alignFields = {'goCue'};
    smoothWidth = 60;
    if strcmp(datasets{d,1}(1:2),'t5')
        datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
    else
        datFields = {'glove','currentMovement','glove_speed'};
    end
    timeWindow = [-1500,3000];
    binMS = 20;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 0.5;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];

    if strcmp(datasets{d,1},'t5.2018.05.30')
        dualSetIdx = 1;
    elseif strcmp(datasets{d,1},'t5.2018.06.04')
        dualSetIdx = 1;
    elseif strcmp(datasets{d,1},'t5.2018.03.19')
        dualSetIdx = 1:5;
    elseif strcmp(datasets{d,1},'t5.2018.03.21')
        dualSetIdx = 1:2;
    elseif strcmp(datasets{d,1},'t5.2018.04.02')
        dualSetIdx = 1:8;
    elseif strcmp(datasets{d,1},'t5.2018.06.18')
        dualSetIdx = 1:2;
    elseif strcmp(datasets{d,1},'t5.2018.06.20')
        dualSetIdx = 1;
    end

    timeWindow_dPC = [0,1000];
    
    for outerMovSetIdx = dualSetIdx
        close all;
        
        %%
        %---dual movement----
        allIdx = find(ismember(alignDat.bNumPerTrial, datasets{d,2}{outerMovSetIdx}));
        movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
        eventIdx = alignDat.eventIdx(allIdx);
        varianceSummary = zeros(4,3);

%           BI_LEFT_LEFT(195)
%           BI_LEFT_RIGHT(196)
%           BI_LEFT_UP(197)
%           BI_LEFT_DOWN(198)
% 
%           BI_RIGHT_LEFT(199)
%           BI_RIGHT_RIGHT(200)
%           BI_RIGHT_UP(201)
%           BI_RIGHT_DOWN(202)
% 
%           BI_UP_LEFT(203)
%           BI_UP_RIGHT(204)
%           BI_UP_UP(205)
%           BI_UP_DOWN(206)
% 
%           BI_DOWN_LEFT(207)
%           BI_DOWN_RIGHT(208)
%           BI_DOWN_UP(209)
%           BI_DOWN_DOWN(210)

        factorMap = [
            187, 1, 0;
            188, 2, 0;
            189, 3, 0;
            190, 4, 0;
            191, 0, 1;
            192, 0, 2;
            193, 0, 3;
            194, 0, 4;
            195, 1, 1;
            196, 1, 2;
            197, 1, 3;
            198, 1, 4;
            199, 2, 1;
            200, 2, 2;
            201, 2, 3;
            202, 2, 4;
            203, 3, 1;
            204, 3, 2;
            205, 3, 3;
            206, 3, 4;
            207, 4, 1;
            208, 4, 2;
            209, 4, 3;
            210, 4, 4;   ];            
        movFactors = zeros(length(movCues),2);
        for x=1:length(movCues)
            fIdx = find(factorMap(:,1)==movCues(x));
            movFactors(x,:) = factorMap(fIdx,2:3);
        end

        noSingleMovements = find(~ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
        dPCA_out_dual = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements)), ...
            movFactors(noSingleMovements,:), timeWindow_dPC/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 30, 'xval' );

        lineArgs_dual = cell(nDirCon,nDirCon);
        colors = jet(nDirCon)*0.8;
        ls = {'-',':','--','-.'};
        for x=1:nDirCon
            for c=1:nDirCon
                lineArgs_dual{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
            end
        end

        %2-factor dPCA
        eff1 = effNames{d}{outerMovSetIdx}{1};
        eff2 = effNames{d}{outerMovSetIdx}{2};
        
        labels = {eff1, eff2, 'CI', [eff1 ' x ' eff2]};
        layoutInfo.nPerMarg = 3;
        layoutInfo.fPos = [573, 195, 600, 847];
        layoutInfo.gap = [0.03 0.01];
        layoutInfo.marg_h = [0.07 0.02];
        layoutInfo.marg_w = [0.10 0.02];
        layoutInfo.colorFactor = 2;
        layoutInfo.textLoc = [0.8,0.2];
        layoutInfo.plotLayout = 'vertical';

        timeAxis = ((timeWindow_dPC(1)/binMS):(timeWindow_dPC(2)/binMS))/50;
        [yAxesFinal, allHandles, axFromDualMovements] = twoFactor_dPCA_plot_pretty_2( dPCA_out_dual, timeAxis, lineArgs_dual, ...
            labels, 'sameAxes', [], [], dPCA_out_dual.dimCI, colors, layoutInfo );
    
        %[~, allHandles, axFromDualMovements] = twoFactor_dPCA_plot( dPCA_out_dual,  (timeWindow_dPC(1)/binMS):(timeWindow_dPC(2)/binMS), ...
        %    lineArgs_dual, labels, 'sameAxes');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA.svg'],'svg');

        %eff 1
        axIdx = find(dPCA_out_dual.whichMarg==1);
        effDim = dPCA_out_dual.W(:,axIdx(1:min(4,length(axIdx))));
        [ varianceSummary(1,1), varianceSummary(1,2:3) ] = getSimulVariance( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, effDim, 10:50, 100 );
        
        %eff 2
        axIdx = find(dPCA_out_dual.whichMarg==2);
        effDim = dPCA_out_dual.W(:,axIdx(1:min(4,length(axIdx))));
        movWindow = 10:50;
        [ varianceSummary(2,1), varianceSummary(2,2:3) ] = getSimulVariance( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, effDim, 10:50, 100 );
        
        %%
        %---single movement----
        allIdx = find(ismember(alignDat.bNumPerTrial, datasets{d,2}{outerMovSetIdx}));
        movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
        codeList = unique(movCues);

        factorMap = [
            187, 1, 0;
            188, 2, 0;
            189, 3, 0;
            190, 4, 0;
            191, 1, 1;
            192, 2, 1;
            193, 3, 1;
            194, 4, 1;
            195, 1, 1;
            196, 1, 2;
            197, 1, 3;
            198, 1, 4;
            199, 2, 1;
            200, 2, 2;
            201, 2, 3;
            202, 2, 4;
            203, 3, 1;
            204, 3, 2;
            205, 3, 3;
            206, 3, 4;
            207, 4, 1;
            208, 4, 2;
            209, 4, 3;
            210, 4, 4;   ];            
        movFactors = zeros(length(movCues),2);
        for x=1:length(movCues)
            fIdx = find(factorMap(:,1)==movCues(x));
            movFactors(x,:) = factorMap(fIdx,2:3);
        end

        singleMovements = find(ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
        dPCA_out_single = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
            movFactors(singleMovements,:), timeWindow_dPC/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 20, 'xval' );
        
        lineArgs_single = cell(nDirCon,2);
        colors = jet(nDirCon)*0.8;
        ls = {':','-'};
        for x=1:nDirCon
            for c=1:2
                lineArgs_single{x,c} = {'Color',colors(x,:),'LineWidth',2,'LineStyle',ls{c}};
            end
        end

        %2-factor dPCA
        labels = {'Dir', 'Effector', 'CI', 'Dir x Eff'};
        layoutInfo.nPerMarg = 3;
        layoutInfo.fPos = [573, 195, 600, 847];
        layoutInfo.gap = [0.03 0.01];
        layoutInfo.marg_h = [0.07 0.02];
        layoutInfo.marg_w = [0.10 0.02];
        layoutInfo.colorFactor = 1;
        layoutInfo.textLoc = [0.8,0.2];
        layoutInfo.plotLayout = 'vertical';
        
        timeAxis = ((timeWindow_dPC(1)/binMS):(timeWindow_dPC(2)/binMS))/50;
        [yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot_pretty_2( dPCA_out_single, timeAxis, lineArgs_single, ...
            labels, 'sameAxes', [], [], dPCA_out_single.dimCI, colors, layoutInfo );
        %[yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot( dPCA_out_single,  (timeWindow_dPC(1)/binMS):(timeWindow_dPC(2)/binMS), ...
        %    lineArgs_single, labelsSingle, 'sameAxes', []);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMove_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMove_dPCA.svg'],'svg');

        %same axes
        fullAx = [vertcat(axFromDualMovements{:}); vertcat(axFromSingle{:})];
        fullLims = [min(fullAx(:)), max(fullAx(:))];
        [yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot( dPCA_out_single,  (timeWindow_dPC(1)/binMS):(timeWindow_dPC(2)/binMS), ...
            lineArgs_single, labels, 'sameAxes', [], fullLims);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMoveSameAx_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMoveSameAx_dPCA.svg'],'svg');

        [~, allHandles, axFromDualMovements] = twoFactor_dPCA_plot( dPCA_out_dual,  (timeWindow_dPC(1)/binMS):(timeWindow_dPC(2)/binMS), ...
            lineArgs_dual, labels, 'sameAxes', [], fullLims);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2moveSameAx_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2moveSameAx_dPCA.svg'],'svg');
        
        %eff 2
        movSets = {[187,188,189,190],[191,192,193,194]};
        dPCA_single_set = cell(length(movSets),1);
        for setIdx=1:length(movSets)
            singleMovements = find(ismember(movCues, movSets{setIdx}));
            dPCA_single_set{setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
                movFactors(singleMovements,1), timeWindow_dPC/binMS, binMS/1000, {'Dir','CI'} );
            
            axIdx = find(dPCA_single_set{setIdx}.whichMarg==1);
            effDim = dPCA_single_set{setIdx}.W(:,axIdx(1:4));
            movWindow = 10:50;
            [ varianceSummary(setIdx+2,1), varianceSummary(setIdx+2,2:3) ] = getSimulVariance( eventIdx(singleMovements), movCues(singleMovements), ...
                alignDat.zScoreSpikes, effDim, 10:50, 100 );
        end
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_varSummary'],'varianceSummary');
        
        %%
        singleMovements = find(ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
        dPCA_out_sAll = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
            movFactors(singleMovements,1)+movFactors(singleMovements,2)*4, timeWindow_dPC/binMS, binMS/1000, {'CI','CD'}, 20);
        
        cWindow = 90:120;
        if nDirCon==4
            idxSets = {1:4,5:8}; 
        else
            idxSets = {1:2,3:4}; 
        end
        simMatrix = plotCorrMat( dPCA_out_sAll.featureAverages, cWindow, [], idxSets, idxSets);
    
        saveas(gcf, [outDir filesep datasets{d,3}{outerMovSetIdx} '_CorrMat.png'],'png');

        dirMap = [187, -1, 0;
            188, 1, 0;
            189, 0, 1;
            190, 0, -1;
            191, -1, 0;
            192, 1, 0;
            193, 0, 1;
            194, 0, -1];

        movSets = {[187,188,189,190],[191,192,193,194]};
        allPD = cell(length(movSets),1);
        allPVal = cell(length(movSets),1);
        
        for movSetIdx = 1:length(movSets)
            trlIdx = find(ismember(movCues, movSets{movSetIdx}));
            
            allDat = [];
            allTargPos = [];
            for innerIdx=1:length(trlIdx)
                loopIdx = cWindow + alignDat.eventIdx(allIdx(trlIdx(innerIdx)));
                allDat = [allDat; mean(alignDat.zScoreSpikes(loopIdx,:))];
                
                mapIdx = find(dirMap(:,1)==movCues(trlIdx(innerIdx)));
                targPos = dirMap(mapIdx,2:3);
                
                allTargPos = [allTargPos; targPos];
            end
            if nDirCon==2
                allTargPos = allTargPos(:,1);
                nCoef = 2;
            else
                nCoef = 3;
            end

            pVals = zeros(192,1);
            E = zeros(192,nCoef);
            for featIdx=1:192
                [B,BINT,R,RINT,STATS] = regress(allDat(:,featIdx), [ones(length(allTargPos),1), allTargPos]);
                pVals(featIdx) = STATS(3);
                E(featIdx,:) = B;
            end

            allPD{movSetIdx} = E(:,2:end);
            allPVal{movSetIdx} = pVals;
        end
        
        %plots
        R2 = zeros(length(allPD));
        rotMat = cell(length(allPD), length(allPD));
        for x=1:length(allPD)
            for y=1:length(allPD)
               rotMat{x,y} = allPD{x}\allPD{y};
               [B,BINT,R,RINT,STATS1] = regress(allPD{y}(:,1),allPD{x});
               if nDirCon==4
                   [B,BINT,R,RINT,STATS2] = regress(allPD{y}(:,2),allPD{x});
                   R2(x,y) = mean([STATS1(1), STATS2(1)]);
               else
                   R2(x,y) = STATS1(1);
               end
            end
        end
        for x=1:size(R2,1)
            R2(x,x) = 0;
        end

        eNames = effNames{d}{outerMovSetIdx};
        
        figure
        imagesc(R2,[0,max(abs(R2(:)))]);
        colorbar;
        set(gca,'XTick',1:4,'XTickLabel',eNames,'XTickLabelRotation',45);
        set(gca,'YTick',1:4,'YTickLabel',eNames);
        set(gca,'FontSize',14);
        if nDirCon==2
            rm = vertcat(rotMat{:});
            title(num2str(rm(2:3)));
        end
        saveas(gcf, [outDir filesep 'R2Mat_' datasets{d,3}{outerMovSetIdx} '.png'],'png');

        if nDirCon==4
            nCon = length(allPD);
            figure('Position',[154   367   859   738]);
            hold on
            for x=1:nCon
                for y=1:nCon
                    subplot(nCon,nCon,(x-1)*nCon+y);
                    hold on;
                    plot([0, rotMat{x,y}(1,1)], [0,rotMat{x,y}(2,1)],'-o','LineWidth',2);
                    plot([0, rotMat{x,y}(1,2)], [0,rotMat{x,y}(2,2)],'-o','LineWidth',2);
                    plot([0,0],[-1,1],'-k');
                    plot([-1,1],[0,0],'-k');
                    xlim([-1,1]);
                    ylim([-1,1]);
                    axis equal;

                    if y==1
                        ylabel(eNames{x});
                    end
                    if x==nCon
                        xlabel(eNames{y});
                    end
                    set(gca,'FontSize',14,'XTick',[],'YTick',[]);
                end
            end
            saveas(gcf, [outDir filesep 'PDRotMat_' datasets{d,3}{outerMovSetIdx} '.png'],'png');
        end
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_pdSummary'],'rotMat','allPD','allPVal','R2');
        close all;
        
        %%
        %2D dPC trajectories
        axHandles = zeros(6,1);
        colors = jet(nDirCon)*0.8;
        ls = {'-',':','--','-.'};
        
        plotWindow = 1:51;
        figure('Position',[252   357   550   745]);
        for setIdx=1:2
            axHandles(setIdx) = subtightplot(3,2,setIdx);
            hold on;
            
            axIdx = find(dPCA_single_set{setIdx}.whichMarg==1);
            nCon = size(dPCA_single_set{setIdx}.Z,2);
            
            for conIdx=1:nCon
                xTraj = squeeze(dPCA_single_set{setIdx}.Z(axIdx(1),conIdx,:));
                yTraj = squeeze(dPCA_single_set{setIdx}.Z(axIdx(2),conIdx,:));
                plot(xTraj(plotWindow), yTraj(plotWindow), 'Color', colors(conIdx,:), 'LineWidth', 2);
                %if setIdx==1
                %    plot(xTraj(plotWindow), yTraj(plotWindow), 'Color', colors(conIdx,:), 'LineWidth', 4);
                %else
                %    plot(xTraj(plotWindow), yTraj(plotWindow), 'Color', 'k', 'LineWidth', 2, 'LineStyle',ls{conIdx});
                %end
            end
            axis tight;
        end
    
        for effIdx=1:2
            axHandles(2+effIdx) = subtightplot(3,2,2+effIdx);
            hold on;
            
            axIdx = find(dPCA_out_dual.whichMarg==effIdx);
            nCon = size(dPCA_out_dual.Z,2);
            
            for conIdx_x=1:nCon
                for conIdx_y=1:nCon
                    xTraj = squeeze(dPCA_out_dual.Z(axIdx(1),conIdx_x,conIdx_y,:));
                    yTraj = squeeze(dPCA_out_dual.Z(axIdx(2),conIdx_x,conIdx_y,:));
                    plot(xTraj(plotWindow), yTraj(plotWindow), 'LineStyle',ls{conIdx_y},'Color',colors(conIdx_x,:), 'LineWidth', 2);
                end
            end
            axis tight;
        end
        
        colors = jet(nDirCon)*0.8;
        ls = {'-',':','--','-.'};
        for effIdx=1:2
            axHandles(4+effIdx) = subtightplot(3,2,4+effIdx);
            hold on;
            
            axIdx = find(dPCA_single_set{effIdx}.whichMarg==1);
            W = dPCA_single_set{effIdx}.W(:,axIdx(1:2));
            nCon = size(dPCA_out_dual.Z,2);
            
            for conIdx_x=1:nCon
                for conIdx_y=1:nCon
                    neuralAct = squeeze(dPCA_out_dual.featureAverages(:,conIdx_x,conIdx_y,:))';
                    traj = neuralAct*W;
                    plot(traj(plotWindow,1), traj(plotWindow,2), 'LineStyle',ls{conIdx_y},'Color',colors(conIdx_x,:),'LineWidth',2);
                end
            end
            axis tight;
        end
        
        allLim = [];
        for x=1:length(axHandles)
            yLimits = get(axHandles(x),'YLim');
            xLimits = get(axHandles(x),'XLim');
            allLim = [allLim; xLimits, yLimits];
        end
        finalLimits = [min(allLim(:,1)), max(allLim(:,2)), min(allLim(:,3)), max(allLim(:,4))];
        
        for x=1:length(axHandles)
            axes(axHandles(x));
            axis off;
            xlim(finalLimits(1:2));
            ylim(finalLimits(3:4));
        end
        
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'dPCA_traj.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'dPCA_traj.svg'],'svg');
        
        close all;

    end %movement set
end %dataset
