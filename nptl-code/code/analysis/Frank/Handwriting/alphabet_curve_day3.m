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

uniqueCodes = unique(trlCodes);
letterCodes = uniqueCodes(2:29);
curveCodes = uniqueCodes(30:end);
codeSets = {letterCodes, curveCodes};
movLabels = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt',...
    'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
    'cv37','cv38','cv39','cv40'};

%%
%make data cubes for each condition & save
dat = struct();

allCodes = [letterCodes; curveCodes];
for t=1:length(allCodes)
    concatDat = triggeredAvg( zscore(alignDat.headVel), alignDat.eventIdx(trlCodes==allCodes(t)), [-50,150] );
    dat.(movLabels{t}) = concatDat;
end

save('alphabetCurveCube_day2_headVel.mat','-struct','dat');

%%
%make data cubes for each condition & save
dat = struct();

allCodes = [letterCodes; curveCodes];
for t=1:length(allCodes)
    concatDat = triggeredAvg( alignDat.zScoreSpikes_blockMean, alignDat.eventIdx(trlCodes==allCodes(t)), [-50,150] );
    dat.(movLabels{t}) = concatDat;
end

save('alphabetCurveCube_day2.mat','-struct','dat');

%%
%make data cubes for each condition & save
dat = struct();

allCodes = [letterCodes];
for t=1:length(allCodes)
    concatDat = triggeredAvg( alignDat.zScoreSpikes_blockMean, alignDat.eventIdx(trlCodes==allCodes(t)), [0,120] );
    dat.(movLabels{t}) = concatDat;
end

save('alphabet_decode_day2.mat','-struct','dat');

%%
%make data cubes for each condition & save
dat = struct();

allCodes = [letterCodes];
for t=1:length(allCodes)
    concatDat = triggeredAvg( alignDat.zScoreSpikes_blockMean, alignDat.eventIdx(trlCodes==allCodes(t)), [0,100] );
    dat.(movLabels{t}) = concatDat;
end

save('alphabet_decode_day2_short.mat','-struct','dat');

%%
%unroleld data cube for RNN
twRNN = [0,150];

letterTrials = find(ismember(trlCodes, letterCodes));
neuralCube = zeros(length(letterTrials),twRNN(2)-twRNN(1)+1,size(alignDat.zScoreSpikes_blockMean,2));
fullClass = trlCodes(letterTrials);

for t=1:length(letterTrials)
    loopIdx = (alignDat.eventIdx(letterTrials(t))+twRNN(1)):(alignDat.eventIdx(letterTrials(t))+twRNN(2));
    tmp = alignDat.zScoreSpikes_blockMean(loopIdx,:);
    neuralCube(t,:,:) = tmp;
end

[~,~,classes] = unique(fullClass);

badX = [3,10,11,12];
xTrl = find(trlCodes(letterTrials)==letterCodes(24));
badTrl = xTrl(badX);

neuralCube(badTrl,:,:) = [];
classes(badTrl) = [];

save('alphabet_decode_day2_RNN.mat','neuralCube','classes');

%%
%substitute in aligned data
alignedCube_hv = load('alphabetCurveCube_day2_headVel_aligned.mat');
alignedCube = load('alphabetCurveCube_day2_aligned_noSmooth.mat');

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

decVel = [ones(size(alignDat.zScoreSpikes_align,1),1), alignDat.zScoreSpikes_align]*filts;

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
%jPCA
tw_all = [-49, 149];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;

Data = struct();
timeMS = round(timeAxis*1000);
% for n=1:8
%     Data(n).A = squeeze(mPCA_out{2}.featureAverages(:,n,:))';
%     Data(n).times = timeMS;
% end
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
setLabels = {movLabels(1:28), movLabels(29:end)};

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
    for t=1:length(Data)
        text(Projections(t).proj(1,1), Projections(t).proj(1,2), setLabels{1}{t}, 'FontSize', 14)
    end
    
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
X = orthoPrepSpace( mPCA_out{2}.featureAverages(:,1:8,:), 2, 2, 1:40, 70:120 );

%%
%ortho prep space?
plotSet = 2;

X = [filts_prep, filts_mov];
X = X(2:end,:);

nDims = 4;
nCon = size(mPCA_out{plotSet}.featureAverages,2);
timeWindow = [-49,149];
timeAxis = (timeWindow(1):timeWindow(2))*0.01;

ciDim = mPCA_out{1}.readouts(:,6)*0.2;
plotCon = [22];
colors = hsv(length(plotCon))*0.8;

tmp = squeeze(mPCA_out{plotSet}.featureAverages(:,plotCon,:));
tmpMean = squeeze(mean(tmp,2))';
meanProj = tmpMean*X;
meanProj(:) = 0;

