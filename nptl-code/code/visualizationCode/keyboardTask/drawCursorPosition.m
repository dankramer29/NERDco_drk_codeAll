function drawCursorPosition(sps, whichScreen, cursorPos, cursorDiam, cursorColor)
    global isCursorShowing
%  if between(cursorPos(1),sps.xstart+[0 sps.width]) && between(cursorPos(2),sps.ystart+[0 sps.height])
    if between(cursorPos(1),[0 sps.width]) && between(cursorPos(2),[0 sps.height])
        if isCursorShowing
            HideCursor();
            isCursorShowing = false;
        end
        cursorBoundingRect = [cursorPos(:) - cursorDiam/2; cursorPos(:)+cursorDiam/2];
        Screen('FillOval', whichScreen, cursorColor, cursorBoundingRect, 100);
    else
        if ~isCursorShowing
            ShowCursor();
            isCursorShowing = true;
        end
    end
