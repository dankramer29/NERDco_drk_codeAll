function thresholdData = broadband2thresholds(filePrefix, blockId, ...
                                              rmsMults, rms, filterType,convFilter)
% BROADBAND    
% 
% thresholdData = broadband2thresholds(filePrefix, blockId, rmsMults, rms, filterType)

% Thresholds data from NS5 file and aligns it to xpc start time.
% blockId specifies the xpc block ID run and rmsMult specifies the
% multiplier to use for threshold setting
%
% Threshdata.samples(1, :) are the thresh values for the first tick of the
% of the xpc block

%%% GLOBALS
READ_CEREB_SAMPLES = 120 * 30000; % Read this many samples at once
NUM_CHANNELS = 96;

FILTER_SKIP_CEREB_SAMPLES = 30*30000; % Load N seconds of data prior to 
                                       % block of interest, note RMS
                                       % calc based on READ_CEREB_SAMPLES -
                                       % FILTER_SKIP_CEREB_SAMPLES


% Open Nev to get time sync data (via serial port)
nev = openNEV([filePrefix '.nev'], 'read', 'nosave');
timeStamps = extractNevSerialTimeStamps(nev);

% Select the block of interest and check that block IDs are sequential
blockIdIdx = find(timeStamps.blockId == blockId);
assert(length(diff(blockIdIdx)) > 0, 'blockId issues');
assert(unique(diff(blockIdIdx)) == 1, 'Error in Block IDs recorded in NEV');

% Pull cerebus and xpc times from block of interest
cerebusTime = timeStamps.cerebusTime(blockIdIdx); % time in # of 30 kHz samples
xpcTime = timeStamps.xpcTime(blockIdIdx); % time in milliseconds from block start

cerebusStartTime = cerebusTime(1);
cerebusEndTime = cerebusTime(end);

if ~exist('filterType','var')
    filterType = 'spikesmedium';
end

if ~exist('convFilter','var')
    convFilter = [];
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


numCerebSamples = ceil((cerebusEndTime - max(cerebusSampleStartTime,0))/30);
for nRMS = 1:length(rmsMults)
    thresholdData(nRMS).samples = zeros(numCerebSamples, NUM_CHANNELS);
end

cerebusSampleStartIdx = max(cerebusSampleStartTime, 0);
cerebusSampleIdx = cerebusSampleStartIdx;
%h = waitbar(0);
while cerebusSampleIdx < cerebusEndTime
    % start at before cerebusStartTime to allow filter to "warm up"
    % note, the openNSx read below does not read the last sample in the range given,
    % hence to overlap in successive calls
    
    if(cerebusEndTime > cerebusSampleIdx+READ_CEREB_SAMPLES)
        ns5 = openNSx([filePrefix '.ns5'], 'read', ['t:' num2str(cerebusSampleIdx) ':' num2str(cerebusSampleIdx+READ_CEREB_SAMPLES)]);
    else
        ns5 = openNSx([filePrefix '.ns5'], 'read', ['t:' num2str(cerebusSampleIdx) ':' num2str(cerebusEndTime)]);
    end
    
    % Apply common average referencing
    ns5.Data = single(ns5.Data');
    ns5.Data = ns5.Data - mean(ns5.Data, 2) * ones(1, size(ns5.Data, 2));
    if ~isempty(filt)
        if useFiltfilt
            spikeBandData = filtfilthd(filt,ns5.Data);
        else
            % Filter for spike band
            spikeBandData = filt.filter(ns5.Data);
        end
    else
        spikeBandData = ns5.Data;
    end
    

    if ~isempty(convFilter)
        for channel = 1:NUM_CHANNELS
            tmp = conv(spikeBandData(:,channel), ...
                       convFilter, 'same');
            spikeBandData(:,channel) = tmp;
        end
    end
    
    numCerebusSamplesRead = size(spikeBandData, 1);
    
    
    if(~exist('rms', 'var') || isempty(rms))
        rms = std(spikeBandData(FILTER_SKIP_CEREB_SAMPLES:end, :));
    end

    for nRMS = 1:length(rmsMults)
        rmsMult = rmsMults(nRMS)
        for channel = 1:NUM_CHANNELS
     
            if(rmsMult > 0)
                thidx = spikeBandData(:, channel) > rmsMult*rms(channel);
            else
                thidx = spikeBandData(:, channel) < rmsMult*rms(channel);
            end
       
            %%% HACK FOR THRESHOLDING
            thidx = conv(single(thidx), ones(30, 1), 'same');
             
       
            thresholdData(nRMS).samples( ((cerebusSampleIdx-cerebusSampleStartIdx)/30) ...
                                   + uint32([1:ceil(numCerebusSamplesRead/30)]), channel) = thidx(1:30:end);
       
        end
    end
    
    cerebusSampleIdx = cerebusSampleIdx + numCerebusSamplesRead;
%    waitbar((cerebusSampleIdx-cerebusSampleStartIdx)/(cerebusEndTime - cerebusSampleStartIdx), h);
    
end

%delete(h);

% Grab data starting from the first xpc sync, add 100ms of data at the end,
% as this is the period at which this clock is written from the xpc to
% cerebus

for nRMS = 1:length(rmsMults)
    if cerebusSampleStartTime > 0 %% data starts at xpc "time 0"
        thresholdData(nRMS).samples = single(thresholdData(nRMS).samples((FILTER_SKIP_CEREB_SAMPLES/30):end, :) > 0);
        thresholdData(nRMS).txStartTimeXpc = 0;
    else %% data starts /after/ xpc "time 0"
        thresholdData(nRMS).samples = single(thresholdData(nRMS).samples > 0);
        thresholdData(nRMS).txStartTimeXpc = -(cerebusSampleStartTime+FILTER_SKIP_CEREB_SAMPLES)/30;    
    end
    thresholdData(nRMS).xpcTime = xpcTime;
    thresholdData(nRMS).cerebusTimeMS = cerebusTime/30;
    thresholdData(nRMS).thresholdValues = rmsMults(nRMS) * rms;
end
 
end

