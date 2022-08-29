function loadCurParams()

    global xPCParams modelConstants;

    saveDir = fullfile(modelConstants.sessionRoot, modelConstants.paramsDir);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    
    xPCParams = loadvar(fullfile(saveDir, 'curParams.mat'), 'xPCParams');

end