%%
folderName = 'BCIDynamics_4';
datasets = {
    't5-2017-09-20'};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
lfadsPreDir = [paths.dataPath filesep 'Derived' filesep 'pre_LFADS'];

%%
for d=1:length(datasets) 
    disp(datasets{d});
    fileName = [dataDir filesep datasets{d} '.mat'];
    predata = load(fileName);
        
    for alignIdx = 1
        catNeural = cat(3,predata.allNeural{alignIdx,1}, predata.allNeural{alignIdx,2});
        catNeural = permute(catNeural, [3 2 1]);
        catNeural = int64(catNeural / (1000/predata.binMS));
        binnedCubeToLFADS( [lfadsPreDir filesep folderName filesep], [datasets{d} '_' predata.alignTypes{alignIdx}], catNeural, 0.8, predata.binMS  );
    end
end

%%
%bash scripts    
remotePreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' folderName];
remotePostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' folderName];
lfadsPyDir = '/net/home/fwillett/models/lfads/';
scriptDir = [paths.dataPath '/Derived/pre_LFADS/' folderName '/'];

availableGPU = [0 1 2 3 5 6 7 8];
mode = 'pairedSampleAndAverage';
displayNum = 7;

%try random values uniformly within a hyperbox of specified
%limits
defaultOpts = lfadsMakeOptsSimple();
defaultOpts.learning_rate_stop = 1e-04;
defaultOpts.gen_dim = 128;
defaultOpts.keep_prob = 0.98;
defaultOpts.l2_con_scale = 250;
defaultOpts.l2_gen_scale = 250;

paramVec = [];
datasetVec = [];
for d=1:length(datasets)
    fileName = [dataDir filesep datasets{d} '.mat'];
    predata = load(fileName);

    for alignIdx = 1
        datasetName = [datasets{d} '_' predata.alignTypes{alignIdx}];
        newOpts = defaultOpts;
        
        nTrls = size(predata.allNeural{1,1},1);
        nValid = ceil(nTrls*0.2);
        batchSize = min(128, nValid - 2);
        newOpts.batch_size = batchSize;

        newOpts.co_dim = 0;
        paramVec = [paramVec; newOpts];
        datasetVec = [datasetVec; {datasetName}];

        newOpts.co_dim = 3;
        paramVec = [paramVec; newOpts];
        datasetVec = [datasetVec; {datasetName}];
    end
end

lfadsMakeBatchScripts( scriptDir, remotePreDir, remotePostDir, lfadsPyDir, ...
    datasetVec, paramVec, availableGPU, displayNum, mode );

save([scriptDir 'runParams.mat'],'paramVec','datasetVec');