function l = loadRuntimeLog(fname)

if ~exist('fname','var')
    global modelConstants
    logdir = [modelConstants.sessionRoot modelConstants.runtimeLogDir];
    fname = [logdir modelConstants.runtimeLogFile];
end

try
    l = load(fname);
catch
    warning(sprintf('loadRuntimeLog: couldn''t load log from %s', fname));
    l=struct;
end