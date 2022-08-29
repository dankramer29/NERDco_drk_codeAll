%%
blockList = [6 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24];
sessionName = 't5.2019.04.22';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'AlphabetCurve' filesep sessionName];
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
timeWindow = [-1000,4000];
binMS = 10;
alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
meanRate = mean(alignDat.rawSpikes)*1000/binMS;
tooLow = meanRate < 1.0;
alignDat.rawSpikes(:,tooLow) = [];
alignDat.meanSubtractSpikes(:,tooLow) = [];
alignDat.zScoreSpikes(:,tooLow) = [];

alignDat.zScoreSpikes = gaussSmooth_fast(zscore(alignDat.rawSpikes),3);
smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);

trlCodes = alignDat.currentMovement(alignDat.eventIdx);
nothingTrl = trlCodes==218;

uniqueCodes = unique(trlCodes);
letterCodes = uniqueCodes(2:29);
curveCodes = uniqueCodes(30:end);
codeSets = {letterCodes, curveCodes};
movLabels = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt',...
    'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36'};

% LETTER_A(400)
% LETTER_B(401)
% LETTER_C(402)
% LETTER_D(403)
% LETTER_T(404)
% LETTER_M(405)
% LETTER_O(406)
% 
% LETTER_E(412)
% LETTER_F(413)
% LETTER_G(414)
% LETTER_H(415)
% LETTER_I(416)
% LETTER_J(417)
% LETTER_K(418)
% LETTER_L(419)
% LETTER_N(420)
% LETTER_P(421)
% LETTER_Q(422)
% LETTER_R(423)
% LETTER_S(424)
% LETTER_U(425)
% LETTER_V(426)
% LETTER_W(427)
% LETTER_X(428)
% LETTER_Y(429)    
% LETTER_Z(430) 
% 
% LETTER_DASH(431)
% LETTER_GREATER(432)

%%
%substitute in aligned data
alignedCube = load('alphabetCurveCube_aligned.mat');
alignDat.zScoreSpikes_align = alignDat.zScoreSpikes;

allCodes = [letterCodes; curveCodes];
for t=1:length(movLabels)
    trlIdx = find(trlCodes==allCodes(t));
    for x=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(x))-49):(alignDat.eventIdx(trlIdx(x))+150);
        alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(movLabels{t})(x,2:end,:);
    end
end

alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0;
smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes_align, 3);

%%
%makea decoder on arrow conditions
sCodes = curveCodes(1:8);
codeDir = [1,0;
           1/sqrt(2), 1/sqrt(2);
           0,1;
           -1/sqrt(2),1/sqrt(2);
           -1,0;
           -1/sqrt(2),-1/sqrt(2);
           0,-1;
           1/sqrt(2),-1/sqrt(2)];

allDir = [];
allNeural = [];
for t=1:length(alignDat.eventIdx)
    [LIA,LOCB] = ismember(trlCodes(t),sCodes);
    if LIA
        currDir = codeDir(LOCB,:);
        newDir = repmat(currDir, 81, 1);

        loopIdx = (alignDat.eventIdx(t)+10):(alignDat.eventIdx(t)+90);
        newNeural = smoothSpikes(loopIdx,:);

        allDir = [allDir; newDir];
        allNeural = [allNeural; newNeural];
    end
end

[ filts, featureMeans ] = buildLinFilts( allDir, allNeural, 'standard' );
decVel = smoothSpikes*filts;

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
%prep clustering
setLabels = {movLabels(1:28), movLabels(29:end)};
for setIdx = 1:length(codeSets)
    simMatrix = plotCorrMat_cv( mPCA_out{setIdx}.featureVals  , [1,50], setLabels{setIdx} );
end

superVals = cat(2, mPCA_out{1}.featureVals(:,:,:,1:20), mPCA_out{2}.featureVals);
simMatrix_all = plotCorrMat_cv( superVals  , [1,50], movLabels );

set(gcf,'Position',[680         143        1241         955]);
saveas(gcf,[outDir 'simMatrix_all.fig'],'fig');
%%
% LETTER_A(400)
% LETTER_B(401)
% LETTER_C(402)
% LETTER_D(403)
% LETTER_T(404)
% LETTER_M(405)
% LETTER_O(406)
% 
% LETTER_E(412)
% LETTER_F(413)
% LETTER_G(414)
% LETTER_H(415)
% LETTER_I(416)
% LETTER_J(417)
% LETTER_K(418)
% LETTER_L(419)
% LETTER_N(420)
% LETTER_P(421)
% LETTER_Q(422)
% LETTER_R(423)
% LETTER_S(424)
% LETTER_U(425)
% LETTER_V(426)
% LETTER_W(427)
% LETTER_X(428)
% LETTER_Y(429)    
% LETTER_Z(430) 
% 
% LETTER_DASH(431)
% LETTER_GREATER(432)

%%
codeListSets = {letterCodes, curveCodes};
movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt'};
movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36'};
movLabelSets = {movLabels1, movLabels2};

for setIdx=1:length(codeListSets)
    codeList = codeListSets{setIdx};
    movLabels = movLabelSets{setIdx};

    tw_all = [-49, 150];
    timeStep = binMS/1000;
    timeAxis = (tw_all(1):tw_all(2))*timeStep;
    nDimToShow = 5;
    nPerPage = 10;
    currIdx = 1:10;

    for pageIdx=1:3
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

                imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),[-1 1]);
                axis tight;
                plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
                plot([1.5,1.5],get(gca,'YLim'),'-k','LineWidth',2);

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
%letter trajectories
letterIdxPage = [1 2 3 4 6 7 8 10 11 15 16 17 18 19 20 21 22 23 25 26 27 28];

codeList = {letterCodes, curveCodes, letterCodes(letterIdxPage)};
movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','>'};
movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36'};
movLabelSets = {movLabels1, movLabels2, movLabels1(letterIdxPage)};

for setIdx=1:length(codeList)
    tw_all = [-49, 150];
    timeStep = binMS/1000;
    timeAxis = (tw_all(1):tw_all(2))*timeStep;
    nDimToShow = 5;
    
    bias = [0, 0];
    figure('Position',[680   384   801   714]);
    for c=1:length(codeList{setIdx})
        concatDat = triggeredAvg( decVel, alignDat.eventIdx(trlCodes==codeList{setIdx}(c)), tw_all );

        subtightplot(5,5,c);
        hold on;

        mn = squeeze(mean(concatDat,1))+bias;
        traj = [cumsum(mn(61:end,1)), cumsum(mn(61:end,2))];
        plot(traj(:,1),traj(:,2),'LineWidth',2);
        plot(traj(1,1),traj(1,2),'o');
        title(movLabelSets{setIdx}{c},'FontSize',20);
        axis off;
        axis equal;
    end
end

%%
%linear classifier
codeList = unique(trlCodes);
dataIdxStart = 10:40;
nDecodeBins = 5;

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

saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');
saveas(gcf,[outDir filesep 'linearClassifier.pdf'],'pdf');

%%
%make data cubes for each condition & save
dat = struct();

allCodes = [letterCodes; curveCodes];
for t=1:length(allCodes)
    concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(trlCodes==allCodes(t)), [-50,150] );
    dat.(movLabels{t}) = concatDat;
end

save('alphabetCurveCube.mat','-struct','dat');