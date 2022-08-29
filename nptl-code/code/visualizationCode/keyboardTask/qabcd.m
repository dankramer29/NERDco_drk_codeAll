function q= qwerty2()
    q.keyboardType = uint8(keyboardConstants.KEYBOARD_QABCD);
    keysStartY = 0.25;
    totalHeight = 0.18;
    buttonHeight = totalHeight;%0.14;%0.18;
    vSpace = totalHeight - buttonHeight; % 0.15*totalHeight;%0.04;
    totalWidth = 0.10;
    buttonWidth = totalWidth;% 0.07;%0.1;
    hSpace = totalWidth - buttonWidth; %0.15*totalWidth;%0.02;
    textXOffset = 0.035;
    iTextOffset = 0.047; %% yes this is as stupid as it sounds.
    textYOffset = 0.07;

    trStartX = buttonWidth+hSpace;
    trStartY = 0.03;
    q.textRegion = [trStartX trStartY trStartX+(buttonWidth+hSpace)*8-hSpace trStartY+buttonHeight];

    rows(1).letters = 'abcdefghij';
    rows(1).xstart = 0;
    rows(1).ystart = keysStartY;
    
    rows(2).letters = 'klmnopqrs';
    rows(2).xstart = (buttonWidth+hSpace)*0.5;
    rows(2).ystart = (buttonHeight+vSpace)+rows(1).ystart;
    
    rows(3).letters = 'tuvwxyz';
    rows(3).xstart = (buttonWidth+hSpace)*1.5;
    rows(3).ystart = (buttonHeight+vSpace)+rows(2).ystart;
    
    numKeys = 0;
    for nr = 1:length(rows)
        currentX = rows(nr).xstart;
        currentY = rows(nr).ystart;
        for nn = 1:length(rows(nr).letters)
            numKeys = numKeys+1;
            q.keys(numKeys).x = currentX;
            q.keys(numKeys).y = currentY;
            q.keys(numKeys).text = uint8(rows(nr).letters(nn));
            q.keys(numKeys).textX = q.keys(numKeys).x+textXOffset;
            if q.keys(numKeys).text == uint8('i') % special offset for I
                q.keys(numKeys).textX = q.keys(numKeys).x+iTextOffset;
			end
            
            q.keys(numKeys).textY = q.keys(numKeys).y+textYOffset;
            q.keys(numKeys).ID = uint16(numKeys);
            q.keys(numKeys).width = buttonWidth;
            q.keys(numKeys).height = buttonHeight;
            q.keys(numKeys).type = uint8(keyboardConstants.KEY_TYPE_LETTER);
            q.keys(numKeys).regionShape = uint8(keyboardConstants.SHAPE_RECT);
            q.keys(numKeys).displayShape = uint8(keyboardConstants.SHAPE_ROUNDED_RECT);
            currentX = currentX+buttonWidth+hSpace;
        end
    end
    
    currentX = 0; %(buttonWidth+hSpace)*2;
    currentY = (buttonHeight +vSpace) + rows(3).ystart;

    % add a space
    numKeys = numKeys+1;
    q.keys(numKeys).x = currentX;
    q.keys(numKeys).y = currentY;
    q.keys(numKeys).text = uint8(' ');
    q.keys(numKeys).textX = q.keys(numKeys).x+textXOffset;
    q.keys(numKeys).textY = q.keys(numKeys).y+textYOffset;
    q.keys(numKeys).ID = uint16(numKeys);
    q.keys(numKeys).width = 7 * (buttonWidth+hSpace)-hSpace;
    q.keys(numKeys).height = buttonHeight;
    q.keys(numKeys).type = uint8(keyboardConstants.KEY_TYPE_SPACE);
    q.keys(numKeys).regionShape = uint8(keyboardConstants.SHAPE_RECT);
    q.keys(numKeys).displayShape = uint8(keyboardConstants.SHAPE_ROUNDED_RECT);
    currentX = currentX+q.keys(numKeys).width+hSpace;
    
    % add a backspace
    numKeys = numKeys+1;
    q.keys(numKeys).x = currentX;
    q.keys(numKeys).y = currentY;
    q.keys(numKeys).text = uint8(8);
    q.keys(numKeys).textX = q.keys(numKeys).x+textXOffset + 0.07;
    q.keys(numKeys).textY = q.keys(numKeys).y+textYOffset + 0.009;
    q.keys(numKeys).ID = uint16(numKeys);
    q.keys(numKeys).width = 3 * (buttonWidth+hSpace);
    q.keys(numKeys).height = buttonHeight;
    q.keys(numKeys).type = uint8(keyboardConstants.KEY_TYPE_BACKSPACE);
    q.keys(numKeys).regionShape = uint8(keyboardConstants.SHAPE_RECT);
    q.keys(numKeys).displayShape = uint8(keyboardConstants.SHAPE_ROUNDED_RECT);
    currentX = currentX+(buttonWidth+hSpace);
    
    %% set the size of the struct to a fixed size regardless of the number of keys
    %% this allows variability across keyboard designs
    [q.keys(1:end).numKeys] = deal(numKeys);
    keyFields = fields(q.keys);
    for nn = numKeys+1:double(keyboardConstants.MAX_NUM_KEYS)
        for nf = 1:numel(keyFields)
            q.keys(nn).(keyFields{nf})=0;
        end
    end
        
	q = keyboardPresentation(q);
	
end
