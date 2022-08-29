function sCursor = smoothCursor(cursor, updateRate, prevCursor)
% SMOOTHCURSOR    
% 
% sCursor = smoothCursor(cursor, updateRate, prevCursor)


    filterWidthMult = 3;

    if exist('prevCursor', 'var')
        tCursor = [prevCursor cursor];
        startOfCurData = size(prevCursor, 2) + 1;
    else
        tCursor = cursor;
    end
    
    filterWidth = (floor(updateRate) + 1)*filterWidthMult;

    % smooth
    sCursorX = smooth(tCursor(1,:), filterWidth, 'loess');
    sCursorY = smooth(tCursor(2,:), filterWidth, 'loess');
%    sCursorZ = smooth(tCursor(3,:), filterWidth, 'loess');

    % assign
    sCursor = zeros(2, numel(sCursorX));
    sCursor(1,:) = sCursorX;
    sCursor(2,:) = sCursorY;
%    sCursor(3,:) = sCursorZ;

    % truncate previous data
    if exist('prevCursor', 'var')
        sCursor = sCursor(:, floor(startOfCurData - filterWidth/10) : floor(end - filterWidth/10));
    end
