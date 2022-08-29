function DrawTargets(window,width,height,posx,posy)
%
%
% CC - 6th November 2011 - Draw a fixation cross at Screen center.

if nargin < 3
    [width, height]=Screen('WindowSize', window);
    if nargin < 1
        error('No window provided');
    end
end

xc = width/2;
yc = height/2;
Screen(window,'FillOval', [0 128 0],[xc-posx-20 posy-20 xc-posx+20 posy+20]);
Screen(window,'FillOval', [128 0 0],[xc+posx-20 posy-20 xc+posx+20 posy+20]);
