%%
%load dataset
paths = getFRWPaths( );
addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));
    
saveDir = [paths.dataPath '/Derived/RNNOfflinePerformance/'];

dataDir = [paths.dataPath '/Derived/2dDatasets'];
prepDataDir = [paths.dataPath filesep 'Derived' filesep 'rnnDecoding_2dDatasets_v2'];
datasetName = 't5.2016.09.28.mat';

opts.outSubDir = {'test2','test3_4comp_2','test3_4comp_3','test3_4comp_4',...
    'test4','test5'};
opts.dataType = {'rawFeatures','4comp_2','4comp_3','4comp_4','rawFeatures','rawFeatures'};
opts.datasetNum = {'0','0','0','0','1','0'};
opts.batchNames = {'full','2comp','3comp','4comp','full_multi','full_multi_x'};

for batchIdx = 1:length(opts.outSubDir)
    load([dataDir filesep datasetName]);
    dataset.trialEpochs(dataset.trialEpochs>length(dataset.cursorPos)) = length(dataset.cursorPos);

    remIdx = [];
    for b=1:length(dataset.blockList)
        if dataset.decodingClick(b)
            trlIdx = find(dataset.blockNums(dataset.trialEpochs(:,1))==dataset.blockList(b));
            remIdx = [remIdx; trlIdx];
        end
    end

    dataset.trialEpochs(remIdx,:) = [];
    dataset.instructedDelays(remIdx,:) = [];
    dataset.intertrialPeriods(remIdx,:) = [];
    dataset.isSuccessful(remIdx) = [];
    
