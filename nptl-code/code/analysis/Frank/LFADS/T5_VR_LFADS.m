addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/submodules/nptlDataExtraction'));

dataDir = '/Users/frankwillett/Data/t5/';
datasets = {'t5.2017.04.03',[4 5 6 11 12 13], 65:80, 0; %5D
    't5.2017.03.22',[6 7 13 16 17], [], 0; %3D
    't5.2017.04.12',[5 6 7 12 13 14], [] 1; %4D
    't5.2017.09.20',[]
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
    load([sessionPath 'Data' filesep 'Filters' filesep R(1).decoderD.filterName '.mat']);
    for t=1:length(R)
        R(t).spikeRaster = bsxfun(@lt, R(t).minAcausSpikeBand, model.thresholds');
    end
    
    %convert to LFADS format
    outputDir = '/Users/frankwillett/Data/pre_LFADS/';
    excludeChans = datasets{d,3};
    gpuNum = datasets{d,4};
    RToLFADS( R, 10, [0 2000], excludeChans, outputDir, strrep(datasets{d,1},'.','-'), gpuNum );
    
end
