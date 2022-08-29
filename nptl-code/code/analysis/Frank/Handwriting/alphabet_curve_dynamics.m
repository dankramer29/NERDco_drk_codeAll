%%
blockList = [6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
sessionName = 't5.2019.04.24';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'AlphabetCurve_day2' filesep sessionName];
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
nothingTrl = trlCodes==218;

[uniqueCodes, ~, tcReorder] = unique(trlCodes);
letterCodes = uniqueCodes(2:29);
curveCodes = uniqueCodes(30:end);
codeSets = {letterCodes, curveCodes};
movLabels = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt',...
    'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
    'cv37','cv38','cv39','cv40'};

movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt'};
movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
    'cv37','cv38','cv39','cv40'};
movLabelSets = {movLabels1, movLabels2};

%%
%substitute in aligned data
cubeDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes'];
alignedCube_hv = load([cubeDir filesep 'alphabetCurveCube_day2_headVel_aligned.mat']);
alignedCube = load([cubeDir filesep 'alphabetCurveCube_day2_aligned_noSmooth.mat']);

alignDat.zScoreSpikes_align = alignDat.zScoreSpikes_blockMean;
alignDat.headVel_align = alignDat.headVel;

allCodes = [letterCodes; curveCodes];
for t=1:length(movLabels)
    trlIdx = find(trlCodes==allCodes(t));
    for x=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(x))-49):(alignDat.eventIdx(trlIdx(x))+150);
        alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(movLabels{t})(x,2:end,:);
        alignDat.headVel_align(loopIdx,:) = alignedCube_hv.(movLabels{t})(x,2:end,:);
    end
end

alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0;
smoothSpikes_align = gaussSmooth_fast(alignDat.zScoreSpikes_align, 3);

%%
timeWindow_mpca = [-500,1500];
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

mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(codeSets) 
    trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_align, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end
close all;

%%
%makea decoder on arrow conditions
sCodes = [curveCodes(1:8);];

codeDir = [1,0;
           1/sqrt(2), 1/sqrt(2);
           0,1;
           -1/sqrt(2),1/sqrt(2);
           -1,0;
           -1/sqrt(2),-1/sqrt(2);
           0,-1;
           1/sqrt(2),-1/sqrt(2);];

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
    [LIA,LOCB] = ismember(trlCodes(t),sCodes(1:8));
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
%make a decoder using templates
load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates.mat');

win = [-49, 149];
warpedTemplates = cell(size(templates));

