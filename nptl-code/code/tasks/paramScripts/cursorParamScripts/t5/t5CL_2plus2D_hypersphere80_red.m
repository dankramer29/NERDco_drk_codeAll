% Simlified 2plus2D, where only RED target coordinates vary from zero.
%
% closed loop for T5
% July 13 2017

setModelParam('holdTime', 200)                           
% % % "Large" target sizes
setModelParam('targetDiameter', 0.090) 
setModelParam('cursorDiameter', 0.029)

% "Medium" target sizes
% setModelParam('targetDiameter', 0.040) 
% setModelParam('cursorDiameter', 0.039)

% "Small" target sizes
% setModelParam('targetDiameter', 0.030) 
% setModelParam('cursorDiameter', 0.029)


setModelParam('splitDimensions', true)
setModelParam('numDisplayDims', uint8(4) ); 
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('pause', true)
setModelParam('trialTimeout', 90000); %90s
setModelParam('maxTaskTime',floor(1000*60*15)); % 15 minute max
setModelParam('randomSeed', 1);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',1);
setModelParam('preTrialLength',20 );

% Dimensionality mapping: regular
setModelParam('xk2HorizontalPos', uint8(1) ); %red cursor horizontal is regular horizontal
setModelParam('xk2HorizontalVel', uint8(2) ); %red cursor horizontal is regular horizontal
setModelParam('xk2VerticalPos', uint8(5) ); %red cursor vertical is regular depth
setModelParam('xk2VerticalVel', uint8(6) ); %red cursor vertical is regular depth
setModelParam('xk2DepthPos', uint8(7) ); %blue cursor vertical is regular vertical
setModelParam('xk2DepthVel', uint8(8) ); %blue cursor vertical is regular vertical
setModelParam('xk2RotatePos', uint8(3) ); %blue cursor horizontal is regular rotate
setModelParam('xk2RotateVel', uint8(4) ); %blue cursor horizontal is regular rotate


%% use these if trained OL on 2+2D
% setModelParam('xk2HorizontalPos', uint8(1) ); %red cursor horizontal is regular horizontal
% setModelParam('xk2HorizontalVel', uint8(2) ); %red cursor horizontal is regular horizontal
% setModelParam('xk2VerticalPos', uint8(3) ); %red cursor vertical is regular depth
% setModelParam('xk2VerticalVel', uint8(4) ); %red cursor vertical is regular depth
% setModelParam('xk2DepthPos', uint8(5) ); %blue cursor vertical is regular vertical
% setModelParam('xk2DepthVel', uint8(6) ); %blue cursor vertical is regular vertical
% setModelParam('xk2RotatePos', uint8(7) ); %blue cursor horizontal is regular rotate
% setModelParam('xk2RotateVel', uint8(8) ); %blue cursor horizontal is regular rotate


setModelParam('maxTaskTime', 60*10*1000);


% -----------------------------------------------------------------
%% Get the coordinates for all the  targets
% -----------------------------------------------------------------
radius = 0.10; %
targsFull = [];
% Generate the target sequence.
possibleCoordinates = [-1 0 1];
for i1 = 1  : numel( possibleCoordinates )
    for i2 = 1 :  numel( possibleCoordinates )
        
        addMe =  [possibleCoordinates(i1);
            possibleCoordinates(i2);
            0;
            0];
        if any( addMe ) % exlcudes zero
            targsFull = [targsFull, addMe];
        end
    end
end

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
setModelParam('numTrials', 3*2*numTargetsInt); % out-and-back
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
% setBiasFromPrevBlock;


% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
%% setModelParam('meansTrackingPeriodMS',0);

% Linear gain
% RED CURSOR GAIN
gain_red_x = 1; 
gain_red_y = gain_red_x; % 

% BLUE CURSOR GAIN
gain_blue_x = 0.2;
gain_blue_y = gain_blue_x;

gain = getModelParam('gain');
gain(1:4) = [gain_red_x gain_red_y gain_blue_x gain_blue_y];
setModelParam('gain', gain);

%%
% Exponetial gain?
setModelParam('powerGain', 1)
% setModelParam('powerGainUnityCrossing', 4.50e-05)
setModelParam('powerGainUnityCrossing', 2e-05)

doResetBK = false;
unpauseOnAny(doResetBK);