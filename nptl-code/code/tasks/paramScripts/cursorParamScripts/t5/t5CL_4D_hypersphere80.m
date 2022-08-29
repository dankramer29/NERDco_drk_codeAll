% Targets are at the 242 combinatiosn of [-1,0,1] across all dimensions.
%
% closed loop for T5
% March 14 2017

% low gain
setModelParam('holdTime', 50)   
setModelParam('targetDiameter', 0.050) 
setModelParam('cursorDiameter', 0.049)
gain_x = 0.33; % 

% regular gain% setModelParam('holdTime', 500)   
% setModelParam('targetDiameter', 0.050) 
% setModelParam('cursorDiameter', 0.049)
% gain_x = 1; % 


% "Medium" target sizes
% setModelParam('targetDiameter', 0.040) 
% setModelParam('cursorDiameter', 0.039)

% "Small" target sizes
% setModelParam('targetDiameter', 0.030) 
% setModelParam('cursorDiameter', 0.029)

% Nonlinear gain challenge sizes
setModelParam('targetDiameter', 0.02) 
setModelParam('cursorDiameter', 0.02)

setModelParam('splitDimensions', false)
setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('pause', true)
setModelParam('trialTimeout', 10000); %10s
setModelParam('maxTaskTime',floor(1000*60*10)); % 15 minute max
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


%% Standard Dimensionaliy mapping
setModelParam('xk2HorizontalPos', uint8(1) ); %red cursor horizontal is regular horizontal
setModelParam('xk2HorizontalVel', uint8(2) ); %red cursor horizontal is regular horizontal
setModelParam('xk2VerticalPos', uint8(3) ); %red cursor vertical is regular depth
setModelParam('xk2VerticalVel', uint8(4) ); %red cursor vertical is regular depth
setModelParam('xk2DepthPos', uint8(5) ); %blue cursor vertical is regular vertical
setModelParam('xk2DepthVel', uint8(6) ); %blue cursor vertical is regular vertical
setModelParam('xk2RotatePos', uint8(7) ); %blue cursor horizontal is regular rotate
setModelParam('xk2RotateVel', uint8(8) ); %blue cursor horizontal is regular rotate



% -----------------------------------------------------------------
%% Get the coordinates for all the  targets
% -----------------------------------------------------------------
radius = 0.10; %
targsFull = [];
% Generate the target sequence.
possibleCoordinates = [-1 0 1];
for i1 = 1  : numel( possibleCoordinates )
    for i2 = 1 :  numel( possibleCoordinates )
        for i3 = 1 :  numel( possibleCoordinates )
            for i4 = 1 :  numel( possibleCoordinates )
                addMe =  [possibleCoordinates(i1);
                    possibleCoordinates(i2);
                    possibleCoordinates(i3);
                    possibleCoordinates(i4)];
                if any( addMe ) % exlcudes zero
                    targsFull = [targsFull, addMe];
                end
                
            end
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
setModelParam('numTrials', 2*numTargetsInt); % out-and-back
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
% gain_x = 0.7; % first CL block


gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);

%%
% Exponetial gain?
setModelParam('powerGain', 2)
% setModelParam('powerGainUnityCrossing', 4.50e-05)
setModelParam('powerGainUnityCrossing', 2e-04)

doResetBK = false;
unpauseOnAny(doResetBK);