function streams=loadAllStreams(sessionPath, blocksToFit)
    %% load all the streams
    global modelConstants
    for nb = 1:length(blocksToFit)
        blockNum = blocksToFit(nb);
        flDir = [sessionPath modelConstants.dataDir 'FileLogger/'];
        streams{nb} = loadStream([flDir num2str(blockNum) '/'], blockNum);
    end
end
