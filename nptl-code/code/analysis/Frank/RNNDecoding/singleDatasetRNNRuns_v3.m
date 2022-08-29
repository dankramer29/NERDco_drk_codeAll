%%
%raw features
remoteDatasetDir = '/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Fold1';
remoteOutDir = '/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_out/test3';
pyDir = '/net/home/fwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
scriptDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/test3/';

mkdir(scriptDir);

availableGPU = [0 1 2 3 5 6 7 8];
displayNum = 7;

opts = rnnDecMakeOptsSimple( );
opts.datasets = {'t5.2016.09.28'};
opts.datasetDir = remoteDatasetDir;
opts.outputDir = remoteOutDir;
opts.nDecUnits = 100;
opts.nEpochs = 1000;

%try random values uniformly within a box of specified
%limits
paramFields = {'nLayers','nDecUnits','nDecInputFactors','learnRateStart','rnnType','L2Reg','keepProbLayer','keepProbIn'};
paramPossibilities = {1:2, [64 128 256 512], [2 3 4 5 6], [0.005 0.01 0.02],{'RNN','GRU','LSTM'},[0 10 100 1000],[0.9 1.0],[0.9 1.0]};
runTable = rnnUniformParamSample( paramPossibilities, 128 );

paramVec = rnnDecMakeFullParamVec( opts, paramFields, runTable );

rnnDecMakeBatchScripts( scriptDir, remoteOutDir, pyDir, paramVec, availableGPU, displayNum );
rnnDecMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );

