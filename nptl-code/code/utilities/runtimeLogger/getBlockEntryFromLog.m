function bout = getBlockEntryFromLog(blockNum)

l = loadRuntimeLog();

try
    if ~isfield(l,'blocks')
        bout = [];
        return
    end
    
    bout = l.blocks([l.blocks.blockNum] == blockNum);
catch
    warning(sprintf('getBlockEntryFromLog: couldn''t. %s', lasterr));
end