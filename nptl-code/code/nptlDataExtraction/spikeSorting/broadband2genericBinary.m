function broadband2genericBinary(filePrefix, blockId, channels, ...
                                 outPrefix, sessionID, options)
%function broadband2genericBinary(filePrefix, blockId, channels, ...
%                             outPrefix, channelOffset)
%
% Outputs the broadband (30kHz) nsX data in a generic binary format that can be
% understood by plexon's offline spike sorter
%
%  filePrefix: cell array of .nev / .ns5 file paths
%
%  blockId: vector - the xpc block IDs
%
%  channels: which channels to export ([] for all channels). likely
%      numbers between 1-96
%
%  outPrefix: path to output the binary files and metadata (mat file)
%
%  options.channelOffset: e.g. for multiple arrays, one needs to
%      offset the channel numbers by some number (i.e. 96 if this is
%      the 2nd array). defaults to 0.
%
%  options.segments: pauseblock numbers for each nsx file
%  options.metadataPref: prefix for metadata file (e.g. for
%     specific array)
%
%
%  Chethan Pandarinath, 2013,2014,2015

dotind = strfind2(sessionID,'.',1);
participant = sessionID(1:dotind-1);
cerebusStartTimes = options.cerebusStartTimes;
cerebusEndTimes = options.cerebusEndTimes;

if ~iscell(filePrefix)
    disp(['broadband2genericBinary: warning - filePrefix should be ' ...
          'cell array']);
    filePrefix = {filePrefix};
end


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

if isfield(options,'segments')
    segments = options.segments;
else
    segments = 1;
end

if isfield(options,'channelOffset')
    channelOffset = options.channelOffset;
else
    channelOffset = 0;
end

if isfield(options,'arrayNames')
    arrayNames = options.arrayNames;
else
    arrayNames = {};
end

%% check data
if numel(filePrefix) ~= numel(segments)
    error(['broadband2genericBinary: you should be passing in an ' ...
           'equal number of nsX filenames and pauseblock segments']);
end

%%% GLOBALS
READ_CEREB_SAMPLES = 120 * 30000; % Read this many samples at once
                                  %    NUM_CHANNELS = length(channels);
CHANNELS_ON_ARRAY = 96;

FILTER_SKIP_CEREB_SAMPLES = 1*30000; % Load N seconds of data prior to 
                                     % block of interest, note RMS
                                     % calc based on READ_CEREB_SAMPLES -
                                     % FILTER_SKIP_CEREB_SAMPLES



metadata = struct;
metadata.channels = channels + channelOffset;
metadata.files = filePrefix;
metadata.segments = segments;
metadata.sections = struct;
metadata.blocks = blockId;
metadata.arrayNames = arrayNames;

if ~exist('filterType','var')
    filterType = 'spikesmedium';
end

%% outPrefix should be a directory
if ~isdir(outPrefix)
    disp(['making directory ' outPrefix]);
    mkdir(outPrefix);
end

disp(sprintf('broadband2genericBinary: outputting files to: %s', outPrefix));

%% we need filehandles for each channel
for nchannel = 1:numel(channels)
    fout = sprintf('%sch%03i.binary',outPrefix, channelOffset+ ...
                   channels(nchannel));
    fhandles(nchannel) = fopen(fout,'w');
end

% make a destination for the metadatafile
metadataOut = sprintf('%smetadata.mat',outPrefix);


