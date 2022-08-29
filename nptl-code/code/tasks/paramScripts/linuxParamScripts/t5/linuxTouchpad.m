setModelParam('pause', true)
setModelParam('taskType', uint32(linuxConstants.TASK_FREE_RUN));

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = 0.6;
setModelParam('gain', [gain_x gain_y 0 0]);
setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

%% threshold value from glove mean readings - CHANGE TO MEAN VALUE FROM GLOVETEST
setModelParam('gloveThreshold', 2200);
gInds = false(5,1);
gInds(1:5) = true; %% MEAN - all five fingers
setModelParam('gloveIndices', gInds);
setModelParam('clickHoldTime', uint16(200));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_GLOVE));
setModelParam('stopOnClick', false);


% %% neural decode
% loadFilterParams;

