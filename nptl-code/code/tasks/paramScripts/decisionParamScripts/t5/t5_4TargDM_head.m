PIXEL_DIST_FROM_CENTER = 409; 
AUX_COLOR = [0; 204; 102;];
EFFECTOR_COLOR = [255; 255; 255];
% default gain
gain_x = 0; % so cursor is still during pre state
gain_y = gain_x;
gainCorrectDim =  getModelParam('gain');
gainCorrectDim(1) = gain_x;
gainCorrectDim(2) = gain_y;
setModelParam('gain', gainCorrectDim);
setModelParam('mouseOffset', [0 0]);

% number of trials
setModelParam('numTrials', 48); %this should be size(stimulus matrix,1). 
<<<<<<< HEAD
setModelParam('maxTaskTime',1000*60*12); % 12 minute blocks
=======
setModelParam('maxTaskTime',1000*60*12); % 6 minute blocks
>>>>>>> 58f59cd556699c3db3f8b0472343d7c23f6279a0

% task params
setModelParam('targetDiameter', 100); %for center and report targs
setModelParam('cursorDiameter', 50);
setModelParam('holdTime', 400);
setModelParam('trialTimeout', 6000);
setModelParam('intertrialTime', 300); % ms
setModelParam('preTrialLength',200 );
setModelParam('taskOrder', uint16(0)); % checkerboard first SF copy this line to targets first param scripts, but with 0
setModelParam('coherences', uint16([0 4 7 10 15 30 80])); %defaults
% viz: 
cursorColors = [EFFECTOR_COLOR, AUX_COLOR, zeros(3,1)];
setModelParam('cursorColors', uint16(cursorColors)); 
setModelParam('gridSize', 150); %in pixels
setModelParam('crossSize', 20); %in pixels
%%
doResetBK = true;
gainCorrectDim =  zeros( size( getModelParam('gain') ) );
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
setModelParam('taskType', uint32(cursorConstants.TASK_HEAD_REPORT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_HEAD_MOUSE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('numDisplayDims', uint8(2) ); %SF changed this from 4 to 2

% other params
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 1);
setModelParam('expRandMu', 1000); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
%setModelParam('expRandMax', 1500);
setModelParam('maxFixDur', 1000); %max time spent fixating
setModelParam('maxTargDur', 900); %max time spent with just the targets up
setModelParam('maxStimDur', 5000); %max time to see stimulus 
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('showScores', false); %this'll be true for some states
setModelParam('trialsPerScore', uint16(48));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);

setModelParam('failOnLiftoff', false);
setModelParam('clickPercentage', 0); % all dwell by default
setModelParam('stopOnClick', false);
setModelParam('stopOffTarget', false);
setModelParam('mouseOffset', [0 0]);
setModelParam('headSpeedCap', 10);
% zero gain at start
setModelParam('gain', zeros( size( getModelParam('gain') ) ));

% set targets & workspace bounds
nTargs = 4;
%radial4 = zeros(2, nTargs);
% this target order goes: down, left, up, right. 
radial4 = [0 -1 0 1; -1 0 1 0]; %SNF will get clever about this later- first two are targ 1
fullPattern = PIXEL_DIST_FROM_CENTER .* radial4;

numTargetsInt = uint16(size(fullPattern,2));
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS),  double(cursorConstants.MAX_TARGETS)])); %SF wonders if the MAX_TARGETS thing is for the compiler
targetIndsMat(1:2,1:numTargetsInt)  = round(fullPattern);
setModelParam('numTargets', numTargetsInt);

% 539 and 959 below keep it visible, otherwise it's 1 pixel too far and thus offscreen
setModelParam('workspaceY', double([-540 539]));
setModelParam('workspaceX', double([-960 959]));
%targetInds is of size
%single(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), cursorConstants.MAX_TARGETS]))
setModelParam('targetInds', single(targetIndsMat)); 

setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics

% Brief unpause  so game sends over target coordinates before pausing again
% This avoids having flashing of PTB on and off at game start
setModelParam('pause', false);
pause(0.100); 
setModelParam('pause', true);

unpauseOnAny(doResetBK);
setModelParam('gain', gainCorrectDim); % unlocks cursor