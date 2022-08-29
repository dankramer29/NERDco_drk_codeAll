function spikeband = broadband2streamMinMax(filePrefix, blockId, ...
                                                outPrefix,options)
    % BROADBAND2STREAMMINMAX
    % 
    % spikeband = broadband2streamMinMax(filePrefix, blockId, outPrefix,options)

    %
    % outputs to a structure comparable to the continuous stream data structure
    % output format:
    %    
    %    spikeband.clock [1 x T]         :   clock times
    %    spikeband.minSpikeBand [96 x T] :   ms-binned min spikeband values for each channel
    %    spikeband.minSpikeInd [96 x T]  :   index of above
    %    spikeband.meanSquared           :   outputs MS value for a single channel, channel ID rotates ever 100 ms
    %    spikeband.meanSquaredChannel    :   channel index of above


if ~exist('options','var')
    options.foo = false;
end
if ~isstruct(options)
    error('broadband2streamMinMax: options must be a struct');
end

if isfield(options,'filterType')
    filterType = options.filterType;
end
if ~exist('filterType','var')
    filterType = 'spikesmedium';
end

if isfield(options,'segment')
    segment = options.segment;
end

    %%% GLOBALS
    READ_CEREB_SAMPLES = 120 * 30000; % Read this many samples at once
    NUM_CHANNELS = 96;

    FILTER_SKIP_CEREB_SAMPLES = 5*30000; % Load N seconds of data prior to 
                                         % block of interest, note RMS
                                         % calc based on READ_CEREB_SAMPLES -
                                         % FILTER_SKIP_CEREB_SAMPLES


    if ~isfield(options,'cerebusTime') | ~isfield(options,'xpcTime')
        % Open Nev to get time sync data (via serial port)
        nev = openNEV([filePrefix '.nev'], 'read', 'nosave');
        timeStamps = extractNevSerialTimeStamps(nev);
        if isempty(timeStamps) | isempty(fields(timeStamps))
            if exist([filePrefix '.ns3'],'file')
                timeStamps = extractNS3BNCTimeStamps(filePrefix);
            else
                error('cant find these timestamps')
            end
        end

        % Select the block of interest and check that block IDs are sequential
        blockIdIdx = find(timeStamps.blockId == blockId);
        assert(length(diff(blockIdIdx)) > 0, 'blockId issues');
        if any(diff(blockIdIdx) ~= 1)
            numSkipped = length(find(diff(blockIdIdx)~=1));
            warning(sprintf('Error in Block IDs recorded in NEV - blockId is not contiguous. %g skips', numSkipped));
        end

        % Pull cerebus and xpc times from block of interest
        cerebusTime = timeStamps.cerebusTime(blockIdIdx); % time in # of 30 kHz samples
        xpcTime = timeStamps.xpcTime(blockIdIdx); % time in milliseconds from block start
        cerebusStartTime = cerebusTime(1);
        cerebusEndTime = cerebusTime(end);
    else
        cerebusTime = options.cerebusTime;
        cerebusStartTime = cerebusTime(1);
        xpcTime = options.xpcTime;
        tmp = openNSx([filePrefix '.ns5']);
        cerebusEndTime = tmp.MetaTags.DataPoints(segment);
        clear tmp;
    end




    %assert(cerebusStartTime > (FILTER_SKIP_CEREB_SAMPLES + (xpcTime(1)*30) ), 'XPC task started too soon after cerebus recording, not enough data to warm up filter');
    if cerebusStartTime < (FILTER_SKIP_CEREB_SAMPLES + (xpcTime(1)*30) )
        warning('XPC task started too soon after cerebus recording, not enough data to warm up filter');
    end

    useFiltfilt = false;

    % Spike Band filter (may want to change this or have it selectable via param) 
    switch lower(filterType)
      case 'spikesmedium'
        filt = spikesMediumFilter();
      case 'spikeswide'
        filt = spikesWideFilter();
      case 'spikesnarrow'
        filt = spikesNarrowFilter();
      case 'spikesmediumfiltfilt'
        filt = spikesMediumFilter();
        useFiltfilt = true;
      case 'none'
        filt =[];
    end
    filt = spikesMediumFilter();
    filt.PersistentMemory = true; % allow successive filtering


    % Collect enough data to warm up filter and also make sure to offset by the
    % first xpcTime
    cerebusSampleStartTime = cerebusStartTime - FILTER_SKIP_CEREB_SAMPLES - (xpcTime(1)*30);
    if cerebusSampleStartTime < 0
        if FILTER_SKIP_CEREB_SAMPLES <=0
            disp('data will start after xpc clock')
        end
    end

    %% create an offset which, when added to the cerebusSampleIdx, gives the xpcIdx
    xpcOffset30k = xpcTime(1)*30 - cerebusTime(1);
    %% so to get xpc time from cerebus time, add xpcOffset30k and divide by 30


    numCerebSamples = ceil((cerebusEndTime - max(cerebusSampleStartTime,0))/30);

    cerebusSampleStartIdx = max(cerebusSampleStartTime, 0);
    cerebusSampleIdx = cerebusSampleStartIdx;
    %h = waitbar(0);

    channelRmsInd = 0;
    prevMsVals = zeros(100,NUM_CHANNELS,'single');

    while cerebusSampleIdx < cerebusEndTime
        % note, the openNSx read below does not read the last sample in the range given,
        % hence the overlap in successive calls


        endpt = min(cerebusSampleIdx+ READ_CEREB_SAMPLES,cerebusEndTime);
        if ~exist('segment','var')
            ns5 = openNSx([filePrefix '.ns5'], 'read', ...
                          ['t:' num2str(cerebusSampleIdx) ':' num2str(endpt)]);
            data = single(ns5.Data');
        else
            ns5 = readSegmentedNS5([filePrefix '.ns5'],segment, 1:NUM_CHANNELS, cerebusSampleIdx,endpt);
            data = single(ns5.Data{segment}');
        end
        % Apply common average referencing
        data = data - repmat(mean(data, 2),1,size(data,2));
        if ~isempty(filt)
            if useFiltfilt
                spikeBandData = filtfilthd(filt,data);
            else
                % Filter for spike band
                spikeBandData = filt.filter(data);
            end
        else
            spikeBandData = data;
        end
        numCerebusSamplesRead = size(spikeBandData, 1);

        SBtoKeep = 30*floor(numCerebusSamplesRead/30);
        mins = zeros(floor(size(spikeBandData)./ [30 1]),'single');
        minInd = zeros(floor(size(spikeBandData)./ [30 1]),'uint8');
        movAvgMs = zeros(floor(size(spikeBandData)./ [30 1]),'single');

        for nc = 1:size(spikeBandData,2)
            % get the spikeband min values and min indices
            cbroadband = reshape(spikeBandData(1:SBtoKeep,nc),30,[]);
            [channelMinVals channelMinInds] = min(cbroadband);
            mins(:,nc) = channelMinVals;
            minInd(:,nc) = uint8(channelMinInds);
            
            % get the mean-squared values
            localMs = mean(cbroadband.^2);
            latestMs = [prevMsVals(:,nc)' localMs];
            channelMovAvgMS=tsmovavg(latestMs,'s',100);
            movAvgMs(:,nc) = channelMovAvgMS(101:end);
            prevMsVals(:,nc) = localMs(end-99:end);
        end

        xpcSampleIdx = floor((cerebusSampleIdx+xpcOffset30k)/30);
        xpcInds = xpcSampleIdx+(0:size(mins,1)-1);
        
        if ~exist('xpcStartInd','var')
            xpcStartInd = min(xpcInds(xpcInds>0));
        end
        
        spikeband.clock(xpcInds(xpcInds>0)-xpcStartInd+1,1) = xpcInds(xpcInds>0);
        spikeband.minSpikeBand(xpcInds(xpcInds>0)-xpcStartInd+1,:) = mins(xpcInds>0,:);
        spikeband.minSpikeBandInd(xpcInds(xpcInds>0)-xpcStartInd+1,:) = minInd(xpcInds>0,:);
        % get the RMS values
        for t = 1:size(movAvgMs,1)
            channelRmsInd = channelRmsInd+1;
            if channelRmsInd > NUM_CHANNELS, channelRmsInd = 1; end
            meanSquared(t) = movAvgMs(t,channelRmsInd);
            meanSquaredChannel(t) = uint8(channelRmsInd);
        end
        spikeband.meanSquared(xpcInds(xpcInds>0)-xpcStartInd+1,1) = meanSquared(xpcInds>0);
        spikeband.meanSquaredChannel(xpcInds(xpcInds>0)-xpcStartInd+1,1) = meanSquaredChannel(xpcInds>0);
        

        cerebusSampleIdx = cerebusSampleIdx + numCerebusSamplesRead;
        %    waitbar((cerebusSampleIdx-cerebusSampleStartIdx)/(cerebusEndTime - cerebusSampleStartIdx), h);
        
    end

    outFile = [outPrefix num2str(blockId)];
    save(outFile,'spikeband', '-v6'); 
    system( sprintf('chmod g+w %s', [outFile '.mat'] ) ); % Fix permissions so others can modify SDS 2 November 2016
