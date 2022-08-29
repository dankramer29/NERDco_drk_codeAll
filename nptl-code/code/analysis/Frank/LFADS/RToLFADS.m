function RToLFADS( R, binSize, timeWindow, excludeChans, outputDir, datasetName, gpuNum )
    %convert an R struct into an LFADS-ready format
    %save hdf5 and .mat file
    %save .sh script for training model and doing inference
    %use default parameters for now
    
    nTrl = length(R);
    nDim = length(R(1).posTarget);
    nUnits = size(R(1).spikeRaster,1);
    targPos = horzcat(R.posTarget)';
    targList = unique(targPos, 'rows');
    
    nBins = floor((timeWindow(2)-timeWindow(1))/binSize);
    nMS = timeWindow(2)-timeWindow(1);
    
    shuffIdx = randperm(nTrl);
    trainPct = 0.8;
    cutoffIdx = round(trainPct*nTrl);
    trainIdx = shuffIdx(1:cutoffIdx);
    validIdx = shuffIdx((cutoffIdx+1):end);
    
    all_data = zeros(nUnits, nBins, nTrl);
    for x=1:nTrl
        fullRaster = R(x).spikeRaster;
        if size(R(x).spikeRaster,2)<nMS
            nextRaster = R(x+1).spikeRaster;
            fullRaster = [fullRaster, nextRaster];
        end
        
        binCounts = zeros(nBins, nUnits);
        binIdx = 1:binSize;
        for t=1:nBins
            binCounts(t,:) = sum(fullRaster(:,binIdx),2);
            binIdx = binIdx+5;
        end
        
        all_data(:,:,x) = binCounts';
    end
    
    includeChans = setdiff(1:nUnits, excludeChans);
    all_data(excludeChans,:,:) = [];
    train_data = all_data(:,:,trainIdx);
    valid_data = all_data(:,:,validIdx);
    
    %%
    %file save
    mkdir([outputDir datasetName]);
    h5create([outputDir datasetName filesep datasetName '.h5'],'/train_data',size(train_data),'Datatype','int64');
    h5create([outputDir datasetName filesep datasetName '.h5'],'/valid_data',size(valid_data),'Datatype','int64');
    h5create([outputDir datasetName filesep datasetName '.h5'],'/train_percentage',1);
    h5create([outputDir datasetName filesep datasetName '.h5'],'/dt',1);
    
    h5write([outputDir datasetName filesep datasetName '.h5'],'/train_data',int64(train_data));
    h5write([outputDir datasetName filesep datasetName '.h5'],'/valid_data',int64(valid_data));
    h5write([outputDir datasetName filesep datasetName '.h5'],'/train_percentage',0.8);
    h5write([outputDir datasetName filesep datasetName '.h5'],'/dt',binSize/1000);
    
    h5disp([outputDir datasetName filesep datasetName '.h5']);
    
    save([outputDir datasetName filesep 'matlabDataset.mat'],'all_data','excludeChans','includeChans','trainIdx','validIdx','targPos','targList');
    
    %%
    %bash script
    remotePreDir = '/net/home/fwillett/pre_LFADS/';
    remotePostDir = '/net/home/fwillett/post_LFADS/';
    lfadsPyDir = '/net/home/fwillett/models/lfads/';
    
    fid = fopen([outputDir datasetName filesep 'bashScript.sh'],'w');
    fprintf(fid,'#!/bin/bash');
    
    cudaPathLine = '\nexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64/';
    fprintf(fid, cudaPathLine);
    
    cvd = ['\nexport CUDA_VISIBLE_DEVICES=' num2str(gpuNum)];
    fprintf(fid, cvd);
    
    displayLine = ['\nexport DISPLAY=:7'];
    fprintf(fid, displayLine);
    
    runPythonLine = ['\npython ' lfadsPyDir 'run_lfads.py'];
    runPythonLine = [runPythonLine ' --kind=train'];
    runPythonLine = [runPythonLine ' --data_dir=' remotePreDir datasetName filesep];
    runPythonLine = [runPythonLine ' --data_filename=' datasetName];
    runPythonLine = [runPythonLine ' --lfads_save=' remotePostDir datasetName];
    runPythonLine = [runPythonLine ' --co_dim=0'];
    runPythonLine = [runPythonLine ' --factors_dim=20'];
    runPythonLine = [runPythonLine ' --ext_input_dim=0'];
    runPythonLine = [runPythonLine ' --controller_input_lag=1'];
    fprintf(fid, runPythonLine);
    
    runPythonLine = ['\npython ' lfadsPyDir 'run_lfads.py'];
    runPythonLine = [runPythonLine ' --kind=posterior_sample_and_average'];
    runPythonLine = [runPythonLine ' --data_dir=' remotePreDir datasetName filesep];
    runPythonLine = [runPythonLine ' --data_filename=' datasetName];
    runPythonLine = [runPythonLine ' --lfads_save=' remotePostDir datasetName];
    runPythonLine = [runPythonLine ' --co_dim=0'];
    runPythonLine = [runPythonLine ' --factors_dim=20'];
    runPythonLine = [runPythonLine ' --ext_input_dim=0'];
    runPythonLine = [runPythonLine ' --controller_input_lag=1'];
    runPythonLine = [runPythonLine ' --batch_size=1024'];
    runPythonLine = [runPythonLine ' --checkpoint_pb_load_name=checkpoint_lve'];
    fprintf(fid, runPythonLine);
    
    fclose(fid);
    
    %%
    %bash script for running on my laptop with cpu
    remotePreDir = '/Users/frankwillett/Data/pre_LFADS/';
    remotePostDir = '/Users/frankwillett/Data/post_LFADS/';
    lfadsPyDir = '/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/LFADS/lfadsFromGIT/';
    
    fid = fopen([outputDir datasetName filesep 'bashScriptLocal.sh'],'w');
    fprintf(fid,'#!/bin/bash');
    
    cudaPathLine = '\nexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64/';
    fprintf(fid, cudaPathLine);
    
    p27ActivateLine = '\nsource activate p27';
    fprintf(fid, p27ActivateLine);
    
    runPythonLine = ['\npython ' lfadsPyDir 'run_lfads.py'];
    runPythonLine = [runPythonLine ' --kind=train'];
    runPythonLine = [runPythonLine ' --data_dir=' remotePreDir datasetName filesep];
    runPythonLine = [runPythonLine ' --data_filename=' datasetName];
    runPythonLine = [runPythonLine ' --lfads_save=' remotePostDir datasetName];
    runPythonLine = [runPythonLine ' --co_dim=0'];
    runPythonLine = [runPythonLine ' --factors_dim=20'];
    runPythonLine = [runPythonLine ' --ext_input_dim=0'];
    runPythonLine = [runPythonLine ' --controller_input_lag=1'];
    runPythonLine = [runPythonLine ' --device=cpu:0'];
    fprintf(fid, runPythonLine);
    
    runPythonLine = ['\npython ' lfadsPyDir 'run_lfads.py'];
    runPythonLine = [runPythonLine ' --kind=posterior_sample_and_average'];
    runPythonLine = [runPythonLine ' --data_dir=' remotePreDir datasetName filesep];
    runPythonLine = [runPythonLine ' --data_filename=' datasetName];
    runPythonLine = [runPythonLine ' --lfads_save=' remotePostDir datasetName];
    runPythonLine = [runPythonLine ' --co_dim=0'];
    runPythonLine = [runPythonLine ' --factors_dim=20'];
    runPythonLine = [runPythonLine ' --ext_input_dim=0'];
    runPythonLine = [runPythonLine ' --controller_input_lag=1'];
    runPythonLine = [runPythonLine ' --batch_size=1024'];
    runPythonLine = [runPythonLine ' --checkpoint_pb_load_name=checkpoint_lve'];
    runPythonLine = [runPythonLine ' --device=cpu:0'];
    fprintf(fid, runPythonLine);
    
    fclose(fid);
end

