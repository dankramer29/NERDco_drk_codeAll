function flipTime = symbolSetupScreen(data)
global taskParams;
global symbolVector;
global keyOrder;
global pastSymbolSet;
if isempty(symbolVector)
    symbolVector = getSymbolList();
    keyOrder = 1:8;
    %keyOrder = randperm(8);
end
textKey = {'Right','Up Right','Up','Up Left','Left','Down Left','Down','Down Right'};

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

            disp(data.targPosAll(1:2,1:9));
            
            mp = screenParams.midpoint;
            for nt = 1:data.numTargets
                currentTargetCoords = double(data.targPosAll(1:2,nt))+mp(:);
                currentTargetBoundingRect = [currentTargetCoords - double(data.targetDiameter)/2; ...
                    currentTargetCoords + double(data.targetDiameter)/2];
                Screen('FillOval', whichScreen, [100 100 100], currentTargetBoundingRect, 100);
            end
        
            %% 
            if isempty(pastSymbolSet)
                pastSymbolSet = data.currentSymbolSet;
            end
            symbolSetChanged = any(abs(double(data.currentSymbolSet) - double(pastSymbolSet))>0);
            if symbolSetChanged
                %keyOrder = randperm(8);
            end
            pastSymbolSet = data.currentSymbolSet;
            
            Screen('Preference', 'TextRenderer', 1);
            Screen('TextFont', screenParams.whichScreen, 'DejaVu');
            
            inMoveState = m.packetType==SymbolStates.STATE_MOVE_ONE || m.packetType==SymbolStates.STATE_MOVE_TWO;
            
            if data.cognitiveVMRMode 
                if ~data.recentering
                    %light up rotated target
                    rotIdx = mod((int16(data.currentTarget)-int16(1)) + int16(data.symbolVMRRot), 8) + int16(1);
                    currentTargetCoords = double(data.targPosAll(1:2,rotIdx))+mp(:);
                    currentTargetBoundingRect = [currentTargetCoords - double(data.targetDiameter)/2; ...
                        currentTargetCoords + double(data.targetDiameter)/2];
                    Screen('FillOval', whichScreen, [0 255 255], currentTargetBoundingRect, 100);
                else
                    currentTargetCoords = mp(:);
                    currentTargetBoundingRect = [currentTargetCoords - double(data.targetDiameter)/2; ...
                        currentTargetCoords + double(data.targetDiameter)/2];
                    Screen('FillOval', whichScreen, [100 100 100], currentTargetBoundingRect, 100);
                end
            else
                if ~data.recentering && (data.currentTarget < data.numTargets) && inMoveState
                    Screen('TextSize',whichScreen, 80);
                    Screen('DrawText', screenParams.whichScreen, symbolVector(data.currentSymbolSet(data.currentTarget)), mp(1)-50, mp(2)-200, [255 255 255]); 
                end
            end
            
            %plot key
            if ~data.cognitiveVMRMode 
                if ~all(data.currentSymbolSet==0) && m.packetType~=SymbolStates.STATE_READY
                    for x=1:length(data.currentSymbolSet)
                        keyIdx = keyOrder(x);
                        Screen('TextSize',whichScreen, 40);
                        Screen('DrawText', screenParams.whichScreen, textKey{keyIdx}, mp(1)-950, mp(2)+90*x-400, [255 255 255]); 

                        Screen('TextSize',whichScreen, 80);
                        Screen('DrawText', screenParams.whichScreen, symbolVector(data.currentSymbolSet(keyIdx)), mp(1)-600, mp(2)+90*x-400, [255 255 255]); 
                    end
                    %Screen('DrawText', screenParams.whichScreen, symbolVector(data.currentSymbolSet), mp(1)-700, mp(2)+450, [255 255 255]); 
                end
            end
            
            %test to make sure all symbols appear correctly
%             plotIdx = 1:10;
%             for x=1:10
%                 Screen('DrawText', screenParams.whichScreen, symbolVector(plotIdx), mp(1)-200, mp(2)-400+(x*50), [255 255 255]); 
%                 plotIdx = plotIdx+10;
%             end
                
            %%
            %score
            Screen('TextSize',whichScreen, 50);
            if ~isnan(data.acqTimeScore)
                Screen('DrawText', screenParams.whichScreen, num2str(double(data.acqTimeScore)/1000,'%0.2f'), mp(1)+500, mp(2)-450, [255 255 255]);    
            end
            
            %%
            green = [00 204 00];
            orange = [255 133 0];
            red = [204 0 0];
            cursorOutline=3; %% in pixels

            switch m.packetType
                case SymbolStates.STATE_INIT
                case SymbolStates.STATE_READY
                    Screen('DrawText', screenParams.whichScreen, ['Get Ready (' num2str(double(data.countdownTimer)/1000,'%0.0f') ')'], mp(1)-185, mp(2)-250, [255 255 255]);    
                case SymbolStates.STATE_REHEARSE
                    Screen('DrawText', screenParams.whichScreen, ['Rehearse (' num2str(double(data.countdownTimer)/1000,'%0.0f') ')'], mp(1)-185, mp(2)-250, [255 255 255]);    
                case {SymbolStates.STATE_MOVE_ONE, SymbolStates.STATE_MOVE_TWO}
                    if data.lastTarget>0
                        lastTargetCoords = double(data.targPosAll(1:2,data.lastTarget)) + mp(:);
                        lastTargetBoundingRect = [lastTargetCoords - double(data.targetDiameter)/2; ...
                            lastTargetCoords + double(data.targetDiameter)/2];
                        if data.showFailedTarg
                            %show next target in orange
                            nextIdx = data.currentTarget;
                            nextTargetCoords = double(data.targPosAll(1:2,nextIdx)) + mp(:);
                            nextTargetBoundingRect = [nextTargetCoords - double(data.targetDiameter)/2; ...
                                nextTargetCoords + double(data.targetDiameter)/2];
                            Screen('FillOval', whichScreen, orange, nextTargetBoundingRect, 100);
                        else
                            Screen('FillOval', whichScreen, green, lastTargetBoundingRect, 100);
                        end
                    end
                otherwise
                    disp('dont understand this state')
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
