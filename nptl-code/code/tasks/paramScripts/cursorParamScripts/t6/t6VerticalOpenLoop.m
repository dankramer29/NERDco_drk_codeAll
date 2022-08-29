setModelParam('pause', true)
setModelParam('targetDiameter', 100)
setModelParam('holdTime', 350)
setModelParam('maxTaskTime',floor(1000*60*3));
setModelParam('cursorDiameter', 45)
setModelParam('clickHoldTime', 600)
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 64);
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
setModelParam('clickPercentage', 0);
setModelParam('stopOnClick', false);
setModelParam('soundOnOverTarget', false);

%% trackpad position to position gain parameters
gain_x = 0.75;
gain_y = gain_x;
%% in the INPUT_TYPE_AUTO_ACQUIRE framework, gain(1) sets the cursor speed
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);


numTargetsInt = uint16(2);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = [  0    0; ...
                                     409 -409];


setModelParam('workspaceY', double([-539 539]));
setModelParam('workspaceX', double([-960 960]));


setModelParam('targetInds', int16(targetIndsMat));
