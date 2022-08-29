%%
%load dataset
paths = getFRWPaths( );
addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));
    
saveDir = [paths.dataPath '/Derived/RNNOfflinePerformance_monk/'];

dataDir = [paths.dataPath filesep 'Derived' filesep 'rnnDecoding_monk'];
prepDataDir = [paths.dataPath filesep 'Derived' filesep 'rnnDecoding_monk'];
datasetName = 'J_2015-10-01.mat';

opts.outSubDir = {'test1'};
opts.dataType = {''};
opts.datasetNum = {'0'};
opts.batchNames = {'full'};

barDimIdx = 2;

for batchIdx = 1:length(opts.outSubDir)
    load([dataDir filesep datasetName]);
    testIdx = find(C.test(1));
   
    %analyze results
    outDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_monk_out/' opts.outSubDir{batchIdx}];
    scriptDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_monk_scripts/' opts.outSubDir{batchIdx} '/'];
    load([scriptDir filesep 'runParams.mat']);

    outputFinalField = ['outputsFinal' opts.datasetNum{batchIdx}];
    targetsFinalField = ['targetsFinal' opts.datasetNum{batchIdx}];
    inFacFinalField = ['inFacFinal' opts.datasetNum{batchIdx}];
    decStatesFinalField = ['decoderStatesFinal' opts.datasetNum{batchIdx}];
    
    decOut = cell(size(runTable,1),4);
    perfTable = nan(size(runTable,1),5);
    for r=1:size(runTable,1)
        disp(r);
        fileName = [outDir filesep num2str(r) filesep 'finalOutput.mat'];
         if exist(fileName,'file')
            result = load(fileName);
            
            nFacDim = ndims(result.(inFacFinalField));
            allIdx = [];
     
            outUnroll = [];
            targetsUnroll = [];
            inFacUnroll = [];
            decStatesUnroll = [];
            for t=1:length(testIdx)
                nLoops = length(reachEpochs(testIdx(t),1):reachEpochs(testIdx(t),2));
                outUnroll = [outUnroll; squeeze(result.(outputFinalField)(t,(end-nLoops+1):end,:))];
                targetsUnroll = [targetsUnroll; squeeze(result.(targetsFinalField)(t,(end-nLoops+1):end,:))];
                if nFacDim==2
                    inFacUnroll = [inFacUnroll; squeeze(result.(inFacFinalField)(t,(end-nLoops+1):end,:))'];
                else
                    inFacUnroll = [inFacUnroll; squeeze(result.(inFacFinalField)(t,(end-nLoops+1):end,:))];
                end
                allIdx = [allIdx; (reachEpochs(testIdx(t),1):reachEpochs(testIdx(t),2))'];
                if isfield(result,'decoderStatesFinal0')
                    decStatesUnroll = [decStatesUnroll; squeeze(result.(decStatesFinalField)(t,(end-nLoops+1):end,:))];
                end
            end

            perfTable(r,1) = mean(diag(corr(outUnroll(:,barDimIdx), targetsUnroll(:,barDimIdx)))); 
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
    
    %%
    targDist = matVecMag(data.targetPos(:,1:2) - data.handPos(:,1:2),2);
    
    figure;
    plot(data.handPos(:,2));
    hold on;
    plot(data.targetPos(:,2));
    plot(reachEpochs(:,1), data.handPos(reachEpochs(:,1),2),'o','MarkerSize',12);
    plot(reachEpochs(:,1), targDist(reachEpochs(:,1)),'o','MarkerSize',12);
    
    %%
    %bin trials into (dir) x (dist) bins
    trlDist = targDist(reachEpochs(:,1));
    posErr = data.targetPos(reachEpochs(:,1),1:2) - data.handPos(reachEpochs(:,1),1:2);
    
    [nTrls, distCodes] = histc(trlDist, linspace(30,120,11));
    dirCodes = dirTrialBin( posErr, 4 );
    reDirCodes = nan(size(dirCodes));
    reDirCodes(dirCodes==2) = 1;
    reDirCodes(dirCodes==4) = 2;
    
    plotTrials = ~isnan(reDirCodes) & data.isOuterReach(useTrials) & distCodes~=0 & data.delayTrl(useTrials) & ...
        data.isSuccessful(useTrials);
       
    %center out direction binning
    smoothSpikes = gaussSmooth_fast(data.spikes,1.5);
    full_dPCA_out = apply_dPCA_simple( smoothSpikes, reachEpochs(plotTrials,1), [reDirCodes(plotTrials), distCodes(plotTrials)], ...
        [-25, 75], 0.02, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 20 );
        
    lineArgs = cell(2,10);
    colors = jet(10)*0.8;
    for d=1:10
        lineArgs{1,d} = {'Color',colors(d,:),'LineWidth',2,'LineStyle',':'};
        lineArgs{2,d} = {'Color',colors(d,:),'LineWidth',2,'LineStyle','-'};
    end
    
    twoFactor_dPCA_plot( full_dPCA_out, (-25:75)*0.02, lineArgs, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 'sameAxes' );
    
    %%
    %best network
    [sortVals,sortIdx] = sort(perfTable(:,4),'ascend');
    medIdx = sortIdx(1);
    medIdx = 7;
    %medIdx = runIdx(sortIdx(round(end/2)));

    coef = buildLinFilts(decOut{medIdx,3}, [ones(length(allIdx),1), data.spikes(allIdx,:)], 'standard');
    predVals = [ones(length(allIdx),1), data.spikes(allIdx,:)]*coef;

    A = coef(2:end,:);
    P = A*inv(A'*A)*A';

    projTX = (P*data.spikes')';

    net_dPCA_out = apply_dPCA_simple( projTX, reachEpochs(plotTrials,1), [reDirCodes(plotTrials), distCodes(plotTrials)], ...
        [-25, 75], 0.02, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 20 );
    twoFactor_dPCA_plot( net_dPCA_out, (-25:75)*0.02, lineArgs, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 'sameAxes' );
    
    %%
    %recover input for the whole file
    nInputs = unique(vertcat(runTable{:,3}));
    for x=1:length(nInputs)
        runIdx = find(vertcat(runTable{:,3})==nInputs(x));
        pTmp = perfTable(runIdx,4);
        
        [sortVals,sortIdx] = sort(pTmp,'ascend');
        %medIdx = runIdx(sortIdx(1));
        medIdx = runIdx(sortIdx(round(end/2)));
        
        coef = buildLinFilts(decOut{medIdx,3}, [ones(length(allIdx),1), data.spikes(allIdx,:)], 'standard');
        predVals = [ones(length(allIdx),1), data.spikes(allIdx,:)]*coef;
        
        A = coef(2:end,:);
        P = A*inv(A'*A)*A';
        
        projTX = (P*data.spikes')';
        
        net_dPCA_out = apply_dPCA_simple( projTX, reachEpochs(plotTrials,1), [reDirCodes(plotTrials), distCodes(plotTrials)], ...
            [-25, 75], 0.02, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 20 );
        twoFactor_dPCA_plot( net_dPCA_out, (-25:75)*0.02, lineArgs, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 'sameAxes' );
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
            %plot(get(gca,'XLim'),[controls.(controlFields{perfMetrics})(1,2), controls.(controlFields{perfMetrics})(1,2)],'--k');
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
    hold on
    plot(decOut{bestIdx,2}(:,barDimIdx),'LineWidth',2);
    plot(decOut{bestIdx,1}(:,barDimIdx),'LineWidth',2);
    plot(decOut{medIdx,1}(:,barDimIdx),'LineWidth',2);
    legend({'Target','RNN Best','RNN Median'});

    saveas(gcf, [saveDir filesep opts.outSubDir{batchIdx} '_linePlot_all.fig'], 'fig');
    
    %%
    %plot a sampling of decoded vs. real trajectories for different targets
    allOut = zeros(size(data.spikes,1),2);
    allOut(allIdx,:) = decOut{bestIdx,1}*500;
    
    plotTrials = ~isnan(reDirCodes) & data.isOuterReach(useTrials) & distCodes~=0 & data.delayTrl(useTrials) & ...
        data.isSuccessful(useTrials);
    
    colors = jet(5)*0.8;
    plotDistIdx = 1:2:10;
    outputMat = {allOut, controls.xValOut_lin*500, controls.xValOut_ridge*500};
    decNames = {'RNN','Linear + Exponential Smoothing','Wiener Filter'};
    
    figure('Position',[99   229   936   825]);
    for dirIdx=1:2
        for distIdx=1:length(plotDistIdx)
            plotIdx = intersect(find(plotTrials & distCodes==plotDistIdx(distIdx) & reDirCodes==dirIdx), testIdx);
            plotIdx = plotIdx(randi(length(plotIdx),1));
            
            for decIdx=1:length(decNames)
                allOut = outputMat{decIdx}(:,2);
                
                ax1 = subplot(3,2,(decIdx-1)*2 + 1);
                hold on;
                for p=1
                    loopIdx = reachEpochs(plotIdx(p),1):reachEpochs(plotIdx(p),2);
                    timeAxis = (0:(length(loopIdx)-1))*0.02;
                    plot(timeAxis, data.handPos(loopIdx(1),barDimIdx) + cumsum(allOut(loopIdx,1)/50),'Color',colors(distIdx,:),'LineWidth',2);
                    plot(timeAxis, data.handPos(loopIdx,barDimIdx),':','Color',colors(distIdx,:),'LineWidth',2);
                end
                title(decNames{decIdx});

                ax2 = subplot(3,2,(decIdx-1)*2 + 2);
                hold on;
                for p=1
                    loopIdx = reachEpochs(plotIdx(p),1):reachEpochs(plotIdx(p),2);
                    timeAxis = (0:(length(loopIdx)-1))*0.02;
                    plot(timeAxis, allOut(loopIdx,1),'Color',colors(distIdx,:),'LineWidth',2);
                    plot(timeAxis, data.handVel(loopIdx,barDimIdx)*500,':','Color',colors(distIdx,:),'LineWidth',2);
                end
                title(decNames{decIdx});
            end
        end
    end
    
    axes(ax1);
    xlabel('Time (s)');
    ylabel('Hand Position (mm)');
    set(gca,'LineWidth',2,'FontSize',16);
    
    axes(ax2);
    xlabel('Time (s)');
    ylabel('Hand Velocity (mm/s)');
    set(gca,'LineWidth',2,'FontSize',16);
    
    saveas(gcf, [saveDir filesep opts.outSubDir{batchIdx} '_exampleOutput.png'], 'png');
    
    %%
    %generate fake neural data by using dPCA dimensions and scaling them
    %differently
    plotTrials = ~isnan(reDirCodes) & data.isOuterReach(useTrials) & distCodes~=0 & data.delayTrl(useTrials) & ...
        data.isSuccessful(useTrials);
    baseTrial = intersect(find(plotTrials & distCodes==10 & reDirCodes==1), testIdx);
    baseTrial = baseTrial(randi(length(baseTrial),1));
            
    nTrlBins = reachEpochs(baseTrial,2)-reachEpochs(baseTrial,1)+1;
    modifyIdx = (510-nTrlBins-20):510;
    loopIdx = (reachEpochs(baseTrial,2)-510+1):reachEpochs(baseTrial,2);
    
    nDim = 10;
    inputs = zeros(length(modScales)*nDim,510,192);
    inputIdx = 1;
    conTable = [];
    
    meanVal = mean(data.spikes);         
    modScales = linspace(0,1,9);
    shiftIdx = 0:2:20;
    
    for dimIdx=1:nDim
        for modIdx=1:length(modScales) 
            %reconData = baseData + (modScales(modIdx)-1)*(baseData*full_dPCA_out.W(:,dimIdx))*full_dPCA_out.V(:,dimIdx)';
            projScores = (data.spikes(loopIdx,:) - meanVal)*full_dPCA_out.W;
            projScores(:,dimIdx) = projScores(:,dimIdx)*modScales(modIdx);
            reconData = (projScores*full_dPCA_out.V') + meanVal;
            
            inputs(inputIdx,:,:) = reconData;
            
            conTable = [conTable; [dimIdx, modIdx]];
            inputIdx = inputIdx + 1;
        end
    end
    
    for modIdx=1:length(modScales) 
        %reconData = baseData + (modScales(modIdx)-1)*(baseData*full_dPCA_out.W(:,dimIdx))*full_dPCA_out.V(:,dimIdx)';
        projScores = (data.spikes(loopIdx,:) - meanVal)*full_dPCA_out.W;
        
        scalePattern = zeros(1,20);
        scalePattern([2 5 8]) = modScales(modIdx);
        scalePattern([1 3]) = 0;
        scalePattern(4) = 1;
        
        scaledScores = bsxfun(@times, projScores, scalePattern);
        reconData = (scaledScores*full_dPCA_out.V') + meanVal;
        inputs(inputIdx,:,:) = reconData;

        conTable = [conTable; [11, modIdx]];
        inputIdx = inputIdx + 1;
        
        scalePattern = zeros(1,20);
        scalePattern([2 5 8]) = modScales(modIdx);
        scalePattern([1 3]) = 1;
        scalePattern(4) = 1;
        
        scaledScores = bsxfun(@times, projScores, scalePattern);
        reconData = (scaledScores*full_dPCA_out.V') + meanVal;
        inputs(inputIdx,:,:) = reconData;

        conTable = [conTable; [12, modIdx]];
        inputIdx = inputIdx + 1;
        
        scalePattern = zeros(1,20);
        scalePattern([2 5 8]) = 0.5;
        scalePattern([1 3]) = 1;
        scalePattern(4) = modScales(modIdx);
        
        scaledScores = bsxfun(@times, projScores, scalePattern);
        reconData = (scaledScores*full_dPCA_out.V') + meanVal;
        inputs(inputIdx,:,:) = reconData;

        conTable = [conTable; [13, modIdx]];
        inputIdx = inputIdx + 1;
        
        shiftedScores = projScores;
        shiftedScores(1:(end-shiftIdx(modIdx)),[1 3]) = shiftedScores((shiftIdx(modIdx)+1):end,[1 3]);
        reconData = (shiftedScores*full_dPCA_out.V') + meanVal;
        inputs(inputIdx,:,:) = reconData;

        conTable = [conTable; [14, modIdx]];
        inputIdx = inputIdx + 1;
    end
    
    save(['/Users/frankwillett/Data/Derived/rnnDecoding_monk/Probe/' datasetName],'inputs',...
        'conTable');
    
    runIdxToProbe = find(validIdx);
    
    %%
    remoteDatasetDir = '/Users/frankwillett/Data/Derived/rnnDecoding_monk/Probe';
    remoteOutDir = '/Users/frankwillett/Data/Derived/rnnDecoding_monk_out/test1_probe';
    pyDir = '/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
    scriptDir = '/Users/frankwillett/Data/Derived/rnnDecoding_monk_scripts/test1_probe/';

    mkdir(scriptDir);

    availableGPU = [6 7 8];
    displayNum = 7;

    opts = rnnDecMakeOptsSimple( );
    opts.datasets = {'J_2015-10-01'};
    opts.datasetDir = remoteDatasetDir;
    opts.outputDir = remoteOutDir;
    opts.nDecUnits = 100;
    opts.nEpochs = 1000;
    opts.nInputsPerModelDataset = 192;
    opts.mode = 'decode';

    %try random values uniformly within a box of specified
    %limits
    baseDir = '/Users/frankwillett/Data/Derived/rnnDecoding_monk_out/test1/';
    paramFields = {'nLayers','nDecUnits','nDecInputFactors','learnRateStart','rnnType','loadDir'};
    newTable = runTable;
    for x=1:length(runIdxToProbe)
        newTable{x,6} = [baseDir num2str(runIdxToProbe(x)) '/'];
    end

    paramVec = rnnDecMakeFullParamVec( opts, paramFields, newTable );
    rnnDecMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );
    save([scriptDir 'runParams.mat'],'paramFields','runTable','paramVec');
    
    %%
    %decoding results from system ID probe
    smoothSpikes = gaussSmooth_fast(data.spikes,1.5);
    full_dPCA_out = apply_dPCA_simple( smoothSpikes, reachEpochs(plotTrials,1), [reDirCodes(plotTrials), distCodes(plotTrials)], ...
        [-25, 75], 0.02, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 20 );
    twoFactor_dPCA_plot( full_dPCA_out, (-25:75)*0.02, lineArgs, {'Dir', 'Dist', 'CI', 'Dir x Dist'}, 'sameAxes' );
    
    load(['/Users/frankwillett/Data/Derived/rnnDecoding_monk/Probe/' datasetName],'inputs','conTable');
    fullDecOut = load(['/Users/frankwillett/Data/Derived/rnnDecoding_monk_out/test1_probe/' num2str(7) '/decodeOutput.mat']);

    figure
    for dimIdx=1:14
        plotIdx = find(conTable(:,1)==dimIdx);
        colors = jet(length(plotIdx))*0.8;
        
        subplot(4,4,dimIdx);
        hold on
        for x=1:length(plotIdx)
            plot(squeeze(fullDecOut.outputs0(plotIdx(x),:,barDimIdx)),'Color',colors(x,:),'LineWidth',2)
        end
        xlim([400 510]);
        ylim([-0.1 1]);
    end

end

%%
%decoding results from system ID probe
load('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Probe/t5.2016.09.28.mat','inputs','inputPatterns',...
    'conTable');
fullDecOut = load('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5_probe/5/decodeOutput.mat');

for probeType = 1:4
    dirMap = [6 3 2 1 4 7 8 9];
    plotIdx = 150:500;
    magOut = cell(8,1);

    figure
    for d=1:8
        dirIdx = find(conTable(:,1)==d & conTable(:,3)==probeType & conTable(:,2)<=10);
        colors = jet(length(dirIdx))*0.8;
        magOut{d} = zeros(length(dirIdx),1);

        subplot(3,3,dirMap(d));
        hold on
        for x=1:length(dirIdx)
            plot(squeeze(fullDecOut.outputs0(dirIdx(x),plotIdx,1)),'-','Color',colors(x,:),'LineWidth',2);
            plot(squeeze(fullDecOut.outputs0(dirIdx(x),plotIdx,2)),':','Color',colors(x,:),'LineWidth',2);
            magOut{d}(x) = mean(matVecMag(squeeze(fullDecOut.outputs0(dirIdx(x),plotIdx,:)),2));
        end
    end
    title(['Type ' num2str(probeType)]);

    figure; 
    hold on
    for d=1:8
        plot(magOut{d});
    end
    title(['Type ' num2str(probeType)]);
end

dSet = dataset;

allIdx_full = [];
outFull = zeros(size(dSet.TX,1),2);
inFacFull = zeros(size(dSet.TX,1),6);
decStatesFull = zeros(size(dSet.TX,1),512);
for t=1:length(allTargetsTrlIdx)
    outFull(loopIdx,:) = squeeze(fullDecOut.outputs0(t,(end-nLoops+1):end,:));
    inFacFull(loopIdx,:) = squeeze(fullDecOut.inFac0(t,(end-nLoops+1):end,:));
    decStatesFull(loopIdx,:) = squeeze(fullDecOut.decStates0(t,(end-nLoops+1):end,:));
end

unitMean = mean(abs(decStatesFull));
largeUnits = find(unitMean>0.5);
out = apply_dPCA_simple( repmat(decStatesFull(:,largeUnits),1,20), dSet.trialEpochs(coTrials,1), coDirCodes(coTrials), ...
    [-25, 100], 0.02, {'CD','CI'}, 20 );
oneFactor_dPCA_plot( out, (-25:100)*0.02, dirLineArgs, {'Dir', 'CI'}, 'sameAxes' );

figure
hold on
plot(matVecMag(outFull,2),'LineWidth',4);
plot(decStatesFull(:,largeUnits));

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


