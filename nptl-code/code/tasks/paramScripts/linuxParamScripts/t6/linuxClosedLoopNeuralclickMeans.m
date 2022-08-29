setModelParam('pause', true)
setModelParam('taskType', uint32(linuxConstants.TASK_FREE_RUN));

setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = 0.6;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

%% threshold value from glove mean readings - CHANGE TO MEAN VALUE FROM GLOVETEST
setModelParam('gloveThreshold', 1980);
gInds = false(5,1);
gInds(1:5) = true; %% MEAN - all five fingers
setModelParam('gloveIndices', gInds);
setModelParam('clickHoldTime', uint16(30));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
%setModelParam('hmmClickLikelihoodThreshold', 0.93);
setHMMThreshold()
setModelParam('hmmClickSpeedMax', 0.25);
setModelParam('stopOnClick', true);


%% neural decode
loadFilterParams;

% neural click
loadDiscreteFilterParams;

%setModelParam('resetDisplay', true);
%clear pause % sometimes the 'pause' variable gets set by build scripts
%pause(4);
%setModelParam('resetDisplay', false);

startContinuousMeansTracking
thirtySecondPause
unpauseExpt
