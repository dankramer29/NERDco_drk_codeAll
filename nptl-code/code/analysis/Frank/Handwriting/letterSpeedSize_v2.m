%%
%blockList = [1 2 11 12 13 14];
blockList = [11 12 16 17 18 19 20 21 22];
sessionName = 't5.2019.04.29';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSpeedSize' filesep sessionName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%       
bNums = horzcat(blockList);
movField = 'rigidBodyPosXYZ';
filtOpts.filtFields = {'rigidBodyPosXYZ'};
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

for t=1:length(allR)
    allR(t).headVel = [0 0 0; diff(allR(t).rigidBodyPosXYZ')]';
end

alignFields = {'goCue'};
smoothWidth = 0;
datFields = {'rigidBodyPosXYZ','currentMovement','headVel'};
timeWindow = [-1000,4000];
binMS = 10;
alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

meanRate = mean(alignDat.rawSpikes)*1000/binMS;
tooLow = meanRate < 1.0;
alignDat.rawSpikes(:,tooLow) = [];
alignDat.meanSubtractSpikes(:,tooLow) = [];
alignDat.zScoreSpikes(:,tooLow) = [];

alignDat.zScoreSpikes_allBlocks = zscore(alignDat.rawSpikes);
alignDat.zScoreSpikes_blockMean = alignDat.zScoreSpikes;

smoothSpikes_allBlocks = gaussSmooth_fast(zscore(alignDat.rawSpikes),3);
smoothSpikes_blockMean = gaussSmooth_fast(alignDat.zScoreSpikes,3);

trlCodes = alignDat.currentMovement(alignDat.eventIdx);
codeList = unique(trlCodes);
nothingTrl = trlCodes==218;

%%
%make data cubes for each condition & save
movLabels1 = {'a','t','m','z','right','up','left','down'};
movLabels2 = {'aSmallSlow','aBigSlow','aSmallFast','aBigFast',...
    'mSmallSlow','mBigSlow','mSmallFast','mBigFast',...
    'zSmallSlow','zBigSlow','zSmallFast','zBigFast',...
    'tSmallSlow','tBigSlow','tSmallFast','tBigFast'};
movLabels3 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12'};
movLabels = [movLabels1, movLabels2, movLabels3];

codeList1 = [400 404 405 430 486 488 490 492];
codeList2 = [439 441 445 447 448 450 454 456 457 459 463 464 465 467 471 473];
codeList3 = [526:537];

codeListOrdered = [codeList1, codeList2, codeList3];

dat = struct();
for t=1:length(codeListOrdered)
    concatDat = triggeredAvg( alignDat.zScoreSpikes_blockMean, alignDat.eventIdx(trlCodes==codeListOrdered(t)), [-50,250] );
    dat.(movLabels{t}) = concatDat;
end

save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes' filesep 'letterSpeedSize_cube.mat'],'-struct','dat');

%%
%substitute in aligned data
alignedCube = load([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes' filesep 'letterSpeedSize_aligned.mat']);
alignDat.zScoreSpikes_align = alignDat.zScoreSpikes_blockMean;

for t=1:length(codeListOrdered)
    trlIdx = find(trlCodes== codeListOrdered(t));
    for x=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(x))-49):(alignDat.eventIdx(trlIdx(x))+250);
        alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(movLabels{t})(x,2:end,:);
    end
end

alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0;
smoothSpikes_align = gaussSmooth_fast(alignDat.zScoreSpikes_align, 3);

%%
timeWindow_mpca = [-500,2500];
tw =  timeWindow_mpca/binMS;
tw(1) = tw(1) + 1;
tw(2) = tw(2) - 1;
    
margGroupings = {{1, [1 2]}, {2}};
margNames = {'Condition-dependent', 'Condition-independent'};
opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 5;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;
opts_m.nResamples = 10;

codeSets = {codeList1([1 2 3 4]), codeList1([5 6 7 8]), codeListOrdered};
mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(codeSets) 
    trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_align, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
    
    [sortIdx, reorderIdx] = sort(codeSets{pIdx});
    mPCA_out{pIdx}.featureAverages(:,reorderIdx,:) = mPCA_out{pIdx}.featureAverages;
    mPCA_out{pIdx}.featureVals(:,reorderIdx,:,:) = mPCA_out{pIdx}.featureVals;
end
close all;

%%
%makea decoder on arrow conditions
sCodes = [codeList1([5 6 7 8]), codeList3([1 7])];

codeDir = [1,0;
           0 1;
           -1 0;
           0 -1;
           1 0;
           1 0;];

idxWindow = [20, 50];
idxWindowPrep = [-50, 0];

allDir = [];
allNeural = [];

allDir_prep = [];
allNeural_prep = [];

for t=1:length(alignDat.eventIdx)
    [LIA,LOCB] = ismember(trlCodes(t),sCodes);
    if LIA
        currDir = codeDir(LOCB,:);
        newDir = repmat(currDir, idxWindow(2)-idxWindow(1)+1, 1);

        loopIdx = (alignDat.eventIdx(t)+idxWindow(1)):(alignDat.eventIdx(t)+idxWindow(2));
        newNeural = smoothSpikes_align(loopIdx,:);

        allDir = [allDir; newDir];
        allNeural = [allNeural; newNeural];

        %zeroing
        newDir = repmat(currDir, idxWindowPrep(2)-idxWindowPrep(1)+1, 1);
        loopIdx = (alignDat.eventIdx(t)+idxWindowPrep(1)):(alignDat.eventIdx(t)+idxWindowPrep(2));
        newNeural = smoothSpikes_align(loopIdx,:);

        allDir_prep = [allDir_prep; newDir];
        allNeural_prep = [allNeural_prep; newNeural];
    end
end

Y_mov = [allDir; zeros(size(allDir_prep))];
X_mov = [[ones(size(allNeural,1),1), allNeural]; [ones(size(allNeural_prep,1),1), allNeural_prep]];
[ filts_mov, featureMeans ] = buildLinFilts( Y_mov, X_mov, 'ridge', 1e3 );

Y_prep = [allDir_prep; zeros(size(allDir))];
X_prep = [[ones(size(allNeural_prep,1),1), allNeural_prep]; [ones(size(allNeural,1),1), allNeural]];
[ filts_prep, featureMeans ] = buildLinFilts( Y_prep, X_prep, 'ridge', 1e3 );

decVel = [ones(size(alignDat.zScoreSpikes_align,1),1), alignDat.zScoreSpikes_align]*filts_mov;

colors = jet(length(sCodes))*0.8;
figure
hold on
for t=1:length(alignDat.eventIdx)
    [LIA,LOCB] = ismember(trlCodes(t),sCodes);
    if LIA
        currDir = codeDir(LOCB,:);
        newDir = repmat(currDir, idxWindow(2)-idxWindow(1)+1, 1);

        loopIdx = (alignDat.eventIdx(t)+idxWindow(1)):(alignDat.eventIdx(t)+idxWindow(2));
        
        traj = cumsum(decVel(loopIdx,:));
        plot(cumsum(decVel(loopIdx,1)), cumsum(decVel(loopIdx,2)),'Color',colors(LOCB,:));
        plot(traj(end,1), traj(end,2),'o','Color',colors(LOCB,:),'MarkerSize',8,'MarkerFaceColor',colors(LOCB,:));
    end
end
axis equal;

%%
%ortho prep space?
color = [1 0 0];
nDims = 4;
timeWindow = [-49,249];
    
X = [filts_prep, filts_mov];
X = X(2:end,:);

movLabelSets = {movLabels,movLabels,movLabels}; 
headings = {'X','Y','CIS'};

for plotSet=3
    timeAxis = (timeWindow(1):timeWindow(2))*0.01;
    ciDim = mPCA_out{1}.readouts(:,6)*0.2;
    nPerPage = 6;
    currIdx = 1:nPerPage;
    nPages = ceil(size(mPCA_out{plotSet}.featureAverages,2)/nPerPage);
    
    for pageIdx=1:nPages
        figure('Position',[73          49         526        1053]);
        for plotConIdx=1:length(currIdx)
            plotCon = currIdx(plotConIdx);
            if plotCon > size(mPCA_out{plotSet}.featureAverages, 2)
                continue
            end
            
            tmp = squeeze(mPCA_out{plotSet}.featureAverages(:,plotCon,:));
            for dimIdx = 1:3
                subplot(nPerPage,3,(plotConIdx-1)*3+dimIdx);
                hold on;
                tmp = squeeze(mPCA_out{plotSet}.featureAverages(:,plotCon,:))';
                if dimIdx==1 || dimIdx==2
                    plot(timeAxis, tmp*X(:,dimIdx),'LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, tmp*X(:,2+dimIdx),'LineWidth',2,'Color',color);
                else
                    plot(timeAxis, tmp*ciDim,'LineWidth',2,'Color',color*0.5);
                end
                    
                plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);
                xlim([timeAxis(1), timeAxis(end)]);
                ylim([-1,1]);
                plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
                set(gca,'FontSize',16,'LineWidth',2);
                
                if dimIdx==1
                    ylabel(movLabelSets{plotSet}{plotCon});
                end
                
                if plotConIdx==1
                    title(headings{dimIdx});
                end
            end
        end
        
        saveas(gcf,[outDir 'prepDynamicsPage_' num2str(pageIdx) '_set_' num2str(plotSet) '.png'],'png');
        currIdx = currIdx + nPerPage;
    end
end

%%
%prep clustering
movLabels = {'aSmallSlow','aBigSlow','aSmallFast','aBigFast',...
    'mSmallSlow','mBigSlow','mSmallFast','mBigFast',...
    'zSmallSlow','zBigSlow','zSmallFast','zBigFast',...
    'tSmallSlow','tBigSlow','tSmallFast','tBigFast'};
    
simMatrix_all = plotCorrMat_cv( mPCA_out{1}.featureVals, [1,50], movLabels );
set(gcf,'Position',[680         143        1241         955]);
saveas(gcf,[outDir 'simMatrix_all.fig'],'fig');

prepVec = squeeze(nanmean(nanmean(mPCA_out{1}.featureVals(:,:,1:50,:),4),3))';
plotIdx = 1:16;
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(plotIdx,:));

SCORE = (prepVec(plotIdx,:)-MU)*COEFF;

figure
hold on
for x=1:length(plotIdx)
    t = plotIdx(x);
    text(SCORE(x,1), SCORE(x,2), SCORE(x,3), movLabels{t});
end

colors = hsv(12);
for c=1:8
    plot3(SCORE(c,1), SCORE(c,2), SCORE(c,3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',8);
end

xlim([-2,2]);
ylim([-2,2]);
zlim([-2,2]);

%%
codeList = unique(trlCodes);
codeListSets = {codeList(1:16); codeList(17:end)};
movLabels1 = {'aSmallSlow','aBigSlow','aSmallFast','aBigFast',...
    'mSmallSlow','mBigSlow','mSmallFast','mBigFast',...
    'zSmallSlow','zBigSlow','zSmallFast','zBigFast',...
    'tSmallSlow','tBigSlow','tSmallFast','tBigFast'};
movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12'};
movLabelSets = {movLabels1, movLabels2};

for setIdx=1:length(codeListSets)
    codeListInner = codeListSets{setIdx};
    movLabels = movLabelSets{setIdx};

    tw_all = [-49, 250];
    timeStep = binMS/1000;
    timeAxis = (tw_all(1):tw_all(2))*timeStep;
    nDimToShow = min(5, size(mPCA_out{setIdx}.readoutZ_unroll,2)/2);
    nPerPage = 10;
    currIdx = 1:10;
    nPages = 2;
    
    for pageIdx=1:nPages
        figure('Position',[ 680   185   711   913]);
        for conIdx=1:length(currIdx)
            c = currIdx(conIdx);
            if c > length(codeListInner)
                break;
            end
            concatDat = triggeredAvg( mPCA_out{setIdx}.readoutZ_unroll(:,1:nDimToShow), alignDat.eventIdx(trlCodes==codeListInner(c)), tw_all );

            for dimIdx=1:nDimToShow
                subtightplot(length(currIdx),nDimToShow,(conIdx-1)*nDimToShow + dimIdx);
                hold on;

                tmp = squeeze(concatDat(:,:,dimIdx));
                %imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),[-2 2]);
                imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),prctile(tmp(:),[2.5 97.5]));
                axis tight;
                plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
                plot([2.0,2.0],get(gca,'YLim'),'-k','LineWidth',2);

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
                if c==length(codeListInner)
                    set(gca,'YTick',[]);
                    xlabel('Time (s)');
                else
                    set(gca,'XTick',[],'YTick',[]);
                end
            end
        end
        currIdx = currIdx + length(currIdx);

        saveas(gcf,[outDir 'popRaster_page' num2str(pageIdx) '_set_' num2str(setIdx) '.png'],'png');
    end
