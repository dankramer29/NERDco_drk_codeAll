function addBlockToLog(block)

l = loadRuntimeLog();

try
    if ~isfield(l,'blocks')
        l.blocks = [];
    end
    addind = numel(l.blocks)+1;
    
    f = fields(block);
    for nf = 1:numel(f)
        l.blocks(addind).(f{nf}) = block.(f{nf});
    end
    saveRuntimeLog(l);
catch
    warning(sprintf('addBlockToLog: couldn''t. %s', lasterr));
end