% Starting this script for robot task free-space exploration.
% Runs for 5 minutes. Target exists but is invisible.
%
% Beata Jarosiewicz, modified from Sergey Stavisky's 4D version, 8/18/2017
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_ROBOT))  % this is important

% helps debounce selections; won't allow new toggle for this many
% milliseconds after previous click
setModelParam('selectionRefractoryMS', uint16( 1500 ) ); % 

setModelParam('numDisplayDims', uint8(3) );
setModelParam('pause', true)
setModelParam('targetDiameter', 0.030) 
setModelParam('holdTime', inf)
setModelParam('cursorDiameter', 0.020)
setModelParam('trialTimeout', floor(1000*60*5)); % 5 minute max
setModelParam('maxTaskTime',floor(1000*60*5)); %5 minute max
setModelParam('numTrials', 130);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_NOTARGETS));
setModelParam('showScores', false);
% Define dimension mappings (these are standard but could in principle be
% changed)
setModelParam('xk2HorizontalPos', 1);
setModelParam('xk2HorizontalVel', 2);
setModelParam('xk2VerticalPos', 3);
setModelParam('xk2VerticalVel', 4);
setModelParam('xk2DepthPos', 5);
setModelParam('xk2DepthVel', 6);
setModelParam('xk2RotatePos', 7);
setModelParam('xk2RotateVel', 8);
setModelParam('xk2Rotate2Pos', 9);
setModelParam('xk2Rotate2Vel', 10);

% Uncomment below to use neural dim 4 for "flap"
% setModelParam('xk2RotatePos', 9);
% setModelParam('xk2RotateVel', 10);
% setModelParam('xk2Rotate2Pos', 7);
% setModelParam('xk2Rotate2Vel', 8);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

% No trials per se, so no recentering. Especially not with TASK_NOTARGETS,
% because then it may try to recenter to an impossible position
setModelParam('recenterOnFail', false); % no recentering
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);

numTargetsInt = uint16(1);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));

% Get the coordinates for all the radial targets
radius = 0.10; % 10 cm
targetOffscreen = [ 999 ; ...
                    999  ;...
%                     999  ;...
                    999 ];

targetIndsMat(1:3,1:numTargetsInt) = targetOffscreen;

setModelParam('workspaceY', double([-inf inf]));
setModelParam('workspaceX', double([-inf inf]));
setModelParam('workspaceZ', double([-inf inf]));
setModelParam('workspaceR',  double([0 0])); %BJ: freezing rotation
setModelParam('workspaceR2', double([0 0]));

setModelParam('targetInds', single(targetIndsMat));


%% Click parameters
cursor_click_enable;
setModelParam('stopOnClick', double( true ) );
setModelParam('hmmClickSpeedMax', double( 1e-3 ) ); % make more like 1e-5 for real


%% neural decode
loadFilterParams;

% % trying with bias killer off:
% enableBiasKiller([], 60000);  %use 60 sec time constant instead of default 30 for robot b/c movements are so slow
% setBiasFromPrevBlock;

% neural click
loadDiscreteFilterParams; % Returns loadedModel
% updateHMMThreshold(0.92, 0, loadedModel ); % open loop training params, prompt for block for recalc of likelihoods

% OR: set absolute LL threshold itself so can stay constant across blocks 
% even if frequency of click changes (centile is sensitive to % of time
% spent clicking):
curThresh = .9;
fprintf(1, 'Setting absolute HMM likelihood threshold to %01.2f ...', curThresh);
modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
setHMMThreshold(curThresh); % push variables

% a bit brittle, will fail if hmm wasn't trained this time
setModelParam('clickHoldTime', uint16(45)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 

%% Linear gain?
% gain_x = 0;
gain_x = 1.5;
% gain_x = 1; %0.7;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);

%% Exponetial gain?
setModelParam('powerGain', 2)
% setModelParam('powerGainUnityCrossing', 4.50e-05)
setModelParam('powerGainUnityCrossing', 1e-04)

% ensure bias killer is NOT enabled:
doResetBK = false;
unpauseOnAny(doResetBK);
setModelParam('biasCorrectionEnable',false);