save([scriptDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec');

%%
%control features
for nControlInput = 2:4
    remoteDatasetDir = ['/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_v2/4comp_' num2str(nControlInput) '/Fold1'];
    remoteOutDir = ['/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_out/test3_4comp_' num2str(nControlInput)];
    pyDir = '/net/home/fwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
    scriptDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/test3_4comp_' num2str(nControlInput) '/'];

    mkdir(scriptDir);

    availableGPU = [0 1 2 3 5 6 7 8];
    displayNum = 7;

    opts = rnnDecMakeOptsSimple( );
    opts.datasets = {'t5.2016.09.28'};
    opts.datasetDir = remoteDatasetDir;
    opts.outputDir = remoteOutDir;
    opts.nDecUnits = 100;
    opts.nEpochs = 1000;
    opts.keepProbLayer = 1.0;
    opts.keepProbIn = 1.0;
    opts.nInputsPerModelDataset = nControlInput;
    opts.nDecInputFactors = nControlInput;
    opts.useInputProj = 0;

    %try random values uniformly within a box of specified
    %limits
    paramFields = {'nLayers','nDecUnits','learnRateStart','rnnType','L2Reg'};
    paramPossibilities = {1:2, [64 128 256 512], [0.005 0.01 0.02],{'RNN','GRU','LSTM'},[0 10 100]};
    runTable = rnnUniformParamSample( paramPossibilities, 32 );

    paramVec = rnnDecMakeFullParamVec( opts, paramFields, runTable );

    rnnDecMakeBatchScripts( scriptDir, remoteOutDir, pyDir, paramVec, availableGPU, displayNum );
    rnnDecMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );

    save([scriptDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec');
end

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

    %training meta
    tm = load([prepDataDir filesep 'trainingMeta' filesep datasetName],'out');
    testIdx = find(tm.out.C.test(1));
    rnnMask = false(length(testIdx),510,2);
    for t=1:length(testIdx)
        nLoops = length(dataset.trialEpochs(testIdx(t),1):dataset.trialEpochs(testIdx(t),2));
        rnnMask(t,(end-nLoops+1):end,:) = true;
    end
    prepDat = load([prepDataDir filesep opts.dataType{batchIdx} filesep 'Fold1' filesep datasetName]);

    %analyze results
    outDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/' opts.outSubDir{batchIdx}];
    scriptDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/' opts.outSubDir{batchIdx} '/'];
    load([scriptDir filesep 'runParams.mat']);

    outputFinalField = ['outputsFinal' opts.datasetNum{batchIdx}];
    targetsFinalField = ['targetsFinal' opts.datasetNum{batchIdx}];
    
    if strcmp(opts.outSubDir{batchIdx},'test2')
        %reorder shuffled trials
        fileName = [outDir filesep '1' filesep 'finalOutput.mat'];
        remapIdx = zeros(size(prepDat.targetsFinal,1),1);
        for t=1:size(prepDat.targetsFinal,1)
            corrVal = zeros(size(prepDat.targetsFinal,1),1);
            for x=1:size(prepDat.targetsFinal,1)
                corrVal(x) = corr(squeeze(prepDat.targetsFinal(t,:,1))', squeeze(result.targetsFinal0(x,:,1))');
            end
            [~,remapIdx(t)] = max(corrVal);
        end
    end
    
    decOut = cell(size(runTable,1),2);
    perfTable = nan(size(runTable,1),5);
    for r=1:size(runTable,1)
        fileName = [outDir filesep num2str(r) filesep 'finalOutput.mat'];
        allIdx = [];
        if exist(fileName,'file')
            result = load(fileName);
            if strcmp(opts.outSubDir{batchIdx},'test2')
                %reorder shuffled trials
                result.outputsFinal0 = result.outputsFinal0(remapIdx,:,:);
                result.targetsFinal0 = result.targetsFinal0(remapIdx,:,:);
            end
            
            outUnroll = [];
            targetsUnroll = [];
            for t=1:length(testIdx)
                nLoops = length(tm.out.in.reachEpochs(testIdx(t),1):tm.out.in.reachEpochs(testIdx(t),2));
                outUnroll = [outUnroll; squeeze(result.(outputFinalField)(t,(end-nLoops+1):end,:))];
                targetsUnroll = [targetsUnroll; squeeze(result.(targetsFinalField)(t,(end-nLoops+1):end,:))];
                allIdx = [allIdx; (tm.out.in.reachEpochs(testIdx(t),1):tm.out.in.reachEpochs(testIdx(t),2))'];
            end

            perfTable(r,1) = mean(diag(corr(outUnroll, targetsUnroll))); 
            perfTable(r,2) = (180/pi)*nanmean(abs(getAngularError(outUnroll, targetsUnroll)));
            perfTable(r,3) = mean(diag(corr(matVecMag(outUnroll,2), matVecMag(targetsUnroll,2))));
            perfTable(r,4) = mean(mean((outUnroll - targetsUnroll).^2));

            decOut{r,1} = outUnroll;
            decOut{r,2} = targetsUnroll;
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
            plot(get(gca,'XLim'),[controls.(controlFields{perfMetrics})(1,1), controls.(controlFields{perfMetrics})(1,1)],'--k');
            title(metricNames{perfMetrics});
        end
        saveas(gcf, [saveDir filesep opts.outSubDir{batchIdx} '_' metricNames{perfMetrics} '.png'], 'png');
    end
    
    %%
    [~,sortIdx] = sort(perfTable(:,4),'ascend');
    sortParams = runTable(sortIdx,:);
    
    bestIdx = sortIdx(1);
    medIdx = sortIdx(round(length(sortIdx)/2));
    
    figure
    hold on
    plot(decOut{bestIdx,2}(:,1),'LineWidth',2);
    plot(decOut{bestIdx,1}(:,1),'LineWidth',2);
    plot(decOut{medIdx,1}(:,1),'LineWidth',2);
    plot(controls.xValOut(controls.foldIdx{1,2},1),'LineWidth',2);
    plot(controls.xValOut_lin(controls.foldIdx{1,2},1),'LineWidth',2);
    legend({'Target','RNN Best','RNN Median','MagDec','Linear'});
    saveas(gcf, [saveDir filesep opts.outSubDir{batchIdx} '_linePlot_X.fig'], 'fig');

    figure
    hold on
    plot(matVecMag(decOut{bestIdx,2}(:,1),2),'LineWidth',2);
    plot(matVecMag(decOut{bestIdx,1}(:,1),2),'LineWidth',2);
    plot(matVecMag(decOut{medIdx,1}(:,1),2),'LineWidth',2);
    plot(matVecMag(controls.xValOut(controls.foldIdx{1,2},:),2),'LineWidth',2);
    plot(matVecMag(controls.xValOut_lin(controls.foldIdx{1,2},:),2),'LineWidth',2);
    legend({'Target','RNN Best','RNN Median','MagDec','Linear'});
    
    saveas(gcf, [saveDir filesep opts.outSubDir{batchIdx} '_linePlot_mag.fig'], 'fig');
    
    %%
    figure; 
    ax1 = subplot(2,1,1);
    hold on;
    plot(squeeze(decoderStatesFinal0(2,:,:)));
    plot(squeeze(outputsFinal0(2,:,:)),'LineWidth',4);
    xlim([1 500]);
    
    ax2 = subplot(2,1,2);
    hold on;
    plot(zscore(squeeze(inFacFinal0(2,:,:))));
    xlim([1 500]);
    
    linkaxes([ax1, ax2],'x');
end


figure
hold on
plot(squeeze(result.targetsFinal0(1,:,1)));
plot(squeeze(prepDat.targetsFinal(1,:,1)));