%     nBinsPerChunk = 510; 
%     trlLen = dataset.trialEpochs(:,2) - dataset.trialEpochs(:,1) + 1;
%     tooLong = trlLen>450;
%     dataset.trialEpochs(tooLong,:) = [];
%     
%     tooEarly = dataset.trialEpochs(:,2) < nBinsPerChunk;
%     dataset.trialEpochs(tooEarly,:) = [];

    %training meta
    tm = load([prepDataDir filesep 'trainingMeta' filesep datasetName],'out');
    testIdxTM = find(tm.out.C.test(1));
    trainIdxTM = find(tm.out.C.training(1));
    prepDat = load([prepDataDir filesep opts.dataType{batchIdx} filesep 'Fold1' filesep datasetName]);
    allTargets = [prepDat.targets; prepDat.targetsVal; prepDat.targetsFinal];
    innerTrainIdx = trainIdxTM(1:(4*floor(length(trainIdxTM)/5)));
    innerTestIdx = setdiff(trainIdxTM, innerTrainIdx);
    allTargetsTrlIdx = [innerTrainIdx; innerTestIdx; testIdxTM];

    %analyze results
    outDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/' opts.outSubDir{batchIdx}];
    scriptDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/' opts.outSubDir{batchIdx} '/'];
    load([scriptDir filesep 'runParams.mat']);

    outputFinalField = ['outputsFinal' opts.datasetNum{batchIdx}];
    targetsFinalField = ['targetsFinal' opts.datasetNum{batchIdx}];
    inFacFinalField = ['inFacFinal' opts.datasetNum{batchIdx}];
    decStatesFinalField = ['decoderStatesFinal' opts.datasetNum{batchIdx}];
    
    if strcmp(opts.outSubDir{batchIdx},'test2')
        %reorder shuffled trials
        fileName = [outDir filesep '1' filesep 'finalOutput.mat'];
        result = load(fileName);
        
        maxVal = zeros(size(prepDat.targetsFinal,1),1);
        trueTestIdx = zeros(size(prepDat.targetsFinal,1),1);
        for t=1:size(prepDat.targetsFinal,1)
            corrVal = zeros(size(prepDat.targetsFinal,1),1);
            for x=1:size(allTargets,1)
                corrVal(x) = corr(squeeze(allTargets(x,:,1))', squeeze(result.targetsFinal0(t,:,1))');
            end
            [maxVal(t),trueTestIdx(t)] = max(corrVal);
        end
        trueTestIdx = allTargetsTrlIdx(trueTestIdx);
    end
    
    decOut = cell(size(runTable,1),4);
    perfTable = nan(size(runTable,1),5);
    for r=1:size(runTable,1)
        fileName = [outDir filesep num2str(r) filesep 'finalOutput.mat'];
        allIdx = [];
        if exist(fileName,'file')
            result = load(fileName);
            if strcmp(opts.outSubDir{batchIdx},'test2')
                %reorder shuffled trials
                useTestIdx = trueTestIdx;
            else
                useTestIdx = testIdxTM;
            end
            
            outUnroll = [];
            targetsUnroll = [];
            inFacUnroll = [];
            decStatesUnroll = [];
            for t=1:length(useTestIdx)
                nLoops = length(tm.out.in.reachEpochs(useTestIdx(t),1):tm.out.in.reachEpochs(useTestIdx(t),2));
                outUnroll = [outUnroll; squeeze(result.(outputFinalField)(t,(end-nLoops+1):end,:))];
                targetsUnroll = [targetsUnroll; squeeze(result.(targetsFinalField)(t,(end-nLoops+1):end,:))];
                inFacUnroll = [inFacUnroll; squeeze(result.(inFacFinalField)(t,(end-nLoops+1):end,:))];
                allIdx = [allIdx; (tm.out.in.reachEpochs(useTestIdx(t),1):tm.out.in.reachEpochs(useTestIdx(t),2))'];
                if isfield(result,'decoderStatesFinal0')
                    decStatesUnroll = [decStatesUnroll; squeeze(result.(decStatesFinalField)(t,(end-nLoops+1):end,:))];
                end
            end

            perfTable(r,1) = mean(diag(corr(outUnroll, targetsUnroll))); 
            perfTable(r,2) = (180/pi)*nanmean(abs(getAngularError(outUnroll, targetsUnroll)));
            perfTable(r,3) = mean(diag(corr(matVecMag(outUnroll,2), matVecMag(targetsUnroll,2))));
            perfTable(r,4) = mean(mean((outUnroll - targetsUnroll).^2));

            decOut{r,1} = outUnroll;
            decOut{r,2} = targetsUnroll;
            decOut{r,3} = inFacUnroll;
            decOut{r,4} = decStatesUnroll;
        end
    end

    validIdx = ~isnan(perfTable(:,1));
    perfTable = perfTable(validIdx,:);
    runTable = runTable(validIdx,:);
    decOut = decOut(validIdx,:);
    
    if strcmp(opts.outSubDir{batchIdx},'test4')
        perfTable = perfTable(1:6,:);
        runTable = runTable(1:6,:);
    end
    
    %bin trials into (dir) x (dist) bins
    targDist = matVecMag(dataset.targetPos - dataset.cursorPos,2);
    trlDist = targDist(dataset.trialEpochs(:,1));
    posErr = dataset.targetPos(dataset.trialEpochs(:,1),:) - dataset.cursorPos(dataset.trialEpochs(:,1),:);
    
    gridBlocks = dataset.blockList(strcmp(dataset.gameNames,'keyboard'));
    gridTrials = find(ismember(dataset.blockNums(dataset.trialEpochs(:,1)), gridBlocks));
    [nTrls, distCodes] = histc(trlDist, linspace(100,900,3));
    gridDirCodes = dirTrialBin( posErr, 4 );
    gridTrials = setdiff(gridTrials, find(distCodes==0));
    
    centerOutBlocks = dataset.blockList(strcmp(dataset.gameNames,'cursor'));
    coTrials = find(ismember(dataset.blockNums(dataset.trialEpochs(:,1)), centerOutBlocks));
    coDirCodes = dirTrialBin( posErr, 8 );
        
    %center out direction binning
    out = apply_dPCA_simple( dataset.TX, dataset.trialEpochs(gridTrials,1), [gridDirCodes(gridTrials), distCodes(gridTrials)], ...
        [-25, 100], 0.02, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 20 );
        
    lineArgs = cell(4,2);
    dirColors = hsv(4)*0.8;
    for d=1:length(lineArgs)
        lineArgs{d,1} = {'Color',dirColors(d,:),'LineWidth',2,'LineStyle',':'};
        lineArgs{d,2} = {'Color',dirColors(d,:),'LineWidth',2,'LineStyle','-'};
    end
    
    twoFactor_dPCA_plot( out, (-25:100)*0.02, lineArgs, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 'sameAxes' );
    
    dirLineArgs = cell(8,1);
    dirColors8 = hsv(8)*0.8;
    for d=1:length(dirLineArgs)
        dirLineArgs{d} = {'Color',dirColors8(d,:),'LineWidth',2,'LineStyle','-'};
    end
    
    out = apply_dPCA_simple( dataset.TX, dataset.trialEpochs(coTrials,1), coDirCodes(coTrials), ...
        [-25, 100], 0.02, {'CD','CI'}, 20 );
    oneFactor_dPCA_plot( out, (-25:100)*0.02, dirLineArgs, {'Dir', 'CI'}, 'sameAxes' );
    
    %%
    %best network
    [sortVals,sortIdx] = sort(perfTable(:,4),'ascend');
    medIdx = sortIdx(1);
    %medIdx = runIdx(sortIdx(round(end/2)));

    coef = buildLinFilts(decOut{medIdx,3}, [ones(length(allIdx),1), dataset.TX(allIdx,:)], 'standard');
    predVals = [ones(length(allIdx),1), dataset.TX(allIdx,:)]*coef;

    A = coef(2:end,:);
    P = A*inv(A'*A)*A';

    projTX = (P*dataset.TX')';

    net_dPCA_out = apply_dPCA_simple( projTX, dataset.trialEpochs(gridTrials,1), [gridDirCodes(gridTrials), distCodes(gridTrials)], ...
        [-25, 100], 0.02, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 20 );
    twoFactor_dPCA_plot( net_dPCA_out, (-25:100)*0.02, lineArgs, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 'sameAxes' );
    
    %%
    %recover input for the whole file
    nInputs = 2:6;
    for x=1:length(nInputs)
        runIdx = find(vertcat(runTable{:,3})==nInputs(x));
        pTmp = perfTable(runIdx,4);
        
        [sortVals,sortIdx] = sort(pTmp,'ascend');
        medIdx = runIdx(sortIdx(1));
        %medIdx = runIdx(sortIdx(round(end/2)));
        
        coef = buildLinFilts(decOut{medIdx,3}, [ones(length(allIdx),1), dataset.TX(allIdx,:)], 'standard');
        predVals = [ones(length(allIdx),1), dataset.TX(allIdx,:)]*coef;
        
        A = coef(2:end,:);
        P = A*inv(A'*A)*A';
        
        projTX = (P*dataset.TX')';
        
        out = apply_dPCA_simple( projTX, dataset.trialEpochs(gridTrials,1), [gridDirCodes(gridTrials), distCodes(gridTrials)], ...
            [-25, 100], 0.02, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 20 );
        twoFactor_dPCA_plot( out, (-25:100)*0.02, lineArgs, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 'sameAxes' );
    end
    
    %%
    %recover input for the whole file
    nInputs = 2:6;
    for x=1:length(nInputs)
        runIdx = find(vertcat(runTable{:,3})==nInputs(x));
        pTmp = perfTable(runIdx,4);
        
        [sortVals,sortIdx] = sort(pTmp,'ascend');
        medIdx = runIdx(sortIdx(1));
        %medIdx = runIdx(sortIdx(round(end/2)));
        
        coef = buildLinFilts(decOut{medIdx,3}, [ones(length(allIdx),1), dataset.TX(allIdx,:)], 'standard');
        predVals = [ones(length(allIdx),1), dataset.TX(allIdx,:)]*coef;
        
        A = coef(2:end,:);
        P = A*inv(A'*A)*A';
        
        projTX = (P*dataset.TX')';
        
        out = apply_dPCA_simple( projTX, dataset.trialEpochs(coTrials,1), coDirCodes(coTrials), ...
            [-25, 100], 0.02, {'CD','CI'}, 20 );
        oneFactor_dPCA_plot( out, (-25:100)*0.02, dirLineArgs, {'Dir', 'CI'}, 'sameAxes' );
    end
    
    %%
    %load controls
    controls = load([prepDataDir filesep 'controlDecoders' filesep datasetName]);
    controlFields = {'fold_R','fold_angErr','fold_magR','fold_mse'};
    metricNames = {'R','angErr','magR','MSE'};
    
    for perfMetrics=1:4
        figure('Position',[680         819        1079         279]);
        for columnIdx = 1:size(runTable,2)
            subplot(1,size(runTable,2),columnIdx);
            hold on;
            if ischar(runTable{1,columnIdx})
                boxplot(perfTable(:,perfMetrics), vertcat(runTable(:,columnIdx)));
            else
                boxplot(perfTable(:,perfMetrics), vertcat(runTable{:,columnIdx}));
            end
            plot(get(gca,'XLim'),[controls.(controlFields{perfMetrics})(1,2), controls.(controlFields{perfMetrics})(1,2)],'--k');
            title(metricNames{perfMetrics});
        end
        saveas(gcf, [saveDir filesep opts.outSubDir{batchIdx} '_' metricNames{perfMetrics} '.png'], 'png');
    end
    
    %%
    if size(runTable,2)>=3
        twoDIdx = find(vertcat(runTable{:,3})==2);
        [~,sortIdx] = sort(perfTable(twoDIdx,4),'ascend');
        med2DIdx = twoDIdx(sortIdx(1));
    end
    
    [~,sortIdx] = sort(perfTable(:,4),'ascend');
    sortParams = runTable(sortIdx,:);
    
    bestIdx = sortIdx(1);
    medIdx = sortIdx(round(length(sortIdx)/2));

    figure
    ax1 = subplot(3,1,1);
    hold on
    plot(decOut{bestIdx,2}(:,1),'LineWidth',2);
    plot(decOut{bestIdx,1}(:,1),'LineWidth',2);
    plot(decOut{medIdx,1}(:,1),'LineWidth',2);
    plot(controls.xValOut(allIdx,1),'LineWidth',2);
    plot(controls.xValOut_lin(allIdx,1),'LineWidth',2);
    legend({'Target','RNN Best','RNN Median','MagDec','Linear'});

    ax2 = subplot(3,1,2);
    hold on
    plot(decOut{bestIdx,2}(:,2),'LineWidth',2);
    plot(decOut{bestIdx,1}(:,2),'LineWidth',2);
    plot(decOut{medIdx,1}(:,2),'LineWidth',2);
    plot(controls.xValOut(allIdx,2),'LineWidth',2);
    plot(controls.xValOut_lin(allIdx,2),'LineWidth',2);
    legend({'Target','RNN Best','RNN Median','MagDec','Linear'});
    
    B = [0.06];
    A = [1, -0.94];
    
    ax3 = subplot(3,1,3);
    hold on
    plot(matVecMag(decOut{bestIdx,2},2),'LineWidth',2);
    plot(matVecMag(decOut{bestIdx,1},2),'LineWidth',2);
    plot(matVecMag(decOut{medIdx,1},2),'LineWidth',2);
    plot(matVecMag(controls.xValOut(allIdx,:),2),'LineWidth',2);
    plot(matVecMag(controls.xValOut_lin(allIdx,:),2),'LineWidth',2);
    legend({'Target','RNN Best','RNN Median','MagDec','Linear'});
    
    magSignal = zscore(dataset.TX * net_dPCA_out.W(:,1));
    filtDim = magSignal;
    filtDim = filter(B,A,filtDim);
    plot(filtDim(allIdx,:)+0.5,'LineWidth',2,'Color','k');
    
    linkaxes([ax1, ax2, ax3],'x');
    
    saveas(gcf, [saveDir filesep opts.outSubDir{batchIdx} '_linePlot_all.fig'], 'fig');
end

%%
%generate fake neural data by using dPCA dimensions and scaling them
%differently
%center out direction binning
smoothSpikes = gaussSmooth_fast(dataset.TX,1.5);
full_dPCA_out = apply_dPCA_simple( smoothSpikes, dataset.trialEpochs(gridTrials,1), [gridDirCodes(gridTrials), distCodes(gridTrials)], ...
        [-25, 100], 0.02, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 20 );

lineArgs = cell(4,2);
dirColors = hsv(4)*0.8;
for d=1:length(lineArgs)
    lineArgs{d,1} = {'Color',dirColors(d,:),'LineWidth',2,'LineStyle',':'};
    lineArgs{d,2} = {'Color',dirColors(d,:),'LineWidth',2,'LineStyle','-'};
end

twoFactor_dPCA_plot( full_dPCA_out, (-25:100)*0.02, lineArgs, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 'sameAxes' );
    
plotTrials = intersect(gridTrials, find(dataset.isSuccessful));
baseTrial = intersect(intersect(find(distCodes==2 & gridDirCodes==1), testIdxTM), plotTrials);
baseTrial = baseTrial(randi(length(baseTrial),1));

nTrlBins = dataset.trialEpochs(baseTrial,2)-dataset.trialEpochs(baseTrial,1)+1;
modifyIdx = (510-nTrlBins-20):510;
loopIdx = (dataset.trialEpochs(baseTrial,2)-510+1):dataset.trialEpochs(baseTrial,2);

modScales = linspace(0,1,9);
shiftIdx = 0:2:20;
nDim = 10;
inputs = zeros(length(modScales)*nDim,510,192);
inputIdx = 1;
conTable = [];

gridIdx = expandEpochIdx(dataset.trialEpochs(gridTrials,:));
meanVal = mean(dataset.TX(gridIdx,:));         

for dimIdx=1:nDim
    for modIdx=1:length(modScales) 
        %reconData = baseData + (modScales(modIdx)-1)*(baseData*full_dPCA_out.W(:,dimIdx))*full_dPCA_out.V(:,dimIdx)';
        projScores = (dataset.TX(loopIdx,:) - meanVal)*full_dPCA_out.W;
        projScores(:,dimIdx) = projScores(:,dimIdx)*modScales(modIdx);
        reconData = (projScores*full_dPCA_out.V') + meanVal;

        inputs(inputIdx,:,:) = reconData;

        conTable = [conTable; [dimIdx, modIdx]];
        inputIdx = inputIdx + 1;
    end
end

for modIdx=1:length(modScales) 
    %reconData = baseData + (modScales(modIdx)-1)*(baseData*full_dPCA_out.W(:,dimIdx))*full_dPCA_out.V(:,dimIdx)';
    projScores = (dataset.TX(loopIdx,:) - meanVal)*full_dPCA_out.W;

    scalePattern = zeros(1,20);
    scalePattern([2 3]) = modScales(modIdx);
    scalePattern(1) = 0;
    scalePattern(4) = 1;

    scaledScores = bsxfun(@times, projScores, scalePattern);
    reconData = (scaledScores*full_dPCA_out.V') + meanVal;
    inputs(inputIdx,:,:) = reconData;

    conTable = [conTable; [11, modIdx]];
    inputIdx = inputIdx + 1;

    scalePattern = zeros(1,20);
    scalePattern([2 3]) = modScales(modIdx);
    scalePattern(1) = 1;
    scalePattern(4) = 1;

    scaledScores = bsxfun(@times, projScores, scalePattern);
    reconData = (scaledScores*full_dPCA_out.V') + meanVal;
    inputs(inputIdx,:,:) = reconData;

    conTable = [conTable; [12, modIdx]];
    inputIdx = inputIdx + 1;

    scalePattern = zeros(1,20);
    scalePattern([2 3]) = 0.5;
    scalePattern(1) = 1;
    scalePattern(4) = modScales(modIdx);

    scaledScores = bsxfun(@times, projScores, scalePattern);
    reconData = (scaledScores*full_dPCA_out.V') + meanVal;
    inputs(inputIdx,:,:) = reconData;

    conTable = [conTable; [13, modIdx]];
    inputIdx = inputIdx + 1;

    shiftedScores = projScores;
    shiftedScores(1:(end-shiftIdx(modIdx)),1) = shiftedScores((shiftIdx(modIdx)+1):end,1);
    reconData = (shiftedScores*full_dPCA_out.V') + meanVal;
    inputs(inputIdx,:,:) = reconData;

    conTable = [conTable; [14, modIdx]];
    inputIdx = inputIdx + 1;
end

save(['/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Probe/' datasetName],'inputs',...
    'conTable');

runIdxToProbe = find(validIdx);

%%
%decoding results from system ID probe
originalIdx = dataset.trialEpochs(baseTrial,1):dataset.trialEpochs(baseTrial,2);
originalOutAll = load('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5_decode/4/decodeOutput.mat');

outFull = zeros(size(dataset.TX,1),2);
for t=1:length(allTargetsTrlIdx)
    loopIdx = (tm.out.in.reachEpochs(allTargetsTrlIdx(t),1):tm.out.in.reachEpochs(allTargetsTrlIdx(t),2));
    nLoops = length(tm.out.in.reachEpochs(allTargetsTrlIdx(t),1):tm.out.in.reachEpochs(allTargetsTrlIdx(t),2));
    outFull(loopIdx,:) = squeeze(originalOutAll.outputs0(t,(end-nLoops+1):end,:));
end

figure
plot(outFull(originalIdx,:));

load('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Probe/t5.2016.09.28.mat','inputs',...
    'conTable');
fullDecOut = load('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5_probe/4/decodeOutput.mat');

for plotDimIdx=1:2
    figure
    for dimIdx=1:14
        plotIdx = find(conTable(:,1)==dimIdx);
        colors = jet(length(plotIdx))*0.8;

        subplot(4,4,dimIdx);
        hold on
        for x=1:length(plotIdx)
            plot(squeeze(fullDecOut.outputs0(plotIdx(x),:,plotDimIdx)),'Color',colors(x,:),'LineWidth',2)
        end
        xlim([350 510]);
        ylim([-0.5 0.5]);
    end
end

%%
%decoding results from T5 dataset
figure
hold on;
plot(decOut{bestIdx,4});
plot(matVecMag(decOut{bestIdx,2},2),'LineWidth',4);
plot(matVecMag(decOut{bestIdx,1},2),'LineWidth',4);

fullDecOut = load('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5_decode/1/decodeOutput.mat');

allIdx_full = [];
outFull = zeros(size(dataset.TX,1),2);
inFacFull = zeros(size(dataset.TX,1),6);
decStatesFull = zeros(size(dataset.TX,1),512);
for t=1:length(allTargetsTrlIdx)
    loopIdx = (tm.out.in.reachEpochs(allTargetsTrlIdx(t),1):tm.out.in.reachEpochs(allTargetsTrlIdx(t),2));
    nLoops = length(tm.out.in.reachEpochs(allTargetsTrlIdx(t),1):tm.out.in.reachEpochs(allTargetsTrlIdx(t),2));
    outFull(loopIdx,:) = squeeze(fullDecOut.outputs0(t,(end-nLoops+1):end,:));
    inFacFull(loopIdx,:) = squeeze(fullDecOut.inFac0(t,(end-nLoops+1):end,:));
    decStatesFull(loopIdx,:) = squeeze(fullDecOut.decStates0(t,(end-nLoops+1):end,:));
end

unitMean = mean(abs(decStatesFull));
largeUnits = find(unitMean>0.5);
out = apply_dPCA_simple( repmat(decStatesFull(:,largeUnits),1,20), dataset.trialEpochs(coTrials,1), coDirCodes(coTrials), ...
    [-25, 100], 0.02, {'CD','CI'}, 20 );
oneFactor_dPCA_plot( out, (-25:100)*0.02, dirLineArgs, {'Dir', 'CI'}, 'sameAxes' );

figure
hold on
plot(matVecMag(outFull,2),'LineWidth',4);
plot(decStatesFull(:,largeUnits));
    
%%
figure
hold on
plot(squeeze(result.targetsFinal0(1,:,1)));
plot(squeeze(prepDat.targetsFinal(1,:,1)));


