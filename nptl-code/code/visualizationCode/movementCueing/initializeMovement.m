function initializeMovement()

    global screenParams;
    global taskParams;
    global modelConstants;
    if isempty(modelConstants)
        modelConstants = modelDefinedConstants();
    end
    taskParams.handlerFun = @movementSetupScreen;
 
    switch taskParams.engineType
      case EngineTypes.VISUALIZATION
        global screenParams;
      case EngineTypes.SOUND
        global soundParams;
        
        soundsToLoad = {'wrist','elbow','thumb','index','left','right','up','down'};
        for s=1:length(soundsToLoad)
            [l,fs,nb]=wavread(['~/' modelConstants.vizDir '/sounds/movementCue/' soundsToLoad{s} '.wav']);
            l = resample(l,44100,fs);
            l=l';
            soundParams.(soundsToLoad{s}) = l(1,:);
        end
        
        soundParams.index = l(1,:);
        soundParams.goSound = soundParams.beep;
        soundParams.returnSound = soundParams.beep;
        soundParams.lastSoundTime = 0;
    end
    