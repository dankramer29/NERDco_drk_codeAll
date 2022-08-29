setModelParam('pause', true)
setModelParam('holdTime', 200)
setModelParam('keyPressedTime', 200)
setModelParam('clickRefractoryPeriod', 400)
setModelParam('dwellRefractoryPeriod', 400)
setModelParam('clickHoldTime', uint16(100));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setModelParam('hmmClickLikelihoodThreshold', 0.94);
setModelParam('hmmClickSpeedMax', 0.25);
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_CLICK));

setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 10000);
setModelParam('keyboardDims', uint16([540 295 840 695]));
setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));
setModelParam('initialInput', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('showScores', true);
setModelParam('showBackspace', true);
setModelParam('scoreTime', 3000);
setModelParam('recenterOnFail', false);


%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

%setModelParam('workspaceX', double([-960 960]));
%setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-720 720]));
setModelParam('workspaceY', double([-450 450]));

% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_QWERTY2));

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;
