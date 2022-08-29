% Targets are at the 8 combinations of [-1 or 1] in just one of the four dimensions at a
% time.
%
% closed loop for T5
% June 25 2017

setModelParam('holdTime', 500)                           
% % % "Large" target sizes
% setModelParam('targetDiameter', 0.050) 
% setModelParam('cursorDiameter', 0.049)

% % "Medium" target sizes
setModelParam('targetDiameter', 0.040) 
setModelParam('cursorDiameter', 0.039)

% "Small" target sizes
% setModelParam('targetDiameter', 0.030) 
% setModelParam('cursorDiameter', 0.029)


setModelParam('numTrials', 8*2*8); % 64 times out-and-back; 8 repetitions of each target.
setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('pause', true)
setModelParam('trialTimeout', 10000); %10s
setModelParam('maxTaskTime',floor(1000*60*15)); % 15 minute max
setModelParam('randomSeed', 1);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);
setModelParam('preTrialLength',20 );


% -----------------------------------------------------------------
%% Get the coordinates for all the  targets
% -----------------------------------------------------------------
radius = 0.10; %
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
    size( unique( targsFull, 'rows') ,2 ), 2*numTargetsInt )


%%
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));
setModelParam('workspaceR2', double([0 0]));


%% neural decode
loadFilterParams;

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;


% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
%% setModelParam('meansTrackingPeriodMS',0);

% Linear gain?
gain_x = 1; % first CL block
%gain_x = 0.7; % 

gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);

%%
% Exponetial gain?
setModelParam('powerGain', 1)
% setModelParam('powerGainUnityCrossing', 4.50e-05)
setModelParam('powerGainUnityCrossing', 2e-05)

doResetBK = false;
unpauseOnAny(doResetBK);