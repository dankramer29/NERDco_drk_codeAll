function drawRoundedButton(params, rect)

paddingxy = params.paddingxy;
stroke = params.keyStroke;
arcpercxy = params.arcpercxy;

keyFgColor = params.keyFgColor;
keyBgColor = params.keyBgColor;

%% outerRect is the outline going around the entire region, minus any padding
outerRect = rect + paddingxy(1)*[1 0 -1 0] + paddingxy(2)*[0 1 0 -1];
%% innerRect is the outerRect minus stroke length
innerRect = outerRect + [1 1 -1 -1] * stroke;


%% where the rectangles actually stop
solidBoundaryOuter = [(outerRect(3)-outerRect(1))*arcpercxy(1)+outerRect(1) ...
    (outerRect(4)-outerRect(2))*arcpercxy(2)+outerRect(2) ... 
    (outerRect(3)-outerRect(1))*(1-arcpercxy(1))+outerRect(1) ...
    (outerRect(4)-outerRect(2))*(1-arcpercxy(2))+outerRect(2)];
solidBoundaryInner = solidBoundaryOuter + [1 1 -1 -1] * stroke;

arcEdgesOuter = [(outerRect(3)-outerRect(1))*2*arcpercxy(1)+outerRect(1) ...
    (outerRect(4)-outerRect(2))*2*arcpercxy(2)+outerRect(2) ... 
    (outerRect(3)-outerRect(1))*(1-2*arcpercxy(1))+outerRect(1) ...
    (outerRect(4)-outerRect(2))*(1-2*arcpercxy(2))+outerRect(2)];
arcEdgesInner = arcEdgesOuter + [1 1 -1 -1] * stroke;

%% first draw four edges


%% left bar and right bar
Screen('FillRect', params.whichScreen, keyFgColor, [outerRect(1) solidBoundaryOuter(2) outerRect(3) solidBoundaryOuter(4)]);
%% top bar and bottom bar
Screen('FillRect', params.whichScreen, keyFgColor, [solidBoundaryOuter(1) outerRect(2) solidBoundaryOuter(3) outerRect(4)]);

%% same but for inner
Screen('FillRect', params.whichScreen, keyBgColor, [innerRect(1) solidBoundaryInner(2) innerRect(3) solidBoundaryInner(4)]);
Screen('FillRect', params.whichScreen, keyBgColor, [solidBoundaryInner(1) innerRect(2) solidBoundaryInner(3) innerRect(4)]);


%% then draw four corners
% top left
arcRectOuter = [outerRect(1:2) arcEdgesOuter(1:2)];
Screen('FillArc',params.whichScreen,keyFgColor,arcRectOuter,270,90)
arcRectInner = [innerRect(1:2) arcEdgesInner(1:2)];
Screen('FillArc',params.whichScreen,keyBgColor,arcRectInner,270,90)

% bottom left
arcRectOuter = [outerRect(1) arcEdgesOuter(4) arcEdgesOuter(1) outerRect(4)];
Screen('FillArc',params.whichScreen,keyFgColor,arcRectOuter,180,90)
arcRectInner = [innerRect(1) arcEdgesInner(4) arcEdgesInner(1) innerRect(4)];
Screen('FillArc',params.whichScreen,keyBgColor,arcRectInner,180,90)

% top right
arcRectOuter = [arcEdgesOuter(3) outerRect(2) outerRect(3) arcEdgesOuter(2)];
Screen('FillArc',params.whichScreen,keyFgColor,arcRectOuter,0,90)
arcRectInner = [arcEdgesInner(3) innerRect(2) innerRect(3) arcEdgesInner(2)];
Screen('FillArc',params.whichScreen,keyBgColor,arcRectInner,0,90)

% bottom right
arcRectOuter = [arcEdgesOuter(3) arcEdgesOuter(4) outerRect(3) outerRect(4)];
Screen('FillArc',params.whichScreen,keyFgColor,arcRectOuter,90,90)
arcRectInner = [arcEdgesInner(3) arcEdgesInner(4) innerRect(3) innerRect(4)];
Screen('FillArc',params.whichScreen,keyBgColor,arcRectInner,90,90)
