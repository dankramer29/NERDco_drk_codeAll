          
opts = rnnDecMakeOptsSimple( );
opts.datasets = {'t5.2016.09.16','t5.2016.09.19'};
opts.datasetDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets/rawFeatures/Fold1';
opts.outputDir = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets_out/test';
opts.nDecUnits = 100;

scriptName = '/Users/frankwillett/Data/Derived/rnnDecoding_2dDatasets/testScript';
gpuNum = -1;
codeDir = '/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';

rnnDecMakeShellScriptSimple( scriptName, codeDir, opts, -1, 17 );