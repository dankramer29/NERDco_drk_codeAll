%%
blockList = [26 27 28 30 31];
sessionName = 't5.2019.04.03';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1500 4000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Pilot' filesep sessionName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%       
bNums = horzcat(blockList);
movField = 'windowsMousePosition';
filtOpts.filtFields = {'windowsMousePosition'};
filtOpts.filtCutoff = 10/500;
R = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );

allR = []; 
for x=1:length(R)
    for t=1:length(R{x})
        R{x}(t).blockNum=bNums(x);
        R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
    end
    allR = [allR, R{x}];
end

alignFields = {'goCue'};
smoothWidth = 0;
datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
timeWindow = [-1000,7500];
binMS = 10;
alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
meanRate = mean(alignDat.rawSpikes)*1000/binMS;
tooLow = meanRate < 1.0;
alignDat.rawSpikes(:,tooLow) = [];
alignDat.meanSubtractSpikes(:,tooLow) = [];
alignDat.zScoreSpikes(:,tooLow) = [];

smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);

trlCodes = alignDat.currentMovement(alignDat.eventIdx);
nothingTrl = trlCodes==218;

%%
timeWindow_mpca = [-1000,4000];
tw =  timeWindow_mpca/binMS;
tw(1) = tw(1) + 1;
tw(2) = tw(2) - 1;
    
margGroupings = {{1, [1 2]}, {2}};
margNames = {'Condition-dependent', 'Condition-independent'};
opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 8;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

%      LETTER_A(400)
%      LETTER_B(401)
%      LETTER_C(402)
%      LETTER_D(403)
%      LETTER_T(404)
%      LETTER_M(405)
%      LETTER_O(406)
%       
%      LETTER_CAT(407)
%      LETTER_BAT(408)
%      LETTER_BOMB(409)
%      LETTER_TOM(410)

letterCodes = [400:406];
wordCodes = [407:410];
codeSets = {letterCodes, wordCodes};

mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(codeSets) 
    trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    mc_oneStart = mc-min(mc)+1;
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes, alignDat.eventIdx(trlIdx), ...
        mc_oneStart', tw, binMS/1000, opts_m );
end
close all;

%%
codeList = 400:410;
movLabels = {'a','b','c','d','t','m','o','cat','bat','bomb','tom'};

tw_all = [-99, 749];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;
nDimToShow = 3;

figure('Position',[680   185   442   913]);
for c=1:length(codeList)
    concatDat = triggeredAvg( mPCA_out{pIdx}.readoutZ_unroll(:,1:nDimToShow), alignDat.eventIdx(trlCodes==codeList(c)), [-99,749] );
    
    for dimIdx=1:nDimToShow
        subtightplot(11,nDimToShow,(c-1)*nDimToShow + dimIdx);
        hold on;
        
        imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),[-1 1]);
        axis tight;
        plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
        plot([4,4],get(gca,'YLim'),'-k','LineWidth',2);
        plot([5.5,5.5],get(gca,'YLim'),'-k','LineWidth',2);
        
        cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
        colormap(cMap);
        
        %title(movLabels{c});
        if dimIdx==1
            ylabel(movLabels{c},'FontSize',16,'FontWeight','bold');
        end
        if c==1
            title(['Dimension ' num2str(dimIdx)],'FontSize',16);
        end
        
        set(gca,'FontSize',16);
        if c==length(codeList)
            set(gca,'YTick',[]);
            xlabel('Time (s)');
        else
            set(gca,'XTick',[],'YTick',[]);
        end
    end
end

%%
figure
for c=1:length(codeList)
    trlIdx = find(trlCodes==codeList(c));    
    concatDat = triggeredAvg( alignDat.windowsMousePosition, alignDat.eventIdx(trlCodes==codeList(c)), [-100,500] );
    
    subtightplot(4,4,c);
    hold on;
    for t=1:size(concatDat,1)
        X = squeeze(concatDat(t,100:end,1));
        Y = squeeze(concatDat(t,100:end,2));
        X = X - X(1);
        Y = Y - Y(1);
        
        plot(X);
        plot(Y,'r');
    end
    title(movLabels{c});
end

%%

%%
%linear classifier
movLabels = {'a','b','c','d','t','m','o'};

codeList = unique(trlCodes);
dataIdxStart = 20:50;
nDecodeBins = 8;

allFeatures = [];
allCodes = trlCodes;
for t=1:length(trlCodes)
    tmp = [];
    dataIdx = dataIdxStart;
    for binIdx=1:nDecodeBins
        loopIdx = dataIdx + alignDat.eventIdx(t);
        tmp = [tmp, mean(alignDat.zScoreSpikes(loopIdx,:))];
        dataIdx = dataIdx + length(dataIdx);
    end
    
    allFeatures = [allFeatures; tmp];
end

subsetIdx = find(ismember(allCodes, letterCodes));

obj = fitcdiscr(allFeatures(subsetIdx,:),allCodes(subsetIdx),'DiscrimType','diaglinear');
cvmodel = crossval(obj);
L = kfoldLoss(cvmodel);
predLabels = kfoldPredict(cvmodel);

C = confusionmat(allCodes(subsetIdx), predLabels);
C_counts = C;
for rowIdx=1:size(C,1)
    C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
end

colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

figure('Position',[212   524   808   567]);
hold on;

imagesc(C);
set(gca,'XTick',1:length(movLabels),'XTickLabel',movLabels,'XTickLabelRotation',45);
set(gca,'YTick',1:length(movLabels),'YTickLabel',movLabels);
set(gca,'FontSize',16);
set(gca,'LineWidth',2);
colorbar;
title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
axis tight;
% letterCodes = [400:406];
% wordCodes = [407:410];
% codeSets = {letterCodes, wordCodes};
% 
% currentIdx = 1;
% currentColor = 1;
% for c=1:length(codeSets)
%     newIdx = currentIdx + (1:length(codeSets{c}))';
%     rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(currentColor,:));
%     currentIdx = currentIdx + length(codeSets{c});
%     currentColor = currentColor + 1;
% end
% axis tight;

saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');
saveas(gcf,[outDir filesep 'linearClassifier.pdf'],'pdf');
