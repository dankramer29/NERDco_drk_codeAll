setModelParam('pause', true)
setModelParam('taskType', uint32(linuxConstants.TASK_FREE_RUN));

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = 0.6;
setModelParam('gain', [gain_x gain_y 0 0]);
setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

setModelParam('targetDevice', uint16(linuxConstants.DEVICE_ARM));
setModelParam('screenUpdateRate', 2);


setModelParam('clickHoldTime', uint16(100));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setHMMThreshold();
setModelParam('hmmClickSpeedMax', 0.25);
setModelParam('stopOnClick', true);


%% neural decode
loadFilterParams;

% neural click
loadDiscreteFilterParams;

