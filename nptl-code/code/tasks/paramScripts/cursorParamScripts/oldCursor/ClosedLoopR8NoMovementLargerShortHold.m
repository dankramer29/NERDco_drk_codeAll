setModelParam('pause', true)
setModelParam('targetDiameter', 175)
setModelParam('holdTime', 350)
setModelParam('cursorDiameter', 45)
setModelParam('trialTimeout', 7000);
setModelParam('numTrials', 200);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);

setModelParam('lockFingerPosition',true);
%% increasing this number will allow a longer radius around the initial finger position
setModelParam('fingerPositionTolerance',40);

setModelParam('biasCorrectionVelocityThreshold',0.34); %% set based on speed hist from 20130827-11
setModelParam('biasCorrectionTau',30*1000); %% set to 30 s copying east coast params

%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = 0.6;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = [0 316 484 316 0 -316 -484 -316; 409 316 0 -316 -409 -316 0 316];

setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

setModelParam('targetInds', int16(targetIndsMat));

%% neural decode
loadFilterParams;