figure('Position',[73   209   263   893]);
for dimIdx = 1:nDims
    subplot(nDims,1,dimIdx);
    hold on;
    for conIdx = 1:length(plotCon)
        tmp = squeeze(mPCA_out{plotSet}.featureAverages(:,plotCon(conIdx),:))';
        plot(timeAxis, tmp*X(:,dimIdx)-meanProj(:,dimIdx),'LineWidth',2,'Color',colors(conIdx,:));
    end
    plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);
    xlim([timeAxis(1), timeAxis(end)]);
    ylim([-1,1]);
    plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
    set(gca,'FontSize',16,'LineWidth',2);
end

figure('Position',[73   444   264   658]);
for dimIdx = 1:3
    subplot(3,1,dimIdx);
    hold on;
    for conIdx = 1:length(plotCon)
        tmp = squeeze(mPCA_out{plotSet}.featureAverages(:,plotCon(conIdx),:))';
        if dimIdx==1 || dimIdx==2
            plot(timeAxis, tmp*X(:,dimIdx)-meanProj(:,dimIdx),'LineWidth',2,'Color',colors(conIdx,:)*0.5);
            plot(timeAxis, tmp*X(:,2+dimIdx)-meanProj(:,dimIdx),'LineWidth',2,'Color',colors(conIdx,:));
        else
            plot(timeAxis, tmp*ciDim,'LineWidth',2,'Color',colors(conIdx,:)*0.5);
        end
    end
    plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);
    xlim([timeAxis(1), timeAxis(end)]);
    ylim([-1,1]);
    plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
    set(gca,'FontSize',16,'LineWidth',2);
end

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
prepVec = squeeze(nanmean(nanmean(superVals(:,:,1:50,:),4),3))';

plotIdx = [1:8, 9:12, 37 38 39 40]+28;
%plotIdx = 1:26;
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
bwToUse = [1,3,5,10,15,20,33,50,100];
T_skip = 0;
acc = zeros(length(bwToUse), 2);

for overlapMode=1:2
    for binWidthIdx = 1:length(bwToUse)
        dataIdxStart = 1:bwToUse(binWidthIdx);
        if overlapMode==1
            binIncrement = 1;
            nDecodeBins = 100-bwToUse(binWidthIdx)+1;
        else
            binIncrement = bwToUse(binWidthIdx);
            nDecodeBins = ceil(100/bwToUse(binWidthIdx));
        end
        
        allFeatures = [];
        allCodes = trlCodes;
        for t=1:length(trlCodes)
            tmp = [];
            dataIdx = dataIdxStart;
            for binIdx=1:nDecodeBins
                tmpIdx = dataIdx;
                tmpIdx(tmpIdx>100)=[];
                loopIdx = tmpIdx + alignDat.eventIdx(t);
                
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

        response = allCodes;
        predictors = allFeatures;
        trainFun = @(pred, resp)(buildNaiveBayesClassifier(pred, resp, 1));
        decoderFun = @(model, pred)(applyNaiveBayesClassifier(model, pred));
        testFun = @(pred, truth)(mean(pred==truth));
        nFolds = 10;

        [ perf, decoder, predVals, respVals, allTestIdx] = crossVal( predictors, response, trainFun, testFun, decoderFun, nFolds);
        acc(binWidthIdx, overlapMode) = mean(predVals==allCodes);
    end
end

figure;
plot(bwToUse, acc, '-o','LineWidth',3);
xlabel('Bin Width');
ylabel('Accuracy');
legend({'Sliding','Disjoint'});
set(gca,'FontSize',16,'LineWidth',2);

saveas(gcf,[outDir filesep 'linearClassifier_binWidthAcc_sliding.png'],'png');

%%
%linear classifier
badX = [3,10,11,12];
xTrl = find(trlCodes==letterCodes(24));
badTrl = xTrl(badX);

bwToUse = [5,10,20,25,33,50,100];
allL = zeros(length(bwToUse),1);
pLabels = cell(length(bwToUse),1);
for binWidthIdx = 1:length(bwToUse)
    bw = bwToUse(binWidthIdx);
    movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','>'};
    codeList = unique(trlCodes);

    dataIdxStart = 1:(bw);
    nDecodeBins = 100/bw;
    binIncrement = bw;

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
    allL(binWidthIdx) = kfoldLoss(cvmodel);
    pLabels{binWidthIdx} = kfoldPredict(cvmodel);
end

figure;
plot(bwToUse, 1-allL, '-o','LineWidth',3);
xlabel('Bin Width');
ylabel('Accuracy');
set(gca,'FontSize',16,'LineWidth',2);

saveas(gcf,[outDir filesep 'linearClassifier_binWidthAcc.png'],'png');

C = confusionmat(allCodes(subsetIdx), pLabels{5});
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


