setModelParam('pause', true)
setModelParam('targetDiameter', 60)
setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 30000);
setModelParam('numTrials', 320);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 1); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 1);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));


%% IMU position to position
setModelParam('gain', [750 750]);
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_IMU_POS_TO_POS));

numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(1.5)*double([0    71   100  71   0     -71  -100 -71;
                                                       100  71   0    -71  -100  -71  0    71]);
setModelParam('targetInds', int16(targetIndsMat));
