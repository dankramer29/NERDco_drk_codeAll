% lower hold time for open loop
setModelParam('holdTime', 750);
setModelParam('trialTimeout', 5000);
setModelParam('autoplayMovementDuration', 50);

setModelParam('numTrials', 256); % real
% setModelParam('numTrials', 64); % DEV


% set to auto aquire targets
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_WIA_HEAD));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_WIA_HEAD));

% open loop specific?
setModelParam('soundOnOverTarget', false);

% T5 asked for slower than it was at 1
gain_x = 0.7;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y 0 0 0]); % BJ May 2017: now 5D

% Targets
numTargetsInt = uint16(16);
setModelParam('numTargets', numTargetsInt);

targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));  

centers = [-260, 0;
    260, 0];
theta = linspace(0,2*pi,9);
theta = theta(1:8);
allTargets = [];
for centerIdx=1:size(centers,1)
    allTargets = [allTargets; repmat(centers(centerIdx,:), length(theta), 1)+200*[cos(theta)', sin(theta)']];
end

targetIndsMat(1:2,1:numTargetsInt)  = allTargets';

% targetIndsMat(1:2,1:numTargetsInt)  = [0 316 447  316    0 -316 -447 -316; ...
%                                      447 316   0 -316 -447 -316     0 316];
setModelParam('targetInds', single(targetIndsMat));

% task
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT_NO_BACK));
setModelParam('numDisplayDims', uint8(2) );
% max task duration
setModelParam('maxTaskTime',1000*60*3);
% Target and cursor sizes
setModelParam('targetDiameter', 80);
setModelParam('cursorDiameter', 20);
% other params
setModelParam('wiaMode',uint16(cursorConstants.WIA_IMAGINE_ONLY_NO_HC));
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 1000);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('showScores', false);
setModelParam('trialsPerScore', uint16(48));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);
setModelParam('preTrialLength',20 );
setModelParam('failOnLiftoff', false);
setModelParam('clickPercentage', 0); % all dwell by default
setModelParam('stopOnClick', false);
setModelParam('stopOffTarget', false);
setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));
setModelParam('headSpeedCap',single(100.0));
setModelParam('showWiaText',uint16(0));
setModelParam('displayObject',uint8(cursorConstants.BACKGROUND_DUAL_JOYSTICK));
setModelParam('discreteOLMode',uint8(1));
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics

% Brief unpause  so game sends over target coordinates before pausing again
% This avoids having flashing of PTB on and off at game start
setModelParam('pause', false);
pause(0.100); 
setModelParam('pause', true);


unpauseOnAny;