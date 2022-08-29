%%
blockList = [11 12 13 15 16 17 18 19];
sessionName = 't5.2019.06.05';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'FingerTyping' filesep sessionName];
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
timeWindow = [-1000,2000];
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
uniqueCodes = unique(trlCodes);

movLabels = {'1','2','3','4','5','6','7','8','9','0','-','=','<-',...
    'q','w','e','r','t','y','u','i','o','p',...
    'a','s','d','f','g','h','j','k','l',';','''',...
    'shift','z','x','c','v','b','n','m',',','.','/',...
    'lSpace','rSpace'};
codeSets = {uniqueCodes};

%%
timeWindow_mpca = [-500,1500];
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
opts_m.nResamples = 10;

mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(codeSets) 
    trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end
close all;

%%
%clustering
leftHand = [1 2 3 4 5 6 14 15 16 17 18 24 25 26 27 28 35 36 37 38 39 40 46];
rightHand = setdiff(1:47, leftHand);

simMatrix = plotCorrMat_cv( mPCA_out{1}.featureVals , [1 50], movLabels );

simMatrix = plotCorrMat_cv( mPCA_out{1}.featureVals , [60,120], movLabels );
simMatrix = plotCorrMat_cv( mPCA_out{1}.featureVals , [60,120], movLabels, {leftHand, rightHand} );

homeRow = [24 25 26 27 28 46  33 32 31 30 29 47];
simMatrix = plotCorrMat_cv( squeeze(mPCA_out{1}.featureVals(:,homeRow,:,:)) , [60,120], movLabels(homeRow) );
simMatrix = plotCorrMat_cv( squeeze(mPCA_out{1}.featureVals(:,homeRow,:,:)) , [60,120], movLabels(homeRow), {1:6, 7:12} );

simMatrix = plotCorrMat_cv( squeeze(mPCA_out{1}.featureVals(:,rightHand,:,:)) , [60,120], movLabels(rightHand) );

%%
fingerCode = [1 1 2 3 4 4 4 3 2 1 1 1 1, ...
    1 2 3 4 4 4 4 3 2 1, ...
    1 2 3 4 4 4 4 3 2 1 1, ...
    1 1 2 3 4 4 4 4 3 2 1, ...
    1 1];

handCode = zeros(length(movLabels),1);
handCode(leftHand) = 1;
handCode(rightHand) = 2;

rowCode = zeros(length(movLabels));
rowCode(1:13) = 1;
rowCode(14:23) = 2;
rowCode(14:23) = 2;
rowCode(24:34) = 3;
rowCode(35:end) = 4;

movVec = squeeze(mean(mean(mPCA_out{1}.featureVals(:,:,60:120,:),3),4))';
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(movVec);

colorLabels = {fingerCode, handCode, rowCode};
textLabels = {'Finger','Laterality','Row'};

for labelIdx=1:length(colorLabels)
    labels = colorLabels{labelIdx};
    nLabels = length(unique(labels));
    
    colors = jet(nLabels)*0.8;
    
    figure
    hold on
    for x=1:(size(SCORE,1)-2)
        %plot3(SCORE(x,1), SCORE(x,2), SCORE(x,3), 'o');
        cIdx = labels(x);
        text(SCORE(x,1), SCORE(x,2), SCORE(x,3), movLabels{x},'FontSize',16,'FontWeight','bold','Color',colors(cIdx,:));
    end
    xlim([-2,2]);
    ylim([-2,2]);
    zlim([-2,2]);
    set(gca,'FontSize',16,'LineWidth',2);
    
    title(textLabels{labelIdx});
    saveas(gcf,[outDir filesep 'stateSpace_' textLabels{labelIdx} '.fig'],'fig');
end

%%
labels = colorLabels{1};
nLabels = length(unique(labels));   
colors = jet(nLabels)*0.8;

for handIdx=1:2
    plotIdx = find(handCode==handIdx);
    plotIdx = setdiff(plotIdx, [46 47]);
    
    figure
    hold on
    for x=1:length(plotIdx)
        cIdx = labels(plotIdx(x));
        text(SCORE(plotIdx(x),3), SCORE(plotIdx(x),2), -SCORE(plotIdx(x),1), movLabels{plotIdx(x)},'FontSize',16,'FontWeight','bold','Color',colors(cIdx,:));
    end
    xlim([-2,2]);
    ylim([-2,2]);
    zlim([-2,2]);
    set(gca,'FontSize',16,'LineWidth',2);
    
    title(textLabels{labelIdx});
    saveas(gcf,[outDir filesep 'stateSpace_hand' num2str(handIdx) '.fig'],'fig');
end

%%
movVec = squeeze(mean(mean(mPCA_out{1}.featureVals(:,:,60:120,:),3),4))';

fingerIdx = homeRow;
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(movVec(fingerIdx,:));

figure; 
hold on
for t=1:length(fingerIdx)
    plot3(SCORE(t,1), SCORE(t,2), SCORE(t,3), 'o','Color',[0.8 0.8 0.8], 'MarkerFaceColor',[0.8 0.8 0.8],'MarkerSize',20)
    text(SCORE(t,1),SCORE(t,2),SCORE(t,3), movLabels(fingerIdx(t)),'HorizontalAlignment','Center','FontSize',16,'FontWeight','bold');
end

%%
%decode keyboard locations

imageLoc = [900, 73, 23;
    901 123, 23;
    902 171 23;
    903 220 23;
    904 268 23;
    905 318 23;
    906 366 23;
    907 414 23;
    908 464 23;
    909 513 23;
    910 561 23;
    911 611 23;
    912 672 23;

    913 97 72;
    914 147 72;
    915 194 72;
    916 243 72;
    917 292 72;
    918 343 72;
    919 391 72;
    920 438 72;
    921 488 72;
    922 537 72;
    
    923 109 121;
    924 158 121;
    925 207 121;
    926 256 121;
    927 305 121;
    928 353 121;
    929 403 121;
    930 452 121;
    931 500 121;
    932 550 121;
    933 600 121;
    
    934 29 170;
    935 133 170;
    936 183 170;
    937 233 170;
    938 280 170;
    939 328 170;
    940 380 170;
    941 427 170;
    942 476 170;
    943 525 170;
    944 573 170;
    
    945 281 223;
    946 375 223;];

thumbIdx = false(47,1);
thumbIdx(46:47) = true;

for handToDecode=1:2
    hIdx = find(handCode==handToDecode & ~thumbIdx);
    imLoc = imageLoc(hIdx,2:3);
    imLoc(:,2) = -imLoc(:,2);
    fv = mPCA_out{1}.featureVals(:,hIdx,60:120,:);
    
    allNeural = [];
    allLoc = [];
    allCon = [];
    for x=1:length(hIdx)
        newNeural = squeeze(fv(:,x,:,:));
        newNeural = newNeural(:,:)';
        allNeural = [allNeural; newNeural];
        
        allLoc = [allLoc; repmat(imLoc(x,:), size(newNeural,1), 1)];
        allCon = [allCon; repmat(x, size(newNeural,1), 1)];
    end
    
    crossValLoc = zeros(length(hIdx),2);
    for x=1:length(hIdx)
        trainIdx = find(allCon~=x);
        testIdx = find(allCon==x);
        
        filts = buildLinFilts( allLoc(trainIdx,:), [ones(length(trainIdx),1), allNeural(trainIdx,:)], 'standard');
    
        decTest = [ones(length(testIdx),1), allNeural(testIdx,:)]*filts;
        crossValLoc(x,:) = mean(decTest);
    end
    
    if handToDecode==1
        colors = 0.9*[123 221 172
            106 221 248
            242 162 197
            242 190 115]/256;
    else
        colors = 0.9*[123 221 172
            106 221 248
            242 162 197
            248 229 109]/256;
    end
    
    figure('Position',[680   819   384   279]);
    hold on
    for x=1:length(hIdx)
        colorIdx = fingerCode(hIdx(x));
        plot(crossValLoc(x,1), crossValLoc(x,2), 'o','Color',colors(colorIdx,:),'MarkerFaceColor',colors(colorIdx,:),'MarkerSize',20);
        text(crossValLoc(x,1), crossValLoc(x,2), movLabels{hIdx(x)}, 'Color', 'k', 'FontSize',16,'FontWeight','bold','HorizontalAlignment','center');
    end
    xlim([min(crossValLoc(:,1))-20,max(crossValLoc(:,1))+20]);
    ylim([min(crossValLoc(:,2))-20,max(crossValLoc(:,2))+20]);
    set(gca,'XTick',[],'YTick',[]);
    
    saveas(gcf,[outDir filesep 'decode_keyboard' num2str(handIdx) '.png'],'png');
end

%%
%linear classifier
codeList = unique(trlCodes);
dataIdxStart = 1:35;
nDecodeBins = 2;
%dataIdxStart = -50:-1;
%nDecodeBins = 1;

allFeatures = [];
allCodes = trlCodes;
for t=1:length(trlCodes)
    tmp = [];
    dataIdx = dataIdxStart;
    for binIdx=1:nDecodeBins
        loopIdx = dataIdx + alignDat.eventIdx(t);
        %tmp = [tmp, mean(alignDat.zScoreSpikes_align(loopIdx,:),1)];
        tmp = [tmp, mean(alignDat.zScoreSpikes(loopIdx,:),1)];
        dataIdx = dataIdx + length(dataIdx);
    end
    
    allFeatures = [allFeatures; tmp];
end

%subLetters = 1:length(movLabels);
subLetters = [14:32, 36:42];
%subLetters = [14:length(movLabels)];
subsetIdx = find(ismember(allCodes, uniqueCodes(subLetters)));
mSub = movLabels(subLetters);

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
set(gca,'XTick',1:length(mSub),'XTickLabel',mSub,'XTickLabelRotation',45);
set(gca,'YTick',1:length(mSub),'YTickLabel',mSub);
set(gca,'FontSize',16);
set(gca,'LineWidth',2);
colorbar;
title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
axis tight;

saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');
saveas(gcf,[outDir filesep 'linearClassifier.fig'],'fig');