function binnedCubeToLFADS( outputDir, datasetName, all_data, trainPct, binMS  )

    nTrl = size(all_data,3);
    shuffIdx = randperm(nTrl);
    
    cutoffIdx = round(trainPct*nTrl);
    trainIdx = shuffIdx(1:cutoffIdx);
    validIdx = shuffIdx((cutoffIdx+1):end);
    
    train_data = all_data(:,:,trainIdx);
    valid_data = all_data(:,:,validIdx);
    
    mkdir(outputDir);
    if exist([outputDir filesep datasetName '.h5'],'file')
        delete([outputDir filesep datasetName '.h5']);
    end
    
    h5create([outputDir filesep datasetName '.h5'],'/train_data',size(train_data),'Datatype','int64');
    h5create([outputDir filesep datasetName '.h5'],'/valid_data',size(valid_data),'Datatype','int64');
    h5create([outputDir filesep datasetName '.h5'],'/train_percentage',1);
    h5create([outputDir filesep datasetName '.h5'],'/dt',1);
    
    h5write([outputDir filesep datasetName '.h5'],'/train_data',int64(train_data));
    h5write([outputDir filesep datasetName '.h5'],'/valid_data',int64(valid_data));
    h5write([outputDir filesep datasetName '.h5'],'/train_percentage',0.8);
    h5write([outputDir filesep datasetName '.h5'],'/dt',binMS/1000);
    
    %h5disp([outputDir datasetName filesep datasetName '.h5']);
    
    save([outputDir filesep 'mat_' datasetName '.mat'],'all_data','trainIdx','validIdx');
end

