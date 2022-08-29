setModelParam('pause', true)
setModelParam('targetDiameter', 100)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 50)
setModelParam('trialTimeout', 7000);
%setModelParam('trialDelayLength', 0);
setModelParam('numTrials', 320);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_MOUSE_RELATIVE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('showScores', true);
setModelParam('trialsPerScore', uint16(32));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);
setModelParam('pxOffset',0);
setModelParam('pyOffset',0);
setModelParam('vxOffset',0);
setModelParam('vyOffset',0);

%% trackpad position to position gain parameters
gain_x = 0.6/1000;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = 3*double([0    71   100  71   0     -71  -100 -71;
                                              100  71   0    -71  -100  -71  0    71]);
setModelParam('targetInds', int16(targetIndsMat));