%%
%blockList = [1 2 11 12 13 14];
blockList = [1 2 9 10 13 14];
sessionName = 't5.2019.04.29';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'HeadControl' filesep sessionName];
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

trlSets = {find(ismember(alignDat.bNumPerTrial, blockList(1:2)));
    find(ismember(alignDat.bNumPerTrial, blockList(3:4)));
    find(ismember(alignDat.bNumPerTrial, blockList(5:6)))};

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

mPCA_out = cell(length(trlSets),1);
for pIdx=1:length(trlSets) 
    trlIdx = trlSets{pIdx};
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_blockMean, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end
close all;

%%
movLabels = {'a','t','m','z','right','up','left','down'};
setTitles = {'Arm+Head','Arm','Head'};

%compare to internal baseline
for pIdx=1:length(trlSets) 
    trlIdx = trlSets{pIdx};
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    movWindow = [61, 100];
    baselineWindow = [-40,0];

    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_internalBaseline( mc_oneStart, smoothSpikes_blockMean, ...
        alignDat.eventIdx(trlIdx), movWindow, baselineWindow, {1:8}, 'raw' );
    singleTrialBarPlot( {1:8}, rawProjPoints_marg, cVar_marg, movLabels);
    
    disp(mean(cVar_marg(:,1)));
    title(setTitles{pIdx});
end

%%
%prep clustering
superVals = cat(2, mPCA_out{1}.featureVals, mPCA_out{2}.featureVals);
superVals = cat(2, superVals, mPCA_out{3}.featureVals);

simMatrix_all = plotCorrMat_cv( superVals, [61,81], movLabels, {1:8, 9:16, 17:24}, {1:8, 9:16, 17:24} );
set(gcf,'Position',[680         143        1241         955]);
saveas(gcf,[outDir 'simMatrix_all.fig'],'fig');

%%
%jPCA
tw_all = [-49, 149];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;

Data = struct();
timeMS = round(timeAxis*1000);
for n=1:size(mPCA_out{1}.featureAverages,2)
    Data(n).A = squeeze(mPCA_out{1}.featureAverages(:,n,:))';
    Data(n).times = timeMS;
end

jPCA_params.normalize = true;
jPCA_params.softenNorm = 0;
jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
jPCA_params.meanSubtract = true;
jPCA_params.numPCs = 6;  % default anyway, but best to be specific

winStart = [50,100,150,200,250];
freq = zeros(length(winStart),6);

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
    %saveas(gcf, [outDir filesep setNames{blockSetIdx} '_' num2str(windowIdx(1)) '_to_' num2str(windowIdx(2)) '_jPCA_' warpSuffix '.png'],'png');

    psParams.times = jPCATimes(1):binMS:1000;
    psParams.planes2plot = [1];
    phaseSpace(Projections, jPCA_Summary, psParams);  % makes the plot

    % get the eigenvalues and eigenvectors
    [V,D] = eig(jPCA_Summary.Mskew); % V are the eigenvectors, D contains the eigenvalues
    evals = diag(D); % eigenvalues

    % the eigenvalues are usually in order, but not always.  We want the biggest
    [~,sortIndices] = sort(abs(evals),1,'descend');
    evals = evals(sortIndices);  % reorder the eigenvalues
    evals = imag(evals);  % get rid of any tiny real part
    V = V(:,sortIndices);  % reorder the eigenvectors (base on eigenvalue size)

    freq(wIdx,:) = (abs(evals)*100)/(2*pi);
end


%%
codeListSets = {letterCodes, curveCodes};
movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt'};
movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
    'cv37','cv38','cv39','cv40'};
movLabelSets = {movLabels1, movLabels2};

for setIdx=1:length(codeListSets)
    codeList = codeListSets{setIdx};
    movLabels = movLabelSets{setIdx};

    tw_all = [-49, 150];
    timeStep = binMS/1000;
    timeAxis = (tw_all(1):tw_all(2))*timeStep;
    nDimToShow = min(5, size(mPCA_out{1}.readoutZ_unroll,2)/2);
    nPerPage = 10;
    currIdx = 1:10;
    if setIdx==1
        nPages = 3;
    else
        nPages = 4;
    end

    for pageIdx=1:nPages
        figure('Position',[ 680   185   711   913]);
        for conIdx=1:length(currIdx)
            c = currIdx(conIdx);
            if c > length(codeList)
                break;
            end
            concatDat = triggeredAvg( mPCA_out{1}.readoutZ_unroll(:,1:nDimToShow), alignDat.eventIdx(trlCodes==codeList(c)), tw_all );

            for dimIdx=1:nDimToShow
                subtightplot(length(currIdx),nDimToShow,(conIdx-1)*nDimToShow + dimIdx);
                hold on;

                tmp = squeeze(concatDat(:,:,dimIdx));
                imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),prctile(tmp(:),[2.5, 97.5]));
                axis tight;
                plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
                plot([1.0,1.0],get(gca,'YLim'),'-k','LineWidth',2);

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
        currIdx = currIdx + length(currIdx);

        saveas(gcf,[outDir 'popRaster_page' num2str(pageIdx) '_set_' num2str(setIdx) '.png'],'png');
    end
end

%%
badX = [3,10,11,12];
xTrl = find(trlCodes==letterCodes(24));
badTrl = xTrl(badX);

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


