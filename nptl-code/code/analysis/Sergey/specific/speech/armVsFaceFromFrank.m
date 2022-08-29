%%
blockList = [5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
% sessionPath = ['/Users/frankwillett/Data' filesep 'BG Datasets' filesep 't5.2018.10.22' filesep];
sessionPath = ['/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.22/']

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, blockList, [], 4.5 );

%%
%get raw trial codes
trlCodes = zeros(size(R));
for t=1:length(trlCodes)
    trlCodes(t) = R(t).startTrialParams.currentMovement;
end
[trlCodeList,~,trlCodesRemap] = unique(trlCodes);

%reorcder the codes to put sets of movements together
reorderIdx = [34, ...
    1 2 11 12 13 14 15 16 17 18 19, ...
    3 4 5 6 7 8 9 10, ...
    20 21 22 23 24 25 32 33, ...
    26 27 28 29 30 31];

trlCodesReorder = trlCodes;
for t=1:length(reorderIdx)
    tmp = find(trlCodes==trlCodeList(reorderIdx(t)));
    trlCodesReorder(tmp) = t;
end

%%
%compute mean rates for each trial between 200 and 600 ms
meanRate = zeros(length(R),192);
for t=1:length(R)
    goIdx = R(t).goCue;
    movWindow = goIdx + (200:600);
    windowLen = length(movWindow)/1000;
    
    meanRate(t,1:96) = sum(R(t).spikeRaster(:,movWindow),2)/windowLen;
    meanRate(t,97:end) = sum(R(t).spikeRaster(:,movWindow),2)/windowLen;
end

%%
%exclude low firing rate units
tooLow = mean(meanRate)<1;
meanRate(:,tooLow) = [];

%%
%For each movement, compute modulation magnitude relative to baseline.
%Makes a scatter plot with the top 2 PCs for each movement as a sanity check.
averageModulation = zeros(length(trlCodeList),2);
figure; 
for t=1:length(trlCodeList)
    trlIdx = find(trlCodesReorder==t);
    baselineIdx = find(trlCodesReorder==1);
    averageModulation(t,1) = norm(mean(meanRate(trlIdx,:)) - mean(meanRate(baselineIdx,:)));
    
    tmp = [meanRate(trlIdx,:); meanRate(baselineIdx,:)];
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(tmp);

    subtightplot(6,6,t);
    hold on; 
    plot(SCORE(1:length(trlIdx),1), SCORE(1:length(trlIdx),2), 'o');
    plot(SCORE((1+length(trlIdx)):end,1), SCORE((1+length(trlIdx)):end,2), 'ro');
    set(gca,'XTick',[],'YTick',[]);
end

%%
%Modulation measure removing common mode. 
%u_base + u_grandDiff + u_conDiff_1 + u_conDiff_2 + ...
codeSets = {2:12, 13:20, 21:28, 29:34};
for setIdx=1:length(codeSets)
    setTrl = find(ismember(trlCodesReorder, codeSets{setIdx}));
    baselineTrl = find(trlCodesReorder==1);
    
    baselineMean = mean(meanRate(baselineTrl,:));
    setRates_minusBase = meanRate(setTrl,:) - baselineMean;
    setGrandMean = mean(setRates_minusBase);
    setConRates = setRates_minusBase - setGrandMean;
    
    for t=1:length(codeSets{setIdx})
        innerTrlIdx = trlCodesReorder(setTrl)==codeSets{setIdx}(t);
        averageModulation(codeSets{setIdx}(t),2) = norm(mean(setConRates(innerTrlIdx,:)));
    end
end

%%
%Plot an overview of all movements as another check.
movLabels = {'SayBa','SayGa','TurnRight','TurnLeft','TurnUp','TurnDown','TiltRight','TiltLeft','Forward','Backward',...
    'TongueUp','TongueDown','TongueLeft','TongueRight','MouthOpen','JawClench','LipsPucker','EyebrowsRaise','NoseWrinkle',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen','IndexRaise','TumbRaise','Nothing'};
movLabels = movLabels(reorderIdx);

figure('Position',[680   793   928   305]);
plot(averageModulation,'o','LineWidth',2);
set(gca,'XTick',1:length(averageModulation),'XTickLabel',movLabels,'XTickLabelRotation',45,'FontSize',16);
ylabel('Modulation Norm');

%%
%Compare face trials to arm trials.
modType = 1;
codeSets = {2:12, 13:20, 21:28, 29:34};

anova1([averageModulation(codeSets{1},modType); averageModulation(codeSets{3},modType)],...
    [zeros(length(codeSets{1}),1); ones(length(codeSets{3}),1)]);

figure('Position',[680   873   217   225]);
hold on;
bar([mean(averageModulation(codeSets{1},modType)), mean(averageModulation(codeSets{3},modType))],'FaceColor','w','LineWidth',2);
plot(1,averageModulation(codeSets{1},modType),'ko','MarkerSize',12);
plot(2,averageModulation(codeSets{3},modType),'ko','MarkerSize',12);
xlim([0.5,2.5]);
set(gca,'FontSize',16);
set(gca,'XTick',[1 2],'XTickLabel',{'Face','Arm'},'XTickLabelRotation',45);
ylabel('Modulation Size (Hz)');
