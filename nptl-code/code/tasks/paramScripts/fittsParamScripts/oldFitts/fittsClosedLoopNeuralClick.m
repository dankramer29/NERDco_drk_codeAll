setModelParam('pause', true)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 19)
setModelParam('trialTimeout', 15000);
setModelParam('numTrials', 240);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(fittsConstants.TASK_FITTS));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', true);
setModelParam('recenterDelay',0);

td = zeros([1 fittsConstants.MAX_DIAMETERS],'uint16');
td(1:3) = [56 121 196];
setModelParam('targetDiameters', td);
setModelParam('numTargetDiameters', uint16(3)); %% this is the trial delay length parameter
setModelParam('minTargetDistance', double(10));


%% click-related parameters
setModelParam('clickPercentage', 1);
setModelParam('clickHoldTime', uint16(10));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setModelParam('stopOnClick', true);
setModelParam('hmmClickLikelihoodThreshold', 0.95);

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = 0.6;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

wspX = double([-720 720]);
wspY = double([-540 540]);
setModelParam('workspaceY', wspY);
setModelParam('workspaceX', wspX);

margin = max(double(td))/2;
tgspY = [wspY(1)+margin wspY(2)-margin];
tgspX = [wspX(1)+margin wspX(2)-margin];
setModelParam('targetSpaceY', tgspY);
setModelParam('targetSpaceX', tgspX);

%% neural decode
loadFilterParams;
ngain_x = 1;
ngain_y = 1;
%setModelParam('neuralGain', [ngain_x ngain_y]);

loadDiscreteFilterParams;
