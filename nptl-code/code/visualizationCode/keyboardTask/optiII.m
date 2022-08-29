function q = optiII()

	q.keyboardType = uint8(keyboardConstants.KEYBOARD_OPTIII);
	
    keysStartY = 1/6;
    totalHeight = 1/6;
    buttonHeight = totalHeight;
    totalWidth = 1/6;
    buttonWidth = totalWidth;
	
    hSpace = totalWidth - buttonWidth;
    textXOffset = 0.06;
    iTextOffset = 0.07; %% yes this is as stupid as it sounds.
    deleteTextOffset = 0.025;
    textYOffset = 0.063;
    
    
    
    trStartX = 0;
    trStartY = 1/6 *0.4;
    q.textRegion = [trStartX trStartY trStartX+(totalWidth)*6 trStartY+buttonHeight/2];

	
	
    for nrow = 1:5
		switch nrow
			case 1
				rows(1).letters = 'qkcgvj';
			case 2
				rows(2).letters = [8 'sind '];
			case 3
				rows(3).letters = 'wtheam';
			case 4
				rows(4).letters = [' uorl' 8];
			case 5
				rows(5).letters = 'zbfypx';
		end
		
        rows(nrow).xstart = 0;
        rows(nrow).ystart = keysStartY+totalHeight*(nrow-1);
    end
	

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
            q.keys(numKeys).textY = q.keys(numKeys).y+textYOffset;
            q.keys(numKeys).ID = uint16(numKeys);
            q.keys(numKeys).width = buttonWidth;
            q.keys(numKeys).height = buttonHeight;
            q.keys(numKeys).type = uint8(keyboardConstants.KEY_TYPE_LETTER);
            q.keys(numKeys).regionShape = uint8(keyboardConstants.SHAPE_RECT);
            q.keys(numKeys).displayShape = uint8(keyboardConstants.SHAPE_ROUNDED_RECT);
            currentX = currentX+buttonWidth+hSpace;
			if q.keys(numKeys).text == uint8(8) % backspace
			    q.keys(numKeys).type = uint8(keyboardConstants.KEY_TYPE_BACKSPACE);
                q.keys(numKeys).textX = q.keys(numKeys).x+deleteTextOffset;
            elseif q.keys(numKeys).text == uint8(' ') % space
			    q.keys(numKeys).type = uint8(keyboardConstants.KEY_TYPE_SPACE);
            elseif q.keys(numKeys).text == uint8('i') % I
                q.keys(numKeys).textX = q.keys(numKeys).x+iTextOffset;
			end
	    end
    end

    %% CP, 2014-07-29
    % add start/stop key for free typing
    numKeys = numKeys+1;
    % key will live on the bottom right of the keyboard
    q.keys(numKeys).x = 1+buttonWidth/5;
    % parallel to last row
    q.keys(numKeys).y = currentY;
    q.keys(numKeys).text = uint8(keyboardConstants.KEY_INDEX_STARTSTOP);
    q.keys(numKeys).textX = q.keys(numKeys).x+0.001;%textXOffset;
    q.keys(numKeys).textY = q.keys(numKeys).y;%textYOffset;
    q.keys(numKeys).ID = uint16(numKeys);
    q.keys(numKeys).width = buttonWidth;
    q.keys(numKeys).height = buttonHeight;
    q.keys(numKeys).type = uint8(keyboardConstants.KEY_TYPE_STARTSTOP);
    q.keys(numKeys).regionShape = uint8(keyboardConstants.SHAPE_RECT);
    q.keys(numKeys).displayShape = uint8(keyboardConstants.SHAPE_ROUNDED_RECT);
	
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