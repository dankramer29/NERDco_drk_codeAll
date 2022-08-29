function logRemoteParameterError(exception)
	global modelConstants;
    saveDir = fullfile(modelConstants.sessionRoot, modelConstants.paramsDir);
    fileName = 'parameterChangelog.txt';
    fout = fopen(fullfile(saveDir,fileName),'a');
    if ~fout
        error(['error opening file ' fullfile(saveDir,fileName)]);
    end
    txt = sprintf('\n%s: ERROR: %s\n%s: ERROR: %s\n%s: ERROR: %s',datestr(now), exception.message,...
        datestr(now), exception.identifier);
    fprintf(fout,txt);
    for nn = 1:length(exception.stack)
        txt = sprintf('\n%s: ERROR: %s', datestr(now), exception.stack(nn).file);
        fprintf(fout,txt);
        txt = sprintf('\n%s: ERROR: %s', datestr(now), exception.stack(nn).name);
        fprintf(fout,txt);
        txt = sprintf('\n%s: ERROR: %s', datestr(now), exception.stack(nn).line);
        fprintf(fout,txt);
    end
    fclose(fout);
end