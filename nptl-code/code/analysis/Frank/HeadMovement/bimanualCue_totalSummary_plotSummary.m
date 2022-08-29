%%
datasets = {
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RLegRArm'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 19 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
};

%%
dat = cell(size(datasets,1),1);
for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    dat{d} = load([outDir filesep 'varianceLossSummary_goCue.mat'],'totalSummary','totalSummary_os','totalSummary_2fac');
end

saveDir = '/Users/frankwillett/Data/Derived/bimanualMovCue/';
%%
%codes:
%head = 1
%LArm = 2
%RArm = 3
%LLeg = 4
%RLeg = 5
%Tongue = 6

allDat.totalSummary = [dat{1}.totalSummary; dat{2}.totalSummary; dat{3}.totalSummary];
allDat.totalSummary_os = [dat{1}.totalSummary_os; dat{2}.totalSummary_os; dat{3}.totalSummary_os];
allDat.totalSummary_2fac = [dat{1}.totalSummary_2fac; dat{2}.totalSummary_2fac; dat{3}.totalSummary_2fac];

attenRatio = allDat.totalSummary_2fac ./ allDat.totalSummary(:,1:2);

avgSummary = zeros(1,2);
for x=2:size(attenRatio,1)
    [~,maxIdx] = max(allDat.totalSummary(x,1:2));
    [~,minIdx] = min(allDat.totalSummary(x,1:2));
    avgSummary(1) = avgSummary(1) + (attenRatio(x,maxIdx));
    avgSummary(2) = avgSummary(2) + (attenRatio(x,minIdx));
    %avgSummary(1) = avgSummary(1) + max(attenRatio(x,:));
    %avgSummary(2) = avgSummary(2) + min(attenRatio(x,:));
end
avgSummary = avgSummary / (size(attenRatio,1)-1);

taskCodes = [1 6;
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

testIdx = [2 3 5 6 7];

effNames = {'Head','LArm','RArm','LLeg','RLeg','Tng'};

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
        
        bar(t-0.15, attenRatio(rowIdx(t), colIdx), 0.15, 'FaceColor', [0 0 0.9],'LineWidth',1);
        bar(t+0.15, attenRatio(rowIdx(t), otherEffectorColIdx), 0.15, 'FaceColor', [0.9 0 0],'LineWidth',1); 
        
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
        
        bar(t-0.15, allDat.totalSummary(rowIdx(t), colIdx), 0.15, 'FaceColor', [0 0 0.9],'LineWidth',1);
        bar(t+0.15, allDat.totalSummary(rowIdx(t), otherEffectorColIdx), 0.15, 'FaceColor', [0.9 0 0],'LineWidth',1); 
        
        allAxTick = [allAxTick, t-0.15, t+0.15];
        allTickLabels = [allTickLabels, effNames(effIdx), effNames(otherEffIdx)];
    end
    set(gca,'XTick',allAxTick,'XTickLabels',allTickLabels,'XTickLabelRotation',45,'FontSize',14,'LineWidth',1);
    ylim([0 80]);
    ylabel(effNames(effIdx));
end
saveas(gcf, [saveDir 'uniEffectorVariance_allEffectors.png'], 'png');
    
    
    