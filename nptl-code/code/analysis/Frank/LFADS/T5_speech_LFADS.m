paths = getFRWPaths();
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

dataDir = '/net/derivative/user/sstavisk/Results/speech/dataForLFADS/';
datasets = {
    't5.2017.10.23-phonemes_5ae60c61a42dca423cd4ab54034528cc.mat','t5.2017.10.23-phonemes','shuffle'
    't5.2017.10.23-caterpillar_b450ebf04ef105cc4d99d2de1ad31a5e.mat','t5.2017.10.23-caterpillar','shuffle'
    't5.2017.10.23-caterpillar_6d87e2b2dea9d0fd01a4dab770229c1b.mat','t5.2017.10.23-caterpillar-overlap','noShuffle'
    't5.2017.10.25-words_82c2626e58be7297f50c2fe82ad705f5.mat','t5.2017.10.25-words','shuffle'
    't8.2017.10.18-words_8addfbbee389070374096973486f884a.mat','t8.2017.10.18-words','shuffle'
    };

%%
for d=4:length(datasets)

    %%
    remotePreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/'];
    remotePostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/'];
    lfadsPyDir = '/net/home/fwillett/models/lfads/';
    scriptDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' datasets{d,2} filesep];
    
    %%
    dat = load([dataDir datasets{d,1}]);
    dat.datTensor = int64(dat.datTensor/100);
    dat.datTensor = permute(dat.datTensor, [2 3 1]);

    tensorToLFADS( dat.datTensor, datasets{d,2}, remotePreDir, 10, strcmp(datasets{d,3}, 'shuffle') );
    
    %%
    %bash scripts    
    availableGPU = [0 1 2 3];

    mode = 'pairedSampleAndAverage';
    displayNum = 7;
    
    %try random values uniformly within a hyperbox of specified
    %limits
    paramFields = {'co_dim'};
    paramPossibilities = {0:4};
    runTable = lfadsGridParamSample( paramPossibilities, 3 );
    
    defaultOpts = lfadsMakeOptsSimple();
    defaultOpts.batch_size = min(128, floor(size(dat.datTensor,3)*0.2)-1);
    paramVec = lfadsMakeFullParamVec( paramFields, runTable, defaultOpts );
    datasetNames = repmat(datasets(d,2), size(runTable,1), 1);
    
    lfadsMakeBatchScripts( scriptDir, [remotePreDir datasets{d,2}], [remotePostDir datasets{d,2}], lfadsPyDir, ...
        datasetNames, paramVec, availableGPU, displayNum, mode );
    
    save([scriptDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec','datasetNames');
    
end

%%
%quickly load and check results
lfadsPostDir = '/net/home/fwillett/Data/Derived/post_LFADS/t5.2017.10.23-phonemes/';
lfadsPreDir = '/net/home/fwillett/Data/Derived/pre_LFADS/t5.2017.10.23-phonemes/';
datasetName = '2';
fileTrain = [lfadsPostDir datasetName filesep 'model_runs_h5_train_posterior_sample_and_average'];
fileValid = [lfadsPostDir datasetName filesep 'model_runs_h5_valid_posterior_sample_and_average'];
fileInput = [lfadsPreDir 't5.2017.10.23-phonemes'];

resultTrain = hdf5load(fileTrain);
resultValid = hdf5load(fileValid);
resultInput = hdf5load(fileInput);

trlIdx = 20;

figure('Position',[336   143   532   650]);
subplot(2,1,1);
imagesc(resultValid.output_dist_params(:,:,trlIdx));
subplot(2,1,2);
imagesc(resultInput.valid_data(:,:,trlIdx));
linkaxes;

%%
trlIdx = 20;

figure('Position',[336   143   532   650]);
subplot(2,1,1);
plot(resultValid.output_dist_params(:,:,trlIdx)');
subplot(2,1,2);
plot(resultInput.valid_data(:,:,trlIdx)');
linkaxes;

%%

trlIdx = 30;

figure('Position',[336   143   532   650]);
subplot(2,1,1);
imagesc(resultTrain.output_dist_params(:,:,trlIdx));
subplot(2,1,2);
imagesc(resultInput.train_data(:,:,trlIdx));
linkaxes;

