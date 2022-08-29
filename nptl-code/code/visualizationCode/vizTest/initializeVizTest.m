function initializeVizTest()

	global screenParams;
	global taskParams;

	% whichScreen = screenParams.whichScreen;
 %    Screen('TextFont',whichScreen, 'Courier New'); %Courier New
 %    Screen('TextSize',whichScreen, 50);

%    loadImages();

    taskParams.handlerFun = @vizSetupScreen;