for nb = 1:numel(filePrefix)

    % % Open Nev to get time sync data (via serial port)
    %nev = openNEV([filePrefix{nb} '.nev'], 'read', 'nosave');
    %timeStamps = extractNevSerialTimeStamps(nev);
    %if isempty(timeStamps) | isempty(fields(timeStamps))
    %    if exist([filePrefix{nb} '.ns3'],'file')
    %        timeStamps = extractNS3BNCTimeStamps(filePrefix{nb});
    %    else
    %        error('cant find these timestamps')
    %    end
    %end
    % % Select the block of interest and check that block IDs are
    % % sequential
    % bindx={};
    % for nset = 1:numel(timeStamps)
    %     bindx{nset} = find(timeStamps(nset).blockId == blockId(nb));
    % end
    % blockIdIdx = bindx{segments(nb)};
    % assert(length(diff(blockIdIdx)) > 0, 'blockId issues');
    % assert(unique(diff(blockIdIdx)) == 1, 'Error in Block IDs recorded in NEV');

    % % Pull cerebus and xpc times from block of interest
    % cerebusTime = timeStamps(segments(nb)).cerebusTime(blockIdIdx); % time in # of 30 kHz samples
    % xpcTime = timeStamps(segments(nb)).xpcTime(blockIdIdx); % time in milliseconds from block start

    % %% use the precomputed "blocks.mat" file for alignment
    % blocks = loadvar(sprintf(['/net/derivative/stream/%s/%s/' ...
    %                     'blocks.mat'], participant, sessionID), ...
    %                      'blocks');
    % blocks = removeBlockfilePauseblockDuplicates(blocks);
    % for nn = 1:numel(blocks)
    %     for nfiles = 1:numel(xpcStartTime)
    %     end
    % end


    cerebusStartTime = cerebusStartTimes(nb);
    cerebusEndTime = cerebusEndTimes(nb);
    
    if cerebusStartTime < FILTER_SKIP_CEREB_SAMPLES
        warning('broadband2genericBinary: not enough data to warm up filter');
    end


    % Spike Band filter (may want to change this or have it selectable via param) 
    switch lower(filterType)
      case 'spikesmedium'
        bam1 = [0.95321773445431  -1.90644870937033 0.95323097500802 1 -1.90514144409761 0.90775595733389; ...
                0.97970016700443  -1.95938672569874 0.97968655878878 1 -1.95804317832840 0.96073029104793];
        gm1 = 1;
        filt = dfilt.df2sos(bam1, gm1);
        
        % filt = spikesMediumFilter();
      case 'spikeswide'
        filt = spikesWideFilter();
      case 'spikesnarrow'
        filt = spikesNarrowFilter();
      case 'none'
        filt =[];
    end
    %filt = spikesMediumFilter();
    filt.PersistentMemory = true; % allow successive filtering


    % Collect enough data before timepoints of interest to warm up filter
    cerebusSampleStartTime = cerebusStartTime - FILTER_SKIP_CEREB_SAMPLES;
    
    numCerebSamples = ceil((cerebusEndTime - max(cerebusSampleStartTime,0))/30);
    cerebusSampleStartIdx = max(cerebusSampleStartTime, 0);
    cerebusSampleIdx = cerebusSampleStartIdx;
    while cerebusSampleIdx < cerebusEndTime
        % start at before cerebusStartTime to allow filter to "warm up"
        % note, the openNSx read below does not read the last sample in the range given,
        % hence to overlap in successive calls

        endpt = min(cerebusSampleIdx+ READ_CEREB_SAMPLES,cerebusEndTime);
        if ~exist('segments','var')
            ns5 = openNSx([filePrefix{nb} '.ns5'], 'read', ...
                          ['t:' num2str(cerebusSampleIdx) ':' num2str(endpt)]);
            data = single(ns5.Data');
        else
            ns5 = readSegmentedNS5([filePrefix{nb} '.ns5'], segments(nb), 1:CHANNELS_ON_ARRAY, ...
                                   cerebusSampleIdx,endpt);
            data = single(ns5.Data{segments(nb)}');
        end

        % Apply common average referencing
        data = data(:,channels) - mean(data, 2) * ones(1, numel(channels));
        
        if ~isempty(filt)
            % Filter for spike band
            spikeBandData = filt.filter(data);
            %spikeBandData = FiltFiltM(bam1,gm1,data);
            %spikeBandData = filtfilt(bam1,gm1,double(data));
        else
            spikeBandData = data;
        end

        numCerebusSamplesRead = size(spikeBandData, 1);
        
        for nchannel = 1:length(channels)
            fwrite(fhandles(nchannel),int16(spikeBandData(:,nchannel)),'int16');
        end
        

        cerebusSampleIdx = cerebusSampleIdx + numCerebusSamplesRead;
        
    end
    actualCerebusEndpoint = endpt;
    actualCerebusStartpoint = cerebusSampleStartIdx;
    metadata.sections(nb).cerebusTimes = [actualCerebusStartpoint actualCerebusEndpoint];

end


% close all filehandles
for nchannel = 1:length(channels)
    fclose(fhandles(nchannel));
end
%save metadata
save(metadataOut,'metadata');

