function logBlockData(bnum)

global modelConstants;

try
    blockStopTime = now();
    b=getBlockEntryFromLog(bnum);
    if isempty(b)
        warning('couldn''t find info about that last block in the log...');
        b=struct();
        b.blockNum = bnum;
    end
    b.systemStopTime = blockStopTime;
    
    dirname = [modelConstants.sessionRoot modelConstants.filelogging.outputDirectory num2str(bnum)];
    stream = parseDataDirectoryBlock(dirname, {'meanTracking','neural'});
    b.taskName = stream.taskDetails.taskName;
    b.runtimeMS = calculateBlockRuntime(stream);
    if isempty(stream.decoderD)
        b.filter = []; b.discreteFilter = [];
    else
        b.filter = char(stream.decoderD.filterName(end,stream.decoderD.filterName(end,:)>0));
        b.discreteFilter = char(stream.decoderD.discreteFilterName(end,stream.decoderD.discreteFilterName(end,:)>0));
    end
    b.biasEstimate = getFinalBiasEstimate(stream);
    updateBlockEntryInLog(bnum,b);
catch
    errstr = lasterror();
    warning('logBlockData: couldn''t log data about that block: %s', errstr.message);
end

end