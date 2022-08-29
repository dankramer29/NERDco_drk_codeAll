setModelParam('pause', true)
setModelParam('targetDiameter', 60)
setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 30000);
setModelParam('numTrials', 300);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 1); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 1);
setModelParam('taskType', uint32(cursorConstants.TASK_PINBALL));
setModelParam('inputType', int32(cursorConstants.INPUT_TYPE_THUMB_INDEX_POS_TO_POS));

gain_x = 5;
gain_y = 3;
setModelParam('gain', [gain_x gain_y]);

numTargetsInt = uint16(25);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(1.5)*double([0    0   0  0    0    50  50  50  50   50   100 100 100 100 100  -50 -50 -50 -50 -50  -100 -100 -100 -100 -100;
                                                        100  50  0  -50  -100 100 50  0   -50  -100 100 50  0   -50 -100 100 50  0   -50 -100 100  50   0    -50  -100  ]);
setModelParam('targetInds', int16(targetIndsMat));