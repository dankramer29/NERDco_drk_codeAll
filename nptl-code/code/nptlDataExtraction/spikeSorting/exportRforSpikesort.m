function exportRforSpikesort(sessionID, blockNums, outputDir, options)

% function exportRstruct(sessionID, blockNum, outputDir, options)
%
%   calls broadband2genericBinary in order to extract broadband
%   data for spike sorting
%
%   sessionID: e.g. t6.2013.01.01
%
%   blockNum: duh
%
%   outputDir: directory to output the generic binary formatted
%      data files (outputs 1 per channel)
%
% options:
%   blocksFilePath: base path of "stream" processed data
%          (e.g. "/net/derivative/stream/[participant]/[sessionID]/")
%      defaults to the above, extracting participant from sessionID.
%      all it needs from this directory is the "blocks.mat" file
%      which points to the appropriate nsx files
%
%   rawPath: base path of experimental data
%          (e.g. "/net/experiments/[participant]/[sessionID]/")
%      defaults to the above, extracting participant from
%      sessionID.
%      uses this as the prefix for loading nev/nsX files
%
%   channels: which channels to export. defaults to all channels in
%      the nsx file
%
%  Chethan Pandarinath, 2013,2014,2015

    
    dotind = strfind2(sessionID,'.',1);
    participant = sessionID(1:dotind-1);

    options= setDefault(options,'blocksFilePath',...
                                sprintf(['/net/derivative/stream/' ...
                        '%s/%s/'],participant, sessionID));
    options = setDefault(options,'rawPath',sprintf(['/net/' ...
                        'experiments/%s/%s/'], participant, ...
                                                   sessionID));
    options = setDefault(options,'channels',[]);
    channels = options.channels;
    blocks = loadvar([options.blocksFilePath 'blocks.mat'], ...
                     'blocks');
    arrayNames = {};
    cerebusStartTimes = [];
    cerebusEndTimes = [];

    blocks = removeBlockfilePauseblockDuplicates(blocks);
    %% get all the indices for the relevant blocks
    for nb = 1:numel(blockNums)
        binds = [blocks.blockId];
        bind(nb) = find(binds == blockNums(nb));
    end

    %% for each block, store down the nsx file and pauseblock info
    for nb = 1:numel(bind)
        % support multiple arrays
        thisBlock=blocks(bind(nb));
        if iscell(thisBlock.nsxFile)
            for narray = 1:numel(thisBlock.nsxFile)
                if narray == 3
                    disp('?!?!?!');
                    keyboard
                end
                nf = thisBlock.nsxFile{narray}(1:end-4);

                if numel(thisBlock.nsxFile) > 1
                    prefstring = sprintf('%s/NSP Data/', ...
                                         thisBlock.array{narray});
                else
                    prefstring = '';
                end
                nfiles{narray,nb} = sprintf('%sData/%s%s',options.rawPath,...
                                           prefstring, nf);
                segments(narray,nb) = ...
                    thisBlock.nevPauseBlock(narray);
                arrayNames{narray, nb} = thisBlock.array{narray};
                if isempty(thisBlock.array{narray})
                    arrayNames{narray,nb} = sprintf('array%02i', ...
                                                    narray);
                end
                cerebusStartTimes(narray,nb) = thisBlock.cerebusStartTime(narray);
                cerebusEndTimes(narray,nb) = thisBlock.cerebusEndTime(narray);
            end
        else
            nf=thisBlock.nsxFile(1:end-4);
            nfiles{1,nb} = [options.rawPath 'Data/' nf];
            segments(1,nb) = 1;
            if isfield(thisBlock,'array')
                arrayNames{1, nb} = array{1};
            else
                arrayNames{1, nb} = 'array01';
            end
                cerebusStartTimes(narray,nb) = thisBlock.cerebusStartTime(1);
                cerebusEndTimes(narray,nb) = thisBlock.cerebusEndTime(1);
        end
    end

    %% multiple arrays - need to index the channels properly        
    if size(nfiles,1)>1
        %% if certain channels were requested, divide them across
        %% array requests
        for narray = 1:size(nfiles,1)
            arrayRange = [1 96]+96*(narray-1);
            arrayedChannels{narray} = channels(channels>= arrayRange(1) ...
                                               & channels<=arrayRange(2)) ...
                - arrayRange(1) + 1;
        end
    else
        arrayedChannels{1} = channels;
    end

    for narray = 1:size(nfiles,1)
        if ~isempty(setdiff(arrayNames{narray,1}, ...
                            arrayNames(narray,:)))
            disp(['exportRforSpikesort: looks like some arrays are ' ...
                  'getting mixed together here...?']);
            keyboard
        end
        outputDir1 = sprintf('%s%s/',outputDir,arrayNames{narray,1});

        % in case no channels requested from this array, skip this array
        if ~isempty(channels) && isempty(arrayedChannels{narray}), ...
                continue; end;
        options = struct;
        options.arrayNames =arrayNames(narray,:);
        options.channelOffset = 96*(narray-1);
        options.segments = segments(narray,:);
        options.cerebusStartTimes = cerebusStartTimes(narray,:);
        options.cerebusEndTimes = cerebusEndTimes(narray,:);

keyboard

        broadband2genericBinary(nfiles(narray,:), blockNums, ...
                                arrayedChannels{narray}, outputDir1, ...
                                sessionID, options);
    end
