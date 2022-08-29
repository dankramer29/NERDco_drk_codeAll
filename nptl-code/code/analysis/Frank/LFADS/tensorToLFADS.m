function tensorToLFADS( inTensor, datasetName, outputDir, binSize, doShuff )

    nTrl = size(inTensor,3);
    
    if doShuff
        shuffIdx = randperm(nTrl);
    else
        shuffIdx = 1:nTrl;
    end
    trainPct = 0.8;
    cutoffIdx = round(trainPct*nTrl);
    trainIdx = shuffIdx(1:cutoffIdx);
    validIdx = shuffIdx((cutoffIdx+1):end);
    
    all_data = inTensor;
    train_data = inTensor(:,:,trainIdx);
    valid_data = inTensor(:,:,validIdx);
    
    %%
    %file save
    mkdir([outputDir datasetName]);
    h5create([outputDir datasetName filesep datasetName '.h5'],'/train_data',size(train_data),'Datatype','int64');
    h5create([outputDir datasetName filesep datasetName '.h5'],'/valid_data',size(valid_data),'Datatype','int64');
    h5create([outputDir datasetName filesep datasetName '.h5'],'/train_percentage',1);
    h5create([outputDir datasetName filesep datasetName '.h5'],'/dt',1);
    
    h5write([outputDir datasetName filesep datasetName '.h5'],'/train_data',int64(train_data));
    h5write([outputDir datasetName filesep datasetName '.h5'],'/valid_data',int64(valid_data));
    h5write([outputDir datasetName filesep datasetName '.h5'],'/train_percentage',trainPct);
    h5write([outputDir datasetName filesep datasetName '.h5'],'/dt',binSize/1000);
    
    h5disp([outputDir datasetName filesep datasetName '.h5']);
    
    save([outputDir datasetName filesep 'matlabDataset.mat'],'all_data','trainIdx','validIdx');
    
end

