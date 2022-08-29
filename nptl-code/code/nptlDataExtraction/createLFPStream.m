function createLFPStream(participantID, datestr,blocknum)
% CREATEBROADBANDSTREAM    
% 
% createBroadbandStream(participantID, datestr,blocknum)


    streampath = ['/net/derivative/stream/' participantID '/'];
    rawpath = ['/net/experiments/' participantID '/'];
    
    
    blocks = loadvar([streampath datestr '/blocks'],'blocks');
    binds = [blocks.blockId];
    
    outDir = [streampath datestr '/lfpband/'];
    if ~isdir(outDir)
        mkdir(outDir);
    end

for nb = 1:length(blocknum)    
    
    bid = find(binds == blocknum(nb));
        
    switch participantID
      case 't6'
       
        nsf = blocks(bid).nsxFile;
        if iscell(nsf)
            nsf = nsf{1};
        end
        nfile = [rawpath datestr '/Data/' nsf];

        disp(nfile);
        broadband2streamLFP(nfile(1:end-4), blocknum(nb), ...
                            outDir);
      case {'t7','t5'}
        for narray = 1:length(blocks(bid).array)
            nfile = [rawpath datestr '/Data/' blocks(bid).array{narray} '/NSP Data/' blocks(bid).nsxFile{narray}];
            odArray = [outDir blocks(bid).array{narray} '/'];
            if ~isdir(odArray)
                mkdir(odArray);
            end
            disp(sprintf('processing block %g outputting to directory %s',blocknum(nb),odArray));
            options.cerebusTime = blocks(bid).cerebusStartTime(narray);
            options.xpcTime = blocks(bid).xpcStartTime(narray);
            options.segment = blocks(bid).nevPauseBlock(narray);
            broadband2streamLFP(nfile(1:end-4), blocknum(nb), ...
                                odArray, options);
        end
      otherwise
        error(['don''t know this participant! ' participantID]);
    end
end

