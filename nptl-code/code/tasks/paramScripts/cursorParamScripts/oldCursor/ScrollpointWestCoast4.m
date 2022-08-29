setModelParam('pause', true)
setModelParam('targetDiameter', 150)
setModelParam('holdTime', 500)
setModelParam('maxTaskTime',1000*60*6);
setModelParam('cursorDiameter', 50)
setModelParam('trialTimeout', 7000);
setModelParam('numTrials', 160);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_MOUSE_RELATIVE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_RELATIVE));
setModelParam('showScores', false);
% don't play sound on failure
setModelParam('soundOnFail', false);

%% trackpad position to position gain parameters
gain_x = 5;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);


numTargetsInt = uint16(4);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(3)*double([  0    100     0  -100;
                                                      100      0  -100     0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));


setModelParam('targetInds', int16(targetIndsMat));

%% mouse Low-pass Filter params
[mouseLPFb, mouseLPFa] =  cheby2(5, 30, 0.02);
setModelParam('mouseLPNumerator', [mouseLPFb, zeros(1, 5)]);
setModelParam('mouseLPDenominator', [mouseLPFa, zeros(1, 5)]);
setModelParam('useMouseLPF', false);
