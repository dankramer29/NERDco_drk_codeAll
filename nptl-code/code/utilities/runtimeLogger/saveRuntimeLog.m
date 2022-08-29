function saveRuntimeLog(l)

global modelConstants
logdir = [modelConstants.sessionRoot modelConstants.runtimeLogDir];
fname = [logdir modelConstants.runtimeLogFile];

try
    save(fname,'-struct','l');
catch
    warning(sprintf('saveRuntimeLog: couldn''t save log to %s', fname));
end