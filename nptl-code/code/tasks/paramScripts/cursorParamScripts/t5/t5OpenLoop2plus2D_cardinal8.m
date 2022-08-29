% Targets are at the 6 cardinal endpoints of a 3D axis,
% and then two rotations for each of these. Usedful for training because
% it's easy to understand where the targets are. 
%
% open loop autoplay for T5 using 2 cursors (!!)
% July 13 2017
setModelParam('splitDimensions', true)

setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('autoplayReactionTime', uint16( 700 ))  
setModelParam('autoplayMovementDuration', uint16( 1500 ))   % Translation
setModelParam('showXYZaura', false )

% Uncomment below to have rotation after translation
% setModelParam('autoplayRotationStart', uint16( 200+300+1000 ))   % Rotation start
% Uncomment below to have rotation with translation
setModelParam('autoplayRotationStart', uint16( 700 ))   % Rotation start
setModelParam('autoplayRotationDuration', uint16( 1500 ))  % Rotation duration
setModelParam('pause', true)
setModelParam('targetDiameter', 0.050) 
setModelParam('targetRotDiameter', 0.010) % irrelevant
setModelParam('holdTime', 450)
setModelParam('maxTaskTime',floor(1000*60*6));
setModelParam('numTrials', 2*80); % out-and-back
setModelParam('cursorDiameter', 0.029) % matches closed-loop
setModelParam('trialTimeout', 5000);
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



% Standard mapping for 2Plus2D, ultimately irrelevant because training
% looks at cursorPos, not xk
setModelParam('xk2HorizontalPos', uint8(1) ); %red cursor horizontal is regular horizontal
setModelParam('xk2HorizontalVel', uint8(2) ); %red cursor horizontal is regular horizontal
setModelParam('xk2VerticalPos', uint8(3) ); %red cursor vertical is regular depth
setModelParam('xk2VerticalVel', uint8(4) ); %red cursor vertical is regular depth
setModelParam('xk2DepthPos', uint8(5) ); %blue cursor vertical is regular vertical
setModelParam('xk2DepthVel', uint8(6) ); %blue cursor vertical is regular vertical
setModelParam('xk2RotatePos', uint8(7) ); %blue cursor horizontal is regular rotate
setModelParam('xk2RotateVel', uint8(8) ); %blue cursor horizontal is regular rotate


%%
% -----------------------------------------------------------------
%% Get the coordinates for all the  targets
% -----------------------------------------------------------------
% -----------------------------------------------------------------
%% Get the coordinates for all the  targets
% -----------------------------------------------------------------
radius = 0.12; %
targsFull = [  -1 0 1  0 0  0  0  0  ; ...
                0 1 0 -1 0  0  0  0  ; ...
                0 0 0  0 1 -1  0  0  ; ...
                0 0 0  0 0  0  1 -1  ]; 
               

% scale to unit length
targsFull = targsFull ./ repmat( norms(targsFull), size(targsFull,1),1 );
% multiply by radius
targsFull = targsFull.*radius;


%% Push the targets to model
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
numTargetsInt = uint16( size( targsFull, 2) );
targetIndsMat(1:4,1:numTargetsInt) = targsFull;

setModelParam('numTargets', numTargetsInt);
setModelParam('targetInds', single(targetIndsMat));
fprintf('%i unique radial targets (%i trials)\n', ...
    size( unique( targsFull, 'rows') ,2 ), getModelParam('numTrials' ) )


%%
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));
setModelParam('targetInds', single(targetIndsMat));


% Ensure no gain
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);

% Exponetial gain
setModelParam('powerGain', 1)
setModelParam('powerGainUnityCrossing', 4.50e-05)



disp('press any key to unpauseExpt');
pause();
disp('Starting in 3 seconds!')
pause(3)
unpauseExpt

