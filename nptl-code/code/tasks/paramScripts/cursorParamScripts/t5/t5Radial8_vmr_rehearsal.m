radial8Task();

% forces it to be 2D and also makes SCL cursor task decoders work with a
% high enough gain in pixel land that it's controllable.

% number of trials
setModelParam('numTrials', 800);
% max task duration
setModelParam('maxTaskTime',1000*60*10);

% task params

setModelParam('targetDiameter', 100);
setModelParam('cursorDiameter', 45);
setModelParam('holdTime', 300);
setModelParam('trialTimeout', 2000);

% setModelParam('targetDiameter', 250); % DEV
% setModelParam('holdTime', 800);

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
setModelParam('numDisplayDims', uint8(2) );
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_HEAD_MOUSE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_HEAD_MOUSE));



% other params
setModelParam('vmrTheta',0);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
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

setModelParam('freePlayMode',uint16(1));
setModelParam('doHeadSpeedFail',true);
setModelParam('headSpeedCap',single(0.16));
setModelParam('drawNumbersOnTargets',uint8(1));

% zero gain at start

setModelParam('gain', zeros( size( getModelParam('gain') ) ));


% set targets & workspace bounds
numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:2,1:numTargetsInt)  = [  0 289 409  289    0 -289 -409 -289; ...
                                       409 289   0 -289 -409 -289    0 289];
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
