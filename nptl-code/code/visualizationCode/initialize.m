function initialize()
global taskParams;
switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        initializeScreen();
    case EngineTypes.SOUND
        initializeSound();
end
initializeSockets();