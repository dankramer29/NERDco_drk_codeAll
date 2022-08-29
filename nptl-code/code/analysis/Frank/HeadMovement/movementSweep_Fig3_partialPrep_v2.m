%%
datasets = {
    't5.2018.12.10',{[2 3 4 5 6 7 8 9]},{'Laterality'},[2];
    't5.2019.03.27',{[3 4 5 6 7 8 9 10]},{'Arm vs. Leg'},[3];
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'Fig3' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%         
    bNums = horzcat(datasets{d,2}{:});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
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

    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
    timeWindow = [-1000,2000];
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
 
    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
    
    smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 6);
        
    movCodeTrl = alignDat.currentMovement(alignDat.eventIdx);
    nothingTrl = movCodeTrl==218;
    
    if strcmp(datasets{d,1},'t5.2019.03.27')
        codeOrder = [3 1423 1424 1425 ... %both
            1427 1426 1430 1431 ... %effector
            1429 1428 1432 1433];
        
        newMoveCode = movCodeTrl;
        for x=1:length(codeOrder)
            trlReplace = find(movCodeTrl==codeOrder(x));
            newMoveCode(trlReplace) = x;
        end
        movCodeTrl = newMoveCode;
    end
  
    %%
    %day 2: arm vs. leg
    %RIGHT_WRIST_EXT_BOTH(3)
    %RIGHT_WRIST_FLEX_BOTH(1423)
    %RIGHT_ANKLE_DORSIFLEX_BOTH(1424)
    %RIGHT_ANKLE_PLANTARFLEX_BOTH(1425)
    
    %RIGHT_WRIST_FLEX_EFFECTOR(1426)
    %RIGHT_WRIST_EXT_EFFECTOR(1427)
    %RIGHT_WRIST_FLEX_MOVEMENT(1428)
    %RIGHT_WRIST_EXT_MOVEMENT(1429)
    
    %RIGHT_ANKLE_DORSIFLEX_EFFECTOR(1430)
    %RIGHT_ANKLE_PLANTARFLEX_EFFECTOR(1431)
    %RIGHT_ANKLE_DORSIFLEX_MOVEMENT(1432)
    %RIGHT_ANKLE_PLANTARFLEX_MOVEMENT(1433)
  
    %%
    %day 1: laterality
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

    %%
    %movement, effector
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
    timeWindowAxes = [-1000, 0];
    xLimits = [-0.8, 0];
    saveTitle = 'prep';
    nPerMarg = 1;
    fPos = [135   828   929   240];
    marg_w = [0.25 0.10];

    trlIdx = find(~isnan(newFactors(:,1)));
    dPCA_full = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
        newFactors(trlIdx,:), timeWindowAxes/binMS, binMS/1000, {'Movement','Laterality','CI','MxL Interaction'} );

    timeWindowDisplay = [-1200,1200];
    trlIdx = 1:length(movCodeTrl);
    dPCA_all = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
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

    axIdx_mov = find(dPCA_newAx.whichMarg==1);
    axIdx_mov = axIdx_mov(1);

    axIdx_lat = find(dPCA_newAx.whichMarg==2);
    axIdx_lat = axIdx_lat(1);

    %%
    avgWindow = ((-300-timeWindowDisplay(1))/binMS):(-timeWindowDisplay(1)/binMS);

    figure('Position',[680   872   359   226]);
    hold on
    for c=1:13
        if c<5
            symbol = 'o';
        elseif c<9
            symbol = 'd';
        elseif c<13
            symbol = 's';
        else
            symbol = 'd';
        end
        
        tmpX = squeeze(nanmean(allST{c}(axIdx_mov,avgWindow,:),2));
        tmpX = tmpX(~isnan(tmpX));
        [xPoint,~,xCI] = normfit(tmpX);
        
        tmpY = squeeze(nanmean(allST{c}(axIdx_lat,avgWindow,:),2));
        tmpY = tmpY(~isnan(tmpY));
        [yPoint,~,yCI] = normfit(tmpY);
        
        plot(xCI, [yPoint, yPoint],'-k','LineWidth',1);
        plot([xPoint, xPoint], yCI,'-k','LineWidth',1);

        plot(xPoint, yPoint,symbol, 'Color', lineArgs{c}{2}, 'MarkerFaceColor', lineArgs{c}{2}, 'MarkerSize', 12);
    end
    axis equal;
    set(gca,'LineWidth',2,'FontSize',16,'XTick',[-1,0,1],'YTick',[-1,0,1]);
    xlabel('Movement Dimension (SD)');
    if strcmp(datasets{d,1},'t5.2018.12.10')
        ylabel('Laterality Dimension (SD)');
    else
        ylabel('Arm vs. Leg Dimension (SD)');
    end
    saveas(gcf, [outDir filesep 'prepSpace.png'],'png');
    saveas(gcf, [outDir filesep 'prepSpace.svg'],'svg');

    %%
    %side-by-side plot
    avgWindow = ((-300-timeWindowDisplay(1))/binMS):(-timeWindowDisplay(1)/binMS);
    
    if strcmp(datasets{d,1},'t5.2018.12.10')
        colors = [0.8 0.3 0.3;
            0.3 0.3 0.8;
            1.0 0.8 0.8;
            0.8 0.8 1.0;];
    else
        colors = [204 77 204;
            33 120 103
            255 204 255;
            135 222 205]/255;        
    end

    conSetIdx = {1:4,5:8,9:12};
    axList = [axIdx_lat, axIdx_mov];
    spacing = linspace(-0.1,0.1,4);

    xOrder = {[1 2 3],[1 3 2]};
    
    if strcmp(datasets{d,1},'t5.2018.12.10')
        titles = {'Laterality Dimension','Movmt. Dimension'};
        xLabels = {'Full','Lat.','Movmt.'};
        yLimit = [-1.1,1.1];
    else
        titles = {'Arm vs. Leg Dimension','Movmt. Dimension'};
        xLabels = {'Full','A vs. L','Movmt.'};
        yLimit = [-0.8,0.8];
    end
   
    figure('Position',[295   771   499   214]);
    for dimIdx=1:2
        subplot(1,2,dimIdx);
        hold on;

        for conSet=1:3
            for c=1:length(conSetIdx{conSet})
                cIdx = conSetIdx{xOrder{dimIdx}(conSet)}(c);
                
                tmp = squeeze(nanmean(allST{cIdx}(axList(dimIdx),avgWindow,:),2));
                tmp = tmp(~isnan(tmp));
                [mn,~,CI] = normfit(tmp);
                
                yPoint = mn;
                yCI = CI;

                %plot([conSet+spacing(c), conSet+spacing(c)], yCI,'Color',colors(c,:),'LineWidth',10);
                %plot(conSet+spacing(c), yPoint, 'o', 'Color', colors(c,:),'MarkerSize',4,'LineWidth',2,'MarkerFaceColor',colors(c,:));
           
                plot(conSet+spacing(c), yPoint, 'o', 'Color', colors(c,:),'MarkerSize',10,'LineWidth',2,'MarkerFaceColor',colors(c,:));
                plot([conSet+spacing(c), conSet+spacing(c)], yCI,'-k','LineWidth',1);
            end
        end
        xlim([0.5,3.5]);
        ylim(yLimit);

        if dimIdx==1
            ylabel('Rate (SD)');
        else
            set(gca,'YTickLabel',[]);
        end
        title(titles{dimIdx},'FontWeight','normal');
        set(gca,'XTick',1:3,'XTickLabel',xLabels(xOrder{dimIdx}),'XTickLabelRotation',45,'FontSize',20,'LineWidth',2);
    end

    saveas(gcf, [outDir filesep 'prepBars_3.png'],'png');
    saveas(gcf, [outDir filesep 'prepBars_3.svg'],'svg');

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
    
    cueSetEff = {1,2,3,4,[5 6],[7 8],13};
    cueSetMov = {1,2,3,4,[9 11],[10 12],13};
    allCueSets = {cueSetEff, cueSetMov};
    
    colors = lines(6)*0.8;
    colors = [colors; 0 0 0];
    
    avgWindow = ((-300-timeWindowDisplay(1))/binMS):(-timeWindowDisplay(1)/binMS);

    figure('Position',[1007         711         823         330]);
    for cueSetIdx = 1:length(allCueSets)
        cueSet = allCueSets{cueSetIdx};
        
        subplot(1,2,cueSetIdx);
        hold on
        for c=1:length(cueSet)
            
            allX = [];
            allY = [];
            for x = 1:length(cueSet{c})
                tmpX = squeeze(nanmean(allST{cueSet{c}(x)}(axIdx_mov,avgWindow,:),2));
                tmpX = tmpX(~isnan(tmpX));
                allX = [allX; tmpX];
                
                tmpY = squeeze(nanmean(allST{cueSet{c}(x)}(axIdx_lat,avgWindow,:),2));
                tmpY = tmpY(~isnan(tmpY));
                allY = [allY; tmpY];
            end
            
            plot(allX, allY,'o', 'Color', colors(c,:), 'MarkerFaceColor', colors(c,:), 'MarkerSize', 8);
        end
        if strcmp(datasets{d,1},'t5.2018.12.10')
            xlim([-1.1 1.1]);
            ylim([-1.6 1.2]);
        else
            xlim([-1.0 1.0]);
            ylim([-1.0 1.2]);
        end
        axis equal;
        set(gca,'LineWidth',2,'FontSize',16,'XTick',[-1,0,1],'YTick',[-1,0,1]);
        xlabel('Movement Dimension (SD)');
        if strcmp(datasets{d,1},'t5.2018.12.10')
            ylabel('Laterality Dimension (SD)');
        else
            ylabel('Arm vs. Leg Dimension (SD)');
        end
    end
    
    saveas(gcf, [outDir filesep 'prepSpace_st.png'],'png');
    saveas(gcf, [outDir filesep 'prepSpace_st.svg'],'svg');
    
    %%
    %vertical distributions
    figure('Position',[1007         711         823         330]);
    for cueSetIdx = 1:length(allCueSets)
        cueSet = allCueSets{cueSetIdx};
        
        subplot(1,2,cueSetIdx);
        hold on
        
        setMap = [5 6];
        X = [];
        G = [];
        for c=1:2
            allY = [];
            for x = 1:length(cueSet{setMap(c)})
                tmpY = squeeze(nanmean(allST{cueSet{setMap(c)}(x)}(axIdx_lat,avgWindow,:),2));
                tmpY = tmpY(~isnan(tmpY));
                allY = [allY; tmpY];
            end
            
            X = [X; allY];
            G = [G; ones(length(allY),1)+c];
        end
        
        boxplot(X, G);
        ylim([-1.8 1.5]);
    end
    
    %%
    %horizontal distributions
    figure('Position',[1007         711         823         330]);
    for cueSetIdx = 1:length(allCueSets)
        cueSet = allCueSets{cueSetIdx};
        
        subplot(1,2,cueSetIdx);
        hold on
        
        setMap = [5 6];
        X = [];
        G = [];
        for c=1:2
            allX = [];
            for x = 1:length(cueSet{setMap(c)})
                tmpX = squeeze(nanmean(allST{cueSet{setMap(c)}(x)}(axIdx_mov,avgWindow,:),2));
                tmpX = tmpX(~isnan(tmpX));
                allX = [allX; tmpX];
            end
            
            X = [X; allX];
            G = [G; ones(length(allX),1)+c];
        end
        
        boxplot(X, G, 'orientation', 'horizontal');
        xlim([-1.5, 1.5]);
    end

end