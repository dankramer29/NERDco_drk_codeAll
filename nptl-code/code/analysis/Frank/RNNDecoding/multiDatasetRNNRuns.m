%%
%raw features
remoteDatasetDir = '/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Fold1';
remoteOutDir = '/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_out/test4';
pyDir = '/net/home/fwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
scriptDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/test4/';

% pyDir = '/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
% remoteDatasetDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Fold1';
% remoteOutDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test4';

mkdir(scriptDir);

availableGPU = [0 1 2 3];
displayNum = 7;

opts = rnnDecMakeOptsSimple( );
opts.datasets = {'t5.2016.09.26','t5.2016.09.28','t5.2016.10.03',...
    't5.2017.01.30','t5.2017.02.15','t5.2017.03.30','t5.2017.04.26','t5.2017.05.24','t5.2017.07.31','t5.2017.09.20'};
opts.datasetDir = remoteDatasetDir;
opts.outputDir = remoteOutDir;
opts.nModelDatasets = length(opts.datasets);
opts.nInputsPerModelDataset = cell(length(opts.datasets),1);
for x=1:length(opts.nInputsPerModelDataset)
    opts.nInputsPerModelDataset{x} = 192;
end
opts.nLayers = 2;
opts.nDecInputFactors = 6;
opts.rnnType = 'GRU';
opts.keepProbIn = 1.0;
opts.keepProbLayer = 1.0;
opts.nDecUnits = 512;
opts.nEpochs = 1000;

%try random values uniformly within a box of specified
%limits
paramFields = {'learnRateStart'};
runTable = [{0.005}, {0.005}, {0.01}, {0.01}, {0.02}, {0.02}, {0.04}, {0.04}]';
paramVec = rnnDecMakeFullParamVec( opts, paramFields, runTable );

rnnDecMakeBatchScripts( scriptDir, remoteOutDir, pyDir, paramVec, availableGPU, displayNum );
rnnDecMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );

