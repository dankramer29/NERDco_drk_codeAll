setModelParam('pause', true)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 45)
setModelParam('trialTimeout', 15000);
setModelParam('numTrials', 240);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(fittsConstants.TASK_FITTS));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', true);
setModelParam('recenterDelay',0);

td = zeros([1 fittsConstants.MAX_DIAMETERS],'uint16');
td(1) = 75;
setModelParam('targetDiameters', td);
setModelParam('numTargetDiameters', uint16(1)); %% this is the trial delay length parameter
setModelParam('minTargetDistance', double(200));


%% trackpad position to position gain parameters
gain_x = 1.5;
gain_y = 1.2;
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

