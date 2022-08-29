PIXEL_DIST_FROM_CENTER = 409; 
AUX_COLOR = [0; 204; 102;];
EFFECTOR_COLOR = [255; 255; 255];
%% neural decode
loadFilterParams;

%%
% enableBiasKiller([],[],true,model.beta);
% enableBiasKiller([],[],true, .1);
 enableBiasKiller([],[],true,model.beta);
% enableBiasKiller([],[],true, .1);
%setModelParam('biasCorrectionTau',1000);
setModelParam('biasCorrectionTau',5500*(0.1/1000));

 setBiasFromPrevBlock;
% default gain
gain_x = 0; % so cursor is still during pre state
gain_y = gain_x;
gainCorrectDim =  getModelParam('gain');
gainCorrectDim(1) = gain_x;
gainCorrectDim(2) = -gain_y;
setModelParam('gain', gainCorrectDim);
setModelParam('mouseOffset', [0 0]);
setModelParam('tau', 0.03); 
% number of trials
setModelParam('numTrials', 48); %this should be size(stimulus matrix,1). 
setModelParam('maxTaskTime',1000*60*12);

% task params
setModelParam('targetDiameter', 200); %for center and report targs
setModelParam('cursorDiameter', 50);
setModelParam('holdTime', 400);
setModelParam('trialTimeout', 3500);
setModelParam('intertrialTime', 200); % ms
setModelParam('preTrialLength',100 );
setModelParam('coherences', uint16([0 4 7 10 15 30 80])); %defaults, needs to be length = 7
setModelParam('moveThresh', single(.2)); % in (meters per mm)*10,000
setModelParam('taskOrder', uint16(1)); % checkerboard first SF copy this line to targets first param scripts, but with 0

% viz: 
cursorColors = [EFFECTOR_COLOR, AUX_COLOR, zeros(3,1)];
setModelParam('cursorColors', uint16(cursorColors)); 
setModelParam('gridSize', 150); %in pixels
setModelParam('crossSize', 20); %in pixels
%%
doResetBK = true;
gainCorrectDim =  zeros( size( getModelParam('gain') ) );
% Use these gains for regular train 2D, evaluate 2D operation:
gainCorrectDim(1) = 8000;
gainCorrectDim(2) = 7000; % gainCorrectDim(1);
setModelParam('gain', gainCorrectDim );
%% here to make it easy for Operator to quickly change gain
% gain_manual = 1;
% gainCorrectDim = zeros( size( getModelParam('gain') ) );
% gainCorrectDim(1) = gain_manual; gainCorrectDim(2) = gain_manual;
% setModelParam('gain', gainCorrectDim );
%%
% task
% task
setModelParam('taskType', uint32(cursorConstants.TASK_BCI_REPORT));
%setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_AUTO_ACQUIRE));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_CURSOR_HEADSTILL));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('numDisplayDims', uint8(2) ); %SF changed this from 4 to 2

% other params
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 1);
setModelParam('expRandMu', 600); %% this is the trial delay length parameter
setModelParam('expRandMin', 400); %minimum time spent in delay and fixation period
%setModelParam('expRandMax', 1500);
setModelParam('maxFixDur', 1000); %max time spent fixating
setModelParam('maxTargDur', 800); %max time spent before targets appear
setModelParam('maxStimDur', 3000); %max time to see stimulus 
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