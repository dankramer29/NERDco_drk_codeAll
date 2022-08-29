%--todo: finish figure 4 & 5 drafts based on current analyses.
%--supplemental figure on eye movement artiface & movement cue directional
%analysis.
%--supplemental figure on subspace change not due to noise - include
%magnitude decrease null model and show the change is larger than this
%alone would predict. Also # of trials vs. dual->single ratio showos
%platuea is likely to be similar. (Collect control data?).

%%
% datasets = {
%     't5.2018.05.30',{[14 15 16 17 18 19 21 22 23 24]},{'ArmLegDir'},[14];
%     't5.2018.06.04',{[10 11 12 13 14 15 16 17 18 19 20 21 22 23]},{'ArmHeadDir'},[10];
%     
%     't5.2018.03.19',{[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
%     't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
%     't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 17 18 20],[21 22 23],[24 25 26],[27 28 29]},...
%         {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
%         
%     't5.2018.06.18',{[4 6 7 8 9 10 12]},{'LArmRArm'},[4];
% };

%codes:
%head = 1
%LArm = 2
%RArm = 3
%LLeg = 4
%RLeg = 5
% effNames = {'Head','LArm','RArm','LLeg','RLeg'};
% taskCodes = [5 3;
%    
%     1 3;
%     
%     2 3;
%     1 3;
%     4 5;
%     4 3;
%     
%     1 3;
%     5 3;
%     
%     1 5;
%     1 4;
%     1 2;
%     2 5;
%     2 4;
%     4 5;
%     4 3;
%     5 3;
%     
%     2 3;];

datasets = {    
    't5.2018.03.19',{[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 17 18 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
};

effNames = {'Head','LArm','RArm','LLeg','RLeg'};
taskCodes = [
    2 3;
    1 3;
    4 5;
    4 3;
    
    1 3;
    5 3;
    
    1 5;
    1 4;
    1 2;
    2 5;
    2 4;
    4 5;
    4 3;
    5 3;];

saveDir = '/Users/frankwillett/Data/Derived/bimanualMovCue/';

%%
effOrder = [3 5 2 4 1];
taskCodes_order = taskCodes;
for x=1:length(effOrder)
    rowIdx = find(taskCodes==effOrder(x));
    taskCodes_order(rowIdx) = x;
end
[~,datasetOrder] = sortrows(taskCodes_order,[2 1]);
datasetOrder(12:13) = datasetOrder([13 12]);

sortCodes = taskCodes(datasetOrder,:);

%%
dat = [];
pdStats = [];
varTables = [];
contextDim = [];
contextDim_ci = [];
decAcc_singleToDual = [];
decAcc_dual = [];

effDim = [];
effDim_ci = [];
ciDim = [];
ciDim_ci = [];
ciDim_lower = [];
ciDim_lower_ci = [];

for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    for blockSet=1:length(datasets{d,2})
        blockSetName = datasets{d,3}{blockSet};
        tmp = load([outDir filesep blockSetName '_varSummary.mat']);
        dat = [dat; tmp.varianceSummary];
        
        tmp = load([outDir filesep blockSetName '_encModelStats.mat']);
        pdStats = [pdStats; tmp.meanStats];
        
        tmp = load([outDir filesep blockSetName '_varTable.mat']);
        varTables = [varTables; {tmp.varTable_norm}];
        
        tmp = load([outDir filesep blockSetName '_effDimTransfer.mat']);
        colIdxVec = [1,2,1];
        for dimType=1:3
            colIdx = colIdxVec(dimType);
            dp1 = tmp.dimProj{1,colIdx}(:,:);
            dp2 = tmp.dimProj{2,colIdx}(:,:);

            dp1_ci_lower = squeeze(tmp.dimProj_ci{1,colIdx}(:,:,:,1));
            dp1_ci_higher = squeeze(tmp.dimProj_ci{1,colIdx}(:,:,:,2));
            dp1_ci_lower = dp1_ci_lower(:,:);
            dp1_ci_higher = dp1_ci_higher(:,:);

            dp2_ci_lower = squeeze(tmp.dimProj_ci{2,colIdx}(:,:,:,1));
            dp2_ci_higher = squeeze(tmp.dimProj_ci{2,colIdx}(:,:,:,2));
            dp2_ci_lower = dp2_ci_lower(:,:);
            dp2_ci_higher = dp2_ci_higher(:,:);

            dp2_ci = tmp.dimProj_ci{2,colIdx}(:,:);
            if dimType==3
                binIdx = 50;
            else
                binIdx = 90;
            end
                
            newRow = [dp1(binIdx,:), dp2(binIdx,:)];
            newRow_ci = [dp1_ci_lower(binIdx,:), dp2_ci_lower(binIdx,:), ...
                dp1_ci_higher(binIdx,:), dp2_ci_higher(binIdx,:)];

            if dimType==1
                ciDim = [ciDim; newRow];
                ciDim_ci = [ciDim_ci; newRow_ci];
            elseif dimType==2
                effDim = [effDim; newRow];
                effDim_ci = [effDim_ci; newRow_ci];
            elseif dimType==3
                ciDim_lower = [ciDim_lower; newRow];
                ciDim_lower_ci = [ciDim_lower_ci; newRow_ci];                
            end
        end
        
        tmp = load([outDir filesep blockSetName '_singleMovDualContextClassifier.mat']);
        newRow = [1-tmp.allL(:,1)'];
        decAcc_dual = [decAcc_dual; newRow];
        
        tmp = load([outDir filesep blockSetName '_crossMovSingleToDualClassifier.mat']);
        acc1 = sum(diag(tmp.allC{1,1}))/sum(tmp.allC{1,1}(:));
        acc2 = sum(diag(tmp.allC{2,1}))/sum(tmp.allC{2,1}(:));

        newRow = [acc1, acc2];
        decAcc_singleToDual = [decAcc_singleToDual; newRow];
        
        tmp = load([outDir filesep blockSetName '_contextDim.mat']);
        newRow = [];
        newRow_ci = [];
        for x=1:length(tmp.allResponse)
            newRow = [newRow, tmp.allResponse{x,1}(90)];
            newRow_ci = [newRow_ci, tmp.allResponse{x,2}(:,90)'];
        end
        contextDim = [contextDim; newRow];
        contextDim_ci = [contextDim_ci; newRow_ci];
    end
end

singleDualCross = zeros(length(varTables),2);
for t=1:length(varTables)
    singleDualCross(t,1) = varTables{t}(1,2);
    singleDualCross(t,2) = varTables{t}(3,4);
end

%%
%effector & ci dimensions
redColor = [0.8 0.3 0.3];
blueColor = [0.3 0.3 0.8];
purpleColor = [0.7 0.3 0.7];
colors = [redColor;
    redColor;
    blueColor;
    blueColor;
    purpleColor;
    purpleColor;
    purpleColor;
    purpleColor];
linSpacing = linspace(-0.15,0.15,8);
    
yLabels = {'Eff. Dimension (SD)','CD Dimension (SD)'};
plotIdx = [1 3 4 6 8 9 11 12 13 14];
flipDominanceIdx = [11];

dimsToPlot = {effDim, effDim_ci;
    ciDim, ciDim_ci};
for x=1:size(dimsToPlot,1)
    dimsToPlot{x,1}(flipDominanceIdx,1:4) = dimsToPlot{x,1}(flipDominanceIdx,[3 4 1 2]);
end
ciDim_lower(flipDominanceIdx,1:4) = ciDim_lower(flipDominanceIdx,[3 4 1 2]);

for dimIdx=1:2
    currentDim = dimsToPlot{dimIdx,1};
    currentDim_ci = dimsToPlot{dimIdx,2};
    
    if dimIdx==1
        mn = mean(currentDim(:,1:2),2);        
        currentDim = currentDim - mn;
        currentDim_ci = currentDim_ci - mn;
        
        for x=1:size(currentDim,1)
            if mean(currentDim(x,3:4))<0
                currentDim(x,:) = -currentDim(x,:);
                currentDim_ci(x,:) = -currentDim_ci(x,:);
            end
        end
    else
        mn = mean(ciDim_lower(:,1:2),2);

        currentDim = currentDim - mn;
        currentDim_ci = currentDim_ci - mn;   
        ciDim_lower_norm = ciDim_lower - mn;
        ciDim_lower_ci_norm = ciDim_lower_ci - mn;
    end
    
    currentDim = currentDim(datasetOrder,:);
    currentDim_ci = currentDim_ci(datasetOrder,:);
    
    currentDim_reduced = currentDim(plotIdx,:);
    currentDim_reduced_ci = currentDim_ci(plotIdx,:);

    figure('Position',[260   415   445   254]);
    hold on;
    for t=1:size(currentDim_reduced,1)
        for x=1:8
            plot(linSpacing(x)+t,currentDim_reduced(t,x),'o','Color',colors(x,:),'MarkerFaceColor',colors(x,:),'MarkerSize',8);
        end
    end
    if dimIdx==2
        currentDim = ciDim_lower_norm;
        currentDim_ci = ciDim_lower_ci_norm;
        
        currentDim_reduced = currentDim(plotIdx,:);
        currentDim_reduced_ci = currentDim_ci(plotIdx,:);
    
        for t=1:size(currentDim_reduced,1)
            for x=1:8
                plot(linSpacing(x)+t,currentDim_reduced(t,x),'o','Color',colors(x,:),'MarkerFaceColor',colors(x,:),'MarkerSize',8);
            end
        end        
    end
    
    expLabels = cell(length(currentDim),1);
    for x=1:length(expLabels)
        if ismember(datasetOrder(x),flipDominanceIdx)
            expLabels{x} = [effNames{sortCodes(x,2)}];
        else
            expLabels{x} = [effNames{sortCodes(x,1)}];
        end
    end
    
    ylabel(yLabels{dimIdx});
    set(gca,'XTick',1:length(currentDim_reduced));
    set(gca,'XTickLabel',expLabels(plotIdx),'XTickLabelRotation',45,'FontSize',16,'LineWidth',2);
    ylim([-2,12]);
    xlim([0,11]);
    
    saveas(gcf, [saveDir 'effDims_' num2str(dimIdx) '.png'], 'png');
    saveas(gcf, [saveDir 'effDims_' num2str(dimIdx) '.svg'], 'svg');
end

%%
alignedTables = varTables;
alignedTables{11} = alignedTables{11}([3 4 1 2 5],[3 4 1 2 5]);

figure
for x=1:length(varTables)
    subtightplot(4,4,x);
    imagesc(alignedTables{x});
    set(gca,'YDir','normal');
end

meanTable = zeros(size(alignedTables{1}));
for x=1:length(alignedTables)
    meanTable = meanTable + alignedTables{x};
end
meanTable= meanTable / length(alignedTables);

tickLabels = {'Single Eff 1','Dual Eff 1','Single Eff 2','Dual Eff 2','Dual'};

figure
imagesc(meanTable,[0 1]);
colorbar('FontSize',18,'LineWidth',2,'YTick',[0,0.5,1.0]);
set(gca,'XTick',1:length(tickLabels),'XTickLabel',tickLabels,'XTickLabelRotation',45,'YTick',1:length(tickLabels),'YTickLabel',tickLabels,'FontSize',16);
set(gca,'YDir','normal');
for rowIdx=1:size(meanTable,1)
    for colIdx=1:size(meanTable,2)
        text(colIdx,rowIdx,num2str(meanTable(rowIdx,colIdx),2),'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
    end
end
title('Normalized Variance Explained');
set(gca,'LineWidth',1)

saveas(gcf, [saveDir 'normVarExplainedTable.png'], 'png');
saveas(gcf, [saveDir 'normVarExplainedTable.svg'], 'svg');

%%
nVarSummary = 9;

allDat.varSingle_1 = dat(3:nVarSummary:end,:);
allDat.varSingle_2 = dat(4:nVarSummary:end,:);
allDat.varDual_1 = dat(1:nVarSummary:end,:);
allDat.varDual_2 = dat(2:nVarSummary:end,:);
allDat.varInteraction = dat(5:nVarSummary:end,:);

allDat.attenFactor1 = dat(3:nVarSummary:end,1)./dat(1:nVarSummary:end,1);
allDat.attenFactor2 = dat(4:nVarSummary:end,1)./dat(2:nVarSummary:end,1);
allDat.relativeAttenuation = allDat.attenFactor2 - allDat.attenFactor1;
allDat.relativeVariance_singleContext = dat(4:nVarSummary:end,1)./dat(3:nVarSummary:end,1);

bothAttenFactors = [allDat.attenFactor1, allDat.attenFactor2];
bothSingleVar = [allDat.varSingle_1(:,1), allDat.varSingle_2(:,1)];
%bothRelativeAtten = [allDat.attenFactor1 - allDat.attenFactor2, allDat.attenFactor2 - allDat.attenFactor1];
bothRelativeVar = [allDat.varSingle_1(:,1)./allDat.varSingle_2(:,1), allDat.varSingle_2(:,1)./allDat.varSingle_1(:,1)];
%bothRelativeVar = [allDat.varSingle_1(:,1)-allDat.varSingle_2(:,1), allDat.varSingle_2(:,1)-allDat.varSingle_1(:,1)];

af1 = dat(1:nVarSummary:end,1)./dat(3:nVarSummary:end,1);
af2 = dat(2:nVarSummary:end,1)./dat(4:nVarSummary:end,1);
bothRelativeAtten = [af1-af2, af2-af1];

relativeInteraction = [allDat.varInteraction(:,1)./allDat.varDual_1(:,1), allDat.varInteraction(:,1)./allDat.varDual_2(:,1)];

%%
%attenuation comparison matrix
plotMatrices = {1./bothAttenFactors, bothRelativeAtten, pdStats(:,5:6), singleDualCross, decAcc_dual, decAcc_singleToDual, relativeInteraction};
cScales = {[0,1.4],[-1,1],[0 70], [0, 1], [0, 1], [0, 1], [0, 1]};

rbMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);
colorMaps = {parula, rbMap, parula, parula, parula, parula, parula};

for matrixIdx=1:length(plotMatrices)
    attenMat_cell = cell(5,5);
    for effIdx=1:5
        rowIdx = find(taskCodes(:,1)==effIdx | taskCodes(:,2)==effIdx);
        allAxTick = [];
        allTickLabels = [];
        for t=1:length(rowIdx)
            colIdx = find(taskCodes(rowIdx(t),:)==effIdx);
            otherEffectorColIdx = find(taskCodes(rowIdx(t),:)~=effIdx);
            otherEffIdx = taskCodes(rowIdx(t),otherEffectorColIdx);
            attenMat_cell{effIdx, otherEffIdx} = [attenMat_cell{effIdx, otherEffIdx}, plotMatrices{matrixIdx}(rowIdx(t), colIdx)];
        end
    end
    
    attenMat = zeros(size(attenMat_cell));
    for x=1:length(attenMat)
        for y=1:length(attenMat)
            attenMat(x,y) = mean(attenMat_cell{x,y});
        end
    end

    for x=1:length(attenMat)
        attenMat(x,x) = mean(cScales{matrixIdx});
    end

    reorderIdx = [3 5 2 4 1];
    attenMat = attenMat(reorderIdx, reorderIdx);
    cLimit = cScales{matrixIdx};
    
    im = makeColorImage( attenMat, colorMaps{matrixIdx}, cLimit );
    for x=1:size(im,1)
        im(x,x,:) = [1 1 1];
    end
    
    figure
    image(im);
    set(gca,'XTick',1:5,'XTickLabel',effNames(reorderIdx),'YTick',1:5,'YTickLabel',effNames(reorderIdx));
    set(gca,'FontSize',24);
    for rowIdx=1:size(attenMat,1)
        for colIdx=1:size(attenMat,2)
            if colIdx==rowIdx
                continue;
            end
            text(colIdx,rowIdx,num2str(attenMat(rowIdx,colIdx),2),'HorizontalAlignment','center','FontSize',24,'FontWeight','bold');
        end
    end

    colormap(colorMaps{matrixIdx});
    colorbar('LineWidth',2,'FontSize',20,'YTick',[0,0.5,1],'YTickLabel',{num2str(cLimit(1),2), num2str(mean(cLimit),2), num2str(cLimit(2),2)});
    set(gca,'LineWidth',2);

    saveas(gcf, [saveDir 'attenuationComparisonMatrix_' num2str(matrixIdx) '.png'], 'png');
    saveas(gcf, [saveDir 'attenuationComparisonMatrix_' num2str(matrixIdx) '.svg'], 'svg');
end

%%
%single variance
effOrder = [3 5 2 4 1];
effColors = linspecer(5);
currentPlotIdx = 1;
    
figure('Position',[332   902   498   188]);
hold on;
for effIdx=1:length(effOrder)

    %find codes with this effector
    currentEff = effOrder(effIdx);
    hasEffector = false(size(taskCodes,1),1);
    
    for x=1:length(hasEffector)
        if any(ismember(taskCodes(x,:), currentEff))
            hasEffector(x) = true;
        end
    end
    
    tableIdx = find(hasEffector);
    [~,sortIdx] = sort(taskCodes(tableIdx,1),'descend');
    tableIdx = tableIdx(sortIdx);
    
    for x=1:length(tableIdx)
        colIdx1 = find(taskCodes(tableIdx(x),:)==currentEff);
        eff1Code = taskCodes(tableIdx(x),colIdx1);
        if colIdx1==1
            mn = allDat.varSingle_1(tableIdx(x),1);
            ci = allDat.varSingle_1(tableIdx(x),2:3);
        else
            mn = allDat.varSingle_2(tableIdx(x),1);
            ci = allDat.varSingle_2(tableIdx(x),2:3);
        end
        
        bar(currentPlotIdx, mn, 0.8, 'FaceColor', effColors(eff1Code,:),'LineWidth',1);
        errorbar(currentPlotIdx, mn, mn-ci(1), ci(2)-mn, 'k','LineWidth',1);
        currentPlotIdx = currentPlotIdx + 1;
    end

    ylim([0,5.5]);
    set(gca,'XTick',[3.5,10.5,16,20.5,25],'XTickLabel',{'Right Arm','Right Leg','Left Arm','Left Leg','Head'},'XTickLabelRotation',45,...
        'FontSize',16,'LineWidth',2);
end
ylabel('\Delta Rate (SD)');
saveas(gcf, [saveDir 'varianceBars.png'], 'png');
saveas(gcf, [saveDir 'varianceBars.svg'], 'svg');

%%
%plot every experiment with a bar cluster
plotIdx = [1 3 4 6 8 9 11 12 13 14];
flipDominanceIdx = [11];

redColor = [0.8 0.3 0.3];
blueColor = [0.3 0.3 0.8];

allDat.attenFactor1 = dat(3:nVarSummary:end,1)./dat(1:nVarSummary:end,1);
allDat.attenFactor2 = dat(4:nVarSummary:end,1)./dat(2:nVarSummary:end,1);
bothAttenFactors = [allDat.attenFactor1, allDat.attenFactor2];
bothAttenFactors_ci = [dat(3:nVarSummary:end,2:3)./dat(1:nVarSummary:end,2:3), ...
    dat(4:nVarSummary:end,2:3)./dat(2:nVarSummary:end,2:3)];

allDat.dualToSingle1 = dat(8:nVarSummary:end,1);
allDat.dualToSingle2 = dat(9:nVarSummary:end,1);
allDat.dualToSingle_ci = [dat(8:nVarSummary:end,2:3), dat(9:nVarSummary:end,2:3)];

plotVars = {1./bothAttenFactors, [allDat.dualToSingle1, allDat.dualToSingle2]};
plotVars_ci = {1./bothAttenFactors_ci, allDat.dualToSingle_ci};

for plotVarIdx = 1:length(plotVars)
    plotVars{plotVarIdx}(flipDominanceIdx,[1 2]) = plotVars{plotVarIdx}(flipDominanceIdx,[2 1]);
    plotVars{plotVarIdx} = plotVars{plotVarIdx}(datasetOrder(plotIdx),:);
    
    plotVars_ci{plotVarIdx}(flipDominanceIdx,[1 2 3 4]) = plotVars_ci{plotVarIdx}(flipDominanceIdx,[3 4 1 2]);
    plotVars_ci{plotVarIdx} = plotVars_ci{plotVarIdx}(datasetOrder(plotIdx),:);
end

yLabels = {'Dual/Single Ratio','Dual->Single\newlineVar. Expl.'};

for plotVarIdx = 1:length(plotVars)
    pVar = plotVars{plotVarIdx};
    pVar_ci = plotVars_ci{plotVarIdx};
    
    figure('Position',[332   900   498   190]);
    for x=1:length(pVar)
        hold on;        
        bar(x+0.15, pVar(x,1), 0.25, 'FaceColor', redColor,'LineWidth',1);
        bar(x-0.15, pVar(x,2), 0.25, 'FaceColor', blueColor,'LineWidth',1);
        
        %errorbar(x+0.15, pVar(x,1), pVar(x,1)-pVar_ci(x,1), pVar_ci(x,2)-pVar(x,1), '-k');
        %errorbar(x-0.15, pVar(x,2), pVar(x,2)-pVar_ci(x,3), pVar_ci(x,4)-pVar(x,2), '-k');
    end
    
    expLabels = cell(length(bothAttenFactors),1);
    for x=1:length(bothAttenFactors)
        if ismember(datasetOrder(x),flipDominanceIdx)
            %expLabels{x} = [effNames{sortCodes(x,1)} ' & ' effNames{sortCodes(x,2)}];
            expLabels{x} = [effNames{sortCodes(x,2)}];
        else
            %expLabels{x} = [effNames{sortCodes(x,2)} ' & ' effNames{sortCodes(x,1)}];
            expLabels{x} = [effNames{sortCodes(x,1)}];
        end
    end
    
    set(gca,'XTick',1:length(pVar),'XTickLabel',expLabels(plotIdx),'XTickLabelRotation',45,'FontSize',16,'LineWidth',2);
    ylabel(yLabels{plotVarIdx});
    xlim([0,11]);
    
    saveas(gcf, [saveDir 'comparisonBars_' num2str(plotVarIdx) '.png'], 'png');
    saveas(gcf, [saveDir 'comparisonBars_' num2str(plotVarIdx) '.svg'], 'svg');
end
    