function q = gridTaskGenerator(GRID_X, GRID_Y)
	
	% set dummies for order
	q.keyboardType = [];
	q.textRegion = [];
	
    keysStartY = 0;
    totalHeight = 1/GRID_Y;
    buttonHeight = totalHeight;
    totalWidth = 1/GRID_X;
    buttonWidth = totalWidth;
    hSpace = totalWidth - buttonWidth;
    textXOffset = 0.04;
    textYOffset = 0.07;

    for nrow = 1:GRID_Y
        rows(nrow).letters = char([1:GRID_X]+GRID_X*(nrow-1))+'0';
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
            q.keys(numKeys).displayShape = uint8(keyboardConstants.SHAPE_RECT);
            currentX = currentX+totalWidth;
        end
    end
    
    
    %% set the size of the struct to a fixed size regardless of the number of keys
    %% this allows variability across keyboard designs
    [q.keys(1:end).numKeys] = deal(numKeys);
    keyFields = fields(q.keys);
    for nn = numKeys+1:double(keyboardConstants.MAX_NUM_KEYS)
        for nf = 1:numel(keyFields)
            q.keys(nn).(keyFields{nf})=0;
        end
    end
    
	q = gridPresentation(q);
    
end
