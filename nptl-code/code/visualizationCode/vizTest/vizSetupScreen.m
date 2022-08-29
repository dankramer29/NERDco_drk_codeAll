function flipTime = movementSetupScreen(data)
	global taskParams;
	%% all the relevant info is in the "data" field of the packet, deconstruct it
	m.packetType = data.state;

%% first code path is for visualization engine. next is for sound engine.
switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        global screenParams;
        whichScreen = screenParams.whichScreen;
        %% blank the screen
        clearScreen();
        ColorSC = [255 0 0];
        red = screenParams.red;
        blue = screenParams.blue;
        green = screenParams.green;
        white = screenParams.white;
        
        cursorWidth = 200;
        cursorHeight = 200;
        
        mp = screenParams.midpoint;
%         textCoords = [mp(1) mp(2)-cursorHeight];
        cursorCoords = [mp(1)-cursorWidth/2 mp(2)-cursorHeight/2 mp(1)+cursorWidth/2 mp(2)+cursorHeight/2];
        switch m.packetType
            case CursorStates.STATE_INIT
            case 20
                Screen('FillRect', whichScreen, red, cursorCoords);
            case 30
            otherwise
                disp('dont understand this state')
        end
        
        [vblts SOT FTS]=Screen('Flip', whichScreen, 0, 0, 0); % actually present stimulus
        flipTime = FTS - taskParams.startTime;%toc(taskParams.startTime);
        
        
    case EngineTypes.SOUND
        global soundParams;
        flipTime = 0;
end

function clearScreen()
	Screen('FillRect', whichScreen, screenParams.backgroundIndexColor);	  	end
end
