function initializeRuntimeLogger()
global modelConstants

logdir = [modelConstants.sessionRoot modelConstants.runtimeLogDir];

if ~isdir(logdir)
    mkdir(logdir);
end

fname = [logdir modelConstants.runtimeLogFile];
if ~exist(fname,'file')
    f = struct();
    save(fname, '-struct','f');
end
