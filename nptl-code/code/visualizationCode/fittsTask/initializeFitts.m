function initializeFitts()
    global modelConstants;
    if isempty(modelConstants)
        modelConstants = modelDefinedConstants();
    end
	global taskParams;
	taskParams.handlerFun = @fittsSetupScreen;
    
    switch taskParams.engineType
        case EngineTypes.VISUALIZATION
            global screenParams;
        case EngineTypes.SOUND
            global soundParams;
            
            l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/EC_go.wav'])';
            soundParams.successSound = l(1,:);
            l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/C#C_failure.wav'])';
            soundParams.failSound = l(1,:);
            soundParams.lastSoundTime = 0;            
    end
    