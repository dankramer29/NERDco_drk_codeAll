%%
datasets = {
    't5.2018.05.30',{[14 15 16 17 18 19 21 22 23 24]},{'ArmLegDir'},[14];
    't5.2018.06.04',{[10 11 12 13 14 15 16 17 18 19 20 21 22 23]},{'ArmHeadDir'},[10];
    
    't5.2018.03.19',{[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 17 18 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
        
    't5.2018.06.18',{[4 6 7 8 9 10 12]},{'LArmRArm'},[4];
};

%%
dat = [];
for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    for blockSet=1:length(datasets{d,2})
        blockSetName = datasets{d,3}{blockSet};
        tmp = load([outDir filesep blockSetName '_varSummary.mat']);
        dat = [dat; tmp.varianceSummary];
    end
end

%%
pdStats = [];
for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    for blockSet=1:length(datasets{d,2})
        blockSetName = datasets{d,3}{blockSet};
        tmp = load([outDir filesep blockSetName '_encModelStats.mat']);
        pdStats = [pdStats; tmp.meanStats];
    end
end

%%
saveDir = '/Users/frankwillett/Data/Derived/bimanualMovCue/';

%%
%codes:
%head = 1
%LArm = 2
%RArm = 3
%LLeg = 4
%RLeg = 5
effNames = {'Head','LArm','RArm','LLeg','RLeg'};
taskCodes = [5 3;
   
    1 3;
    
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
    5 3;
    
    2 3;];

allDat.varSingle_1 = dat(3:4:end,:);
allDat.varSingle_2 = dat(4:4:end,:);
allDat.varDual_1 = dat(1:4:end,:);
allDat.varDual_2 = dat(2:4:end,:);

allDat.attenFactor1 = dat(3:4:end,1)./dat(1:4:end,1);
allDat.attenFactor2 = dat(4:4:end,1)./dat(2:4:end,1);
allDat.relativeAttenuation = allDat.attenFactor2 - allDat.attenFactor1;
allDat.relativeVariance_singleContext = dat(4:4:end,1)./dat(3:4:end,1);

bothAttenFactors = [allDat.attenFactor1, allDat.attenFactor2];
bothSingleVar = [allDat.varSingle_1(:,1), allDat.varSingle_2(:,1)];
bothRelativeAtten = [allDat.attenFactor1 - allDat.attenFactor2, allDat.attenFactor2 - allDat.attenFactor1];
bothRelativeVar = [allDat.varSingle_1(:,1)./allDat.varSingle_2(:,1), allDat.varSingle_2(:,1)./allDat.varSingle_1(:,1)];
%bothRelativeVar = [allDat.varSingle_1(:,1)-allDat.varSingle_2(:,1), allDat.varSingle_2(:,1)-allDat.varSingle_1(:,1)];

af1 = dat(1:4:end,1)./dat(3:4:end,1);
af2 = dat(2:4:end,1)./dat(4:4:end,1);
bothRelativeAtten = [af1-af2, af2-af1];

%%
%attenuation bars
remainingCodes = taskCodes;
%remainingAttenFactors = 1./bothAttenFactors;
remainingAttenFactors = pdStats(:,5:6);
%removeIdx = [

effOrder = [3 5 1 2 4];
effColors = linspecer(5);

figure
for effIdx=1:length(effOrder)
    subplot(1,5,effIdx);
    hold on;
    currentPlotIdx = 1;
    
    %find remaining codes with this effector
    currentEff = effOrder(effIdx);
    hasEffector = false(size(remainingCodes,1),1);
    
    for x=1:length(hasEffector)
        if any(ismember(remainingCodes(x,:), currentEff))
            hasEffector(x) = true;
        end
    end
    
    tableIdx = find(hasEffector);
    [~,sortIdx] = sort(remainingCodes(tableIdx,1),'descend');
    tableIdx = tableIdx(sortIdx);
    
    for x=1:length(tableIdx)
        colIdx1 = find(remainingCodes(tableIdx(x),:)==currentEff);
        colIdx2 = find(remainingCodes(tableIdx(x),:)~=currentEff);
        
        eff1Code = remainingCodes(tableIdx(x),colIdx1);
        eff2Code = remainingCodes(tableIdx(x),colIdx2);
        
        bar(currentPlotIdx-0.15, remainingAttenFactors(tableIdx(x), colIdx1), 0.3, 'FaceColor', effColors(eff1Code,:));
        bar(currentPlotIdx+0.15, remainingAttenFactors(tableIdx(x), colIdx2), 0.3, 'FaceColor', effColors(eff2Code,:));
        
        currentPlotIdx = currentPlotIdx + 1;
    end
    
    remainingCodes(hasEffector,:) = [];
    remainingAttenFactors(hasEffector,:) = [];
    
    title(effNames{currentEff});
end

%%
%attenuation comparison matrix
attenMat = zeros(5,5);
for effIdx=1:5
    rowIdx = find(taskCodes(:,1)==effIdx | taskCodes(:,2)==effIdx);
    allAxTick = [];
    allTickLabels = [];
    for t=1:length(rowIdx)
        colIdx = find(taskCodes(rowIdx(t),:)==effIdx);
        otherEffectorColIdx = find(taskCodes(rowIdx(t),:)~=effIdx);
        otherEffIdx = taskCodes(rowIdx(t),otherEffectorColIdx);
        attenMat(effIdx, otherEffIdx) = 1./bothAttenFactors(rowIdx(t), colIdx);
    end
end

for x=1:length(attenMat)
    attenMat(x,x) = 1;
end

reorderIdx = [3 5 1 2 4];
attenMat = attenMat(reorderIdx, reorderIdx);
cLimit = [-max(abs(attenMat(:))), max(abs(attenMat(:)))];

figure
imagesc(attenMat,[0 2]);
set(gca,'XTick',1:5,'XTickLabel',effNames(reorderIdx),'YTick',1:5,'YTickLabel',effNames(reorderIdx));
set(gca,'FontSize',18);
for rowIdx=1:size(attenMat,1)
    for colIdx=1:size(attenMat,2)
        if colIdx==rowIdx
            continue;
        end
        text(colIdx,rowIdx,num2str(attenMat(rowIdx,colIdx),2),'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
    end
end

cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);
colormap(cMap);
colorbar('LineWidth',2,'FontSize',20);
set(gca,'LineWidth',2);

saveas(gcf, [saveDir 'attenuationComparisonMatrix.png'], 'png');
saveas(gcf, [saveDir 'attenuationComparisonMatrix.svg'], 'svg');

%%
%attenuation comparison matrix
attenMat = zeros(5,5);
for effIdx=1:5
    rowIdx = find(taskCodes(:,1)==effIdx | taskCodes(:,2)==effIdx);
    allAxTick = [];
    allTickLabels = [];
    for t=1:length(rowIdx)
        colIdx = find(taskCodes(rowIdx(t),:)==effIdx);
        otherEffectorColIdx = find(taskCodes(rowIdx(t),:)~=effIdx);
        otherEffIdx = taskCodes(rowIdx(t),otherEffectorColIdx);
        attenMat(effIdx, otherEffIdx) = bothRelativeAtten(rowIdx(t), colIdx);
    end
end

reorderIdx = [3 5 1 2 4];
attenMat = attenMat(reorderIdx, reorderIdx);
cLimit = [-max(abs(attenMat(:))), max(abs(attenMat(:)))];

figure
imagesc(attenMat,cLimit);
set(gca,'XTick',1:5,'XTickLabel',effNames(reorderIdx),'YTick',1:5,'YTickLabel',effNames(reorderIdx));
set(gca,'FontSize',18);
for rowIdx=1:size(attenMat,1)
    for colIdx=1:size(attenMat,2)
        if colIdx==rowIdx
            continue;
        end
        text(colIdx,rowIdx,num2str(attenMat(rowIdx,colIdx),2),'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
    end
end

cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);
colormap(cMap);
colorbar('LineWidth',2,'FontSize',20);
set(gca,'LineWidth',2);

saveas(gcf, [saveDir 'attenuationComparisonMatrix.png'], 'png');
saveas(gcf, [saveDir 'attenuationComparisonMatrix.svg'], 'svg');

%%
%single movement variance comparison matrix
varMat = zeros(5,5);
for effIdx=1:5
    rowIdx = find(taskCodes(:,1)==effIdx | taskCodes(:,2)==effIdx);
    allAxTick = [];
    allTickLabels = [];
    for t=1:length(rowIdx)
        colIdx = find(taskCodes(rowIdx(t),:)==effIdx);
        otherEffectorColIdx = find(taskCodes(rowIdx(t),:)~=effIdx);
        otherEffIdx = taskCodes(rowIdx(t),otherEffectorColIdx);
        varMat(effIdx, otherEffIdx) = bothRelativeVar(rowIdx(t), colIdx);
    end
end

reorderIdx = [3 5 1 2 4];
varMat = varMat(reorderIdx, reorderIdx);
cLimit = [-max(abs(varMat(:))), max(abs(varMat(:)))];

figure
imagesc(varMat,cLimit);
set(gca,'XTick',1:5,'XTickLabel',effNames(reorderIdx),'YTick',1:5,'YTickLabel',effNames(reorderIdx));
set(gca,'FontSize',18);
for rowIdx=1:size(varMat,1)
    for colIdx=1:size(varMat,2)
        text(colIdx,rowIdx,num2str(varMat(rowIdx,colIdx),2),'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
    end
end

colormap(cMap);
colorbar('LineWidth',2,'FontSize',20);
set(gca,'LineWidth',2);

saveas(gcf, [saveDir 'varianceComparisonMatrix.png'], 'png');
saveas(gcf, [saveDir 'varianceComparisonMatrix.svg'], 'svg');

%%
figure('Position',[645          48         595        1050]);
for effIdx=1:5
    subplot(5,1,effIdx);
    hold on;
    
    rowIdx = find(taskCodes(:,1)==effIdx | taskCodes(:,2)==effIdx);
    allAxTick = [];
    allTickLabels = [];
    for t=1:length(rowIdx)
        colIdx = find(taskCodes(rowIdx(t),:)==effIdx);
        otherEffectorColIdx = find(taskCodes(rowIdx(t),:)~=effIdx);
        otherEffIdx = taskCodes(rowIdx(t),otherEffectorColIdx);
        
        bar(t-0.15, bothAttenFactors(rowIdx(t), colIdx), 0.15, 'FaceColor', [0 0 0.9],'LineWidth',1);
        bar(t+0.15, bothAttenFactors(rowIdx(t), otherEffectorColIdx), 0.15, 'FaceColor', [0.9 0 0],'LineWidth',1); 
        
        allAxTick = [allAxTick, t-0.15, t+0.15];
        allTickLabels = [allTickLabels, effNames(effIdx), effNames(otherEffIdx)];
    end
    set(gca,'XTick',allAxTick,'XTickLabels',allTickLabels,'XTickLabelRotation',45,'FontSize',14,'LineWidth',1);
    ylim([0 1.2]);
    ylabel(effNames(effIdx));
end
saveas(gcf, [saveDir 'attenuationRatio_allEffectors.png'], 'png');
      
%%
figure('Position',[645          48         595        1050]);
for effIdx=1:5
    subplot(5,1,effIdx);
    hold on;
    
    rowIdx = find(taskCodes(:,1)==effIdx | taskCodes(:,2)==effIdx);
    allAxTick = [];
    allTickLabels = [];
    for t=1:length(rowIdx)
        colIdx = find(taskCodes(rowIdx(t),:)==effIdx);
        otherEffectorColIdx = find(taskCodes(rowIdx(t),:)~=effIdx);
        otherEffIdx = taskCodes(rowIdx(t),otherEffectorColIdx);
        
        bar(t-0.15, bothSingleVar(rowIdx(t), colIdx), 0.15, 'FaceColor', [0 0 0.9],'LineWidth',1);
        bar(t+0.15, bothSingleVar(rowIdx(t), otherEffectorColIdx), 0.15, 'FaceColor', [0.9 0 0],'LineWidth',1); 
        
        allAxTick = [allAxTick, t-0.15, t+0.15];
        allTickLabels = [allTickLabels, effNames(effIdx), effNames(otherEffIdx)];
    end
    set(gca,'XTick',allAxTick,'XTickLabels',allTickLabels,'XTickLabelRotation',45,'FontSize',14,'LineWidth',1);
    ylabel(effNames(effIdx));
end
saveas(gcf, [saveDir 'uniEffectorVariance_allEffectors.png'], 'png');
    
    
    