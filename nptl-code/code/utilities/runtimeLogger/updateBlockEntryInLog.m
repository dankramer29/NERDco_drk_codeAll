function bout = updateBlockEntryInLog(blockNum, block)

l = loadRuntimeLog();

try
    if ~isfield(l,'blocks')
        bout = [];
        return
    end
    
    modInd = [l.blocks.blockNum] == blockNum;
    if isempty(modInd) | modInd == 0
        modInd = numel(l.blocks)+1;
    end
    
    f = fields(block);
    for nf = 1:numel(f)
        l.blocks(modInd).(f{nf}) = block.(f{nf});
    end
    saveRuntimeLog(l);
catch
    warning('updateBlockEntryInLog: couldn''t. %s', lasterr);
end