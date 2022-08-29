% Starting this script for robot task free-space exploration.
% Runs for 10 minutes, target exists but set far outside of workspace, so 
% has no effect.
%
% Sergey Stavisky, Feb 10 2017

setModelParam('xk2HorizontalPos', uint8(7))
setModelParam('xk2HorizontalVel', uint8(8))

setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_ROBOT))  % this is important
setModelParam('pause', true)
setModelParam('targetDiameter', 0.030) 
setModelParam('holdTime', inf)
setModelParam('cursorDiameter', 0.020)
setModelParam('trialTimeout', floor(1000*60*15)); % 10 minute max
setModelParam('maxTaskTime',floor(1000*60*15)); % 10 minute max
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

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

% No trials per se, so no recentering. Especially not with TASK_NOTARGETS,
% because then it may try to recenter to an impossible position
setModelParam('recenterOnFail', false); % no recentering
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);

gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r1 = 0;
gain_r2 = 0;
setModelParam('gain', [gain_x gain_y gain_z gain_r1 gain_r2]);
setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(1);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));


% Get the coordinates of all the radial targets
radius = 0.10; % 10 cm
targetOffscreen = [ 999 ; ...
                    999  ;...
                    999 ];

targetIndsMat(1:3,1:numTargetsInt) = targetOffscreen;

% These are all within xPC game 
setModelParam('workspaceY', double([-0.20 0.20]));
setModelParam('workspaceX', double([-0.20 0.20]));
setModelParam('workspaceZ', double([-0.20 0.20]));
setModelParam('targetInds', single(targetIndsMat));


%% Click parameters
cursor_click_enable;
setModelParam('stopOnClick', double( false ) );
setModelParam('hmmClickSpeedMax', double( 1e-3 ) ); % make more like 1e-5 for real


%% neural decode
loadFilterParams;

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;

% Linear gain?
setModelParam('gain', [3 3 3 1 1]);

% Exponetial gain?
% setModelParam('exponentialGainBase', 1)
% setModelParam('exponentialGainUnityCrossing', 3.0000e-05)

doResetBK = false;
unpauseOnAny(doResetBK);