function flipTime = rsgSetupScreen(data)
global taskParams;
global symbolVector;
global keyOrder;
global pastSymbolSet;

%% all the relevant info is in the "data" field of the packet, deconstruct it
switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        m.packetType = data.state;
        global screenParams;
        
        if ~screenParams.drawn
            initializeScreen(true);
            Screen('BlendFunction', screenParams.whichScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            Screen('FillRect', screenParams.whichScreen, screenParams.backgroundIndexColor);
            DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',100,screenParams.white);
            HideCursor();
            Screen('HideCursorHelper',screenParams.whichScreen);
            [vblts SOT FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
            pause(3);
            taskParams.lastPacketTime = GetSecs();
        end
        whichScreen = screenParams.whichScreen;
        
        %%
        %make sure we have a packet
        %% draw screen background 
        Screen('FillRect', whichScreen, screenParams.backgroundIndexColor);
        mp = screenParams.midpoint;

        %%
        %score
        Screen('TextSize',whichScreen, 50);
        if ~isnan(data.avgErr)
            DrawFormattedText(screenParams.whichScreen, num2str(double(data.avgErr)*100,'%0.1f'), 'center', mp(2)-400, [255 255 255]);    
        end

        %%
        green = [00 204 00];
        orange = [255 133 0];
        white = [255 255 255];
        blue = [100 100 200];
        gray = [170 170 170];
        cursorOutline=3; %% in pixels

        %draw fixation cross at the center for all states
        crossColor = white;
        fr = double(data.rsgFixationRadius);
        Screen('DrawLine', whichScreen, crossColor, mp(1), mp(2)-fr, mp(1), mp(2)+fr, 3);
        Screen('DrawLine', whichScreen, crossColor, mp(1)-fr, mp(2), mp(1)+fr, mp(2), 3);

        targCoords = double(data.targPos' + mp(:));
        targRect = [targCoords - double(data.targetDiameter)/2; ...
            targCoords + double(data.targetDiameter)/2];

        readyCoords = double([0; 100] + mp(:));
        readyRect = [readyCoords - double(data.targetDiameter)/2; ...
            readyCoords + double(data.targetDiameter)/2];

        setCoords = double([0; -100] + mp(:));
        setRect = [setCoords - double(data.targetDiameter)/2; ...
            setCoords + double(data.targetDiameter)/2];

        switch m.packetType
            case rsgStates.STATE_INIT
            case rsgStates.STATE_FIXATE
            case rsgStates.STATE_PRE_READY
                if data.stateTimer>500
                    Screen('FillOval', whichScreen, gray, targRect, 100);
                end
            case rsgStates.STATE_POST_READY
                Screen('FillOval', whichScreen, gray, targRect, 100);
                if data.stateTimer>0 &&  data.stateTimer<data.cueDisplayTime
                    Screen('FillOval', whichScreen, blue, readyRect, 100);
                end
            case rsgStates.STATE_POST_SET
                Screen('FillOval', whichScreen, gray, targRect, 100);
                if data.stateTimer>0 &&  data.stateTimer<data.cueDisplayTime
                    Screen('FillOval', whichScreen, blue, setRect, 100);
                end
            case rsgStates.STATE_ACQUIRE
                if data.timeErr>0
                    signStr = 'Late ';
                else
                    signStr = 'Early ';
                end
                DrawFormattedText(screenParams.whichScreen, [signStr num2str(abs(data.timeErr))], 'center', mp(2)-200, [255 255 255]);   
                if data.targOverlap
                    Screen('FillOval', whichScreen, orange, targRect, 100); 
                else
                    Screen('FillOval', whichScreen, gray, targRect, 100);
                end
            otherwise
                disp('dont understand this state')
        end

        %draw cursor
        cursorPos = double(data.cursorPosition)'; 
        cursorPos(1:2) = cursorPos(1:2) + mp(:); 
        drawCursorWithBorder(screenParams, whichScreen,...
            [cursorPos; 0], double(data.cursorDiameter), [0; 204; 102;], cursorOutline);
        
        [vblts SOT FTS]=Screen('Flip', whichScreen, 0, 0, 0); % actually present stimulus
        flipTime = FTS - taskParams.startTime;%toc(taskParams.startTime);
        
    case EngineTypes.SOUND
        global soundParams;
        flipTime = 0;
        if data.lastSoundTime ~= soundParams.lastSoundTime
            soundParams.lastSoundTime = data.lastSoundTime;
            m.packetType = data.lastSoundState;
            switch m.packetType
                case SequenceStates.SOUND_STATE_SUCCESS
                    errScalar = 1-double(abs(data.err))/300;
                    errScalar = max(errScalar,0);
                    
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, errScalar*soundParams.successSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case SequenceStates.SOUND_STATE_ACQUIRE
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.goSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case SequenceStates.SOUND_STATE_FAIL
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.failSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
            end
        end
end