for conIdx=1:length(movLabels)
    disp(conIdx);
    
    if ismember(conIdx, 29:36)
        shiftPossible = -40:40;
        dilationPossible = linspace(1.0,6.0,50);
    else
        shiftPossible = -20:20;
        dilationPossible = linspace(0.5,2.0,50);
    end
    
    allPerf = zeros(length(dilationPossible), length(shiftPossible));
    all_Y_mov_st = cell(length(dilationPossible), length(shiftPossible));
    adjustedTemplate = cell(length(dilationPossible), length(shiftPossible));
    
    trlIdx = find(trlCodes==uniqueCodes(conIdx+1));
    nTrials = length(trlIdx);
    allLoopIdx = [];
    for t = 1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(t))+win(1)):(alignDat.eventIdx(trlIdx(t))+win(2));
        allLoopIdx = [allLoopIdx; loopIdx'];
    end
    neuralDat = smoothSpikes_blockMean(allLoopIdx,:);
    
    if conIdx>28
        meanSubNeuralDat = squeeze(mPCA_out{2}.featureVals(:,conIdx-28,:,:))-squeeze(mean(mPCA_out{2}.featureAverages,2));
    else
        meanSubNeuralDat = squeeze(mPCA_out{1}.featureVals(:,conIdx,:,:))-squeeze(mean(mPCA_out{1}.featureAverages,2));
    end
    
    meanSubUnroll = [];
    for t=1:length(trlIdx)
        meanSubUnroll = [meanSubUnroll; squeeze(meanSubNeuralDat(:,:,t))'];
    end
    
    if conIdx>28
        fa = squeeze(mPCA_out{2}.featureAverages(:,conIdx-28,:));
    else
        fa = squeeze(mPCA_out{1}.featureAverages(:,conIdx,:));
    end
    avgVel = [ones(size(fa,2),1), fa']*filts_mov;
    
    for dIdx=1:length(dilationPossible)
        for shiftIdx=1:length(shiftPossible)
            tmp = templates{conIdx};
            tmpDilated = interp1(linspace(0,1,size(tmp,1)), tmp, linspace(0,1,size(tmp,1)*dilationPossible(dIdx)));
            avgDatDilated = [zeros((-win(1)+shiftPossible(shiftIdx)),2); tmpDilated];
            avgDatDilated = [avgDatDilated; zeros((win(2)-win(1))-size(avgDatDilated,1)+1,2)];
            
            nBins = win(2)-win(1)+1;
            if size(avgDatDilated,1)>nBins
                avgDatDilated = avgDatDilated(1:nBins,:);
            end
                
            designMat = [ones(length(avgDatDilated),1), avgDatDilated];
            designMat = repmat(designMat,nTrials,1);
            
            E = buildLinFilts(meanSubUnroll, designMat, 'standard');

            pVals = designMat*E;
            %allPerf(dIdx, shiftIdx) = mean(getDecoderPerformance( pVals, meanSubUnroll, 'R2' ));
            allPerf(dIdx, shiftIdx) = mean(corr(avgDatDilated(:), avgVel(:)));
        end
    end
    
    [~,maxIdx]=max(allPerf(:));
    [I,J] = ind2sub(size(allPerf),maxIdx);
    bestDilation = dilationPossible(I);
    bestDelay = shiftPossible(J);

    tmp = templates{conIdx};
    tmpDilated = interp1(linspace(0,1,size(tmp,1)), tmp, linspace(0,1,size(tmp,1)*bestDilation));
    avgDatDilated = [zeros((-win(1)+bestDelay),2); tmpDilated];
    avgDatDilated = [avgDatDilated; zeros((win(2)-win(1))-size(avgDatDilated,1)+1,2)];

    nBins = win(2)-win(1)+1;
    if size(avgDatDilated,1)>nBins
        avgDatDilated = avgDatDilated(1:nBins,:);
    end

    warpedTemplates{conIdx} = avgDatDilated;
end

%make warped template design matrix
conForTrain = 1:68;

targetVel = [];
neuralLoopIdx = [];
conIdxByLoop = [];
for t=1:length(trlCodes)
    loopIdx = (alignDat.eventIdx(t)+win(1)):(alignDat.eventIdx(t)+win(2));
    
    conIdx = tcReorder(t)-1;
    if ismember(conIdx, conForTrain)
        targetVel = [targetVel; warpedTemplates{conIdx}];
        neuralLoopIdx = [neuralLoopIdx; loopIdx'];
        conIdxByLoop = [conIdxByLoop; zeros(length(loopIdx),1)+conIdx];
    end
end

designMat = [ones(length(neuralLoopIdx),1), smoothSpikes_align(neuralLoopIdx,:)];
[ filts_mov, featureMeans ] = buildLinFilts( targetVel*20, designMat, 'ridge', 1e3 );
decVel = [ones(length(smoothSpikes_align),1), smoothSpikes_align]*filts_mov;

cvVel = zeros(size(decVel));
for conIdx=1:68
    disp(conIdx); 
    
    trainIdx = find(conIdxByLoop~=conIdx);
    testIdx = find(conIdxByLoop==conIdx);
    
    designMat = [ones(length(neuralLoopIdx(trainIdx)),1), smoothSpikes_align(neuralLoopIdx(trainIdx),:)];
    [ filts_mov_cv, featureMeans ] = buildLinFilts( targetVel(trainIdx,:)*20, designMat, 'ridge', 1e3 );
    cvVel(neuralLoopIdx(testIdx),:) = [ones(length(neuralLoopIdx(testIdx)),1), smoothSpikes_align(neuralLoopIdx(testIdx),:)]*filts_mov_cv;
end

%%
%measure length
conLen = nan(size(warpedTemplates,1),1);
for w=1:size(warpedTemplates,1)
    zeroIdx = find(warpedTemplates{w}(100:end,1)==0,1,'first');
    if isempty(zeroIdx)
        continue;
    end
    conLen(w) = zeroIdx + 99 - 50; 
end

%%
%ortho prep space?
color = [1 0 0];
nDims = 4;
plotSet = 1;
nCon = size(mPCA_out{plotSet}.featureAverages,2);
timeWindow = [-49,149];
    
X = [filts_prep, filts_mov];
X = X(2:end,:);

headings = {'X','Y','CIS'};

for plotSet=1:2
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
        %bias = [0, 0];
        bias = [0.0, -0.05];
    end

    figure('Position',[680   384   801   714]);
    for c=1:length(codeList{setIdx})
        concatDat = triggeredAvg( cvVel, alignDat.eventIdx(trlCodes==codeList{setIdx}(c)), tw_all );

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

        plot(traj(:,1),traj(:,2),'LineWidth',3,'Color', 'b');

        %plotIdx = 1:20:size(traj,1);
        %for p=1:length(plotIdx)
        %   plot(traj(plotIdx(p),1),traj(plotIdx(p),2),'o','LineWidth',2);
        %end

        %plot(mn,'LineWidth',2);
        %plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);

        title(movLabelSets{setIdx}{c},'FontSize',20);
        axis off;
        %axis equal;
        %xlim([-20,20]);
        %ylim([-20,20]);
    end
end

%%
%fit dynamics model
ciDim = mPCA_out{1}.readouts(:,6)*0.2;

allData = {};
for plotSet=1:2
    for conIdx = 1:size(mPCA_out{plotSet}.featureAverages,2)
        tmp = squeeze(mPCA_out{plotSet}.featureAverages(:,conIdx,:))';
        allData{end+1} = [tmp*X, tmp*ciDim];
    end
end

cDat = vertcat(allData{:});
startTrlIdx = 1:199:size(cDat,1);

ciBinEdges = [-0.2,-0.1,0.0,0.1,0.2,0.3,0.4];
nBins = length(ciBinEdges)-1;
A_mat = cell(nBins,1);
coeff = zeros(nBins,4);

X_mat = cell(nBins,1);

for edgeIdx=1:nBins
    loopIdx = find(cDat(:,5)>ciBinEdges(edgeIdx) & cDat(:,5)<ciBinEdges(edgeIdx+1));
    loopIdx = setdiff(loopIdx, startTrlIdx);
    
    disp(length(loopIdx));
    
    fitX = [ones(length(loopIdx),1), cDat(loopIdx-1,[1 3])];
    fitY = cDat(loopIdx,3);
    A_1 = fitX\fitY;
    
    fitX = [ones(length(loopIdx),1), cDat(loopIdx-1,[2 4])];
    fitY = cDat(loopIdx,4);
    A_2 = fitX\fitY;
    
    A_mat{edgeIdx} = [A_1(3), 0, A_1(2), 0;
        0, A_2(3), 0, A_2(2)];
    
    coeff(edgeIdx,:) = [A_1(2), A_2(2), A_1(3), A_2(3)];
    
    fitX = [ones(length(loopIdx),1), cDat(loopIdx-1,[1 2 3 4])];
    fitY = cDat(loopIdx,[1 2]);
    X_mat{edgeIdx} = fitX\fitY;    
end

%%
%cd trial averages
opts_m_2 = opts_m;
opts_m_2.nCompsPerMarg = 8;
opts_m_2.readoutMode = 'pcaAxes';

trlIdx = find(ismember(trlCodes, vertcat(codeSets{:})));
mc = trlCodes(trlIdx)';
[~,~,mc_oneStart] = unique(mc);

mPCA_out_all = apply_mPCA_general( smoothSpikes_allBlocks, alignDat.eventIdx(trlIdx), ...
    mc_oneStart, tw, binMS/1000, opts_m_2 );

close all;

%%
%prep clustering
mPCA_out_noSubtract = cell(length(codeSets),1);
for pIdx=1:length(codeSets) 
    trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out_noSubtract{pIdx} = apply_mPCA_general( smoothSpikes_allBlocks, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end
close all;

setLabels = {movLabels(1:28), movLabels(29:end)};
for setIdx = 1:length(codeSets)
    if any(isnan(mPCA_out{setIdx}.featureVals(:)))
        useVals = mPCA_out{setIdx}.featureVals(:,:,:,1:19);
    else
        useVals = mPCA_out{setIdx}.featureVals;
    end
    simMatrix = plotCorrMat_cv( useVals  , [1,50], setLabels{setIdx} );
end

superVals = cat(2, mPCA_out_noSubtract{1}.featureVals(:,:,:,2:20), mPCA_out_noSubtract{2}.featureVals(:,:,:,1:19));
simMatrix_all = plotCorrMat_cv( superVals  , [1,50], movLabels );
set(gcf,'Position',[680         143        1241         955]);
saveas(gcf,[outDir 'simMatrix_all.fig'],'fig');

%prep geometry
prepVec_st = squeeze(nanmean(superVals(:,:,1:50,:),3));
prepVec = squeeze(nanmean(nanmean(superVals(:,:,1:50,:),4),3))';

%plotIdx = [1:8, 9:12, 21:28]+28;
plotIdx = 1:68;
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(plotIdx,:));
%[COEFF, SCORE_ring, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec((1:12)+28,:));

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
curveVal_x = zeros(size(prepVec_st,2),1);

curveVal_x(28+15) = -1;
curveVal_x(28+16) = 1;
curveVal_x(28+19) = 1;
curveVal_x(28+20) = -1;

curveVal_x(28+23) = 1;
curveVal_x(28+24) = -1;
curveVal_x(28+27) = 1;
curveVal_x(28+28) = -1;

curveVal_y = zeros(size(prepVec_st,2),1);

curveVal_y(28+13) = -1;
curveVal_y(28+14) = 1;
curveVal_y(28+17) = -1;
curveVal_y(28+18) = -1;

curveVal_y(28+21) = -1;
curveVal_y(28+22) = 1;
curveVal_y(28+25) = -1;
curveVal_y(28+26) = 1;

codeList = unique(trlCodes);
codeList(1) = [];

allNeural = zeros(50*68*20,size(alignDat.zScoreSpikes_allBlocks,2));
allCurveVal = zeros(50*68*20,2);
currIdx = 1:50;

for c=29:size(prepVec_st,2)
    trlIdx = find(trlCodes==codeList(c));
    for t=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(t))-49):(alignDat.eventIdx(trlIdx(t)));
        allNeural(currIdx,:) = alignDat.zScoreSpikes_allBlocks(loopIdx,:);
        allCurveVal(currIdx,:) = repmat([curveVal_x(c), curveVal_y(c)],length(loopIdx),1);
        
        currIdx = currIdx + length(currIdx);
    end
end

badIdx = find(all(allNeural==0,2));
allNeural(badIdx,:) = [];
allCurveVal(badIdx,:) = [];

Y_mov = allCurveVal;
X_mov = [ones(size(allNeural,1),1), allNeural]; 
[ filts_curve, featureMeans ] = buildLinFilts( Y_mov, X_mov, 'ridge', 1e3 );
decCurve = [ones(size(alignDat.zScoreSpikes_allBlocks,1),1), alignDat.zScoreSpikes_allBlocks]*filts_curve;

meanCurve = zeros(size(prepVec_st,2),2);
for c=1:length(meanCurve)
    trlIdx = find(trlCodes==codeList(c));
    loopIdx = [];
    for t=1:length(trlIdx)
        loopIdx = [loopIdx, (alignDat.eventIdx(trlIdx(t))-49):(alignDat.eventIdx(trlIdx(t)))];
    end
    
    meanCurve(c,:) = mean(decCurve(loopIdx,:));
end

figure
plot(zscore(meanCurve),'o')
set(gca,'XTick',1:length(meanCurve),'XTickLabel',movLabels,'XTickLabelRotation',45);

%%
load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/linearPredictions_alphabetCurve.mat')

pStates = permute(pStates, [2 1 3]);
predPlotSet = {pStates(:,1:28,:), pStates(:,29:end,:)};

color = [1 0 0];
nDims = 4;
nCon = size(mPCA_out{plotSet}.featureAverages,2);
timeWindow = [-49,149];
    
X = [filts_prep, filts_mov];
X = X(2:end,:);

headings = {'X','Y','CIS'};

for plotSet=1:2
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
            
            for dimIdx = 1:3
                subplot(nPerPage,3,(plotConIdx-1)*3+dimIdx);
                hold on;
                
                %tmp = squeeze(mPCA_out{plotSet}.featureAverages(:,plotCon,:))';
                tmp = squeeze(nanmean(alignedCube.(movLabelSets{plotSet}{plotCon}),1));
                tmp = tmp(2:(end-1),:);
                
                tmp_pred = squeeze(predPlotSet{plotSet}(2:(end-1),plotCon,:));
                
                if dimIdx==1 || dimIdx==2
                    plot(timeAxis, tmp*X(:,dimIdx),'LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, tmp*X(:,2+dimIdx),'LineWidth',2,'Color',color);
                    
                    plot(timeAxis, tmp_pred*X(:,dimIdx),':','LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, tmp_pred*X(:,2+dimIdx),':','LineWidth',2,'Color',color);
                else
                    plot(timeAxis, tmp*ciDim,'LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, tmp_pred*ciDim,':','LineWidth',2,'Color',color*0.5);
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
        
        saveas(gcf,[outDir 'prepDynamicsPage_pred_' num2str(pageIdx) '_set_' num2str(plotSet) '.png'],'png');
        currIdx = currIdx + nPerPage;
    end
end
