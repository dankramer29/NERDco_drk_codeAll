function target = isCursorOverTarget(keys,cursorPos,dims, showBackspace, showStartStop)
% ISCURSOROVERTARGET    
% 
% target = isCursorOverTarget(keys,cursorPos,dims, showBackspace)
%  keys - e.g. 'keys' field from keyboard definition in allKeyboards
%  cursorPos - cursor position in pixels
%  dims - [xstart ystart width height] of keyboard
%  showBackspace - was backspace allowed?

    target = uint16(0);
    for nkey = 1:keys.numKeys(1)
        if keys.type(nkey)== keyboardConstants.KEY_TYPE_BACKSPACE && ~showBackspace
            continue
        end
        if keys.type(nkey)== keyboardConstants.KEY_TYPE_STARTSTOP && ~showStartStop
            continue
        end
        switch keys.regionShape(nkey)
          case keyboardConstants.SHAPE_RECT
            border = double([keys.x(nkey) keys.y(nkey) ...
                      keys.x(nkey)+keys.width(nkey) keys.y(nkey)+keys.height(nkey)]);
            border([1 3]) = border([1 3]) * double(dims(3))+double(dims(1));
            border([2 4]) = border([2 4]) * double(dims(4))+double(dims(2));
            if cursorPos(1) >= border(1) && cursorPos(1) < border(3) &&...
                    cursorPos(2) >= border(2) && cursorPos(2) < border(4)
                target = uint16(keys.ID(nkey));
                break;
            end
            
        end
    end
    