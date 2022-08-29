function initializeLinux()
	global taskParams;
	taskParams.handlerFun = @linuxSetupScreen;
    Screen('CloseAll');
    
    global modelConstants
    if isempty(modelConstants)
        modelConstants = modelDefinedConstants;
    end
    switch taskParams.engineType
        case EngineTypes.SOUND
            global soundParams;
            %% tapping sound for over targets
            l=loadvar(['~/' modelConstants.vizDir '/sounds/tap.mat'],'sound');
            % scale down volume
            l = 0.6*l;
            soundParams.clickSound = l(1,:);
    end