% Targets are at the 6 cardinal endpoints of a 3D axis -- useeful insofar
% as it is very easy to understand where they are.
%
% open loop autoplay for T5
% Dec 20 2016
setModelParam('numDisplayDims', uint8(3) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('autoplayReactionTime', uint16( 200 ))  
setModelParam('autoplayMovementDuration', uint16( 2000 ))  % in ms
setModelParam('pause', true)
setModelParam('targetDiameter', 0.020) 
setModelParam('holdTime', 200)
setModelParam('maxTaskTime',floor(1000*60*3));
setModelParam('cursorDiameter', 0.020)
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 120);
% setModelParam('numTrials', 60); % DEV 
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
setModelParam('gain', [gain_x gain_y gain_z 1 1]);  %I'm guessing
% setModelParam('mouseOffset', [0 0]); % irrelevant
numTargetsInt = uint16(6);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:3,1:numTargetsInt)  = [   0  0.10       0  -0.10        0      0     ; ...
                                       0.10     0   -0.10      0        0      0   ; ...
                                          0     0       0      0     0.10  -0.10   ];
setModelParam('workspaceY', double([-0.12 0.12]));
setModelParam('workspaceX', double([-0.12 0.12]));
setModelParam('workspaceZ', double([-0.12 0.12]));
setModelParam('targetInds', single(targetIndsMat));


disp('press any key to unpauseExpt');
pause();
unpauseExpt

