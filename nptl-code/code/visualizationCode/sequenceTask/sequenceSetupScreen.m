function flipTime = sequenceSetupScreen(data)
global taskParams;
%% all the relevant info is in the "data" field of the packet, deconstruct it

switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        m.packetType = data.state;
        global screenParams;
        
        if ~screenParams.drawn
            initializeScreen(true);
            Screen('BlendFunction', screenParams.whichScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',10,screenParams.white);
            Screen('FillRect', screenParams.whichScreen, screenParams.backgroundIndexColor);
            DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',10,screenParams.white);
            HideCursor();
            Screen('HideCursorHelper',screenParams.whichScreen);
            [vblts SOT FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
            pause(3);
            taskParams.lastPacketTime = GetSecs();
        end
        whichScreen = screenParams.whichScreen;
        
        %%
        %make sure we have a packet
        if ~all(data.targetSeq==0) 
            %% draw screen background
            Screen('FillRect', whichScreen, screenParams.backgroundIndexColor);

            mp = screenParams.midpoint;
            for nt = 1:data.numTargets
                currentTargetCoords = double(data.targPosAll(1:2,nt))+mp(:);
                currentTargetBoundingRect = [currentTargetCoords - double(data.targetDiameter)/2; ...
                    currentTargetCoords + double(data.targetDiameter)/2];
                Screen('FillOval', whichScreen, [100 100 100], currentTargetBoundingRect, 100);
            end
        
            %%
            %draw sequence arrows for sequence mode (not path mode)
            
            %[  0 289 409  289    0 -289 -409 -289 0; ...
            % 409 289   0 -289 -409 -289    0 289 0];
            %(0,0) is top left of screen 
            %target 9 is the center target, which we ignore when drawing
            %arrows
            if data.rotateType==1
                %cues must be rotated 45 degrees clockwise to determine
                %which target to move towards
                rotateText = 'Clockwise';
                targMap = {'2198', '2192', '2197', '2191', '2196', '2190', '2199', '2193'};
            elseif data.rotateType==3
                rotateText = 'Counter-Clockwise';
                targMap = {'2199', '2193', '2198', '2192', '2197', '2191', '2196', '2190'};         
            elseif data.rotateType==2
                %no rotation
                rotateText = [];
                targMap = {'2193', '2198', '2192', '2197', '2191', '2196', '2190', '2199'};
            end
            
            seq = data.targetSeq;
            unicodeStr = [];
            for s=1:data.numTargsInSeq 
                if seq(s)<9
                    newChar = typecast(hex2dec(targMap{seq(s)}), 'double');
                    unicodeStr = [unicodeStr, newChar];
                end
            end
            
            Screen('Preference', 'TextRenderer', 1);
            Screen('TextFont', screenParams.whichScreen, 'DejaVu');
            if data.pathMode==0
                if data.memorizeMode==0
                    %always draw in center of screen if not memorizing
                    Screen('DrawText', screenParams.whichScreen, unicodeStr, mp(1)-200, mp(2)-200, [255 255 255]);        
                    if ~isempty(rotateText)
                        Screen('DrawText', screenParams.whichScreen, rotateText, mp(1)-200, mp(2)-150, [255 255 255]);        
                    end            
                elseif (m.packetType == SequenceStates.STATE_REHEARSE)
                    %otherwise draw in corner of screen only during rehearse
                    %state
                    Screen('DrawText', screenParams.whichScreen, unicodeStr, mp(1)-450, mp(2)-450, [255 255 255]);        
                    if ~isempty(rotateText)
                        Screen('DrawText', screenParams.whichScreen, rotateText, mp(1)-200, mp(2)-150, [255 255 255]);        
                    end
                end
            end
            
            %%
            %score
            if ~isnan(data.seqTimeScore)
                Screen('DrawText', screenParams.whichScreen, num2str(double(data.seqTimeScore)/1000,'%0.2f'), mp(1)+500, mp(2)-450, [255 255 255]);    
            end
            
            %%
            green = [00 204 00];
            orange = [255 133 0];
            red = [204 0 0];
            cursorOutline=3; %% in pixels

            switch m.packetType
                case SequenceStates.STATE_INIT
                case SequenceStates.STATE_READY
                    Screen('DrawText', screenParams.whichScreen, ['Get Ready (' num2str(double(data.countdownTimer)/1000,'%0.0f') ')'], mp(1)-185, mp(2)-250, [255 255 255]);    
                case SequenceStates.STATE_REHEARSE
                    Screen('DrawText', screenParams.whichScreen, ['Rehearse (' num2str(double(data.countdownTimer)/1000,'%0.0f') ')'], mp(1)-185, mp(2)-250, [255 255 255]);    
                case SequenceStates.STATE_MOVE
                    if data.lastTarget>0
                        lastTargetCoords = double(data.targPosAll(1:2,data.lastTarget)) + mp(:);
                        lastTargetBoundingRect = [lastTargetCoords - double(data.targetDiameter)/2; ...
                            lastTargetCoords + double(data.targetDiameter)/2];
                        if data.showFailedTarg
                            if data.memorizeMode
                                %show next target in orange
                                %nextIdx = data.seqIdx + 1;
                                %if nextIdx>data.numTargets
                                %    nextIdx = 1;
                                %end
                                nextTargetCoords = double(data.targPosAll(1:2,data.targetSeq(data.seqIdx))) + mp(:);
                                nextTargetBoundingRect = [nextTargetCoords - double(data.targetDiameter)/2; ...
                                    nextTargetCoords + double(data.targetDiameter)/2];
                                Screen('FillOval', whichScreen, orange, nextTargetBoundingRect, 100);
                            else
                                %show the target that was accidentally
                                %touched in red
                                Screen('FillOval', whichScreen, red, lastTargetBoundingRect, 100);
                            end
                        else
                            Screen('FillOval', whichScreen, green, lastTargetBoundingRect, 100);
                        end
                    end
                otherwise
                    disp('dont understand this state')
            end

            %draw numbers on targets (if path mode)
            for nt = 1:data.numTargets
                currentTargetCoords = double(data.targPosAll(1:2,nt))+mp(:);
                if data.pathMode==1 
                    %target numbers show the path order
                    if data.memorizeMode==0 || (m.packetType == SequenceStates.STATE_REHEARSE)
                        Screen('DrawText', screenParams.whichScreen, num2str(nt), currentTargetCoords(1)-15, currentTargetCoords(2)-15, [255 255 255]); 
                    end
                end
            end
            
            %draw cursor(s)
            cursorColors = double(data.cursorColors);
            for nc = 1:size(data.cursorPosition,2)
                if all(~isnan(data.cursorPosition(1:2,nc)))
                    cursorPos = double(data.cursorPosition(1:2,nc)); 
                    cursorPos(1:2) = cursorPos(1:2) + mp(:); 
                    drawCursorWithBorder(screenParams, whichScreen,...
                        [cursorPos; 0], double(data.cursorDiameter), cursorColors(1:end,nc), cursorOutline);
                end
            end
            
            if data.pc1MouseInControlMode
                cursorPos = double(data.headMousePos(1:2,nc)); 
                cursorPos(1:2) = cursorPos(1:2) + mp(:); 
                drawCursorWithBorder(screenParams, whichScreen,...
                    [cursorPos; 0], double(data.cursorDiameter), [0; 204; 102;], cursorOutline);
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
                case SequenceStates.SOUND_STATE_SUCCESS
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.successSound);
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