save([scriptDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec');

%%
%raw features
remoteDatasetDir = '/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Fold1';
remoteOutDir = '/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5';
pyDir = '/net/home/fwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
scriptDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/test5/';

mkdir(scriptDir);

availableGPU = [6 7 8];
displayNum = 7;

opts = rnnDecMakeOptsSimple( );
opts.datasets = {'t5.2016.09.28'};
opts.datasetDir = remoteDatasetDir;
opts.outputDir = remoteOutDir;
opts.nModelDatasets = length(opts.datasets);
opts.nInputsPerModelDataset = cell(length(opts.datasets),1);
for x=1:length(opts.nInputsPerModelDataset)
    opts.nInputsPerModelDataset{x} = 192;
end
opts.nLayers = 2;
opts.nDecInputFactors = 6;
opts.rnnType = 'GRU';
opts.keepProbIn = 1.0;
opts.keepProbLayer = 1.0;
opts.nDecUnits = 512;
opts.nEpochs = 1000;
opts.mode = 'preInitTrain';
opts.preInitDatasetNum=1;

%try random values uniformly within a box of specified
%limits
baseDir = '/net/home/fwillett/Data/Derived/rnnDecoding_2dDatasets_out/test4/';
paramFields = {'loadDir'};
runTable = {[baseDir '1/'],[baseDir '2/'],[baseDir '3/'],[baseDir '4/'],[baseDir '5/'],[baseDir '6/']}';
paramVec = rnnDecMakeFullParamVec( opts, paramFields, runTable );

rnnDecMakeBatchScripts( scriptDir, remoteOutDir, pyDir, paramVec, availableGPU, displayNum );
rnnDecMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );

save([scriptDir 'runParams.mat'],'paramFields','runTable','paramVec');

%%
%decode
datasetName = 't5.2016.09.28.mat';
paths = getFRWPaths( );
prepDataDir = [paths.dataPath filesep 'Derived' filesep 'rnnDecoding_2dDatasets_v2'];
controls = load([prepDataDir filesep 'controlDecoders' filesep datasetName]);

stepFun = zeros(510,1);
stepFun(200:400) = 1;

% stepFun2 = zeros(510,1);
% stepFun2(200:300) = 1;
% stepFun2(300:330) = 0;
% stepFun2(330:350) = 1;
% t = (1:510)*0.02;
% stepFun2 = sin(3*pi*t)'.*stepFun;
stepFun2 = zeros(510,1);
stepFun2(401:420) = 1;

angles = linspace(0,2*pi,9)';
angles(end) = [];
targPattern = [cos(angles), sin(angles)];

stepStren = linspace(0,2,20);
currentIdx = 1;
inputPatterns = zeros(320,510,3);
conTable = zeros(320,3);

for d=1:length(angles)
    for s=1:length(stepStren)
        cVec = bsxfun(@times, targPattern(d,:), stepFun)*stepStren(s);
        cVecMag = zeros(size(cVec,1),1);
        inputPatterns(currentIdx,:,:) = [cVec, cVecMag];
        conTable(currentIdx,:) = [d,s,1];
        currentIdx = currentIdx + 1;
        
        cVec = bsxfun(@times, targPattern(d,:), stepFun)*stepStren(s);
        cVecMag = stepFun * stepStren(s);
        inputPatterns(currentIdx,:,:) = [cVec, cVecMag];
        conTable(currentIdx,:) = [d,s,2];
        currentIdx = currentIdx + 1;
        
        cVec = bsxfun(@times, targPattern(d,:), stepFun)*0.5;
        cVecMag = stepFun * stepStren(s);
        inputPatterns(currentIdx,:,:) = [cVec, cVecMag];
        conTable(currentIdx,:) = [d,s,3];
        currentIdx = currentIdx + 1;
        
        cVec = zeros(size(cVec));
        cVecMag = stepFun * stepStren(s);
        inputPatterns(currentIdx,:,:) = [cVec, cVecMag];
        conTable(currentIdx,:) = [d,s,4];
        currentIdx = currentIdx + 1;
        
        cVec = bsxfun(@times, targPattern(d,:), stepFun)*stepStren(s);
        cVec(400:420,2) = stepStren(s);
        cVecMag = abs((stepFun + stepFun2) * stepStren(s));
        inputPatterns(currentIdx,:,:) = [cVec, cVecMag];
        conTable(currentIdx,:) = [d,s,5];
        currentIdx = currentIdx + 1;
    end
end

inputs = zeros(size(inputPatterns,1),510,192);
for x=1:size(inputPatterns,1)
     meanRates = [ones(510,1), squeeze(inputPatterns(x,:,:)), zeros(510,1)]*controls.fullModel.tuningCoef;
     meanRates(meanRates<0)=0;
     P = poissrnd(meanRates/50)*50;
     if any(isnan(P(:)))
         disp(x);
     end
     inputs(x,:,:) = P;
end
save('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Probe/t5.2016.09.28.mat','inputs','inputPatterns',...
    'conTable');

%cVec steps of varying strength
%cVec steps + cVecMag steps of varying strength
%cVecMag steps of varying strength
tmp=load('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Fold1/t5.2016.09.28.mat');
inputs = [tmp.inputs; tmp.inputsVal; tmp.inputsFinal];
targets = [tmp.targets; tmp.targetsVal; tmp.targetsFinal];
errMask = [tmp.errMask; tmp.errMaskVal; tmp.errMaskFinal];
save('/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Full/t5.2016.09.28.mat','inputs','targets','errMask');

%%
remoteDatasetDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Full';
remoteOutDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5_decode';
pyDir = '/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
scriptDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/test5_decode/';

mkdir(scriptDir);

availableGPU = [6 7 8];
displayNum = 7;

opts = rnnDecMakeOptsSimple( );
opts.datasets = {'t5.2016.09.28'};
opts.datasetDir = remoteDatasetDir;
opts.outputDir = remoteOutDir;
opts.nModelDatasets = length(opts.datasets);
opts.nInputsPerModelDataset = cell(length(opts.datasets),1);
for x=1:length(opts.nInputsPerModelDataset)
    opts.nInputsPerModelDataset{x} = 192;
end
opts.nLayers = 2;
opts.nDecInputFactors = 6;
opts.rnnType = 'GRU';
opts.keepProbIn = 1.0;
opts.keepProbLayer = 1.0;
opts.nDecUnits = 512;
opts.nEpochs = 1000;
opts.mode = 'decode';
opts.preInitDatasetNum=0;

%try random values uniformly within a box of specified
%limits
baseDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5/';
paramFields = {'loadDir'};
runTable = {[baseDir '1/'],[baseDir '2/'],[baseDir '3/'],[baseDir '4/'],[baseDir '5/'],[baseDir '6/']}';
paramVec = rnnDecMakeFullParamVec( opts, paramFields, runTable );

rnnDecMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );

save([scriptDir 'runParams.mat'],'paramFields','runTable','paramVec');

%%
remoteDatasetDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_v2/rawFeatures/Probe';
remoteOutDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5_probe';
pyDir = '/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
scriptDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_scripts/test5_probe/';

mkdir(scriptDir);

availableGPU = [6 7 8];
displayNum = 7;

opts = rnnDecMakeOptsSimple( );
opts.datasets = {'t5.2016.09.28'};
opts.datasetDir = remoteDatasetDir;
opts.outputDir = remoteOutDir;
opts.nModelDatasets = length(opts.datasets);
opts.nInputsPerModelDataset = cell(length(opts.datasets),1);
for x=1:length(opts.nInputsPerModelDataset)
    opts.nInputsPerModelDataset{x} = 192;
end
opts.nLayers = 2;
opts.nDecInputFactors = 6;
opts.rnnType = 'GRU';
opts.keepProbIn = 1.0;
opts.keepProbLayer = 1.0;
opts.nDecUnits = 512;
opts.nEpochs = 1000;
opts.mode = 'decode';
opts.preInitDatasetNum=0;

%try random values uniformly within a box of specified
%limits
baseDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test5/';
paramFields = {'loadDir'};
runTable = {[baseDir '1/'],[baseDir '2/'],[baseDir '3/'],[baseDir '4/'],[baseDir '5/'],[baseDir '6/']}';
paramVec = rnnDecMakeFullParamVec( opts, paramFields, runTable );

rnnDecMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );

save([scriptDir 'runParams.mat'],'paramFields','runTable','paramVec');