end

%%
%letter trajectories
%decVel = alignDat.headVel_align(:,1:2);
% kd = 1.0;
% kc = 0.1;
% A = [1-kd, 0;
%      0, 1-kd];
% B = [kc, 0;
%      0,  kc];

letterIdxPage = [1 2 3 4 6 7 8 10 11 15 16 17 18 19 20 21 22 23 25 26 27 28];

codeList = {letterCodes, curveCodes, letterCodes(letterIdxPage)};
movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','>'};
movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
    'cv37','cv38','cv39','cv40'};
movLabelSets = {movLabels1, movLabels2, movLabels1(letterIdxPage)};

for setIdx=1:length(codeList)
    tw_all = [-49, 120];
    timeStep = binMS/1000;
    timeAxis = (tw_all(1):tw_all(2))*timeStep;
    nDimToShow = 5;
    
    if setIdx==2
        bias = [0, 0];
    else
        bias = [0.0, -0.05];
    end

    figure('Position',[680   384   801   714]);
    for c=1:length(codeList{setIdx})
        concatDat = triggeredAvg( decVel, alignDat.eventIdx(trlCodes==codeList{setIdx}(c)), tw_all );

        if setIdx==2
            subtightplot(7,6,c);
        elseif setIdx==1
            subtightplot(5,6,c);
        else
            subtightplot(5,5,c);
        end
        hold on;

        %for t=1:size(concatDat,1)
        %    mn = squeeze(concatDat(t,:,:))+bias;
        %    traj = [cumsum(mn(61:end,1)), cumsum(mn(61:end,2))];
            %plot(traj(:,1),traj(:,2),'LineWidth',0.5,'Color',[0.8 0.8 0.8]);
        %end

        mn = squeeze(mean(concatDat,1))+bias;
        mn = mn(61:end,:);
        traj = cumsum(mn);

        %mn = invNode(mn, nodes./matVecMag(nodes,2), matVecMag(nodes,2));

