setModelParam('pause', true)
setModelParam('targetDiameter', 100)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 5000);
setModelParam('numTrials', 320);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_PINBALL));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));

%% trackpad position to position gain parameters
gain_x = 2*0.16;
gain_y = 2*0.16;
setModelParam('gain', [gain_x gain_y]);

numTargetsInt = uint16(25);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = 4*[0    0   0  0    0    50  50  50  50   50   100 100 100 100 100  -50 -50 -50 -50 -50  -100 -100 -100 -100 -100;
                                       100  50  0  -50  -100 100 50  0   -50  -100 100 50  0   -50 -100 100 50  0   -50 -100 100  50   0    -50  -100  ];
setModelParam('targetInds', int16(targetIndsMat));


%% neural decode
loadFilterParams;
setModelParam('A', model.A);
setModelParam('C', model.C);
setModelParam('K', model.K);
setModelParam('dtMS', uint16(model.dtMS));
setModelParam('thresholds', model.thresholds);
ngain_x = 1;
ngain_y = 1;
setModelParam('neuralGain', [ngain_x ngain_y]);
