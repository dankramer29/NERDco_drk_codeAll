%%
blockList = [3 4 5 7 8];
sessionName = 't5.2019.04.08';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Pilot' filesep sessionName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

alignedCube = load('hwCube_aligned.mat');

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
timeWindow = [-500,3500];
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
%replace with aligned cube data
alignDat.zScoreSpikes_align = alignDat.zScoreSpikes;

allLabels = {'nothing','a','b','c','d','t','m','o','cat','bat','tom','mat'};
codeList = unique(trlCodes);
for t=1:length(allLabels)
    trlIdx = find(trlCodes==codeList(t));
    for x=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(x))-49):(alignDat.eventIdx(trlIdx(x))+350);
        alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(allLabels{t})(x,2:end,:);
    end
end

alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0 ;

%%
timeWindow_mpca = [-500,3500];
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
wordCodes = [407, 408, 410, 411];
codeSets = {letterCodes, wordCodes};

mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(codeSets) 
    trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( alignDat.zScoreSpikes_align, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end
close all;

%%
codeList = [letterCodes, wordCodes];
movLabels = {'a','b','c','d','t','m','o','cat','bat','tom','mat'};

tw_all = [-99, 400];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;
nDimToShow = 5;

figure('Position',[680   185   442   913]);
for c=1:length(codeList)
    concatDat = triggeredAvg( mPCA_out{pIdx}.readoutZ_unroll(:,1:nDimToShow), alignDat.eventIdx(trlCodes==codeList(c)), [-99,400] );
    
    for dimIdx=1:nDimToShow
        subtightplot(11,nDimToShow,(c-1)*nDimToShow + dimIdx);
        hold on;
        
        imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),[-1 1]);
        axis tight;
        plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
        plot([3,3],get(gca,'YLim'),'-k','LineWidth',2);
        
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
%ALIGNED
alignedDat = load('hwCube_aligned.mat');
codeList = [letterCodes, wordCodes];
movLabels = {'a','b','c','d','t','m','o','cat','bat','tom','mat'};

letterLabel = [[0,0.8,2.25,3.0];
    [0,1.25,2.2,3.0];
    [0,1.25,2.2,3.0];
    [0,1,2.3,3.0]];

tw_all = [-50, 350];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;
nDimToShow = 5;

figure('Position',[680   185   442   913]);
for c=1:length(codeList)
    concatDat = alignedDat.(movLabels{c});
    concatDat(isnan(concatDat)) = 0;
    
    reducedDat = zeros(size(concatDat,1), size(concatDat,2), nDimToShow);
    for trialIdx=1:size(concatDat,1)
        reducedDat(trialIdx,:,:) = squeeze(concatDat(trialIdx,:,:))*mPCA_out{pIdx}.readouts(:,1:nDimToShow);
    end
    
    for dimIdx=1:nDimToShow
        subtightplot(11,nDimToShow,(c-1)*nDimToShow + dimIdx);
        hold on;
        
        imagesc(timeAxis, 1:size(reducedDat,1), squeeze(reducedDat(:,:,dimIdx)),[-1 1]);
        axis tight;
        plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
        plot([3,3],get(gca,'YLim'),'-k','LineWidth',2);
        
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
        
%         if any(strcmp(movLabels{c},{'cat','bat','tom','mat'}))
%             colors = hsv(3)*0.8;
%             yLimit = get(gca,'YLim');
%             letterLabelIdx = c - 7;
%             labelTimes = letterLabel(letterLabelIdx,:);
%             for letterIdx=1:3
%                 pos = [labelTimes(letterIdx),0,labelTimes(letterIdx+1)-labelTimes(letterIdx),yLimit(end)];
%                 rectangle('Position',pos,'LineWidth',4,'EdgeColor','w');
%                 rectangle('Position',pos,'LineWidth',2,'EdgeColor','k');
%                 %rectangle('Position',pos,'FaceColor',colors(letterIdx,:));
% %                 p = patch('vertices', [pos(1), pos(2); pos(1)+pos(3), pos(2); pos(1)+pos(3), pos(2)+pos(4); pos(1), pos(2)+pos(4)], ...
% %                   'faces', [1, 2, 3, 4], ...
% %                   'FaceColor', colors(letterIdx,:), ...
% %                   'FaceAlpha', 0.2);
%             end
%         end
    end
end

%%
%jPCA
Data = struct();
timeMS = round(timeAxis*1000);
for n=1:length(codeList)
    Data(n).A = squeeze(nanmean(alignedDat.(movLabels{n}),1));
    Data(n).times = timeMS;
end

