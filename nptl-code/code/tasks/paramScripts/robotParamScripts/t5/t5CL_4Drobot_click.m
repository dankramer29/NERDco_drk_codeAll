% Starting this script for robot task free-space exploration.
% Runs for 10 minutes, target exists but is invisible.
%
% Sergey Stavisky, Feb 10 2017
% setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_ROBOT))  % this is important

% helps debounce selections; won't allow new toggle for this many
% milliseconds after previous
setModelParam('selectionRefractoryMS', uint16( 1500 ) ); % 


setModelParam('numDisplayDims', uint8(4) );
setModelParam('pause', true)
setModelParam('targetDiameter', 0.030) 
setModelParam('holdTime', inf)
setModelParam('cursorDiameter', 0.020)
setModelParam('trialTimeout', floor(1000*60*16)); % 16 minute max
setModelParam('maxTaskTime',floor(1000*60*15)); %15 minute max
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
                    999  ;...
                    999 ];

targetIndsMat(1:4,1:numTargetsInt) = targetOffscreen;


setModelParam('workspaceY', double([-inf inf]));
setModelParam('workspaceX', double([-inf inf]));
setModelParam('workspaceZ', double([-inf inf]));
setModelParam('workspaceR', double([-inf inf]));
setModelParam('workspaceR2', double([0 0]));

setModelParam('targetInds', single(targetIndsMat));


%% Click parameters
cursor_click_enable;
setModelParam('stopOnClick', double( true ) );
setModelParam('hmmClickSpeedMax', double( 1e-3 ) ); % make more like 1e-5 for real


%% neural decode
loadFilterParams;


% YES bias killer
% enableBiasKiller;
% setBiasFromPrevBlock;
% setModelParam('biasCorrectionEnable',true);

% NO bias killer
setModelParam('biasCorrectionEnable',false);


% neural click
loadDiscreteFilterParams; % Returns loadedModel


% set absolute LL threshold itself so can stay constant across blocks 
% even if frequency of click changes (centile is sensitive to % of time
% spent clicking):
% curThresh = .85; % T5
curThresh = 0.9999; % rigH
fprintf(1, 'Setting absolute HMM likelihood threshold to %01.2f ...', curThresh);
% modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
setHMMThreshold(curThresh); % push variables

% a bit brittle, will fail if hmm wasn't trained this time
setModelParam('clickHoldTime', uint16(45)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 

%%
setModelParam('clickHoldTime', uint16(45)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 
setModelParam('hmmClickSpeedMax', double( inf ) ); 


%% Linear gain?
% gain_x = 0;
gain_x = 1;
% gain_x = 1; %0.7;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);

%% Exponetial gain?
setModelParam('powerGain', 1.5 )
setModelParam('powerGainUnityCrossing', 0.0005) 

% setModelParam('powerGain', 1 )
% setModelParam('powerGainUnityCrossing', 0.0005) 

% ensure bias killer is NOT enabled:
doResetBK = false;
unpauseOnAny(doResetBK);
setModelParam('biasCorrectionEnable',false);