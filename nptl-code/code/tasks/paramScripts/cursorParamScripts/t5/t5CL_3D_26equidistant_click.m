% Targets are at the 26 cardinal and diagonal endpoints of what woudl sort
% of be a 3x3x3 lattice, except that all the distances from the center are
% the same (10 cm).
%
% closed loop recalibration  for T5
% Jan 5 2017
setModelParam('numDisplayDims', uint8(3) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('pause', true)
setModelParam('targetDiameter', 0.040) 
setModelParam('holdTime', inf)
setModelParam('cursorDiameter', 0.020)
setModelParam('trialTimeout', 10000);
setModelParam('maxTaskTime',floor(1000*60*10)); % 10 minute max
setModelParam('numTrials', 130);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);


gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
setModelParam('gain', [gain_x gain_y gain_z 1]);
setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(26);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));


% Get the coordinates for all the radial targets
radius = 0.10; % 10 cm
targsCardinal = [  -1 0 1  0 0  0 ; ...
                    0 1 0 -1 0  0 ; ...
                    0 0 0  0 1 -1 ];
targs2dCorner = [-0.7071 0.7071  0.7071 -0.7071 -0.7071 0.7071 -0.7071  0.7071      0       0       0       0; ...
                  0.7071 0.7071 -0.7071 -0.7071       0      0       0       0 0.7071 -0.7071  0.7071 -0.7071; ...
                       0      0       0       0  0.7071 0.7071 -0.7071 -0.7071 0.7071  0.7071 -0.7071 -0.7071];
targs3dCorner = [-0.5774 0.5774 -0.5774  0.5774  -0.5774  0.5774 -0.5774  0.5774; ...
                  0.5774 0.5774 -0.5774 -0.5774   0.5774  0.5774 -0.5774 -0.5774; ...
                  0.5774 0.5774  0.5774  0.5774  -0.5774 -0.5774 -0.5774 -0.5774];

targetIndsMat(1:3,1:numTargetsInt) = [targsCardinal, targs2dCorner, targs3dCorner].*radius;


setModelParam('workspaceY', double([-0.12 0.12]));
setModelParam('workspaceX', double([-0.12 0.12]));
setModelParam('workspaceZ', double([-0.12 0.12]));
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



% neural click
loadDiscreteFilterParams;
updateHMMThreshold(0.87, 0, loadedModel); % open loop training params, prompt for block for recalc of likelihoods
% a bit brittle, will fail if hmm wasn't trained this time
setModelParam('clickHoldTime', uint16(15)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 


% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);

% Linear gain?
setModelParam('gain', [1 1 1 0]);

% Exponetial gain?
setModelParam('exponentialGainBase', 1.4)
% setModelParam('exponentialGainBase', 1)
setModelParam('exponentialGainUnityCrossing', 4.0000e-05)


doResetBK = false;
unpauseOnAny(doResetBK);