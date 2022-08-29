function out = getLatestBlocknumFromLog()

l = loadRuntimeLog();

try
    if isfield(l,'blocks')
        out = max([l.blocks.blockNum]);
    else
        out = -1;
    end
catch
    warning('getLatestBlocknumFromLog: couldnt parse log.');
    out = -1;
end