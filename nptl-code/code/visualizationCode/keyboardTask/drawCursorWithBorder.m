function drawCursorWithBorder(sps, whichScreen, cursorPos, cursorDiam, cursorColor,cursorOutline)
    global isCursorShowing
    if between(cursorPos(1),[0 sps.width]) && between(cursorPos(2),[0 sps.height])
        if isCursorShowing
            HideCursor();
            isCursorShowing = false;
        end
        cursorBoundingRect = [cursorPos(1:2) - cursorDiam/2; cursorPos(1:2)+ cursorDiam/2];
        cursorBoundingRect2 = [cursorPos(1:2) - (cursorDiam/2-cursorOutline); cursorPos(1:2)+(cursorDiam/2-cursorOutline)];
        %Screen('FillOval', whichScreen, cursorColor, cursorBoundingRect , 20);
        %Screen('FillOval', whichScreen, [cursorColor(:)*0.2 cursorColor(:)], [cursorBoundingRect cursorBoundingRect2], 100);
       % Screen('FillOval', whichScreen, [cursorColor(:)*0.2 cursorColor(:)], [cursorBoundingRect cursorBoundingRect2], 300); %SF
        Screen('FillOval', whichScreen, [ cursorColor(:)], [cursorBoundingRect cursorBoundingRect2], 300); %SF
    else
        if ~isCursorShowing
            ShowCursor();
            isCursorShowing = true;
        end
    end
