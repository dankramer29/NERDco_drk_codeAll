setModelParam('pause', true)
setModelParam('holdTime', 1000)
setModelParam('clickRefractoryPeriod', 600)
setModelParam('dwellRefractoryPeriod', 600)
setModelParam('clickHoldTime', uint16(100));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setModelParam('hmmClickLikelihoodThreshold', 0.95);
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_DWELL));

setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 10000);
setModelParam('keyboardDims', uint16([240 150 1440 850]));
setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));
setModelParam('initialInput', uint16(cursorConstants.INPUT_TYPE_THUMB_INDEX_POS_TO_POS));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_THUMB_INDEX_POS_TO_POS));
setModelParam('showScores', true);
setModelParam('showBackspace', true);
setModelParam('scoreTime', 3000);
setModelParam('recenterOnFail', false);


%% trackpad position to position gain parameters
gain_x = 4.5;
gain_y = 4.5;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);
setModelParam('gloveBias', [2600 1400 1700 2000 2000]);

%setModelParam('workspaceX', double([-960 960]));
%setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-720 720]));
setModelParam('workspaceY', double([-450 450]));

