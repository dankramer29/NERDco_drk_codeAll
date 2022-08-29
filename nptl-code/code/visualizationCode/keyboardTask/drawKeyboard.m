function drawKeyboard(keyboardDims,whichScreen,q, keyType)
        params = q;
originalBgColor = params.keyBgColor;
originalFgColor = params.keyFgColor;
originalTextColor = params.textColor;

% iterate over keys
    for nr = 1:q.keys(1).numKeys
        if q.keys(nr).type == keyboardConstants.KEY_TYPE_BACKSPACE && ~q.showBackspace
            continue
        end
        if q.keys(nr).type == keyboardConstants.KEY_TYPE_STARTSTOP && ~q.showStartStop
            continue
        end
        
        params = q;
        if ~isempty(keyType)
            eval(['params.keyFgColor = params.keyFgColor' keyType ';']);
            eval(['params.keyBgColor = params.keyBgColor' keyType ';']);
            eval(['params.textColor = params.textColor' keyType ';']);
        end
        
        rect = [q.keys(nr).x q.keys(nr).y 0 0];
        rect(3:4) = rect(1:2) + [q.keys(nr).width q.keys(nr).height];
        
        rect([1 3]) = rect([1 3]) * double(keyboardDims(3))+double(keyboardDims(1));% + screenParams.xstart;
        rect([2 4]) = rect([2 4]) * double(keyboardDims(4))+double(keyboardDims(2));% + screenParams.ystart;
        params.whichScreen = whichScreen;
        params.paddingxy = q.padding + [0 0];
        
        if q.keys(nr).text==uint8(keyboardConstants.KEY_INDEX_STARTSTOP)
            params.keyBgColor = originalBgColor;
            params.keyFgColor = originalFgColor;
            params.textColor = originalTextColor;
        end
        switch q.keys(nr).displayShape
            case uint8(keyboardConstants.SHAPE_ROUNDED_RECT)
                % iterate over letters
                params.arcpercxy = q.arcperc + [0 0];
                drawRoundedButton(params, rect);
            case uint8(keyboardConstants.SHAPE_RECT)
                params.arcpercxy = [0 0];
                drawRoundedButton(params, rect); %% this can be changed to a new function if necessary
        end

        %% if the buttons should be labeled with text
        if q.showTargetText
            textX = q.keys(nr).textX * double(keyboardDims(3))+double(keyboardDims(1));
            textY = q.keys(nr).textY * double(keyboardDims(4))+double(keyboardDims(2));
            switch q.keys(nr).type
                case keyboardConstants.KEY_TYPE_LETTER
                    DrawFormattedText(whichScreen,upper(char(q.keys(nr).text)),...
                        textX,textY,params.textColor);
                case keyboardConstants.KEY_TYPE_BACKSPACE
                    drawBackspace(params, rect);
                    DrawFormattedText(whichScreen,'DEL',...
                        textX,textY,params.textColor);
                case keyboardConstants.KEY_TYPE_STARTSTOP
                    if strcmp(keyType,'Pressed') %% this is the "active" state
                        %drawStopButton(params,rect);
						drawPauseButton(params, rect);
                    elseif strcmp(keyType,'Cued')
                        drawPlayButton(params,rect);
                    end
            end
        end
    end
    
    %% draw the region for typed text
    if q.showTypedText
        Screen('FillRect',params.whichScreen,q.textRegBgColor,q.textRegion .* double([keyboardDims([3 4]) keyboardDims([3 4]) ]) + double([keyboardDims([1 2]) keyboardDims([1 2]) ]));
    end