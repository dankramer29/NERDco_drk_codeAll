function [R sorted]=combineSortedWithRs(sessionID, blockNum, R, broadbandDir, sortedDir, options)

% function R=combineSortedWithRs(sessionID, blockNum, R, broadbandDir, sortedDir, options)
%
%   loads sorted data (given metadata (from
%      broadband2genericBinary) and .nex file (from OFS))
%
%
%  Chethan Pandarinath, 2015
%
%
% options.blocksFile - pointer to file containing the ns5 / xpc
%   timing relationship. defaults to:
%   /net/derivative/stream/[participant]/[session]/blocks.mat
% options.streamFormat - true if you're sending in stream.neural rather
%   than Rstruct (defaults to false)

METADATA_FN = 'metadata.mat';

options.foo = false;
dotind = strfind2(sessionID,'.',1);
participant = sessionID(1:dotind-1);

if isfield(options,'blocksFile')
    blocksFile = options.blocksFile;
else
    blocksFile = sprintf('/net/derivative/stream/%s/%s/blocks.mat', ...
                         participant, sessionID);
end
if ~isfield(options,'streamFormat')
    options.streamFormat = false;
end

%% we need to know how to sync xpcTime and cerebusTime for
%% this block
blocks=loadvar(blocksFile,'blocks');
blocks = removeBlockfilePauseblockDuplicates(blocks);

thisb = blocks([blocks.blockId]==blockNum);
if isempty(thisb)
    error(sprintf('combineSortedWithRs: couldn''t find block %i in blocksFile %s', ...
                  blockNum, blocksFile));
end
    

%% open the sorted dir, find the metadata files
targets = dir(broadbandDir);
excludes = {'.','..'};
targets = targets([targets.isdir]);

[~, keeps] = setdiff({targets.name},excludes);
targets = targets(keeps);

metadatas = {};
%% search all the target dirs for metadata files
%% pull out the relevant info from the metadata files
for nd = 1:numel(targets)
    fn = fullfile(broadbandDir, targets(nd).name, METADATA_FN);
    if exist(fn)
        m = loadvar(fn,'metadata');
        blockInd = find(m.blocks==blockNum);
        if ~isempty(blockInd)
            if numel(unique(m.arrayNames)) > 1, error(['combineSortedWithR: ' ...
                                    'multiple array names here...']); ...
                    end
            if numel(thisb.xpcStartTime) > 1
                arrayInd = find(strcmp(thisb.array,m.arrayNames{1}));
            else
                arrayInd = 1;
            end

            %% store the relevant metadata parameters for use when
            %% processing the data later
            m1.channels = m.channels;
            m1.subPath = targets(nd).name;
            m1.xpcstart = thisb.xpcStartTime(arrayInd);
            m1.cerebusStart = thisb.cerebusStartTime(arrayInd);

            % continuous data may start earlier than necessary due
            % to e.g. filter warmup
            continuousOffset = m1.cerebusStart - m.sections(blockInd).cerebusTimes(1);
            if blockInd == 1
                m1.continuousStart = 0;
            else
                earlierBlockTimes = arrayfun(@(x) diff(x.cerebusTimes), ...
                                             m.sections(1:blockInd-1));
                m1.continuousStart = sum(earlierBlockTimes);
            end
            m1.continuousStart = m1.continuousStart + continuousOffset;

            m1.continuousEnd = diff(m.sections(blockInd).cerebusTimes) ...
                + m1.continuousStart;
            metadatas{end+1} = m1;
        end
    end
end

labels = {};
timestamps = {};
waveforms = {};
%% load all the discrete (spike time) data for all channels
%% pull the spike timestamps out
%% timestamps will be in relative to the first xpc/cerebus sync'd time
for nm = 1:numel(metadatas)
    metaTimestamps{nm} = {};
    for nc = 1:numel(metadatas{nm}.channels)
        fn = fullfile(sortedDir, metadatas{nm}.subPath, sprintf('ch%03i.nex',...
                      metadatas{nm}.channels(nc)));
        if ~exist(fn, 'file')
            %            disp(sprintf('skipping %s', fn));
            continue;
        end
        x=readNexFile(fn);
        %% save the timestamps and waveforms
        for nn = 1:numel(x.neurons)
            label = sprintf('%03i%s',metadatas{nm}.channels(nc), ...
                            x.neurons{nn}.name(end));
            %% skip "unsorted" data
            if label(end) == 'U'
                continue;
            end
            labels{end+1} = label;
            allT = x.neurons{nn}.timestamps*30000;
            keepInds = (allT>=metadatas{nm}.continuousStart ...
                        & allT <metadatas{nm}.continuousEnd);
            %% time 0 in the continuous units is equal to xpcstart time
            timestamps{end+1} = allT(keepInds) - ...
                metadatas{nm}.continuousStart + metadatas{nm}.xpcstart*30;
            metaTimestamps{nm}{end+1} = timestamps{end};
            if isfield(x,'waves'),
                waveforms{end+1} = x.waves{nn}.waveforms(:, ...
                                                         keepInds);
            end
        end
    end
end

numChannels = numel(timestamps);

for nt = 1:numel(R)
    trialxpcstart = R(nt).clock(1);
    trialxpcend = R(nt).clock(end);
    spikeraster = zeros(numChannels,numel(R(nt).clock));
    chnum = 0;
    for nm = 1:numel(metadatas)
        trialCerebusStart = double(trialxpcstart - ...
                                   metadatas{nm}.xpcstart)*30;
        trialCerebusEnd = double(trialxpcend - ...
                                 metadatas{nm}.xpcstart)*30;
        for nch = 1:numel(metaTimestamps{nm})
            ts = metaTimestamps{nm}{nch};
            timestampsCB = ts(ts>=trialCerebusStart & ts< ...
                            trialCerebusEnd)-trialCerebusStart;
            timestampsMS = floor(timestampsCB/30)+1;

            chnum = chnum+1;
            spikeraster(chnum,timestampsMS) = 1;
        end
    end
    if options.streamFormat
        spikeraster = spikeraster';
    end
    R(nt).spikeraster = sparse(spikeraster);
end    

% output the sorting info
sorted.labels = labels;
sorted.timestamps = timestamps;
sorted.waveforms = waveforms;

    
