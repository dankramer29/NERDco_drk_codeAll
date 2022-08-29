paths = getFRWPaths();
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

badChannels = [     2    46    66    67    68    69    73    76    77    78    82    83    85    86    94    95    96];
dataDir = [paths.dataPath filesep 'BG Datasets' filesep];
datasets = {
    't5.2017.09.20',[5 6 9 10 11 12], badChannels
    };

%%
for d=1:length(datasets)
    %%
    sessionPath = [dataDir datasets{d,1} filesep];
    flDir = [sessionPath 'Data' filesep 'FileLogger' filesep];
    cd(sessionPath);
    
    %load all blocks
    global modelConstants;
    if isempty(modelConstants)
        modelConstants = modelDefinedConstants();
    end
        
    R = [];
    for b=1:length(datasets{d,2})
        disp(b);
        tmp = onlineR(loadStream([flDir num2str(datasets{d,2}(b)) '/'], datasets{d,2}(b)));
        R = [R, tmp];
    end
    
    %make spike raster by applying thresholds
    load([sessionPath 'Data' filesep 'Filters' filesep R(end).decoderD.filterName '.mat']);
    for t=1:length(R)
        R(t).spikeRaster = bsxfun(@lt, R(t).minAcausSpikeBand, model.thresholds');
    end
    
    %convert to LFADS format
    outputDir = '/Users/frankwillett/Data/pre_LFADS/';
    excludeChans = datasets{d,3};
    
    in.R = R;
    in.binSize = 10;
    in.timeWindow = [0 2000];
    in.excludeChans = datasets{d,3};
    in.outputDir = '/Users/frankwillett/Data/Derived/pre_LFADS/';
    in.datasetName = strrep(datasets{d,1},'.','-');

    %convert to .hd5 format, bin, split into test & train
    RToLFADS_v2( in );
    
    %%
    %bash scripts    
    remotePreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' in.datasetName];
    remotePostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' in.datasetName];
    lfadsPyDir = '/net/home/fwillett/models/lfads/';
    scriptDir = [paths.dataPath '/Derived/pre_LFADS/' in.datasetName filesep];
    
    availableGPU = [0 1 2 3 5 6 7 8];
    mode = 'pairedSampleAndAverage';
    displayNum = 7;
    
    %try random values uniformly within a hyperbox of specified
    %limits
    paramFields = {'co_dim','gen_dim','keep_prob','l2_con_scale','l2_gen_scale'};
    paramPossibilities = {0:4, [64 128 200], [0.9, 0.95, 0.98], [10, 25, 250], [10, 25, 250, 2000]};
    runTable = lfadsUniformParamSample( paramPossibilities, 8*16 );
    
    paramVec = lfadsMakeFullParamVec( paramFields, runTable );
    datasetNames = repmat({in.datasetName}, size(runTable,1), 1);
    
    lfadsMakeBatchScripts( scriptDir, remotePreDir, remotePostDir, lfadsPyDir, ...
        datasetNames, paramVec, availableGPU, displayNum, mode );
    
    save([scriptDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec','datasetNames');
    
end