jPCA_params.normalize = true;
jPCA_params.softenNorm = 0;
jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
jPCA_params.meanSubtract = true;
jPCA_params.numPCs = 6;  % default anyway, but best to be specific

winStart = [50,100,150,200,250];
for wIdx=1:length(winStart)
    windowIdx = [winStart(wIdx), winStart(wIdx)+200];

    %short window
    jPCATimes = windowIdx(1):10:windowIdx(2);
    for x = 1:length(jPCATimes)
        [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
        jPCATimes(x) = Data(1).times(minIdx);
    end

    [Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
    phaseSpace(Projections, jPCA_Summary);  % makes the plot
end
close all;

%%
alignedDat = load('hwCube_aligned.mat');
codeList = [letterCodes, wordCodes];
movLabels = {'a','b','c','d','t','m','o','cat','bat','tom','mat'};

tw_all = [-50, 350];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;
nDimToShow = 3;

figure('Position',[680   185   442   913]);
for c=1:length(codeList)
    concatDat = alignedDat.(movLabels{c});
    concatDat(isnan(concatDat)) = 0;
    
    reducedDat = zeros(size(concatDat,1), size(concatDat,2), nDimToShow);
    for trialIdx=1:size(concatDat,1)
        reducedDat(trialIdx,:,:) = squeeze(concatDat(trialIdx,:,:))*mPCA_out{pIdx}.readouts(:,1:nDimToShow);
    end
    
    for dimIdx=1:nDimToShow
        subtightplot(11,nDimToShow,(c-1)*nDimToShow + dimIdx);
        hold on;
        
        plot(mean(squeeze(reducedDat(:,:,dimIdx))));
        axis tight;
        plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
        plot([3,3],get(gca,'YLim'),'-k','LineWidth',2);
        
        
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
movLabels = {'a','b','c','d','t','m','o','cat','bat','tom','mat'};
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
dataIdxStart = 10:40;
nDecodeBins = 3;

allFeatures = [];
allCodes = trlCodes;
for t=1:length(trlCodes)
    tmp = [];
    dataIdx = dataIdxStart;
    for binIdx=1:nDecodeBins
        loopIdx = dataIdx + alignDat.eventIdx(t);
        tmp = [tmp, mean(alignDat.zScoreSpikes(loopIdx,:),1)];
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

%%
%sliding classification
classFilt = obj.Mu;
nUnits = size(alignDat.zScoreSpikes,2);
slideClass = zeros(size(alignDat.zScoreSpikes,1),size(classFilt,1));
nMiniBins = length(dataIdxStart);

for c=1:size(slideClass,2)   
    binIdx = cell(nDecodeBins,1);
    for b=1:nDecodeBins
        binIdx{b} = (1:nMiniBins)+(b-1)*nMiniBins;
    end
   
    featVec = zeros(1,nUnits*nDecodeBins);
    for t=1:(size(slideClass,1)-100)
        currIdx = 1:nUnits;
        for b=1:nDecodeBins
            featVec(currIdx) = mean(alignDat.zScoreSpikes(t+binIdx{b},:));
            currIdx = currIdx + nUnits;
        end
        
        slideClass(t,c) = sum((featVec-classFilt(c,:)).^2);
    end
end

%%
offsetBins = round(size(fullFilt,1)/2);
slideClass = [zeros(offsetBins,7); slideClass];

figure; 
hold on;
plot(1-slideClass./sum(slideClass,2),'LineWidth',2);
legend(movLabels,'AutoUpdate','off');

[~,~,trlCodesReorder] = unique(trlCodes);
allLabels = {'nothing','a','b','c','d','t','m','o','cat','bat','tom','mat'};

yLimit = get(gca,'YLim');
for t=1:length(alignDat.eventIdx)
    plot([alignDat.eventIdx(t), alignDat.eventIdx(t)],yLimit,'--k');
    text(alignDat.eventIdx(t),mean(yLimit),allLabels{trlCodesReorder(t)},'FontSize',16);
end

%%
normClass = -zscore(slideClass);
[ concatDat ] = triggeredAvg( normClass, alignDat.eventIdx(trlCodesReorder==11), [-100,400] );
mn = squeeze(mean(concatDat,1));

figure; 
hold on;
plot(mn,'LineWidth',2);
legend(movLabels,'AutoUpdate','off');

figure; 
hold on;
for t=1:size(concatDat,1)
    plot(squeeze(concatDat(t,:,:)),'LineWidth',2);
end
legend(movLabels,'AutoUpdate','off');

%%
%make data cubes for each condition & save
dat = struct();

for t=1:12
    concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(trlCodesReorder==t), [-50,350] );
    dat.(allLabels {t}) = concatDat;
end

save('hwCube.mat','-struct','dat');