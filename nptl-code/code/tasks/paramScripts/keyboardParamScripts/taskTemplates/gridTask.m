setModelParam('pause', true);
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics

setModelParam('initialInput',uint16(cursorConstants.INPUT_TYPE_NONE));
setModelParam('maxTaskTime',1000*60*6);
%setModelParam('maxTaskTime',1000*60*1);

setModelParam('keyPressedTime', 200);
setModelParam('clickRefractoryPeriod', 400);
setModelParam('dwellRefractoryPeriod', 400);

setModelParam('cursorDiameter', 30);
setModelParam('trialTimeout', 10000);
setModelParam('soundOnError', true);

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


setModelParam('showTargetText',false);
setModelParam('showTypedText',false);
setModelParam('showCueOffTarget', false);
setModelParam('showCueOnTarget',true);

setModelParam('taskType', uint16(keyboardConstants.TASK_CUED_TEXT));

setModelParam('showScores', true);
setModelParam('showBackspace', true);
setModelParam('scoreTime', 3);
setModelParam('recenterOnFail', false);


%addCuedRandomGridSequence(100);

%% trackpad position to position gain parameters
%gain_x = 0.6;
%gain_y = gain_x;
%setModelParam('gain', [gain_x gain_y]);
%setModelParam('mouseOffset', [0 0]);

