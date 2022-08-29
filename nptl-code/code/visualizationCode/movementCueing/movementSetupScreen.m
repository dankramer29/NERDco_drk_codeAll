function flipTime = movementSetupScreen(data)
	global taskParams;
	%% all the relevant info is in the "data" field of the packet, deconstruct it

%% first code path is for visualization engine. next is for sound engine.
switch taskParams.engineType
    case EngineTypes.VISUALIZATION
    	m.packetType = data.state;
        global screenParams;
        if ~screenParams.drawn
            initializeScreen(true);
            Screen('BlendFunction', screenParams.whichScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                
            Screen('FillRect', screenParams.whichScreen, screenParams.backgroundIndexColor);
            [vblts SOT FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
            %         [vblts SOT FTS]=Screen('AsyncFlipBegin', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
            pause(0.1);
            taskParams.lastPacketTime = GetSecs();
        end
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
        textCoords = [mp(1) mp(2)-cursorHeight];
        cursorCoords = [mp(1)-cursorWidth/2 mp(2)-cursorHeight/2 mp(1)+cursorWidth/2 mp(2)+cursorHeight/2];
        
        endInd = min(find(data.movementText == char(0)));
        textDisplay = data.movementText(1:endInd-1);
        
        %----special arrows for bimanual cueing-----
        %left, right, up, down
        arrowCodes = {'2190','2192','2191','2193'};
        spaceCode = '2003';
        xCode = '2715';
        fullArrowCode = [];
      
        switch data.currentMovement
            case movementTypes.BI_NO_LEFT
                fullArrowCode = [xCode, spaceCode, arrowCodes(1)];
            case movementTypes.BI_NO_RIGHT
                fullArrowCode = [xCode, spaceCode, arrowCodes(2)];
            case movementTypes.BI_NO_UP
                fullArrowCode = [xCode, spaceCode, arrowCodes(3)];
            case movementTypes.BI_NO_DOWN 
                fullArrowCode = [xCode, spaceCode, arrowCodes(4)];
                
            case movementTypes.BI_LEFT_NO
                fullArrowCode = [arrowCodes(1), spaceCode, xCode];
            case movementTypes.BI_RIGHT_NO
                fullArrowCode = [arrowCodes(2), spaceCode, xCode];
            case movementTypes.BI_UP_NO
                fullArrowCode = [arrowCodes(3), spaceCode, xCode];
            case movementTypes.BI_DOWN_NO 
                fullArrowCode = [arrowCodes(4), spaceCode, xCode];
                
            case movementTypes.BI_LEFT_LEFT
                fullArrowCode = [arrowCodes(1), spaceCode, arrowCodes(1)];
            case movementTypes.BI_LEFT_RIGHT
                fullArrowCode = [arrowCodes(1), spaceCode, arrowCodes(2)];
            case movementTypes.BI_LEFT_UP
                fullArrowCode = [arrowCodes(1), spaceCode, arrowCodes(3)];
            case movementTypes.BI_LEFT_DOWN 
                fullArrowCode = [arrowCodes(1), spaceCode, arrowCodes(4)];

            case movementTypes.BI_RIGHT_LEFT
                fullArrowCode = [arrowCodes(2), spaceCode, arrowCodes(1)];
            case movementTypes.BI_RIGHT_RIGHT
                fullArrowCode = [arrowCodes(2), spaceCode, arrowCodes(2)];
            case movementTypes.BI_RIGHT_UP
                fullArrowCode = [arrowCodes(2), spaceCode, arrowCodes(3)];
            case movementTypes.BI_RIGHT_DOWN 
                fullArrowCode = [arrowCodes(2), spaceCode, arrowCodes(4)];
                
            case movementTypes.BI_UP_LEFT
                fullArrowCode = [arrowCodes(3), spaceCode, arrowCodes(1)];
            case movementTypes.BI_UP_RIGHT
                fullArrowCode = [arrowCodes(3), spaceCode, arrowCodes(2)];
            case movementTypes.BI_UP_UP
                fullArrowCode = [arrowCodes(3), spaceCode, arrowCodes(3)];
            case movementTypes.BI_UP_DOWN 
                fullArrowCode = [arrowCodes(3), spaceCode, arrowCodes(4)];
                
            case movementTypes.BI_DOWN_LEFT
                fullArrowCode = [arrowCodes(4), spaceCode, arrowCodes(1)];
            case movementTypes.BI_DOWN_RIGHT
                fullArrowCode = [arrowCodes(4), spaceCode, arrowCodes(2)];
            case movementTypes.BI_DOWN_UP
                fullArrowCode = [arrowCodes(4), spaceCode, arrowCodes(3)];
            case movementTypes.BI_DOWN_DOWN 
                fullArrowCode = [arrowCodes(4), spaceCode, arrowCodes(4)];
        end

        Screen('TextSize', whichScreen, 36);
        switch data.textOverlayID
            case uint16(1)
                Screen('DrawText', whichScreen, 'Left Joystick', mp(1)-400, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Right Joystick', mp(1)+150, mp(2)-240, [255 255 255]);   
            case uint16(2)
                Screen('DrawText', whichScreen, 'Head', mp(1)-250, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Right Joystick', mp(1)+150, mp(2)-240, [255 255 255]);   
            case uint16(3)
                Screen('DrawText', whichScreen, 'Right Leg', mp(1)-340, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Right Joystick', mp(1)+150, mp(2)-240, [255 255 255]);   
            case uint16(4)
                Screen('DrawText', whichScreen, 'Left Leg', mp(1)-340, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Right Joystick', mp(1)+150, mp(2)-240, [255 255 255]);  
            case uint16(5)
                Screen('DrawText', whichScreen, 'Head', mp(1)-250, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Tongue', mp(1)+150, mp(2)-240, [255 255 255]);  
            case uint16(6)
                Screen('DrawText', whichScreen, 'Head', mp(1)-250, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Right Leg', mp(1)+150, mp(2)-240, [255 255 255]);  
            case uint16(7)
                Screen('DrawText', whichScreen, 'Head', mp(1)-250, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Left Leg', mp(1)+150, mp(2)-240, [255 255 255]);   
            case uint16(8)
                Screen('DrawText', whichScreen, 'Head', mp(1)-250, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Left Joystick', mp(1)+150, mp(2)-240, [255 255 255]);  
            case uint16(9)
                Screen('DrawText', whichScreen, 'Left Joystick', mp(1)-400, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Right Leg', mp(1)+150, mp(2)-240, [255 255 255]);  
            case uint16(10)
                Screen('DrawText', whichScreen, 'Left Joystick', mp(1)-400, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Left Leg', mp(1)+150, mp(2)-240, [255 255 255]);  
            case uint16(11)
                Screen('DrawText', whichScreen, 'Left Leg', mp(1)-340, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Right Leg', mp(1)+150, mp(2)-240, [255 255 255]);  
            case uint16(12)
                Screen('DrawText', whichScreen, 'Eyes', mp(1)-340, mp(2)-240, [255 255 255]);   
                Screen('DrawText', whichScreen, 'Right Joystick', mp(1)+150, mp(2)-240, [255 255 255]);  
            otherwise
        end
        
        if ~isempty(fullArrowCode) && ~any(strncmp(textDisplay,{'Go','Return'},2))
            unicodeStr = typecast(hex2dec(fullArrowCode), 'double');
            Screen('TextFont', whichScreen, 'DejaVu');
            Screen('TextSize', whichScreen, 80);
            Screen('DrawText', whichScreen, unicodeStr, mp(1)-110, mp(2)-250, [255 255 255]);     
        else
            if length(textDisplay)
                %Screen('DrawText', whichScreen, textDisplay, textCoords(1), textCoords(2), white);
                Screen('TextSize', whichScreen, 40);
                DrawFormattedText(whichScreen, textDisplay, 'center', textCoords(2), white);
            end
        end
        
        switch m.packetType
            case MovementStates.STATE_INIT
            case MovementStates.STATE_PRE_MOVE
            case MovementStates.STATE_MOVEMENT_TEXT
                Screen('FillRect', whichScreen, red, cursorCoords);
            case MovementStates.STATE_GO_CUE %SOLIDCURSOR
                Screen('FillRect', whichScreen, green, cursorCoords);
            case MovementStates.STATE_HOLD_CUE
                Screen('FillRect', whichScreen, red, cursorCoords);
            case MovementStates.STATE_RETURN_CUE
                Screen('FillRect', whichScreen, green, cursorCoords);
            case MovementStates.STATE_REST_CUE
                Screen('FillRect', whichScreen, red, cursorCoords);
            case MovementStates.STATE_END
                taskParams.quit = true;
            otherwise
                disp('dont understand this state')
        end
        
        [vblts SOT FTS]=Screen('Flip', whichScreen, 0, 0, 0); % actually present stimulus
        flipTime = FTS - taskParams.startTime;%toc(taskParams.startTime);
        
        
    case EngineTypes.SOUND
        global soundParams;
        flipTime = 0;
        if data.lastSoundTime ~= soundParams.lastSoundTime
            soundParams.lastSoundTime = data.lastSoundTime;
            m.packetType = data.lastSoundState;
            switch m.packetType
              case MovementStates.SOUND_STATE_MOVEMENT_TEXT
                  % only play spoken cues if requested
                  if data.playSpokenCues
                    switch data.movementType
                        case movementTypes.WRISTFLEX
                          PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.wrist);
                          PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                        case movementTypes.ELBOWFLEX
                          PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.elbow);
                          PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                        case movementTypes.INDEX
                          PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.index);
                          PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                        case movementTypes.THUMB
                          PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.thumb);
                          PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                        case {movementTypes.TURN_HEAD_RIGHT, movementTypes.GENERIC_RIGHT}
                          PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.right);
                          PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                        case {movementTypes.TURN_HEAD_LEFT, movementTypes.GENERIC_LEFT}
                          PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.left);
                          PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                        case {movementTypes.TURN_HEAD_UP, movementTypes.GENERIC_UP}
                          PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.up);
                          PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                        case {movementTypes.TURN_HEAD_DOWN, movementTypes.GENERIC_DOWN}
                          PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.down);
                          PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                    end
                  end
                case MovementStates.SOUND_STATE_GO_CUE
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.goSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case MovementStates.SOUND_STATE_RETURN_CUE
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.returnSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
            end
        end
end

function clearScreen()
	Screen('FillRect', whichScreen, screenParams.backgroundIndexColor);	  	end
end
