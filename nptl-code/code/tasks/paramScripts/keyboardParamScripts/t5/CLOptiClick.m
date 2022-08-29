typingTaskNeural();

% allow click and dwell acquire
setModelParam('acquireMethods', ...
    bitor(uint8(keyboardConstants.ACQUIRE_CLICK), uint8(keyboardConstants.ACQUIRE_DWELL)));

monitor_scale_factor = 11.75 / 13.25; % 24" monitor height / 27" monitor height
screenMidPoint = [960 540];
gridWidth = 1000 * monitor_scale_factor; gridHeight = 1000 * monitor_scale_factor;
setModelParam('keyboardDims', uint16([screenMidPoint - [gridWidth gridHeight]/2 gridWidth gridHeight]));


% choose OPTI II
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_OPTIII));
setModelParam('showStartStop', false);

addCuedText;

% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;

resetDisplay2;

updateHMMThreshold(0.93, 1);

%setModelParam('initialState', uint16(KeyboardStates.STATE_MOVE));

enableBiasKiller;
setBiasFromPrevBlock;

doResetBK = true;
unpauseOnAny(doResetBK);


