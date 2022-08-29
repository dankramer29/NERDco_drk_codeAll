setModelParam('pause', true)
setModelParam('targetDiameter', 60)
setModelParam('holdTime', 0)
setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 160);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_NEURAL_OUT_MOTOR_BACK));

%% gain parameters
gain_x = 0.16;
gain_y = 0.16;
setModelParam('gain', [gain_x gain_y]);


numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(1.5)*double([0    71   100  71   0     -71  -100 -71;
                                                        100  71   0    -71  -100  -71  0    71]);
setModelParam('targetInds', int16(targetIndsMat));



%% neural decode
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));

tmp = load('steadyStateKalman');

setModelParam('A', tmp.MSS.A);
setModelParam('C', tmp.MSS.C);
setModelParam('K', tmp.MSS.K);
setModelParam('dtMS', uint16(50));
setModelParam('thresholds', tmp.MSS.thresholds);
ngain_x = 1;
ngain_y = 1;
setModelParam('neuralGain', [ngain_x ngain_y]);
