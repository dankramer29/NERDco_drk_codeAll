function RToLFADS_v2( in )
    %convert an R struct into an LFADS-ready format
    %save hdf5 and .mat file
    %save .sh script for training model and doing inference
    %use default parameters for now
    
    nTrl = length(in.R);
    nUnits = size(in.R(1).spikeRaster,1);
    
    nBins = floor((in.timeWindow(2)-in.timeWindow(1))/in.binSize);
    nMS = in.timeWindow(2)-in.timeWindow(1);
    
    shuffIdx = randperm(nTrl);
    trainPct = 0.8;
    cutoffIdx = round(trainPct*nTrl);
    trainIdx = shuffIdx(1:cutoffIdx);
    validIdx = shuffIdx((cutoffIdx+1):end);
    
    all_data = zeros(nUnits, nBins, nTrl);
    for x=1:nTrl
        fullRaster = in.R(x).spikeRaster;
        if size(in.R(x).spikeRaster,2)<nMS
            nextRaster = in.R(x+1).spikeRaster;
            fullRaster = [fullRaster, nextRaster];
        end
        
        binCounts = zeros(nBins, nUnits);
        binIdx = 1:in.binSize;
        for t=1:nBins
            binCounts(t,:) = sum(fullRaster(:,binIdx),2);
            binIdx = binIdx+in.binSize;
        end
        
        all_data(:,:,x) = binCounts';
    end
    
    includeChans = setdiff(1:nUnits, in.excludeChans);
    all_data(in.excludeChans,:,:) = [];
    train_data = all_data(:,:,trainIdx);
    valid_data = all_data(:,:,validIdx);
    
    %%
    %file save
    mkdir([in.outputDir in.datasetName]);
    h5create([in.outputDir in.datasetName filesep in.datasetName '.h5'],'/train_data',size(train_data),'Datatype','int64');
    h5create([in.outputDir in.datasetName filesep in.datasetName '.h5'],'/valid_data',size(valid_data),'Datatype','int64');
    h5create([in.outputDir in.datasetName filesep in.datasetName '.h5'],'/train_percentage',1);
    h5create([in.outputDir in.datasetName filesep in.datasetName '.h5'],'/dt',1);
    
    h5write([in.outputDir in.datasetName filesep in.datasetName '.h5'],'/train_data',int64(train_data));
    h5write([in.outputDir in.datasetName filesep in.datasetName '.h5'],'/valid_data',int64(valid_data));
    h5write([in.outputDir in.datasetName filesep in.datasetName '.h5'],'/train_percentage',0.8);
    h5write([in.outputDir in.datasetName filesep in.datasetName '.h5'],'/dt',in.binSize/1000);
    
    h5disp([in.outputDir in.datasetName filesep in.datasetName '.h5']);
    
    excludeChans = in.excludeChans;
    save([in.outputDir in.datasetName filesep 'matlabDataset.mat'],'all_data','excludeChans','includeChans','trainIdx','validIdx');
    
end

