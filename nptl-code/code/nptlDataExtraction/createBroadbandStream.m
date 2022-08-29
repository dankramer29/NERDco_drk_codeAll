function createBroadbandStream(participantID, datestr,blocknum)
% CREATEBROADBANDSTREAM    
% 
% createBroadbandStream(participantID, datestr,blocknum)

    streampath = ['/net/derivative/stream/' participantID '/'];
    rawpath = ['/net/experiments/' participantID '/'];
    
    
    blocks = loadvar([streampath datestr '/blocks'],'blocks');
    binds = [blocks.blockId];
    
    outDir = [streampath datestr '/spikeband/'];
    if ~isdir(outDir)
        mkdir(outDir);
    end


for nb = 1:length(blocknum)
    
    bid = find(binds == blocknum(nb));

    switch participantID
      case 't6'

        nsf = blocks(bid).nsxFile;
        if iscell(nsf)
            if numel(nsf) > 1
                fprintf('createBroadbandStream: warning - this block has multiple associated nsx files...?\n');
                %% choose whichever file has more xpc times
                blockLengths = diff(blocks(bid).cerebusTimes);
                [~, indToKeep] = max(blockLengths);
                nsf = nsf{indToKeep};
            else
                nsf = nsf{1};
            end
        end
        nfile = [rawpath datestr '/Data/' nsf];
        disp(nfile);
        disp(sprintf(['processing block %g outputting to directory ' ...
        '%s\n'],blocknum(nb),outDir));

        broadband2streamMinMax(nfile(1:end-4), blocknum(nb), ...
                               outDir, struct('filterType','spikesmediumfiltfilt'));
      case {'t7','t5'}
        for narray = 1:length(blocks(bid).array)
            nfile = [rawpath datestr '/Data/' blocks(bid).array{narray} '/NSP Data/' blocks(bid).nsxFile{narray}];
            odArray = [outDir blocks(bid).array{narray} '/'];
            if ~isdir(odArray)
                mkdir(odArray);
            end
            disp(sprintf('processing block %g outputting to directory %s',blocknum(nb),odArray));
            options.filterType = 'spikesmediumfiltfilt';
            options.cerebusTime = blocks(bid).cerebusStartTime(narray);
            options.xpcTime = blocks(bid).xpcStartTime(narray);
            options.segment = blocks(bid).nevPauseBlock(narray);
            broadband2streamMinMax(nfile(1:end-4), blocknum(nb), ...
                               odArray, options);
        end
      otherwise
        error(['don''t know this participant! ' participantID]);
    end

end