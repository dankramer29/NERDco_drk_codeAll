w%%
blockList = [4 5 6 8 9 10 11 12 13 14 15 16 17 18];
headBlocks = [4 6 9 11 13 15 17];
armBlocks = [5 8 10 12 14 16 18];

sessionName = 't5.2019.05.06';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'bezierCurves' filesep sessionName];
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
datFields = {'rigidBodyPosXYZ','currentMovement','headVel','windowsPC1GazePoint','windowsMousePosition'};
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

headTrl = find(ismember(alignDat.bNumPerTrial, headBlocks));
trlCodes(headTrl) = trlCodes(headTrl)+100;

uniqueCodes = unique(trlCodes);
codeSets = {uniqueCodes(1:40), uniqueCodes(41:end)};
movLabels = {'right1a','right2a','right3a','right4a','right5a','right6a',...
    'up1a','up2a','up3a','up4a','up5a','up6a',...
    'left1a','left2a','left3a','left4a','left5a','left6a',...
    'down1a','down2a','down3a','down4a','down5a','down6a',...
    'rd1a','rd2a','rd3a','rd4a','rd5a','rd6a','rd7a','rd8a','rd9a','rd10a','rd11a','rd12a','rd13a','rd14a','rd15a','r1d6a',...
    'right1h','right2h','right3h','right4h','right5h','right6h',...
    'up1h','up2h','up3h','up4h','up5h','up6h',...
    'left1h','left2h','left3h','left4h','left5h','left6h',...
    'down1h','down2h','down3h','down4h','down5h','down6h',...
    'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
    };
movLabelsAll = movLabels;

%%
%plot head behavior
plotVar = 'rigidBodyPosXYZ';
%plotVar = 'windowsPC1GazePoint';
minorSets = {1:6, 7:12, 13:18, 19:24, 25:40};

for setIdx=1:length(codeSets)
    figure
    
    for minorIdx=1:length(minorSets)
        subtightplot(2,3,minorIdx);
        hold on;
        
        cs = codeSets{setIdx}(minorSets{minorIdx});
        colors = hsv(size(cs,1))*0.8;
        
        for t=1:length(cs)
            trlIdx = find(trlCodes==cs(t));

            for x=1:length(trlIdx)
                loopIdx = (alignDat.eventIdx(trlIdx(x))):(alignDat.eventIdx(trlIdx(x))+60);
                plot(alignDat.(plotVar)(loopIdx,1), alignDat.(plotVar)(loopIdx,2),'.','Color',colors(t,:),'LineWidth',1);
            end
        end

        %xlim([-0.02, 0.02]);
        %ylim([0.14, 0.20]);
        axis equal;
        axis off;
    end
end

%%
%make data cubes for each condition & save
% dat = struct();
% 
% for t=1:length(uniqueCodes)
%     concatDat = triggeredAvg( zscore(alignDat.headVel), alignDat.eventIdx(trlCodes==uniqueCodes(t)), [-50,150] );
%     dat.(movLabels{t}) = concatDat;
% end
% 
% save('unwarpedCubes_bezierCurves_headVel.mat','-struct','dat');
% 
% %%
% %make data cubes for each condition & save
% dat = struct();
% 
% for t=1:length(uniqueCodes)
%     concatDat = triggeredAvg( alignDat.zScoreSpikes_blockMean, alignDat.eventIdx(trlCodes==uniqueCodes(t)), [-50,150] );
%     dat.(movLabels{t}) = concatDat;
% end
% 
% save('unwarpedCubes_bezierCurves.mat','-struct','dat');

%%
%substitute in aligned data
alignedCube_hv = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/warpedCubes_bezierCurves_headVel.mat');
alignedCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/warpedCubes_bezierCurves.mat');

alignDat.zScoreSpikes_align = alignDat.zScoreSpikes_blockMean;
alignDat.headVel_align = alignDat.headVel;

for t=1:length(movLabels)
    trlIdx = find(trlCodes==uniqueCodes(t));
    for x=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(x))-49):(alignDat.eventIdx(trlIdx(x))+150);
        alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(movLabels{t})(x,2:end,:);
        alignDat.headVel_align(loopIdx,:) = alignedCube_hv.(movLabels{t})(x,2:end,:);
    end
end

alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0;
smoothSpikes_align = gaussSmooth_fast(alignDat.zScoreSpikes_align, 3);

%%
badChan = [44];
smoothSpikes_align(:,badChan) = [];
smoothSpikes_blockMean(:,badChan) = [];
alignDat.zScoreSpikes_blockMean(:,badChan) = [];
alignDat.zScoreSpikes_align(:,badChan) = [];

