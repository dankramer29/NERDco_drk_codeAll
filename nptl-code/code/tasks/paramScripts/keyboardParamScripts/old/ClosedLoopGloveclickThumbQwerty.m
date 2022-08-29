setModelParam('pause', true)
setModelParam('holdTime', 500)
setModelParam('clickRefractoryPeriod', 1000)
setModelParam('dwellRefractoryPeriod', 1000)

setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 10000);
setModelParam('keyboardDims', uint16([240 90 1440 900]));
setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));
setModelParam('initialInput', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('showScores', true);
setModelParam('scoreTime', 3000);
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_CLICK));

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

%setModelParam('workspaceX', double([-960 960]));
%setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-720 720]));
setModelParam('workspaceY', double([-450 450]));

%% threshold value from glove mean readings
setModelParam('gloveThreshold', 2400);
gInds = false(5,1);
gInds(1) = true; %% THUMB
setModelParam('gloveIndices', gInds);
setModelParam('clickHoldTime', uint16(200));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_GLOVE));
setModelParam('recenterOnFail', false);
setModelParam('recenterOnSuccess', false);

%% neural decode
loadFilterParams;