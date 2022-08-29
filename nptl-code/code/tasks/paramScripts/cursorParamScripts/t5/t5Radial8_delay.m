% default gain
gain_x = 0; % so cursor is still during pre state
gain_y = gain_x;
gainCorrectDim =  getModelParam('gain');
gainCorrectDim(1) = gain_x;
gainCorrectDim(2) = gain_y;
setModelParam('gain', gainCorrectDim);
setModelParam('mouseOffset', [0 0]);

% number of trials
setModelParam('numTrials', 320);
setModelParam('maxTaskTime',1000*60*5.1);

% task params
setModelParam('targetDiameter', 60);
setModelParam('cursorDiameter', 20);
setModelParam('holdTime', 400);
setModelParam('trialTimeout', 10000);

%%
doResetBK = true;
gainCorrectDim =  zeros( size( getModelParam('gain') ) );
% Use these high gains if using a SCL decoder (which uses meters as units)
% for the 2D PsychToolbox task (which uses pixels)
% gainCorrectDim(1) = 5000;
% gainCorrectDim(2) = 5000;
% Use these gains for regular train 2D, evaluate 2D operation:
gainCorrectDim(1) = 5000;
gainCorrectDim(2) = gainCorrectDim(1);

%% here to make it easy for Operator to quickly change gain
% gain_manual = 1;
% gainCorrectDim = zeros( size( getModelParam('gain') ) );
% gainCorrectDim(1) = gain_manual; gainCorrectDim(2) = gain_manual;
% setModelParam('gain', gainCorrectDim );
%%
% task
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_HEAD_MOUSE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('numDisplayDims', uint8(4) );

% other params
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 1);
setModelParam('expRandMu', 1500); %% this is the trial delay length parameter
setModelParam('expRandMin', 1000);
setModelParam('expRandMax', 2000);
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

% zero gain at start
setModelParam('gain', zeros( size( getModelParam('gain') ) ));

% set targets & workspace bounds
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

% 539 and 959 below keep it visible, otherwise it's 1 pixel too far and thus offscreen
setModelParam('workspaceY', double([-540 539]));
setModelParam('workspaceX', double([-960 959]));
setModelParam('targetInds', single(targetIndsMat));

setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics
% Brief unpause  so game sends over target coordinates before pausing again
% This avoids having flashing of PTB on and off at game start
setModelParam('pause', false);
pause(0.100); 
setModelParam('pause', true);


unpauseOnAny(doResetBK);
setModelParam('gain', gainCorrectDim); % unlocks cursor