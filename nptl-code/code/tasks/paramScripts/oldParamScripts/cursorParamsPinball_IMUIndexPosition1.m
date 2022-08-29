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


%% IMU and dataglove, position to position
%% gain parameters
gain_x = -1;
gain_y = 750;
setModelParam('gain', [gain_x gain_y]);
%% neutral position
indexNeutral = 1700;
setModelParam('gloveBias', uint16([1550 indexNeutral 500 500 500]));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_INDEX_IMU_POS_TO_POS));

numTargetsInt = uint16(25);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(1.5)*double([0    0   0  0    0    50  50  50  50   50   100 100 100 100 100  -50 -50 -50 -50 -50  -100 -100 -100 -100 -100;
                                                        100  50  0  -50  -100 100 50  0   -50  -100 100 50  0   -50 -100 100 50  0   -50 -100 100  50   0    -50  -100  ]);
setModelParam('targetInds', int16(targetIndsMat));
