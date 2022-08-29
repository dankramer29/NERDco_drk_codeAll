setModelParam('pause', true);
setModelParam('keyPressedTime', 200);
setModelParam('clickRefractoryPeriod', 400);
setModelParam('dwellRefractoryPeriod', 400);
setModelParam('cumulativeDwell',true);

setModelParam('maxTaskTime',1000*60*2);

% dwell hold time
setModelParam('holdTime', 900);
% click hold time
setModelParam('clickHoldTime', uint16(30));

setModelParam('hmmClickSpeedMax', 0.4);
% the hmmResetOnFast is causing bad behavior. just cut it.
setModelParam('hmmResetOnFast',false);
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));


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