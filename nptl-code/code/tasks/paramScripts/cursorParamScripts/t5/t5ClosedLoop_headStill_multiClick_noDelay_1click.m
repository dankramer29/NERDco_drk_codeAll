%% This task is the online control of 4 different click targets and radial 8 spatial targets 
% lower hold time for open loop
centerTime = 500; %this is for dwell target hold (center target) which also is the recenter delay
setModelParam('holdTime', centerTime);
setModelParam('trialTimeout', 9000);
setModelParam('autoplayMovementDuration', 2250);
setModelParam('soundOnOverTarget', false);
%setModelParam('numTrials', 160); % real
setModelParam('numTrials', 64); % dev
% max task duration
setModelParam('maxTaskTime',1000*60*12); %SF: make it long enough to do 160 trials
% set to actively acquire targets
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_CURSOR_HEADSTILL));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
% setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_AUTO_ACQUIRE));
% setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_AUTO_ACQUIRE));
%%  decoders
loadFilterParams;
enableBiasKiller([],[],true,model.beta);
%setBiasFromPrevBlock;
loadDiscreteFilterParams;
%% Click parameters
cursor_click_enable;

% Click Fails
setModelParam('selectionRefractoryMS', uint16( 500 ) ); % grace period. Used for both click and dwell

setModelParam('stopOnClick', double( true ) );
setModelParam('hmmClickSpeedMax', double( inf ) ); % no max speed
% setModelParam('hmmClickSpeedMax', double( 1e-3 ) ); % 

% neural click
% to set threshold to a LL centile:
% updateHMMThreshold(0.89, 0, loadedModel); % open loop training params, prompt for block for recalc of likelihoods
% % % a bit brittle, will fail if hmm wasn't trained this time
% to set threshold to an actual LL value:
curThresh = 0.96;
fprintf(1, 'Setting absolute HMM likelihood threshold to %01.2f ...', curThresh);
modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
setHMMThreshold(curThresh); % push variables
setModelParam('clickHoldTime', uint16(40));
%% set gains and bias killer
doResetBK = true;
gainCorrectDim =  zeros( size( getModelParam('gain') ) );
% Use these high gains if using a SCL decoder (which uses meters as units)
% for the 2D PsychToolbox task (which uses pixels)
% gainCorrectDim(1) = 5000;
% gainCorrectDim(2) = 5000;
% Use these gains for regular train 2D, evaluate 2D operation:
gainCorrectDim(1) = 3500; % YES even for train 2D test 2D, because of Frank refactor
gainCorrectDim(2) = gainCorrectDim(1);
setModelParam('gain', gainCorrectDim); 
%% T5 asked for slower than it was at 1
% gain_x = 1.0;
% gain_y = gain_x;
% setModelParam('gain', [gain_x gain_y 0 0 0]); % BJ May 2017: now 5D
%% Targets
%numTargetsInt = uint16(8);
NUM_TRANS_TARGS = 8;
NUM_CLICK_TARGS = 1; 
numTargetsInt = uint16(NUM_TRANS_TARGS * NUM_CLICK_TARGS);
setModelParam('numTargets', numTargetsInt);

targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:2,1:numTargetsInt)  = repmat([  0   289 409  289    0 -289 -409 -289; ...
                                                409 289   0 -289 -409 -289    0  289], 1, NUM_CLICK_TARGS);
% targetIndsMat(1:2,1:numTargetsInt)  = [0 316 447  316    0 -316 -447 -316; ...
%                                      447 316   0 -316 -447 -316     0 316];
setModelParam('targetInds', single(targetIndsMat));

clickTargs = uint16(zeros(1, double(cursorConstants.MAX_TARGETS))); 
for clickI = 1:NUM_CLICK_TARGS
    clickTargs((clickI-1)*NUM_TRANS_TARGS+1:NUM_TRANS_TARGS*clickI) = repmat(clickI, 1, NUM_TRANS_TARGS);
end
setModelParam('clickTargs', uint16(clickTargs));
%% task
%setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('taskType', uint32(cursorConstants.TASK_MULTICLICK)); %this is for sure getting sent correctly
setModelParam('numDisplayDims', uint8(2) );
% Target and cursor sizes
setModelParam('targetDiameter', 170);
setModelParam('cursorDiameter', 45);
% Head movement params 
setModelParam('headSpeedCap', 10);
setModelParam('doHeadSpeedFail', true); %SNF test
% other params
setModelParam('randomSeed', 1);
%setModelParam('useRandomDelay', 1);
%setModelParam('expRandMu', 1000); %% this is the trial delay length parameter
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0);
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('showScores', false);
setModelParam('trialsPerScore', uint16(48));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', true); %SNF: skip recenter for CL trials 
setModelParam('recenterDelay',centerTime); %how long you hold on the center target 
setModelParam('preTrialLength',20 );
setModelParam('failOnLiftoff', false);
setModelParam('clickPercentage', 0); % all dwell by default
setModelParam('stopOnClick', false);
setModelParam('stopOffTarget', false);
setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics

% Brief unpause  so game sends over target coordinates before pausing again
% This avoids having flashing of PTB on and off at game start
setModelParam('pause', false);
pause(0.100); 
setModelParam('pause', true);

doResetBK = false;
unpauseOnAny(doResetBK);
