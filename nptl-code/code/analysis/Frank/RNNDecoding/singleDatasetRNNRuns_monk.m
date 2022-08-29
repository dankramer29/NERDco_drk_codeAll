%%
%raw features
remoteDatasetDir = '/net/home/fwillett/Data/Derived/rnnDecoding_monk/Fold1';
remoteOutDir = '/net/home/fwillett/Data/Derived/rnnDecoding_monk_out/test1';
pyDir = '/net/home/fwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
scriptDir = '/Users/frankwillett/Data/Derived/rnnDecoding_monk_scripts/test1/';

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

%try random values uniformly within a box of specified
%limits
paramFields = {'nLayers','nDecUnits','nDecInputFactors','learnRateStart','rnnType'};
paramPossibilities = {1:2, [128 256 512], [1 2 3 4 5 10], [0.005 0.01 0.02],{'RNN','GRU','LSTM'}};
runTable = rnnUniformParamSample( paramPossibilities, 64 );

paramVec = rnnDecMakeFullParamVec( opts, paramFields, runTable );

rnnDecMakeBatchScripts( scriptDir, remoteOutDir, pyDir, paramVec, availableGPU, displayNum );
rnnDecMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );

save([scriptDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec');