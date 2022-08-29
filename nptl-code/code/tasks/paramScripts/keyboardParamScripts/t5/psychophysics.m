
setModelParam('pause', true);
setModelParam('keyPressedTime', 100);
setModelParam('clickRefractoryPeriod',50);
setModelParam('dwellRefractoryPeriod', 400);


setModelParam('maxTaskTime',1000*60*2);

% dwell hold time
setModelParam('holdTime', 1000);
% click hold time
setModelParam('clickHoldTime', uint16(30));


setModelParam('cursorDiameter', 30);
setModelParam('trialTimeout', 10000);

setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));
setModelParam('initialInput',uint16(cursorConstants.INPUT_TYPE_NONE));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_MOUSE_RELATIVE));

setModelParam('showScores', true);
setModelParam('showBackspace', true);
setModelParam('scoreTime', 3000);
setModelParam('recenterOnFail', false);

screenMidPoint = [960 540];

% CP/PN changing dimensions for new monitors, 2016-10-03
monitor_scale_factor = 11.75 / 13.25; % 24" monitor height / 27" monitor height
gridWidth = 1000; gridHeight = 1000;% these are for original 24" monitor
gridWidth = gridWidth * monitor_scale_factor;
gridHeight = gridHeight * monitor_scale_factor;
workspace_width = 539;% this are for original 24" monitor
workspace_width = workspace_width * monitor_scale_factor;
setModelParam('keyboardDims', uint16([screenMidPoint - [gridWidth gridHeight]/2 gridWidth gridHeight]));
setModelParam('workspaceX', double([-1 1] * workspace_width));
setModelParam('workspaceY', double([-1 1] * workspace_width));


setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_CLICK));
setModelParam('maxTaskTime',1000*60*2);
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_MOUSE));


% choose OPTI II
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_OPTIII));
setModelParam('showStartStop', false);
setModelParam('maxTaskTime',1000*60*2);

addCuedText

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(2);
setModelParam('resetDisplay', false);

disp('Press any key to unpauseExpt');
pause;

unpauseExpt
