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
saveDir = [paths.dataPath '/Derived/RNNOfflinePerformance/'];

dataDir = [paths.dataPath '/Derived/2dDatasets'];
prepDataDir = [paths.dataPath filesep 'Derived' filesep 'rnnDecoding_2dDatasets_v2'];
datasetName = 't5.2016.09.28.mat';
%outSubDir = 'test2';
%dataType = 'rawFeatures';
outSubDir = 'test3_4comp_4';
dataType = '4comp_4';

load([dataDir filesep datasetName]);
dataset.trialEpochs(dataset.trialEpochs>length(dataset.cursorPos)) = length(dataset.cursorPos);

addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

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
prepDat = load([prepDataDir filesep dataType filesep 'Fold1' filesep datasetName]);

%analyze results
outDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/' outSubDir];
scriptDir = ['/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/' outSubDir '/'];
load([scriptDir filesep 'runParams.mat']);

decOut = cell(size(runTable,1),2);
perfTable = nan(size(runTable,1),5);
for r=1:size(runTable,1)
    fileName = [outDir filesep num2str(r) filesep 'finalOutput.mat'];
    if exist(fileName,'file')
        result = load(fileName);
        
        outUnroll = [];
        targetsUnroll = [];
        for t=1:length(testIdx)
            nLoops = length(tm.out.in.reachEpochs(testIdx(t),1):tm.out.in.reachEpochs(testIdx(t),2));
            outUnroll = [outUnroll; squeeze(result.outputsFinal0(t,(end-nLoops+1):end,:))];
            targetsUnroll = [targetsUnroll; squeeze(result.targetsFinal0(t,(end-nLoops+1):end,:))];
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

%load controls
controls = load([prepDataDir filesep 'controlDecoders' filesep datasetName]);
controlFields = {'fold_R','fold_angErr','fold_magR','fold_mse'};
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
    end
    saveas(gcf, [saveDir filesep outSubDir '_' controlFields{perfMetrics} '.png'], 'png');
end

[~,sortIdx] = sort(perfTable(:,1),'descend');
sortParams = runTable(sortIdx,:);

%%
figure
hold on
plot(decOut{sortIdx(1),2}(:,1),'LineWidth',2);
plot(decOut{sortIdx(1),1}(:,1),'LineWidth',2);
plot(controls.xValOut(controls.foldIdx{1,2},1),'LineWidth',2);
plot(controls.xValOut_lin(controls.foldIdx{1,2},1),'LineWidth',2);
legend({'Target','RNN','MagDec','Linear'});

figure
hold on
plot(matVecMag(decOut{sortIdx(1),2},2),'LineWidth',2);
plot(matVecMag(decOut{sortIdx(1),1},2),'LineWidth',2);
plot(matVecMag(controls.xValOut(controls.foldIdx{1,2},:),2),'LineWidth',2);
plot(matVecMag(controls.xValOut_lin(controls.foldIdx{1,2},:),2),'LineWidth',2);
legend({'Target','RNN','MagDec','Linear'});

