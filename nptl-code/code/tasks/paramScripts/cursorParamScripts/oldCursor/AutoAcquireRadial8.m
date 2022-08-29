setModelParam('pause', true)
setModelParam('targetDiameter', 150)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 50)
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 320);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_AUTO_ACQUIRE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_AUTO_ACQUIRE));
setModelParam('showScores', false);

%% trackpad position to position gain parameters
gain_x = 1.0;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);


numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(3)*double([0    71   100  71   0     -71  -100 -71;
                                                        100  71   0    -71  -100  -71  0    71]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));


setModelParam('targetInds', int16(targetIndsMat));