%         traj = zeros(size(mn(61:end,:),1),2);
%         for x=2:size(traj,1)
%             traj(x,:) = A*traj(x-1,:)' + B*mn(60+x,:)';
%         end
%         traj = cumsum(traj);

        %plot(traj(:,1),traj(:,2),'LineWidth',3,'Color', 'b');

        %plotIdx = 1:20:size(traj,1);
        %for p=1:length(plotIdx)
        %   plot(traj(plotIdx(p),1),traj(plotIdx(p),2),'o','LineWidth',2);
        %end

        plot(mn,'LineWidth',2);
        plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);

        title(movLabelSets{setIdx}{c},'FontSize',20);
        axis off;
        %axis equal;
        %xlim([-20,20]);
        %ylim([-20,20]);
    end
end

%%
%letter trajectories time series
letSet = [5 6 11 12 13 14 15 16 17];
codeList = {letterCodes(letSet)};
movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','>'};
movLabels1 = movLabels1(letSet);
movLabelSets = {movLabels1};

for setIdx=1:length(codeList)
    tw_all = [-49, 100];
    timeStep = binMS/1000;
    timeAxis = (tw_all(1):tw_all(2))*timeStep;
    nDimToShow = 5;
    
    if setIdx==2
        bias = [0, 0];
    else
        bias = [0, -0.2];
    end
    colors = jet(length(codeList{setIdx}))*0.8;

    figure('Position',[680   384   801   714]);
    for dimIdx=1:2
        subplot(1,2,dimIdx)
        hold on;
        for c=1:length(codeList{setIdx})
            concatDat = triggeredAvg( decVel, alignDat.eventIdx(trlCodes==codeList{setIdx}(c)), tw_all );

            mn = squeeze(mean(concatDat,1))+bias;
            plot(mn(:,dimIdx),'LineWidth',4,'Color',colors(c,:));
            %xlim([-50,50]);
            %ylim([-50,50]);
        end
        legend(movLabelSets{setIdx},'FontSize',20);
    end
