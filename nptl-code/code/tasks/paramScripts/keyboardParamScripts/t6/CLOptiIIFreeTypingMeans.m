typingTaskNeural();


% allow click and dwell acquire
setModelParam('acquireMethods', ...
    bitor(uint8(keyboardConstants.ACQUIRE_CLICK), uint8(keyboardConstants.ACQUIRE_DWELL)));


screenMidPoint = [960 540];
gridWidth = 1000; gridHeight = 1000;

setModelParam('keyboardDims', uint16([screenMidPoint - [gridWidth gridHeight]/2 gridWidth gridHeight]));


% choose OPTI II
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_OPTIII));
setModelParam('showStartStop', true);

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;


velGain = 0.9;
setModelParam('scaleXk',[1 1 velGain velGain 1]);

addPromptedQuestion;

setModelParam('maxTaskTime',1000*60*20);
setModelParam('initialState', uint16(KeyboardStates.STATE_INACTIVE));
setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(4);
setModelParam('resetDisplay', false);


startContinuousMeansTracking
thirtySecondPause
unpauseExpt