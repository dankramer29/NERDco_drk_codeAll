setModelParam('pause', true)
setModelParam('targetDiameter', 150)
setModelParam('holdTime', 500)
setModelParam('maxTaskTime',floor(1000*60*4.5));
setModelParam('cursorDiameter', 50)
setModelParam('trialTimeout', 6000);
setModelParam('numTrials', 160);
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
setModelParam('soundOnFail', false);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);


%% trackpad position to position gain parameters
gain_x = 6;
gain_y = 6;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(4);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(3)*double([0 100    0 -100;
                                                    100   0 -100    0]);

setModelParam('workspaceY', double([-520 520]));
setModelParam('workspaceX', double([-940 940]));

setModelParam('targetInds', int16(targetIndsMat));

%% neural decode
loadFilterParams;
