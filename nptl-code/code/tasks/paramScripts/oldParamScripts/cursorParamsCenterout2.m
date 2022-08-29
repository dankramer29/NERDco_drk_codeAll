setModelParam('pause', true)
setModelParam('targetDiameter', 60)
setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 160);
setModelParam('randomSeed', 1);
setModelParam('expRandMu', 1000);
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 500);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
%setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_IMU_POS_TO_POS));
%setModelParam('gain', 1000);
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_IMU_POS_TO_VEL));
setModelParam('gain', 1);
numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = 4*[0    71   100  71   0     -71  -100 -71;
                                 100  71   0    -71  -100  -71  0    71];
setModelParam('targetInds', int16(targetIndsMat));
