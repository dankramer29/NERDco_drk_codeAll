% Targets are at the 6 cardinal endpoints of a 3D axis,
% and then two rotations for each of these. Usedful for training because
% it's easy to understand where the targets are. 
%
% open loop autoplay for T5
% Feb 22 2017
setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('autoplayReactionTime', uint16( 200 ))  
setModelParam('autoplayMovementDuration', uint16( 1400 ))   % Translation
setModelParam('autoplayRotationStart', uint16( 200 ))   % Rotation start
setModelParam('autoplayRotationDuration', uint16( 1400 ))  % Rotation duration
setModelParam('pause', true)
setModelParam('targetDiameter', 0.050) 
setModelParam('holdTime', 350)
setModelParam('maxTaskTime',floor(1000*60*5));
setModelParam('cursorDiameter', 0.049)
setModelParam('trialTimeout', 5000);
setModelParam('numTrials', 120);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
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
% CP 20150824 - increasing open loop speed from 0.75
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain_r2 = 0;

%% in the INPUT_TYPE_AUTO_ACQUIRE framework, gain(1) sets the cursor speed
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);
numTargetsInt = uint16(12);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
radius = 0.10; % 10 cm
targsCardinal = [  -1 0 1  0 0  0   -1  0  1  0  0  0 ; ... 
                    0 1 0 -1 0  0    0  1  0 -1  0  0 ; ...
                    0 0 0  0 1 -1    0  0  0  0  1 -1 ; ...
                    1 1 1  1 1  1   -1 -1 -1 -1 -1 -1 ];

targetIndsMat(1:4,1:numTargetsInt) = [radius.*targsCardinal];
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));
setModelParam('workspaceR2', double([-0.13 0.13]));
setModelParam('targetInds', single(targetIndsMat));


disp('press any key to unpauseExpt');
pause();
disp('Starting in 3 seconds!')
pause(3)
unpauseExpt

