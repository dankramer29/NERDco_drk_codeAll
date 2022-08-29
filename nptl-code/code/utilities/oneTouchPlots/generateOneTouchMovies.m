function generateOneTouchMovies(participantID,sessionID,oneTouchOutputDir)
    streamDir = '/net/derivative/stream/';
    Rdir = '/net/derivative/R/';

    blocks=loadvar([streamDir participantID '/' sessionID '/blocks'],'blocks');
    [jnk,sortOrder] = sort([blocks.blockId],'ascend');
    blocks = blocks(sortOrder);
    blocksRun = [];

    for nr = 1:length(blocks)
        blockNum = blocks(nr).blockId;
        rFile=[Rdir participantID '/' sessionID '/R_' num2str(blockNum) '.mat'];
        if ~exist(rFile,'file')
            disp(['skipping R ' num2str(blockNum)]);
            continue;
        end

        % try
            runGenerateMovie(oneTouchOutputDir,participantID,sessionID,blockNum);
            blocksRun = [blocksRun; blockNum];
        % catch
            disp(lasterr);
            disp(['skipping R ' num2str(blockNum)]);
            continue;
        % end
    end

    options.movieNums = blocksRun;
    updateOneTouchDB(oneTouchOutputDir, participantID, sessionID, options)
