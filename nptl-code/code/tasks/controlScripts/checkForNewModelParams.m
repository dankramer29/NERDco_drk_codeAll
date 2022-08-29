function checkForNewModelParams(varargin)
    try
        global xPCParams modelConstants tg;
%         disp([ datestr(now) ': tick']);
        
        saveDir = fullfile(modelConstants.sessionRoot, modelConstants.paramsDir);
        newParamsName = 'newParams.mat';
        fileName = fullfile(saveDir, newParamsName);
        
        if exist(fileName, 'file')
            newParams = load(fileName);
            delete(fileName);
        else
            return;
        end
        
        if ~all(strcmp(fieldnames(newParams), 'xPCParams'))
            error('badFieldNames', 'Incorrect structure found in newParams.mat file');
            return;
        end
        
        fieldNames = fieldnames(newParams.xPCParams);
        
        for f = 1:numel(fieldNames)
            tmp = newParams.xPCParams.(fieldNames{f});
            tmp2 = xPCParams.(fieldNames{f});
            if any(tmp(:) ~= tmp2(:))
                setModelParam(fieldNames{f}, newParams.xPCParams.(fieldNames{f}), tg);
                %logRemoteParameterChange(fieldNames{f}, newParams.xPCParams.(fieldNames{f}));
            else
                1;
            end
        end
    catch exception
        disp('error checking for params: ')
        disp(exception.identifier);
        disp(exception.message);
        for nn = 1:length(exception.stack)
            disp(exception.stack(nn).file);
            disp(exception.stack(nn).name);
            disp(exception.stack(nn).line);
        end
        logRemoteParameterError(exception);
    end
end