typingTaskNeural();


% allow click and dwell acquire
setModelParam('acquireMethods', ...
    bitor(uint8(keyboardConstants.ACQUIRE_CLICK), uint8(keyboardConstants.ACQUIRE_DWELL)));


%setModelParam('keyboardDims', uint16([240 150 1440 850]));
screenMidPoint = [960 540];
gridWidth = 1000; gridHeight = 1000;
setModelParam('keyboardDims', uint16([screenMidPoint - [gridWidth gridHeight]/2 gridWidth gridHeight]));



setModelParam('dwellRefractoryPeriod', 800);
setModelParam('clickRefractoryPeriod', 800);
setModelParam('holdTime', 1800);

setModelParam('hmmClickSpeedMax', 0.35);


% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_OPTIII));
setModelParam('showStartStop', false);
setModelParam('maxTaskTime',1000*60*3);

addCuedText

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;


setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(1);
setModelParam('resetDisplay', false);
setModelParam('initialState', uint16(KeyboardStates.STATE_MOVE));
startContinuousMeansTracking(false,false);
startDiscreteMeansTracking(true,true);
threeSecondPause();

unpauseExpt

