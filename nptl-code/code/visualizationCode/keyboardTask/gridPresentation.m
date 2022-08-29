function q = gridPresentation(qIn)

    white = [255 255 255];
    black = [0 0 0];
    green = [0 180 0];
    darkgreen = uint8(green*0.666);
    grey = [255 255 255] * 0.2;
    darkgrey = uint8(grey*0.8);
    lightblue = [0 130 130];
    darkred = [70 0 0];
	offwhite = white*0.95;
	
    q = qIn;
	
    q.textRegBgColor = uint8(darkgrey);
    
    q.bgColor = black;
    q.keyFgColor = black;
    q.textColor = offwhite;
    q.keyBgColor = grey;

    q.keyFgColorOver = black;
    q.textColorOver = offwhite;
    q.keyBgColorOver = darkgrey;

    q.keyFgColorPressed = black;
    q.textColorPressed = offwhite;
    q.keyBgColorPressed = lightblue;
    
    q.keyFgColorCued = black;
    q.textColorCued = q.keyFgColorCued;
    q.keyBgColorCued = green;
    
    q.keyFgColorOverCued = black;
    q.textColorOverCued = q.keyFgColorOverCued;
    q.keyBgColorOverCued = darkgreen;
    
    q.keyStroke = 2;
    q.padding = 0.000;
    q.arcperc = 0.00;
    q.textSize = 60;
    q.textStyle = 1;
    q.typedStyle = 0;
    q.showBackspace = false;
	
	% for struct field consistency across typing and grid tasks
	q.textFont = []; %% keys and cued text
    q.typedFont = []; %% the typing window
	
end
