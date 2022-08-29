function [ R, streams ] = getStanfordRAndStream_SF_struct( sessionPath, blockNums, rmsThresh, anchorRMSBlockNum, filtOpts )
% the R struct should not be a cell, get rid of that sh. -SF 
    %load all blocks
    paths = getFRWPaths();
    addpath(genpath([paths.codePath '/code/analysis/Frank']));
   % addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));
    addpath(genpath([paths.codePath '/code/nptlDataExtraction']));
    flDir = [sessionPath 'Data' filesep 'FileLogger' filesep];
    streams = cell(length(blockNums),1);
    R = struct(length(blockNums),1);
    for b=1:length(blockNums)
        disp(blockNums(b));
        streams{b} = parseDataDirectoryBlock([flDir num2str(blockNums(b)) '/'], blockNums(b));
        if ~isempty(filtOpts)
            for f=1:length(filtOpts.filtFields)
                [B,A] = butter(4,filtOpts.filtCutoff(f));
                streams{b}.continuous.(filtOpts.filtFields{f}) = filtfilt(B,A,double(streams{b}.continuous.(filtOpts.filtFields{f})));
                streams{b}.continuous.([filtOpts.filtFields{f} '_speed']) = matVecMag([[0, 0]; diff(streams{b}.continuous.(filtOpts.filtFields{f})(:,1:2))],2);
            end
        end

      %  try %try statements are garbage, why is this here
            R(b) = onlineR(streams{b});
      %  end
    end
        
    %threshold based on RMS computed on the anchor block data
    if isfield(streams{1}.neural,'minAcausSpikeBand')
        spikeField = 'minAcausSpikeBand';
    else
        spikeField = 'minSpikeBand';
    end
    
    anchorBlockIdx = blockNums==anchorRMSBlockNum;
    if isempty(R{anchorBlockIdx})
        rms = channelRMS(streams{anchorBlockIdx}.neural);
    else
        rms = channelRMS(R{anchorBlockIdx});
    end
    thresh = -abs(rmsThresh)*rms;
    
    for b=1:length(blockNums)
        %stream
        if ~isempty(streams{b}.neural) && isfield(streams{b}.neural,spikeField)
            nChans = size(streams{b}.neural.(spikeField),3);
            streams{b}.spikeRaster = bsxfun(@lt, squeeze(streams{b}.neural.(spikeField)(:,1,1:96)), thresh(1:96));
            if nChans>96
                streams{b}.spikeRaster2 = bsxfun(@lt, squeeze(streams{b}.neural.(spikeField)(:,1,97:end)), thresh(97:end));
            end
        else
            streams{b}.spikeRaster = bsxfun(@lt, squeeze(streams{b}.continuous.(spikeField)(:,1,1:96)), thresh(1:96));
        end

        %R
        if ~isempty(R{b})
            nChans = size(R{b}(1).(spikeField),1);
            for t=1:length(R{b})
                R{b}(t).spikeRaster = bsxfun(@lt, R{b}(t).(spikeField)(1:96,:), thresh(1:96)');
                if nChans>96
                    R{b}(t).spikeRaster2 = bsxfun(@lt, R{b}(t).(spikeField)(97:end,:), thresh(97:end)');
                end
            end
        end
    end
    
end

