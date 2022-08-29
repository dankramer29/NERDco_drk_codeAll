setModelParam('pause', true)
setModelParam('targetDiameter', 60)
setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 1300);
setModelParam('numTrials', 480);
setModelParam('randomSeed', 1);
setModelParam('expRandMu', 0); %% this is the delay period
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 500);
setModelParam('gain', 0.1);
setModelParam('taskType', uint32(cursorConstants.TASK_PINBALL));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_MOUSE));
numTargetsInt = uint16(25);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = 4*[0    0   0  0    0    50  50  50  50   50   100 100 100 100 100  -50 -50 -50 -50 -50  -100 -100 -100 -100 -100;
                                       100  50  0  -50  -100 100 50  0   -50  -100 100 50  0   -50 -100 100 50  0   -50 -100 100  50   0    -50  -100  ];
setModelParam('targetInds', int16(targetIndsMat));
setModelParam('useRandomDelay', uint16(0));
