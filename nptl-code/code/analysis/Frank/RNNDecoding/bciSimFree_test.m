%%
%raw features
targSeqFile = '/net/home/fwillett/Data/Derived/bciSim_seq/test1/trackSeq.mat';
remoteOutDir = '/net/home/fwillett/Data/Derived/bciSim_out/test1';
pyDir = '/net/home/fwillett/nptlBrainGateRig/code/analysis/Frank/BackpropSim/';
scriptDir = '/Users/frankwillett/Data/Derived/bciSim_scripts/test1/';

mkdir(scriptDir);

availableGPU = [6 7 8];
displayNum = 7;

opts = bciSimMakeOptsSimple( );
opts.targSeqFile = targSeqFile;
opts.outputDir = remoteOutDir;
opts.nOutputFactors = 4;

%try random values uniformly within a box of specified
%limits
paramFields = {'nDecUnits','nControllerUnits','learnRateStart'};
paramPossibilities = {[64, 128, 256, 512], [64, 128, 256, 512], [0.005, 0.01, 0.02, 0.04]};
runTable = bciSimUniformParamSample( paramPossibilities, 128 );

paramVec = bciSimMakeFullParamVec( opts, paramFields, runTable );

bciSimMakeBatchScripts( scriptDir, remoteOutDir, pyDir, paramVec, availableGPU, displayNum );
bciSimMakeBatchScripts_cpu( scriptDir, remoteOutDir, pyDir, paramVec, displayNum );

save([scriptDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec');