end

%%
%regularized classifier
codeList = unique(trlCodes);
dataIdxStart = 10:50;
nDecodeBins = 6;
binIncrement = 10;

allFeatures = [];
allCodes = trlCodes;
for t=1:length(trlCodes)
    tmp = [];
    dataIdx = dataIdxStart;
    for binIdx=1:nDecodeBins
        loopIdx = dataIdx + alignDat.eventIdx(t);
        tmp = [tmp, mean(alignDat.zScoreSpikes_blockMean(loopIdx,:),1)];

        if binIdx<nDecodeBins
            dataIdx = dataIdx + binIncrement;
        end
    end
    
    allFeatures = [allFeatures; tmp];
end

subsetIdx = find(ismember(allCodes, letterCodes));
subsetIdx = setdiff(subsetIdx, badTrl);
allFeatures = allFeatures(subsetIdx,:);
allCodes = allCodes(subsetIdx);

regValues = linspace(0,1,100);
acc = zeros(length(regValues),1);

for regIdx = 1:length(regValues)
    response = allCodes;
    predictors = allFeatures;
    trainFun = @(pred, resp)(buildNaiveBayesClassifier(pred, resp, regValues(regIdx)));
    decoderFun = @(model, pred)(applyNaiveBayesClassifier(model, pred));
    testFun = @(pred, truth)(mean(pred==truth));
    nFolds = 20;

    [ perf, decoder, predVals, respVals, allTestIdx] = crossVal( predictors, response, trainFun, testFun, decoderFun, nFolds);
    acc(regIdx) = mean(predVals==allCodes);
