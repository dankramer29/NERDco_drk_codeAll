function initializeDecision()
    global modelConstants;
    if isempty(modelConstants)
        modelConstants = modelDefinedConstants();
    end
    
	global taskParams;
	taskParams.handlerFun = @decisionSetupScreen;
    switch taskParams.engineType
        case EngineTypes.VISUALIZATION
            global screenParams;
            global isCursorShowing
            isCursorShowing= true;
            HideCursor();
        case EngineTypes.SOUND
            global soundParams;
            
            % use this sound for success
            l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/EC_go.wav'])';
            soundParams.successSound = l(1,:);
            % use the standard beep for Go
            soundParams.goSound = soundParams.beep;
            l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/C#C_failure.wav'])';
            soundParams.failSound = l(1,:);
            soundParams.lastSoundTime = 0;            

            %% tapping sound for over targets            
            l=loadvar(['~/' modelConstants.vizDir '/sounds/tap.mat'],'sound');
            % scale down volume
            l = 1.2*l;
            soundParams.overSound = l(1,:);
    end
