% lower hold time for open loop
setModelParam('holdTime', 500);
setModelParam('trialTimeout', 5000);
setModelParam('autoplayMovementDuration', 400);

setModelParam('numTrials', 128); % real
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
nTargsPerRing = 8;
nRings = 1;
angles = linspace(0,2*pi,nTargsPerRing+1);
angles(end) = [];

ringPattern = [cos(angles)', sin(angles)'];
distPattern = [1.0];

fullPattern = [];
for t=1:nRings
    fullPattern = [fullPattern, ringPattern'*distPattern(t)];
end

numTargetsInt = uint16(size(fullPattern,2));
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:2,1:numTargetsInt)  = 409*fullPattern;

setModelParam('targetInds', single(targetIndsMat));

% task
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('numDisplayDims', uint8(2) );
% max task duration
setModelParam('maxTaskTime',1000*60*8);
% Target and cursor sizes
setModelParam('targetDiameter', 60);
setModelParam('cursorDiameter', 20);
% other params
setModelParam('wiaMode',uint16(cursorConstants.WIA_WATCH_ONLY));
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 1);
setModelParam('expRandMu', 1200); %% this is the trial delay length parameter
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
setModelParam('headSpeedCap',single(0.16));
setModelParam('showWiaText',uint16(1));

setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics

% Brief unpause  so game sends over target coordinates before pausing again
% This avoids having flashing of PTB on and off at game start
setModelParam('pause', false);
pause(0.100); 
setModelParam('pause', true);


unpauseOnAny;