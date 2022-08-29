function drawPauseButton(params, rect)
paddingxy = params.paddingxy;
stroke = params.keyStroke;
arcpercxy = params.arcpercxy;

keyFgColor = params.keyFgColor;
keyBgColor = params.keyBgColor;
textColor = params.textColor;

%% outerRect is the outline going around the entire region, minus any padding
outerRect = rect + paddingxy(1)*[1 0 -1 0] + paddingxy(2)*[0 1 0 -1];

%% we are just going to draw a fixed-size 
xoffset = 40;
yoffset = 35;
barWidth = 32;
barSpacing = 55;

bar1p1 = outerRect(1:2) +[xoffset yoffset];
bar1p2 = outerRect([1 4]) +[xoffset -yoffset];
bar1p3 = bar1p2; bar1p3(1) = bar1p3(1) + barWidth;
bar1p4 = bar1p1; bar1p4(1) = bar1p4(1) + barWidth;
bar1p5 = bar1p1;

bar1 = [bar1p1; bar1p2; bar1p3; bar1p4; bar1p5];

bar2 = bar1;
bar2(:, 1) = bar2(:, 1) + barSpacing;

Screen('FillPoly', params.whichScreen, textColor, bar1);
Screen('FillPoly', params.whichScreen, textColor, bar2);
