function fliptime = keyboardSetupScreen(data)
    global taskParams;
    %% all the relevant info is in the "data" field of the packet, deconstruct it
    tpadding = 5;
    ctpadding = 5; %% cued text padding
    cuedDims = [1500 70];
    cursorOutline=3; %% in pixels

    
    switch taskParams.engineType
        case EngineTypes.VISUALIZATION
            packetType = data.state;
            
            % do vizualiation in PsychToolbox. This is what NPTL used
            % for 2D, and is currently a faux-3D dev crutch for 3D
            dims = double(data.keyboardDims);
            
            global screenParams;
            global keyboards;
            mp = screenParams.midpoint; % for faux-3D depth
            
            
            if ~isfield(screenParams,'drawn') || ~screenParams.drawn
                screenParams.drawn = false;
                screenParams.lastResetTime = 0;
                screenParams.lastResetTime = uint32(0);
                screenParams.rightBoundExtra = 0; %% if the keyboard overflows past "dimensions" how many extra pixels
            end
            
            %% check to make sure an offscreen keyboard has been created...
            %%   and that it matches the requested keyboard
            if data.cuedTextLength <= length(data.cuedText)
                cuedText = char(data.cuedText(1:data.cuedTextLength));
                if isfield(screenParams,'q'), q = screenParams.q; else q = struct(); end
                %% do we need to redraw the top text block?
                if data.cuedTextLength && data.showCueOffTarget && ...
                        (~isfield(q,'cuedTextLength') || data.cuedTextLength ~= q.cuedTextLength || ~strcmp(cuedText, q.drawnText))
                    screenParams.drawn = false;
                    disp('cued text changed - redrawing');
                end
            end
            
            if ~screenParams.drawn && data.resetDisplay && screenParams.lastResetTime ~= data.lastResetTime
                screenParams.lastResetTime = data.lastResetTime;
                sca();
                initializeKeyboard();
                %% select the right keyboard
                q = keyboards(data.keyboard);
                q.showBackspace = data.showBackspace;
                q.showStartStop = data.showStartStop;
                q.showCueOnTarget = data.showCueOnTarget;
                q.showCueOffTarget = data.showCueOffTarget;
                q.showTargetText = data.showTargetText;
                q.showTypedText = data.showTypedText;
                q.cuedTextLength = data.cuedTextLength;
                q.drawnText = '';
                
                %% make a special provision for opti
                if data.keyboard == keyboardConstants.KEYBOARD_OPTIII || data.keyboard == keyboardConstants.KEYBOARD_OPTIFREE
                    screenParams.rightBoundExtra = 167*2;
                end
                
                %% draw the keyboard on the offscreen window (#1)
                % set some screen parameters
                Screen('TextFont',screenParams.offScreen(1).screen, q.textFont); %Courier New
                Screen('TextSize',screenParams.offScreen(1).screen, q.textSize);
                Screen('TextStyle',screenParams.offScreen(1).screen, q.textStyle);
                drawKeyboard(dims,screenParams.offScreen(1).screen, q, '');
                screenParams.offScreen(1).drawn = data.keyboard;
                screenParams.offScreen(1).keyboardDims = dims;
                
                %% draw the "Over" keyboard on the offscreen window (#2)
                % set some screen parameters
                Screen('TextFont',screenParams.offScreen(2).screen, q.textFont); %Courier New
                Screen('TextSize',screenParams.offScreen(2).screen, q.textSize);
                Screen('TextStyle',screenParams.offScreen(2).screen, q.textStyle);
                drawKeyboard(dims,screenParams.offScreen(2).screen, q, 'Over');
                
                %% draw the "Pressed" keyboard on the offscreen window (#3)
                % set some screen parameters
                Screen('TextFont',screenParams.offScreen(3).screen, q.textFont); %Courier New
                Screen('TextSize',screenParams.offScreen(3).screen, q.textSize);
                Screen('TextStyle',screenParams.offScreen(3).screen, q.textStyle);
                drawKeyboard(dims,screenParams.offScreen(3).screen, q, 'Pressed');
                
                %% draw the "Cued" keyboard on the offscreen window (#4)
                % set some screen parameters
                Screen('TextFont',screenParams.offScreen(4).screen, q.textFont); %Courier New
                Screen('TextSize',screenParams.offScreen(4).screen, q.textSize);
                Screen('TextStyle',screenParams.offScreen(4).screen, q.textStyle);
                drawKeyboard(dims,screenParams.offScreen(4).screen, q, 'Cued');
                
                %% draw the "OverCued" keyboard on the offscreen window (#5)
                % set some screen parameters
                Screen('TextFont',screenParams.offScreen(5).screen, q.textFont); %Courier New
                Screen('TextSize',screenParams.offScreen(5).screen, q.textSize);
                Screen('TextStyle',screenParams.offScreen(5).screen, q.textStyle);
                drawKeyboard(dims,screenParams.offScreen(5).screen, q, 'OverCued');
                
                if q.showTypedText
                    if data.keyboard == keyboardConstants.KEYBOARD_OPTIFREE
                        tpadding = 4;
                    end
                    %% offscreen 6 is for text
                    screenParams.offScreen(6).screen = Screen('OpenOffscreenWindow',...
                        0,q.textRegBgColor,...
                        [0 0 ((q.textRegion(3)-q.textRegion(1)) * dims(3)+tpadding*2)*screenParams.multisample ...
                        ((q.textRegion(4)-q.textRegion(2)) * dims(4)+tpadding*2)*screenParams.multisample],...
                        [],[],screenParams.multisample);
                    Screen('TextFont',screenParams.offScreen(6).screen, q.typedFont); %Courier New
                    if data.keyboard == keyboardConstants.KEYBOARD_OPTIFREE
                        %% make the font slightly larger for "free typing"
                        Screen('TextSize',screenParams.offScreen(6).screen, q.textSize+9);
                    else
                        Screen('TextSize',screenParams.offScreen(6).screen, q.textSize+5);
                    end
                    Screen('TextStyle',screenParams.offScreen(6).screen, q.typedStyle);
                    
                end
                
                if q.showCueOffTarget
                    %% offscreen 7 is for cued text
                    ms2 = 1;
                    cuedWinRect = [0 0 (cuedDims(1)-ctpadding*2)*ms2 ...
                        (cuedDims(2)-ctpadding*2)*ms2];
                    cuedWinScreenRect = [0 0 (cuedDims(1))*ms2 ...
                        (cuedDims(2))*ms2];
                    screenParams.offScreen(7).screen = Screen('OpenOffscreenWindow',...
                        0,screenParams.backgroundIndexColor,...
                        cuedWinScreenRect,...
                        [],[],ms2);
                    Screen('TextFont',screenParams.offScreen(7).screen, q.textFont);
                    Screen('TextSize',screenParams.offScreen(7).screen, 40);
                    Screen('TextStyle',screenParams.offScreen(7).screen, 0);
                end
                if data.cuedTextLength <= length(data.cuedText)
                    %% process the cued data sequence
                    cuedText = char(data.cuedText(1:data.cuedTextLength));
                    if q.showCueOffTarget && (data.cuedTextLength && (~isfield(q,'drawnTextLength') ...
                            || data.cuedTextLength ~= q.drawnTextLength || ~strcmp(cuedText, q.drawnText)))
                        
                        % uppercase first letter of first word
                        cuedText(1) = upper(cuedText(1));
                        cuedText = WrapString(cuedText,80);
                        % draw the text
                        %[nx,ny,bbox]=DrawFormattedText(screenParams.offScreen(7).screen,cuedText,...
                        %    ctpadding, ctpadding, screenParams.white, 60);
                        [nx,ny,bbox]=DrawFormattedText(screenParams.offScreen(7).screen, cuedText,...
                            'center', 'center', screenParams.white, 85,0,0,1,0);
                        q.drawnText = char(data.cuedText(1:data.cuedTextLength));
                        q.cuedTextLength = data.cuedTextLength;
                    end
                else
                    disp('data.cuedTextLength is longer than data.cuedText...')
                end
                %% set screen parameters on onscreen window
                Screen('TextFont',screenParams.whichScreen, q.textFont); %Courier New
                Screen('TextSize',screenParams.whichScreen, q.textSize + 5);
                Screen('TextStyle',screenParams.whichScreen, q.textStyle);
                Screen('HideCursorHelper', screenParams.whichScreen);
                
                screenParams.q = q;
                screenParams.drawn = true;
                
                %                 if (GetSecs() - screenParams.drawnTime) < 5
                %                     %% show the block number
                DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',10,screenParams.white);
                %                 end
                
                [vblts SOT FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
                taskParams.lastPacketTime = GetSecs();
                screenParams.drawnTime = GetSecs();
            end
            
            if ~screenParams.drawn || GetSecs() - screenParams.drawnTime < 4
                fliptime = 0;
                return
            end
            switch packetType
                case KeyboardStates.STATE_END
                    taskParams.quit = true;
                    screenParams.drawn = false;
                    fliptime = 0;
                otherwise
                    q = screenParams.q;
                    %% blank the screen
                    Screen('FillRect', screenParams.whichScreen, [0 0 0]);
                    
                    % copy the background from the offscreen window
                    copyDimensions = [0 0 dims(1:2)+[screenParams.rightBoundExtra 0]];
                    Screen('CopyWindow',screenParams.offScreen(1).screen,screenParams.whichScreen, dims+copyDimensions, dims+copyDimensions);
                    
                    if q.showCueOnTarget && data.cuedTextLength && data.overCuedTarget
                        nkey = data.overCuedTarget;
                        border = getKeyBorder(nkey, q, dims);
                        Screen('CopyWindow',screenParams.offScreen(5).screen,screenParams.whichScreen, border, border);
                    elseif q.showCueOnTarget && data.cuedTextLength && data.cuedTarget
                        nkey = data.cuedTarget;
                        border = getKeyBorder(nkey, q, dims);
                        Screen('CopyWindow',screenParams.offScreen(4).screen,screenParams.whichScreen, border, border);
                    end
                    
                    %% don't cue the targets, or we're over the wrong target
                    if data.overTarget && (~q.showCueOnTarget || ~data.cuedTextLength || (data.overCuedTarget ~= data.overTarget))
                        nkey = data.overTarget;
                        border = getKeyBorder(nkey, q, dims);
                        Screen('CopyWindow',screenParams.offScreen(2).screen,screenParams.whichScreen, border, border);
                    end
                    
                    %% special provision for start/stop key
                    if q.showStartStop
                        if data.state == KeyboardStates.STATE_INACTIVE
                            nkey = find([q.keys.text] == uint8(keyboardConstants.KEY_INDEX_STARTSTOP));
                            border = getKeyBorder(nkey, q, dims);
                            Screen('CopyWindow',screenParams.offScreen(4).screen,screenParams.whichScreen, border, border);
                        else
                            nkey = find([q.keys.text] == uint8(keyboardConstants.KEY_INDEX_STARTSTOP));
                            border = getKeyBorder(nkey, q, dims);
                            Screen('CopyWindow',screenParams.offScreen(3).screen,screenParams.whichScreen, border, border);
                        end
                    end
                    
                    cursorColor = data.cursorColor;
                    %% if in the "pressed" state, copy the recently selected key
                    if data.state == KeyboardStates.STATE_KEY_PRESSED
                        %% copy the selected target over
                        nkey = data.selectedTarget;
                        border = getKeyBorder(nkey, q, dims);
                        Screen('CopyWindow',screenParams.offScreen(3).screen,screenParams.whichScreen, border, border);
                        
                        %% switch cursor color based on last acquire method
                        if data.lastAcquireMethod == uint8(keyboardConstants.ACQUIRE_DWELL)
                            %cursorColor = [242 97 0]'; %% orange
                            %cursorColor = [242 145 0]'; %% orange
                            cursorColor = [180 100 180]'; %% magenta-red
                            
                        elseif data.lastAcquireMethod == uint8(keyboardConstants.ACQUIRE_CLICK)
                            %cursorColor = [0 145 242]'; %% blue
                            %cursorColor = [0 97 242]'; %% blue
                            %cursorColor = [210 210 30]'; %% yellow
                            cursorColor = [200 90 50]'; %% orangey
                        end
                    end
                    
                    if q.showCueOffTarget
                        if isfield(screenParams,'drawnTextLength') && screenParams.drawnTextLength
                            try
                                cuedX = screenParams.midpoint(1) - cuedDims(1)/2;
                                cuedY = cuedDims(2)/2;
                                Screen('CopyWindow',screenParams.offScreen(7).screen,screenParams.whichScreen,...
                                    [0 0 cuedDims(1) cuedDims(2)], [cuedX cuedY cuedX+cuedDims(1) cuedY+cuedDims(2)]);
                            catch
                                sca;
                                keyboard;
                            end
                        end
                    end
                    %% process the typed text sequence
                    if q.showTypedText
                        ts = char(data.textSequence);
                        ts(1) = upper(ts(1));
                        ts(double(data.textInd)) = '_';
                        ts = ts(1:double(data.textInd));
                        
                        % uppercase first letter of first word after any '.'
                        periods = find(ts == '.');
                        for periodsCtr = periods
                            if periodsCtr + 2 <= numel(ts)
                                ts(periodsCtr + 2) = upper(ts(periodsCtr + 2));
                            end
                        end
                        
                        
                        %% fixing max chars per line for monospace
                        maxCharsPerLine = 26;
                        linesToKeep = 2;
                        % get the last N lines
                        ts = WrapString(ts,maxCharsPerLine);
                        %% trim down to last N lines. '\n' is uint8(10)
                        slashes = find(uint8(ts)==10);
                        if numel(slashes)>=linesToKeep
                            ts = ts(slashes(end-(linesToKeep-1))+1:end);
                        end
                        
                        % blank the offscreen window
                        Screen('FillRect', screenParams.offScreen(6).screen, q.textRegBgColor);
                        
                        
                        typedTextVertSpacing = 1;
                        if data.keyboard == keyboardConstants.KEYBOARD_OPTIFREE
                            typedTextVertSpacing = 1.1;
                        end
                        % draw the text
                        [nx,ny,bbox]=DrawFormattedText(screenParams.offScreen(6).screen,ts,...
                            tpadding, tpadding, screenParams.white, [], 0, 0, typedTextVertSpacing);
                        
                        %% desired height and width
                        desiredTextHeight = floor((q.textRegion(4)-q.textRegion(2)) * dims(4)-tpadding*2);
                        desiredTextWidth = floor((q.textRegion(3)-q.textRegion(1)) * dims(3)-tpadding*2);
                        
                        bbox = round(bbox);
                        %% trim or enlarge this rectangle as needed
                        if bbox(3) < tpadding+desiredTextWidth
                            bbox(3) = tpadding+desiredTextWidth;
                        end
                        if bbox(4) < tpadding+desiredTextHeight
                            bbox(4) = tpadding+desiredTextHeight;
                        end
                        if bbox(3) - bbox(1) > desiredTextWidth
                            bbox(1) = bbox(3)-desiredTextWidth;
                        end
                        if bbox(4) - bbox(2) > desiredTextHeight
                            bbox(2) = bbox(4)-desiredTextHeight;
                        end
                        inbox=ceil([bbox(1)-tpadding bbox(2)-tpadding bbox(3)+tpadding bbox(4)+tpadding]);
                        
                        outxstart = floor(q.textRegion(1)*dims(3)+dims(1));
                        outystart = floor(q.textRegion(2)*dims(4)+dims(2));
                        outbox = ceil([outxstart outystart outxstart+desiredTextWidth+tpadding*2 outystart+desiredTextHeight+tpadding*2]);
                    end
                    
                    try
                        %% if typed text is being displayed
                        if q.showTypedText
                            Screen('CopyWindow',screenParams.offScreen(6).screen,screenParams.whichScreen,...
                                inbox, outbox);
                        end
                        
                    catch
                        e=lasterror;
                        disp(e.message);
                        disp(e.identifier);
                        disp(bbox);
                        disp(inbox);
                        disp(outbox);
                        error('argh');
                    end
                    
                    try
                        %% if cued text is being displayed
                        if q.showCueOffTarget
                            cuedX = screenParams.midpoint(1) - cuedDims(1)/2;
                            cuedY = cuedDims(2)/2;
                            Screen('CopyWindow',screenParams.offScreen(7).screen,screenParams.whichScreen,...
                                [0 0 cuedDims(1) cuedDims(2)], [cuedX cuedY cuedX+cuedDims(1) cuedY+cuedDims(2)]);
                        end
                    catch
                        e=lasterror;
                        disp(e.message);
                        disp(e.identifier);
                        disp([0 0 cuedDims(1) cuedDims(2)]);
                        disp([cuedX cuedY cuedX+cuedDims(1) cuedY+cuedDims(2)]);
                        error('cued text display argh');
                    end
                    
                    
                    cursorPos = double(data.cursorPosition(1:3)); % 1:2 for 2d, 3 is z for faux-3D
                    
                    
                    
                    
                    %% draw the cursor
                    %drawCursorPosition(screenParams,screenParams.whichScreen,...
                    %    cursorPos, double(data.cursorDiameter), data.cursorColor);
                    
                    drawCursorWithBorder(screenParams,screenParams.whichScreen,...
                        cursorPos, double(data.cursorDiameter), cursorColor, cursorOutline);
                    
                    
                    %% use synchronous flips... for now
                    [vblts SOT FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
                    %         [vblts SOT FTS]=Screen('AsyncFlipBegin', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
                    fliptime = FTS - taskParams.startTime;%toc(taskParams.startTime);
            end
            
            
            
      case EngineTypes.SOUND
        global soundParams;
        flipTime = 0;
        if data.lastSoundTime ~= soundParams.lastSoundTime
            soundParams.lastSoundTime = data.lastSoundTime;
            m.packetType = data.lastSoundState;
            switch m.packetType
                case KeyboardStates.SOUND_STATE_CLICK
                    if data.acquireMethod == uint8(keyboardConstants.ACQUIRE_CLICK)
                        PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.clickSound);
                        PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                    elseif data.acquireMethod == uint8(keyboardConstants.ACQUIRE_DWELL)
                        PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.dwellSound);
                        PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                    end
                case KeyboardStates.SOUND_STATE_ERROR
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.failSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case KeyboardStates.SOUND_STATE_OVER_TARGET
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.overSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
            end
        end
        fliptime = GetSecs()-taskParams.startTime;
    end


