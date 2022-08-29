% Targets are endpoints of 1 dimension at a time. Useful for simulator
%
% open loop autoplay for T5
% March 10 2017, Sergey Stavisky
setModelParam('numDisplayDims', uint8(5) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('autoplayReactionTime', uint16( 200 ))  
setModelParam('autoplayMovementDuration', uint16( 2000 ))   % Translation
% Uncomment below to have rotation after translation
% setModelParam('autoplayRotationStart', uint16( 200+300+1000 ))   % Rotation start
% Uncomment below to have rotation with translation
setModelParam('autoplayRotationStart', uint16( 200 ))   % Rotation start
setModelParam('autoplayRotationDuration', uint16( 2000 ))  % Rotation duration
setModelParam('pause', true)
setModelParam('targetDiameter', 0.050) 
setModelParam('holdTime', 350)
setModelParam('maxTaskTime',floor(1000*60*6));
setModelParam('cursorDiameter', 0.049)
setModelParam('trialTimeout', 5000);
setModelParam('numTrials', 140); % once to each. 
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



%% in the INPUT_TYPE_AUTO_ACQUIRE framework, gain(1) sets the cursor speed

% Get the coordinates for all the radial targets
radius = 0.10; % Since the 2 rotationals takes up distance, the 3-space
               % distance ends being 10.6cm
targsFull = [  -1 0 1  0 0  0  0  0  0  0; ...
                0 1 0 -1 0  0  0  0  0  0; ...
                0 0 0  0 1 -1  0  0  0  0 ; ...
                0 0 0  0 0  0  1 -1  0  0 ; ...
                0 0 0  0 0  0  0  0  1 -1];
               

% scale to unit length
targsFull = targsFull ./ repmat( norms(targsFull), size(targsFull,1),1 );


numTargetsInt = uint16(size(targsFull,2));
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), ...
    double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:5,1:numTargetsInt) = targsFull;
targetIndsMat(1:5,1:numTargetsInt) = targetIndsMat(1:5,1:numTargetsInt).*radius;
fprintf('%i unique targets\n', size( unique( targsFull', 'rows') ,1) )


%%
setModelParam('numTargets', numTargetsInt);
setModelParam('targetInds', single(targetIndsMat));

%%
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));
setModelParam('workspaceR2', double([-0.13 0.13]));

%%
% Ensure no gain
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain_r2 = gain_x;
setModelParam('gain', [gain_x gain_y gain_z gain_r gain_r2]);
%setModelParam('exponentialGainBase', [1 1 1 1 1])



disp('press any key to unpauseExpt');
pause();
disp('Starting in 3 seconds!')
pause(3)
unpauseExpt

