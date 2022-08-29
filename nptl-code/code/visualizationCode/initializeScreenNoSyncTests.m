function initializeScreen(makeScreen)
    if ~exist('makeScreen','var')
        makeScreen = false;
    end

    global screenParams;

    Screen('Preference','SkipSyncTests', 1);
    screenParams.screens=Screen('Screens');
    screenParams.numScreens=numel(screenParams.screens);
    screenParams.drawn = false;
    %% in case there are two monitors?
    if screenParams.numScreens>1
        [screenParams.width screenParams.height]=Screen('WindowSize',1);
        if makeScreen
            [screenParams.whichScreen, theRect]=Screen('OpenWindow', 1);
        end
    else
        [screenParams.width screenParams.height]=Screen('WindowSize',0);
        if makeScreen
            [screenParams.whichScreen, theRect]=Screen('OpenWindow', 0);
        end
    end

    screenParams.midpoint = round([screenParams.width screenParams.height]/2);


    if makeScreen
        whichScreen = screenParams.whichScreen;
        Screen('TextFont',whichScreen, 'Courier New'); %Courier New
        Screen('TextSize',whichScreen, 50);
        Screen('TextStyle', whichScreen, 1+2);

        Screen('DrawText', whichScreen, 'Initializing');
        [vblts SOT FTS]=Screen('Flip', whichScreen, 0, 0, 0); % actually present stimulus
        screenParams.drawn = true;
    end

    screenParams.red = [255 0 0];
    screenParams.blue = [0 0 255];
    screenParams.green = [0 255 0];
    screenParams.white = [255 255 255];
    screenParams.backgroundIndexColor = [0 0 0];

    screenParams.xDims = [-960 960];
    screenParams.yDims = [-540 540];

    

%     if PsychPortAudio('GetOpenDeviceCount')
%         PsychPortAudio('close');
%     end
% 
%     InitializePsychSound();
%     % Open the default audio device [], with default mode [] (==Only playback),
%     % and a required latencyclass of zero 0 == no low-latency mode, as well as
%     % a frequency of freq and nrchannels sound channels.
%     % This returns a handle to the audio device:
%     try
%         % Try with the frequency we wanted:
%         screenParams.audioHandle = PsychPortAudio('Open', [], [], 0, 44100, 1);
%     catch
%         % Failed. Retry with default frequency as suggested by device:
%         fprintf('\nCould not open device at wanted playback frequency of %i Hz. Will retry with device default frequency.\n', 40000);
%         fprintf('Sound may sound a bit out of tune, ...\n\n');
%         
%         psychlasterror('reset');
%         screenParams.audioHandle = PsychPortAudio('Open', [], [], 0, [], 1);
%     end
%     
    screenParams.oldPriority = Priority(9);
    
    if makeScreen
        Screen('DrawText', whichScreen, 'Initialized');
        [vblts SOT FTS]=Screen('Flip', whichScreen, 0, 0, 0); % actually present stimulus
    end
    
