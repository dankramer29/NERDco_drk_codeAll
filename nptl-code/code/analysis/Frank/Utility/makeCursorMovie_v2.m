function M = makeCursorMovie_v2( cursorXY, targXY, targList, cursorColor, targColor, cursorRad, ...
    targRad, extraCursors, playMovie, fps, xLim, yLim, inTarget, bgColor )

    %a function that makes it easier to call circleMovie to make a video of
    %a cursor moving to targets. This function also makes it easy to
    %display all possible targets in the workspace even if they are not currently
    %the active target, to give the viewer an idea of the extent of the
    %workspace.
    
    %cursorXY is an N x 2 matrix describing the position of the cursor at
    %each time step.
    
    %targXY is an N x 2 matrix describing the position of the target at
    %each time step.
    
    %targList is a T x 2 matrix describing the position of each possible
    %target in the workspace. (for example, T = 8 in the classic center out
    %game).
    
    %cursorColor is a 1 x 3 color vector.
    
    %targColor is a 1 x 3 color vector.
    
    %cursorRad is a scalar radius.
    
    %targRad is a scalar radius.
    
    %extraCursors provides the possibility of displaying more than one
    %cursor. extraCursors is a C x 3 cell array, where C is the number of
    %extra cursors. The first column of the cell array is an N x 2 position
    %matrix, the second is a scalar radius, and the third is a 1 x 3 color
    %vector.
    
    %M is a matrix containing each frame of the movie, which you can play
    %with the movie command
    
    nTargs = size(targList,1);
        
    circleXY = cell(size(extraCursors,1)+nTargs+2,1);
    circleRad = cell(size(extraCursors,1)+nTargs+2,1);
    circleColors = cell(size(extraCursors,1)+nTargs+2,1);
    
    for n=1:nTargs
        circleXY{n} = repmat(targList(n,:),length(cursorXY),1);
        circleRad{n} = repmat(max(targRad),length(cursorXY),1);
        circleColors{n} = repmat([0.1 0.3 0.6] * 0.6,length(cursorXY),1);
    end
    
    circleXY{1+nTargs} = targXY;
    circleRad{1+nTargs} = targRad;
    circleColors{1+nTargs} = repmat(targColor,length(cursorXY),1);
    circleColors{1+nTargs}(inTarget,:) = repmat([1 0.1 0.7],sum(inTarget),1);
    
    if ~isempty(extraCursors)
        for n=1:size(extraCursors,1)
            circleXY{1+n+nTargs} = extraCursors{n,1};
            circleRad{1+n+nTargs} = repmat(extraCursors{n,2}, length(cursorXY),1);
            circleColors{1+n+nTargs} = repmat(extraCursors{n,3}, length(cursorXY),1);
        end
    end
    
    circleXY{size(extraCursors,1)+2+nTargs} = cursorXY;
    circleRad{size(extraCursors,1)+2+nTargs} = cursorRad;
    circleColors{size(extraCursors,1)+2+nTargs} = repmat(cursorColor,length(cursorXY),1);
        

    if playMovie
        playCircleMovie( circleXY, circleRad, circleColors, {xLim, yLim}, fps, bgColor );
        M = [];
    else
        M = circleMovie( circleXY, circleRad, circleColors, {xLim, yLim}, false, fps, bgColor );
    end
end

