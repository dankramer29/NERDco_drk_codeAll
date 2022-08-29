setModelParam('pause', true);
setModelParam('keyPressedTime', 200);
setModelParam('dwellRefractoryPeriod', 400);

setModelParam('maxTaskTime',1000*60*2);

% dwell hold time
setModelParam('holdTime', 1000);
% click hold time
setModelParam('clickHoldTime', uint16(30));

setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NONE));

% allow click and dwell acquire
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_DWELL));

setModelParam('cursorDiameter', 30);
setModelParam('trialTimeout', 10000);

setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));
setModelParam('initialInput',uint16(cursorConstants.INPUT_TYPE_NONE));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_DECODE_V));

setModelParam('showScores', true);
setModelParam('showBackspace', true);
setModelParam('scoreTime', 3000);
setModelParam('recenterOnFail', false);

monitor_scale_factor = 11.75 / 13.25; % 24" monitor height / 27" monitor height
setModelParam('workspaceX', double([-720 720]) * monitor_scale_factor);
setModelParam('workspaceY', double([-539 539]) * monitor_scale_factor);
