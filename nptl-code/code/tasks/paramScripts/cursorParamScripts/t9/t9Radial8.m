setModelParam('pause', true)
setModelParam('targetDiameter', 100)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 45)
setModelParam('trialTimeout', 10000);
setModelParam('maxTaskTime',floor(1000*60*5));
setModelParam('numTrials', 150);
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
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);



%% trackpad position to position gain parameters
gain_x = 0.6;
gain_y = 0.6;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = [0 316 484 316 0 -316 -484 -316; ...
                                    409 316 0 -316 -409 -316 0 316];

setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

setModelParam('targetInds', int16(targetIndsMat));

enableBiasKiller;
setBiasFromPrevBlock();

%% neural decode
loadFilterParams;


startContinuousMeansTracking(true, true);

thirtySecondPause();
% now disable mean updating
setModelParam('meansTrackingPeriodMS',0);

unpauseExpt