function [ R, model ] = getSTanfordBG_RStruct( sessionPath, blockNums, model, rmsThresh )

    %load all blocks
    paths = getFRWPaths();
    addpath(genpath([paths.codePath '/code/analysis/Frank']));
    addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

    currentPath = pwd;
    cd(sessionPath);
        
    flDir = [sessionPath 'Data' filesep 'FileLogger' filesep];
    R = [];
    for b=1:length(blockNums)
        disp(b);
        stream = parseDataDirectoryBlock([flDir num2str(blockNums(b)) '/'], blockNums(b));
        tmp = onlineR(stream);
        for t=1:length(tmp)
            tmp(t).blockNum = blockNums(b);
        end
        
        R = [R, tmp];
    end
    
    %make spike raster by applying thresholds
    if nargin<3
        model = [];
    end
    if nargin<4
        rmsThresh = [];
    end
    if ~isempty(model)
        nChans = size(R(1).minAcausSpikeBand,1);
        for t=1:length(R)
            R(t).spikeRaster = bsxfun(@lt, R(t).minAcausSpikeBand(1:96,:), model.thresholds(1:96)');
            if nChans>96
                R(t).spikeRaster2 = bsxfun(@lt, R(t).minAcausSpikeBand(97:end,:), model.thresholds(97:end)');
            end
        end
    else
        rms = channelRMS(R);
        if ~isempty(rmsThresh)
            thresh = -abs(rmsThresh)*rms;
        else
            thresh = -4.5*rms;
        end
        
        nChans = size(R(1).minAcausSpikeBand,1);
        for t=1:length(R)
            R(t).spikeRaster = bsxfun(@lt, R(t).minAcausSpikeBand(1:96,:), thresh(1:96)');
            if nChans>96
                R(t).spikeRaster2 = bsxfun(@lt, R(t).minAcausSpikeBand(97:end,:), thresh(97:end)');
            end
        end
    end
    
    cd(currentPath);
end

