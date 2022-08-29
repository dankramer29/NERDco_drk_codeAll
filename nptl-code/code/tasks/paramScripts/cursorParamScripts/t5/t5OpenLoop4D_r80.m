% Targets are at the 6 cardinal endpoints of a 3D axis,
% and then two rotations for each of these. Usedful for training because
% it's easy to understand where the targets are. 
%
% open loop autoplay for T5
% Feb 22 2017
setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('autoplayReactionTime', uint16( 200 ))  
setModelParam('autoplayMovementDuration', uint16( 1400 ))   % Translation
setModelParam('showXYZaura', false )

% Uncomment below to have rotation after translation
% setModelParam('autoplayRotationStart', uint16( 200+300+1000 ))   % Rotation start
% Uncomment below to have rotation with translation
setModelParam('autoplayRotationStart', uint16( 200 ))   % Rotation start
setModelParam('autoplayRotationDuration', uint16( 1400 ))  % Rotation duration
setModelParam('pause', true)
setModelParam('targetDiameter', 0.050) 
setModelParam('targetRotDiameter', 0.010) 
setModelParam('holdTime', 350)
setModelParam('maxTaskTime',floor(1000*60*6));
setModelParam('cursorDiameter', 0.049)
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
setModelParam('splitDimensions', false)


%%
% -----------------------------------------------------------------
%% Get the coordinates for all the  targets
% -----------------------------------------------------------------
radius = 0.12; % larger during autoplay than evaluation
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


%% Standard Dimensionaliy mapping
setModelParam('xk2HorizontalPos', uint8(1) ); %red cursor horizontal is regular horizontal
setModelParam('xk2HorizontalVel', uint8(2) ); %red cursor horizontal is regular horizontal
setModelParam('xk2VerticalPos', uint8(3) ); %red cursor vertical is regular depth
setModelParam('xk2VerticalVel', uint8(4) ); %red cursor vertical is regular depth
setModelParam('xk2DepthPos', uint8(5) ); %blue cursor vertical is regular vertical
setModelParam('xk2DepthVel', uint8(6) ); %blue cursor vertical is regular vertical
setModelParam('xk2RotatePos', uint8(7) ); %blue cursor horizontal is regular rotate
setModelParam('xk2RotateVel', uint8(8) ); %blue cursor horizontal is regular rotate


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

