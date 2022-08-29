setModelParam('pause', true)
setModelParam('holdTime', 600)
setModelParam('keyPressedTime', 200)
setModelParam('clickRefractoryPeriod', 400)
setModelParam('dwellRefractoryPeriod', 400)
setModelParam('clickHoldTime', uint16(100));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setModelParam('hmmClickLikelihoodThreshold', 0.93);
setModelParam('hmmClickSpeedMax', 0.25);
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_DWELL));
setModelParam('soundOnError', true);

setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 10000);
screenMidPoint = [960 540];
gridWidth = 1000; gridHeight = 1000;
setModelParam('showTargetText',false);
setModelParam('showTypedText',false);
setModelParam('showCueOffTarget', false);
setModelParam('showCueOnTarget',true);
% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));
setModelParam('keyboardDims', uint16([screenMidPoint - [gridWidth gridHeight]/2 gridWidth gridHeight]));
setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));
setModelParam('initialInput', uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('showScores', false);
setModelParam('showBackspace', false);
setModelParam('scoreTime', 3);
setModelParam('recenterOnFail', true);


%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

%% workspace is defined in unshifted (zero-centered) coordinates
setModelParam('workspaceX', double([-540 540]));
setModelParam('workspaceY', double([-540 540]));

addCuedRandom6x6GridSequence(100);