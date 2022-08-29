function drawStopButton(params, rect)
paddingxy = params.paddingxy;
stroke = params.keyStroke;
arcpercxy = params.arcpercxy;

keyFgColor = params.keyFgColor;
keyBgColor = params.keyBgColor;
textColor = params.textColor;

%% outerRect is the outline going around the entire region, minus any padding
outerRect = rect + paddingxy(1)*[1 0 -1 0] + paddingxy(2)*[0 1 0 -1];

%% we are just going to draw a fixed-size 
xoffset = 50;
yoffset = xoffset;
Screen('FillRect',params.whichScreen,textColor,outerRect +[xoffset yoffset -xoffset -yoffset]);

%xoffset = 45;
%yoffset = xoffset;
%Screen('FillRect',params.whichScreen,keyBgColor,outerRect +[xoffset yoffset -xoffset -yoffset]);
