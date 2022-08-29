function pushDelayedParams()

	global modelConstants;
    global PARAMS_DELAYED_UPDATE
    
    if ~isempty(PARAMS_DELAYED_UPDATE)
        saveDir = fullfile(modelConstants.sessionRoot, modelConstants.paramsDir);
        
        global delayedParams
        xPCParams = delayedParams;
        delayedParams = struct;
        
        disp(['saving newParams.mat']);
        save([saveDir '/newParams.mat'], 'xPCParams');
    end
end
