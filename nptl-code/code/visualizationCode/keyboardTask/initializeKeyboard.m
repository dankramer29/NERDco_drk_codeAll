function initializeKeyboard()
    global modelConstants;
    if isempty(modelConstants)
        modelConstants = modelDefinedConstants();
    end
    
    %% the standard screen setup is not going to work here
        % so just trash the current screen(s) and start over.
        % as long as we set
        %    taskParams.reinitializeScreen = true;
        % then it will get reset afterwards
        sca;
	global taskParams;
        taskParams.reinitializeScreen = true;
	taskParams.handlerFun = @keyboardSetupScreen;

    switch taskParams.engineType
        case EngineTypes.VISUALIZATION
            global screenParams;
            screenParams.multisample = 2;
            
            global isCursorShowing
            isCursorShowing= true;
            
            global keyboards
            keyboards = allKeyboards();
            
            %% setup the main screen
            %% for less than fullscreen - not used
            % screenParams.whichScreen = Screen('OpenWindow',0,screenParams.backgroundIndexColor,...
            %     [screenParams.xstart screenParams.ystart screenParams.xstart+screenParams.width screenParams.ystart+screenParams.height], ...
            %                          [],[],[], screenParams.multisample);
            %% if we want fullscreen
            screenParams.whichScreen = Screen('OpenWindow',0,screenParams.backgroundIndexColor,...
                [],[],[],[],screenParams.multisample);
            
            q = keyboards(1);
            %% open another offscreen window
            screenParams.offScreen(1).screen = Screen('OpenOffscreenWindow',...
                0,screenParams.backgroundIndexColor,...
                [],[],[],screenParams.multisample);
            
            % no keyboard has been drawn yet
            screenParams.offScreen(1).drawn = keyboardConstants.KEYBOARD_NONE;
            screenParams.offScreen(1).keyboardDims = [0 0];
            
            %% open offscreen windows
            screenParams.offScreen(2).screen = Screen('OpenOffscreenWindow',...
                0,screenParams.backgroundIndexColor,...
                [],[],[],screenParams.multisample);
            screenParams.offScreen(3).screen = Screen('OpenOffscreenWindow',...
                0,screenParams.backgroundIndexColor,...
                [],[],[],screenParams.multisample);
            screenParams.offScreen(4).screen = Screen('OpenOffscreenWindow',...
                0,screenParams.backgroundIndexColor,...
                [],[],[],screenParams.multisample);
            screenParams.offScreen(5).screen = Screen('OpenOffscreenWindow',...
                0,screenParams.backgroundIndexColor,...
                [],[],[],screenParams.multisample);
            
            %% this is used in cursor task... needed here?
            %Screen('BlendFunction', screenParams.whichScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            HideCursor();
        case EngineTypes.SOUND
            global soundParams;

            %% make a sound for when keys are clicked on
            %l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/EC_go_plus1pt5.wav'])';
            l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/EC_go.wav'])';
            killind = floor(length(l)/4)+1;
            dampen = zeros([1 length(l)-killind+1]);
            t=1:length(dampen);
            dampen = exp(-(t-1)*0.001);
            l(1,killind:end)=l(1,killind:end).*dampen;
            soundParams.clickSound = l;

            %% make a sound for when keys are dwelled on
            %l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/synthBassG.wav'])';
            %l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/EC_go.wav'])';
            l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/EC_go_minus3.wav'])';
            killind = floor(length(l)/4)+1;
            dampen = zeros([1 length(l)-killind+1]);
            t=1:length(dampen);
            dampen = exp(-(t-1)*0.001);
            l(1,killind:end)=l(1,killind:end).*dampen;
            soundParams.dwellSound = l;
            
            %% tapping sound for over targets            
            l=loadvar(['~/' modelConstants.vizDir '/sounds/tap.mat'],'sound');
            % scale down volume
            l = 0.6*l;
            soundParams.overSound = l(1,:);
            
            %% failure sound
            l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/C#C_failure.wav'])';
			%this is too loud relative to other sounds. lower by a factor of 3
			l = l/3;
            % exponential damping
            killind = floor(2*length(l)/3)+1;
            dampen = zeros([1 length(l)-killind+1]);
            t=1:length(dampen);
            dampen = exp(-(t-1)*0.001);
            l(1,killind:end)=l(1,killind:end).*dampen;

            failLength = size(l,2);
            % trim to 85% of length
            failLength = floor(failLength * 0.8);
            soundParams.failSound = l(1,1:failLength);
            
            %% initialize this value
            soundParams.lastSoundTime = 0;            
    end            