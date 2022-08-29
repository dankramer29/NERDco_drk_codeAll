function spikeband = broadband2streamMinMax(filePrefix, ...
                                                outFile,options)
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
    filterType = 'spikesmediumfiltfilt';
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
    filt.PersistentMemory = true; % allow successive filtering


    ns5NoData = openNSx([filePrefix '.ns5'],'noread');
    %nev = openNEV([filePrefix '.nev']);

    if ~isfield(ns5NoData,'MetaTags')
        error('dont know how to handle this kind of nev yet...??');
    end

    cerebusStartTime = 0;
    %cerebusEndTime = nev.MetaTags.DataDuration;
    %cerebusEndTime = ns5NoData.MetaTags.DataDurationSec * ns5NoData.MetaTags.SamplingFreq;
    cerebusEndTime = ns5NoData.MetaTags.DataPoints;


    % Collect enough data to warm up filter and also make sure to offset by the
    % first xpcTime
    cerebusSampleStartTime = cerebusStartTime;
    if cerebusSampleStartTime < FILTER_SKIP_CEREB_SAMPLES
        disp('broadband2SMM: not enough time for filter to warmup...')
    end

    numCerebSamples = ceil((cerebusEndTime - max(cerebusSampleStartTime,0))/30);

    cerebusSampleStartIdx = max(cerebusSampleStartTime, 0);
    cerebusSampleIdx = cerebusSampleStartIdx;
    %h = waitbar(0);

    channelRmsInd = 0;
    prevMsVals = zeros(100,NUM_CHANNELS,'single');

    outputInd = 0;
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
        cerebusTimes = cerebusSampleIdx+(0:SBtoKeep-1);
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
        outputInds = outputInd +(1:floor(numCerebusSamplesRead/30));
        
        spikeband.cerebusTime(outputInds,1) = cerebusTimes(1:30:end);
        spikeband.minSpikeBand(outputInds,:) = mins;
        spikeband.minSpikeBandInd(outputInds,:) = minInd;
        % get the RMS values
        meanSquared = zeros(length(outputInds),1);
        meanSquaredChannel = zeros(length(outputInds),1);
        for t = 1:size(movAvgMs,1)
            channelRmsInd = channelRmsInd+1;
            if channelRmsInd > NUM_CHANNELS, channelRmsInd = 1; end
            meanSquared(t) = movAvgMs(t,channelRmsInd);
            meanSquaredChannel(t) = uint8(channelRmsInd);
        end
        spikeband.meanSquared(outputInds,1) = meanSquared;
        spikeband.meanSquaredChannel(outputInds,1) = meanSquaredChannel;
        

        cerebusSampleIdx = cerebusSampleIdx + numCerebusSamplesRead;
    end        
    save(outFile,'spikeband');
