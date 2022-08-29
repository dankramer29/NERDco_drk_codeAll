% Targets are at the 26 cardinal and diagonal endpoints of what woudl sort
% of be a 3x3x3 lattice, except that all the distances from the center are
% the same (10 cm).
%
% open loop autoplay for T5
%
% 
% Jan 5 2016
setModelParam('numDisplayDims', uint8(3) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('autoplayReactionTime', uint16( 200 ))  
setModelParam('autoplayMovementDuration', uint16( 1100 ))   % was 750, but T5 requested a bit slower on Feb 9 2017
setModelParam('pause', true)
setModelParam('targetDiameter', 0.020) 
setModelParam('holdTime', 350)
setModelParam('maxTaskTime',floor(1000*60*3));
setModelParam('cursorDiameter', 0.020)
setModelParam('clickHoldTime', 600)
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 129);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
% setModelParam('expRandMin', 500);  % irrelevant right?
% setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_AUTO_ACQUIRE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_AUTO_ACQUIRE));
setModelParam('showScores', false);
setModelParam('clickPercentage', 0);
setModelParam('stopOnClick', false);
setModelParam('soundOnOverTarget', false);

%% trackpad position to position gain parameters
%gain_x = 0.75;
% CP 20150824 - increasing open loop speed from 0.75
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
%% in the INPUT_TYPE_AUTO_ACQUIRE framework, gain(1) sets the cursor speed
setModelParam('gain', [gain_x gain_y gain_z 0 0]);
% setModelParam('mouseOffset', [0 0]); % irrelevant
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


disp('press any key to unpauseExpt');
pause();
disp('Starting in 5 seconds!')
pause(5)
unpauseExpt