%%
%make target velocity time series
%start with head, get velocity-neural offset time
%sCodes = [uniqueCodes((25:40)+40)];
%headTrl = find(ismember(trlCodes,sCodes));
headTrl = find(ismember(alignDat.bNumPerTrial, headBlocks));

tauPossible = 0:20;
headEpochs = [alignDat.eventIdx(headTrl)-25, alignDat.eventIdx(headTrl)+150];
loopIdx = expandEpochIdx(headEpochs);

allPerf = zeros(length(tauPossible),1);
for t=1:length(tauPossible)
    neuralIdx = loopIdx-tauPossible(t);
    designMat = [ones(length(loopIdx),1), alignDat.headVel(loopIdx,1:2)];
    E = buildLinFilts(smoothSpikes_blockMean(neuralIdx,:), designMat, 'standard');
    
    pVals = designMat*E;
    perf = getDecoderPerformance( pVals, smoothSpikes_blockMean(neuralIdx,:), 'R2' );
    allPerf(t) = mean(perf);
end

[~,maxIdx] = max(allPerf);

Y_mov_st = alignDat.headVel(loopIdx+maxIdx,1:2)*10000;
X_mov_st = [ones(length(loopIdx),1), smoothSpikes_blockMean(loopIdx,:)];
[ filts_mov_st, featureMeans ] = buildLinFilts( Y_mov_st, X_mov_st, 'ridge', 1e3 );

%filts_prep = filts_mov_st;
filts_mov = filts_mov_st;

%%
%get arm dimensions, using head kinematics
win = [-25, 60];
dilationPossible = linspace(1.0,1.5,10);
tauPossible = 9;
allPerf = zeros(length(dilationPossible), length(tauPossible));
all_Y_mov_st = cell(length(dilationPossible), length(tauPossible));
reactionTime = 22;

for dIdx=1:length(dilationPossible)
    avgVel = cell(40,1);
    for codeIdx=1:40
        trlIdx = find(trlCodes==codeSets{2}(codeIdx));
        cDat = triggeredAvg(alignDat.headVel(:,1:2)*10000, alignDat.eventIdx(trlIdx), [win(1), 100]);
        avgDat = squeeze(mean(cDat,1));
        
        tmp = avgDat((-win(1)+reactionTime):end,:);
        tmpDilated = interp1(linspace(0,1,size(tmp,1)), tmp, linspace(0,1/dilationPossible(dIdx),size(tmp,1)));
        avgDatDilated = [zeros((-win(1)+reactionTime),2); tmpDilated];
        
        avgVel{codeIdx} = avgDatDilated(1:((win(2)-win(1)+1)),:);
    end

    armTrl = find(ismember(alignDat.bNumPerTrial, armBlocks));
    armEpochs = [alignDat.eventIdx(armTrl)+win(1), alignDat.eventIdx(armTrl)+win(2)];
    loopIdx = expandEpochIdx(armEpochs);

    Y_mov_st = [];
    for t=1:size(armEpochs,1)
        trlIdx = armTrl(t);
        tmpCode = find(trlCodes(trlIdx)==codeSets{1});
        Y_mov_st = [Y_mov_st; avgVel{tmpCode}];
    end

    for t=1:length(tauPossible)
        neuralIdx = loopIdx-tauPossible(t);
        designMat = [ones(length(loopIdx),1), Y_mov_st];
        E = buildLinFilts(smoothSpikes_blockMean(neuralIdx,:), designMat, 'standard');

        pVals = designMat*E;
        perf = getDecoderPerformance( pVals, smoothSpikes_blockMean(neuralIdx,:), 'R2' );
        allPerf(dIdx,t) = mean(perf);
        all_Y_mov_st{dIdx,t} = Y_mov_st;
    end
end

[~,maxIdx]=max(allPerf(:));
[I,J] = ind2sub(size(allPerf),maxIdx);
best_Y_mov_st = all_Y_mov_st{I, J};
bestDelay = tauPossible(J);

%build arm decoder
armTrl = find(ismember(alignDat.bNumPerTrial, armBlocks));
armEpochs = [alignDat.eventIdx(armTrl)+win(1), alignDat.eventIdx(armTrl)+win(2)];
loopIdx = expandEpochIdx(armEpochs);

X_mov_st = [ones(length(loopIdx),1), smoothSpikes_blockMean(loopIdx-bestDelay,:)];
[ filts_mov_st, featureMeans ] = buildLinFilts( best_Y_mov_st, X_mov_st, 'ridge', 1e3 );