end

figure
plot(regValues, acc);

%%
%linear classifier
codeList = unique(trlCodes);

dataIdxStart = 10:40;
nDecodeBins = 3;
binIncrement = 30;

allFeatures = [];
allCodes = trlCodes;
for t=1:length(trlCodes)
    tmp = [];
    dataIdx = dataIdxStart;
    for binIdx=1:nDecodeBins
        loopIdx = dataIdx + alignDat.eventIdx(t);
        tmp = [tmp, mean(alignDat.zScoreSpikes_blockMean(loopIdx,:),1)];

        if binIdx<nDecodeBins
            dataIdx = dataIdx + binIncrement;
        end
    end
    
    allFeatures = [allFeatures; tmp];
end

subsetIdx = find(ismember(allCodes, letterCodes));
subsetIdx = setdiff(subsetIdx, badTrl);

obj = fitcdiscr(allFeatures(subsetIdx,:),allCodes(subsetIdx),'DiscrimType','diaglinear');
cvmodel = crossval(obj);
L = kfoldLoss(cvmodel);
disp(L);

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
set(gca,'XTick',1:length(movLabels1),'XTickLabel',movLabels1,'XTickLabelRotation',45);
set(gca,'YTick',1:length(movLabels1),'YTickLabel',movLabels1);
set(gca,'FontSize',16);
set(gca,'LineWidth',2);
colorbar;
title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
axis tight;

saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');
saveas(gcf,[outDir filesep 'linearClassifier.pdf'],'pdf');

%%
%sliding classifier
codeSets = {letterCodes([5 14 15]), letterCodes([6 16]), curveCodes([1,9]), curveCodes([13,14]), curveCodes([31,34]), curveCodes([37,38])};
letterLabels = {movLabels([5 14 15]), movLabels([6 16]), {'->','-><-'},{'bendUp','bendDown'},{'up','upStroke'},{'hookUp','hookDown'}};

for setIdx=1:length(codeSets)
    trlSet = find(ismember(trlCodes, codeSets{setIdx}));

    baseIdx = -30:0;
    endIdx = -20:100;
    accCurve = zeros(length(endIdx),1);

    for timeIdx=1:length(endIdx)

        allFeatures = [];
        allCodes = [];
        for t=1:length(trlSet)
            trlIdx = trlSet(t);
            allCodes = [allCodes; trlCodes(trlIdx)];

            dataIdx = alignDat.eventIdx(trlIdx) + baseIdx + endIdx(timeIdx);
            tmp = mean(alignDat.zScoreSpikes_blockMean(dataIdx,:),1);
            allFeatures = [allFeatures; tmp];
        end

        obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);

        accCurve(timeIdx) = 1-L;
    end

    figure; 
    hold on;
    plot(endIdx*0.01, accCurve*100, 'LineWidth', 2);

    chanceLevel = 100*(1/length(codeSets{setIdx}));
    plot(get(gca,'XLim'),[chanceLevel, chanceLevel], '--k', 'LineWidth', 2);
    ylim([0,100.0]);
    plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
    set(gca,'FontSize',16,'LineWidth',2);
    xlabel('Time (s)');
    ylabel('Decoding Accuracy (%)');
    title(['Letters: ' letterLabels{setIdx}{:}]);

    saveas(gcf,[outDir filesep 'prepClassifier_' num2str(setIdx) '.png'],'png');
end


