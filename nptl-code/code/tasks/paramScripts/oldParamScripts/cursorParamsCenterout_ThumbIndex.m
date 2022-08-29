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
setModelParam('inputType', int32(cursorConstants.INPUT_TYPE_THUMB_INDEX_POS_TO_POS));

gain_x = 5;
gain_y = 3;
setModelParam('gain', [gain_x gain_y]);

numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = 2*double([0    71   100  71   0     -71  -100 -71;
                                              100  71   0    -71  -100  -71  0    71]);
setModelParam('targetInds', int16(targetIndsMat));
