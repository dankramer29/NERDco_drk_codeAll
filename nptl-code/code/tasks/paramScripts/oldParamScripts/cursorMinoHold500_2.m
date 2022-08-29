setModelParam('pause', true)
setModelParam('targetDiameter', 150)

% hold time (aka dwell time)
setModelParam('holdTime', 500)

setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 5000);
setModelParam('numTrials', 240);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_NEURAL_OUT_MOTOR_BACK));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));

%% trackpad position to position gain parameters
gain_x = 2*0.16;
gain_y = 2*0.16;
setModelParam('gain', [gain_x gain_y]);


% Change this number to push targets in (smaller) /out (larger)
targetDistanceScale = 1.5  *1.5;

 targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));

 % Eight target task (uncomment lines below)
 numTargetsInt = uint16(8);
 targetIndsMat(:,1:numTargetsInt)  = targetDistanceScale*double([0    71   100  71   0     -71  -100 -71;
                                               100  71   0    -71  -100  -71  0    71]);

% Four target task (uncomment lines below)
%targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
%targetIndsMat(:,1:numTargetsInt)  = targetDistanceScale*double([0    100  0    -100;
                                              %100  0    -100  0 ]);

setModelParam('numTargets', numTargetsInt);
setModelParam('targetInds', int16(targetIndsMat));




%% neural decode
loadFilterParams;
setModelParam('A', model.A);
setModelParam('C', model.C);
setModelParam('K', model.K);
setModelParam('dtMS', uint16(model.dtMS));
setModelParam('thresholds', model.thresholds);
ngain_x = 1;
ngain_y = 1.0;
setModelParam('neuralGain', [ngain_x ngain_y]);
