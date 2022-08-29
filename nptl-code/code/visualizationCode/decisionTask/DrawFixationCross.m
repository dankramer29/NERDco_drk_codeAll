function DrawFixationCross(window,width,height)
% 
% 
% CC - 6th November 2011 - Draw a fixation cross at screen center.

if nargin < 3
    [width, height]=Screen('WindowSize', window);
    if nargin < 1
        error('No window provided');
    end
end

xc = width/2;
yc = height/2;
fixcrosslinewidth = 2;
fixcrossdim = 20;
Screen(window,'fillrect',[0 0 0],[xc-fixcrosslinewidth/2 yc-fixcrossdim/2 xc+fixcrosslinewidth/2 yc+fixcrossdim/2]);
Screen(window,'fillrect',[0 0 0],[xc-fixcrossdim/2 yc-fixcrosslinewidth/2 xc+fixcrossdim/2 yc+fixcrosslinewidth/2]);
