function drawPlayButton(params, rect)
paddingxy = params.paddingxy;
stroke = params.keyStroke;
arcpercxy = params.arcpercxy;

keyFgColor = params.keyFgColor;
keyBgColor = params.keyBgColor;
textColor = params.textColor;

%% outerRect is the outline going around the entire region, minus any padding
outerRect = rect + paddingxy(1)*[1 0 -1 0] + paddingxy(2)*[0 1 0 -1];

%% we are just going to draw a fixed-size 
xoffset = 45;
yoffset = 35;

point1 = outerRect(1:2) +[xoffset yoffset];
point2 = [outerRect(3)-xoffset mean(outerRect([2 4]))];
point3 = outerRect([1 4]) +[xoffset -yoffset];
point4 = outerRect(1:2) +[xoffset yoffset];

pointList = [point1(:)';point2(:)';point3(:)';point4(:)';]


Screen('FillPoly',params.whichScreen,textColor,...
    pointList);
