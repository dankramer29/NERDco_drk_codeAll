% Targets are at the 26 cardinal and diagonal endpoints of what woudl sort
% of be a 3x3x3 lattice, except that all the distances from the center are
% the same (10 cm).
%
% closed loop recalibration  for T5
% Jan 5 2017

% Large targets
% setModelParam('targetDiameter', 0.040) 
% setModelParam('holdTime', 500)
% setModelParam('cursorDiameter', 0.020)

% Medium Targets
% setModelParam('targetDiameter', 0.030) 
% setModelParam('holdTime', 500)
% setModelParam('cursorDiameter', 0.020)

% Small Targets
% setModelParam('targetDiameter', 0.020) 
% setModelParam('holdTime', 500)
% setModelParam('cursorDiameter', 0.020)


% "blow-through
setModelParam('targetDiameter', 0.030) 
setModelParam('holdTime', 00)
setModelParam('cursorDiameter', 0.020)


setModelParam('numDisplayDims', uint8(3) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('pause', true)
setModelParam('trialTimeout', 15000);
setModelParam('maxTaskTime',floor(1000*60*10)); % 10 minute max
setModelParam('numTrials', 104);
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

% gain_x = 1.2;
gain_x = 0.6;
gain_y = gain_x;
gain_z = gain_x;
setModelParam('gain', [gain_x gain_y gain_z 0 0]);
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

setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('targetInds', single(targetIndsMat));


%% neural decode
loadFilterParams;


 
% now disable mean updating
% startContinuousMeansTracking(true, true);
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;

doResetBK = true;
unpauseOnAny(doResetBK);