%filts_prep = filts_mov_st;
filts_mov = filts_mov_st;

%%
%makea decoder on arrow conditions
sCodes = [uniqueCodes((25:40))];

theta = linspace(0,2*pi,17);
theta = theta(1:(end-1));

codeDir = [cos(theta)', sin(theta)'];
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
        newNeural = smoothSpikes_blockMean(loopIdx,:);

        allDir = [allDir; newDir];
        allNeural = [allNeural; newNeural];

        %zeroing
        newDir = repmat(currDir, idxWindowPrep(2)-idxWindowPrep(1)+1, 1);
        loopIdx = (alignDat.eventIdx(t)+idxWindowPrep(1)):(alignDat.eventIdx(t)+idxWindowPrep(2));
        newNeural = smoothSpikes_blockMean(loopIdx,:);

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
    [LIA,LOCB] = ismember(trlCodes(t),sCodes(1:16));
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
%return-to-center movement
avgVel = cell(40,1);
for codeIdx=1:40
    trlIdx = find(trlCodes==codeSets{2}(codeIdx));
    cDat = triggeredAvg(alignDat.headVel(:,1:2)*10000, alignDat.eventIdx(trlIdx), [-25,150]);
    avgDat = squeeze(mean(cDat,1));
    avgVel{codeIdx} = avgDat;
end

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

mpCodeSets = {codeSets{1}, codeSets{2}, codeSets{1}(25:40), codeSets{2}(25:40)};
mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(mpCodeSets) 
    trlIdx = find(ismember(trlCodes, mpCodeSets{pIdx}));
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
%ortho prep space?
plotSet = 1;
color = [1 0 0];
nDims = 4;
nCon = size(mPCA_out{plotSet}.featureAverages,2);
timeWindow = [-49,149];
    
movLabelSets = {movLabels(1:40), movLabels(41:end)};
X = [filts_prep, filts_mov];
%X = X(2:end,:);

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
                    plot(timeAxis, [ones(size(tmp,1),1), tmp]*X(:,dimIdx),'LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, [ones(size(tmp,1),1), tmp]*X(:,2+dimIdx),'LineWidth',2,'Color',color);
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
setLabels = {movLabels(1:40), movLabels(41:end)};
for setIdx = 1:length(codeSets)
    simMatrix = plotCorrMat_cv( mPCA_out{setIdx}.featureVals  , [1,50], setLabels{setIdx} );
end

%prep geometry
prepVec = squeeze(nanmean(nanmean( mPCA_out{2}.featureVals(:,:,1:50,:),4),3))';

[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

figure
hold on
for x=1:size(SCORE,1)
    text(SCORE(x,1), SCORE(x,2), SCORE(x,3), movLabels{x},'FontSize',16);
end

rdIdx = 25:40;
colors = hsv(16)*0.8;
for c=1:length(rdIdx)
    plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
end

xlim([-2,2]);
ylim([-2,2]);
zlim([-2,2]);

%%
movLabelSets = {movLabelsAll(1:40), movLabelsAll(41:end)};

for setIdx=1:length(codeSets)
    codeList = codeSets{setIdx};
    ml = movLabelSets{setIdx};

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

                %title(ml{c});
                if dimIdx==1
                    ylabel(ml{c},'FontSize',16,'FontWeight','bold');
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
%plot dec vel  
decVel = [ones(size(smoothSpikes_blockMean,1),1), smoothSpikes_blockMean] * filts_mov;
%decVel = [ones(size(smoothSpikes_align,1),1), smoothSpikes_align] * filts_mov;
minorSets = {1:6, 7:12, 13:18, 19:24, 25:40};

for setIdx=1:length(codeSets)
    figure
    
    for minorIdx=1:length(minorSets)
        subtightplot(2,3,minorIdx);
        hold on;
        
        cs = codeSets{setIdx}(minorSets{minorIdx});
        colors = hsv(size(cs,1))*0.8;
        
        for t=1:length(cs)
            trlIdx = find(trlCodes==cs(t));
            concatDat = triggeredAvg( decVel, alignDat.eventIdx(trlIdx), [10,60] );
            meanVel = squeeze(mean(concatDat,1));
            meanPos = cumsum(meanVel);
            
            plot(meanPos(:,1), meanPos(:,2),'-','Color',colors(t,:),'LineWidth',2);
        end

        %xlim([-14, 14]);
        %ylim([-14, 14]);
        axis equal;
        axis off;
    end
end