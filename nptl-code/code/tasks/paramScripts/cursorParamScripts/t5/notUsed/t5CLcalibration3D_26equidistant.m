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
setModelParam('holdTime', 500)
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
gain_y = 1;
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


%% neural decode
loadFilterParams;


% DONT MEANS TRACK!
% startContinuousMeansTracking(true, true); 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);


enableBiasKiller;
setBiasFromPrevBlock;

doResetBK = true;
unpauseOnAny(doResetBK);