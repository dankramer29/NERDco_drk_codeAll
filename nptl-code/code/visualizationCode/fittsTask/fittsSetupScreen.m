function flipTime = fittsSetupScreen(data)
global taskParams;
%% all the relevant info is in the "data" field of the packet, deconstruct it

switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        m.packetType = data.state;
        global screenParams;
        
        % SDS August 2016
        DEPTH_LIMITS = [-500 500]; % used to scale the size of cursors/targets based on their depth coordinate
        SCALE_RANGE = [0.5 2];    % sizes will go from [0.5 to 1.5] with depth of
        % 0 corresponding to scale of 1.

        
        if ~screenParams.drawn
            initializeScreen(true);
            Screen('BlendFunction', screenParams.whichScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',10,screenParams.white);
            Screen('FillRect', screenParams.whichScreen, screenParams.backgroundIndexColor);
            DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',10,screenParams.white);
            HideCursor();
            Screen('HideCursorHelper',screenParams.whichScreen);
            [vblts SOT FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
            %         [vblts SOT FTS]=Screen('AsyncFlipBegin', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
            pause(3);
            taskParams.lastPacketTime = GetSecs();
        end
        whichScreen = screenParams.whichScreen;

        %% blank the screen
        %clearScreen(whichScreen, backgroundIndexColor);
        Screen('FillRect', whichScreen, screenParams.backgroundIndexColor);
        %red = screenParams.red;
        %blue = screenParams.blue;
        %green = screenParams.green;
        red = [255 0 0 ];
        blue = [0 153 153];
        green = [00 204 00];
        orange = [255 133 0];
        white = screenParams.white;
        %cursorColors = {white, orange};
        boundsColor = [95 95 95];
        cursorOutline=3; %% in pixels
        
        mp = screenParams.midpoint;
        targetDiameter = double(data.currentTargetDiameter);
        nextTargetDiameter = double(data.nextTargetDiameter);
        cursorDiameter = double(data.cursorDiameter);
        currentTargetCoords = double(data.currentTarget(1:2)) + mp(:);
        nextTargetCoords = double(data.nextTarget(1:2)) + mp(:);
        cursorColors = double(data.cursorColors);
        currentTargetBoundingRect = [currentTargetCoords - targetDiameter/2; currentTargetCoords + targetDiameter/2];
        nextTargetBoundingRect = [nextTargetCoords - nextTargetDiameter/2; nextTargetCoords + nextTargetDiameter/2];
        
        %%show left and right grey bars to indicate space outside of the
        %%workspace
        workspaceX = double(data.workspaceX);
        workspaceY = double(data.workspaceY);
        
        if workspaceX(1)-cursorDiameter/2 > screenParams.xDims(1)
            boundsBar = [mp(1)+screenParams.xDims(1) mp(2)+screenParams.yDims(1) mp(1)+workspaceX(1)-cursorDiameter/2 mp(2)+screenParams.yDims(2)];
            Screen('FillRect', whichScreen, boundsColor, boundsBar);
        end
        
        if workspaceY(1)-cursorDiameter/2 > screenParams.yDims(1)
            boundsBar = [mp(1)+screenParams.xDims(1) mp(2)+screenParams.yDims(1) mp(1)+screenParams.xDims(2) mp(2)+workspaceY(1)-cursorDiameter/2];
            Screen('FillRect', whichScreen, boundsColor, boundsBar);
        end

        if workspaceX(2)+cursorDiameter/2 < screenParams.xDims(2)
            boundsBar = [mp(1)+workspaceX(2)+cursorDiameter/2 mp(2)+screenParams.yDims(1) mp(1)+screenParams.xDims(2) mp(2)+screenParams.yDims(2)];
            Screen('FillRect', whichScreen, boundsColor, boundsBar);
        end
        
        if workspaceY(2)+cursorDiameter/2 < screenParams.yDims(2)
            boundsBar = [mp(1)+screenParams.xDims(1) mp(2)+workspaceY(2)+cursorDiameter/2 mp(1)+screenParams.xDims(2) mp(2)+screenParams.yDims(2)];
            Screen('FillRect', whichScreen, boundsColor, boundsBar);
        end
        
        
        switch m.packetType
            case FittsStates.STATE_INIT
            case FittsStates.STATE_PRE_TRIAL
            case FittsStates.STATE_CENTER_TARGET
                % Screen('DrawDots', whichScreen, currentTargetCoords, targetDiameter, green,[0 0], 1);
                Screen('FillOval', whichScreen, green, currentTargetBoundingRect, 100);
            case FittsStates.STATE_SUCCESS
                %Screen('DrawDots', whichScreen, currentTargetCoords, targetDiameter, red,[0 0], 1);
                Screen('FillOval', whichScreen, red, currentTargetBoundingRect, 100);
            case FittsStates.STATE_FAIL
                %Screen('DrawDots', whichScreen, currentTargetCoords, targetDiameter, red,[0 0], 1);
                mp = currentTargetCoords;
                failCoords = [mp(1)-targetDiameter/2 mp(2)-targetDiameter/2 mp(1)+targetDiameter/2 mp(2)+targetDiameter/2];
                Screen('FillRect', whichScreen, red, failCoords);
            case FittsStates.STATE_NEW_TARGET
                %Screen('DrawDots', whichScreen, currentTargetCoords, targetDiameter, red,[0 0], 1);
                %Screen('DrawDots', whichScreen, nextTargetCoords, targetDiameter, blue,[0 0], 1);
                Screen('FillOval', whichScreen, red, currentTargetBoundingRect, 100);
                Screen('FillOval', whichScreen, blue, nextTargetBoundingRect, 100);
            case {FittsStates.STATE_MOVE, FittsStates.STATE_MOVE_CLICK}
                %Screen('DrawDots', whichScreen, currentTargetCoords, targetDiameter, green,[0 0], 1);
                Screen('FillOval', whichScreen, green, currentTargetBoundingRect, 100);
            case FittsStates.STATE_RECENTER_DELAY
            case {FittsStates.STATE_ACQUIRE, FittsStates.STATE_HOVER}
                %Screen('DrawDots', whichScreen, currentTargetCoords, targetDiameter, blue,[0 0], 1);
                Screen('FillOval', whichScreen, blue, currentTargetBoundingRect, 100);
                
            case FittsStates.STATE_END
                taskParams.quit = true;
                
            otherwise
                disp('dont understand this state')
        end
        
        for nc = 1:size(data.cursorPosition,2)
            if all(~isnan(data.cursorPosition(1:2,nc)))
                cursorPos = double(data.cursorPosition(1:3,nc)); 
                cursorPos(1:2) = cursorPos(1:2) + mp(:); 
                cursorBoundingRect = [cursorPos(1:2) - cursorDiameter/2; cursorPos(1:2)+cursorDiameter/2];
                % Screen('FillOval', whichScreen, cursorColors(1:end,nc), cursorBoundingRect, 100);
                drawCursorWithBorder(screenParams, whichScreen,...
                    cursorPos, double(data.cursorDiameter), cursorColors(1:end,nc), cursorOutline);

            end
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
                case FittsStates.SOUND_STATE_SUCCESS
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.successSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case FittsStates.SOUND_STATE_FAIL
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.failSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
            end
        end
end

%% displayCursor
%Screen('DrawDots', whichScreen, cursorPos, cursorDiameter, white,[0 0], 1);

