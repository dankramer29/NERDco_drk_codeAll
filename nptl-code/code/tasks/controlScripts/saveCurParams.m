function saveCurParams()

    global xPCParams modelConstants;

    saveDir = fullfile(modelConstants.sessionRoot, modelConstants.paramsDir);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    
    save(fullfile(saveDir, 'curParams.mat'), 'xPCParams');

end