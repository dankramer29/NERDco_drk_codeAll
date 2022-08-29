setModelParam('pause', true)
setModelParam('targetDiameter', 100)
setModelParam('holdTime', 350)
setModelParam('maxTaskTime',floor(1000*60*3));
setModelParam('cursorDiameter', 45)
setModelParam('clickHoldTime', 600)
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 128);
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
%gain_x = 0.75;
% CP 20150824 - increasing open loop speed from 0.75
gain_x = 1;
gain_y = gain_x;
%% in the INPUT_TYPE_AUTO_ACQUIRE framework, gain(1) sets the cursor speed
setModelParam('gain', [gain_x gain_y 1 1]); % SDS August 2016 it's now 4-vec
% setModelParam('gain', [gain_x gain_y ]); % SDS August 2016 it's now 4-vec
setModelParam('mouseOffset', [0 0]);


% numTargetsInt = uint16(4); % cardinal targets
numTargetsInt = uint16(8); % 8 targets
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:2,1:numTargetsInt)  = [  0 289 409  289    0 -289 -409 -289; ...
                                     409 289   0 -289 -409 -289    0 289];

% targetIndsMat(1:2,1:numTargetsInt)  = [  0  409     0 -409 ; ...  % cardinal only
%                                        409    0  -409    0 ];

setModelParam('workspaceY', double([-539 539]));
setModelParam('workspaceX', double([-960 960]));


setModelParam('targetInds', int16(targetIndsMat));
