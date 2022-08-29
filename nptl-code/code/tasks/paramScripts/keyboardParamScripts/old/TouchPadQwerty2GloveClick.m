setModelParam('pause', true)
setModelParam('holdTime', 300)
setModelParam('clickRefractoryPeriod', 200)
setModelParam('dwellRefractoryPeriod', 200)

setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 10000);
setModelParam('keyboard', uint16(keyboardConstants.KEYBOARD_QWERTY2));
setModelParam('keyboardDims', uint16([240 150 1440 850]));
setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('showScores', true);
setModelParam('scoreTime', 3000);
setModelParam('recenterOnFail', false);
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_CLICK));
setModelParam('showBackspace', true);

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

%setModelParam('workspaceX', double([-960 960]));
%setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-720 720]));
setModelParam('workspaceY', double([-450 450]));

%% threshold value from glove mean readings - CHANGE TO MEAN VALUE FROM GLOVETEST
setModelParam('gloveThreshold', 2600);
gInds = false(5,1);
gInds(1:5) = true; %% MEAN - all five fingers
setModelParam('gloveIndices', gInds);
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_GLOVE));
setModelParam('recenterOnFail', false);
setModelParam('recenterOnSuccess', false);
setModelParam('clickHoldTime', 100)
