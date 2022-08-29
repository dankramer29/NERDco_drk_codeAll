% Targets are around a hypersphere. In 3D, there are 26 target locations
% (brought-in vertices of a 3x3x3 grid). in dims 4 and 5, only 1 rotation
% is applied a time (for now), to try to reduce cogntivie burden.
%
% open loop autoplay for T5
% March 10 2017, Sergey Stavisky
setModelParam('numDisplayDims', uint8(5) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
% setModelParam('displayObject', uint8(cursorConstants.OBJECT_HAMMER ) )
setModelParam('displayObject', uint8(cursorConstants.OBJECT_ROD ) )

setModelParam('autoplayReactionTime', uint16( 400 ))  
setModelParam('autoplayMovementDuration', uint16( 1500 ))   % Translation 
% Uncomment below to have rotation after translation
% setModelParam('autoplayRotationStart', uint16( 200+300+1000 ))   % Rotation start
% Uncomment below to have rotation with translation
setModelParam('autoplayRotationStart', uint16( 400 ))   % Rotation start
setModelParam('autoplayRotationDuration', uint16( 1500 ))  % Rotation duration
setModelParam('pause', true)
setModelParam('targetDiameter', 0.050) 
setModelParam('targetRotDiameter', 0.005) 
setModelParam('holdTime', 350)
setModelParam('maxTaskTime',floor(1000*60*6));
setModelParam('cursorDiameter', 0.049)
setModelParam('trialTimeout', 5000);
setModelParam('numTrials', 208); % once to each. Should be ~6.5 minutes
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
radius = 0.15; % Since the 2 rotationals takes up distance, the 3-space
               % distance ends being 10.6cm
targsCardinal = [  -1 0 1  0 0  0 ; ...
                    0 1 0 -1 0  0 ; ...
                    0 0 0  0 1 -1 ];
targs2dCorner = [-1 1  1 -1 -1 1 -1  1 0  0  0  0; ...
                  1 1 -1 -1  0 0  0  0 1 -1  1 -1; ...
                  0 0  0  0  1 1 -1 -1 1  1 -1 -1];
targs3dCorner = [-1 1 -1  1  -1  1 -1  1; ...
                  1 1 -1 -1   1  1 -1 -1; ...
                  1 1  1  1  -1 -1 -1 -1];
targs3dCombined =  [targsCardinal, targs2dCorner, targs3dCorner];
% now add the rotation possibilities
possibleRot1 = [-1, 1];
possibleRot2 = [-1, 1];
targsFull = [];


% Two different layouts, either combining the rotations, or doing one at a time. Either
% way creates 26*4 targets
% BELOW HAS 1 ROTATION AT A TIME
% This is the suggested way
for iRot = 1 : numel( possibleRot1 )
    targsFull = [targsFull, [targs3dCombined; repmat( [possibleRot1(iRot); 0], 1, size( targs3dCombined, 2 ) )]];
end
for iRot = 1 : numel( possibleRot2 )
    targsFull = [targsFull, [targs3dCombined; repmat( [0; possibleRot2(iRot)], 1, size( targs3dCombined, 2 ) )]];
end

% BELOW COMBINES THE TWO ROTATIONS
% for iRot1 = 1 : numel( possibleRot1 )
%     for iRot2 = 1 : numel( possibleRot2 )
%         targsFull = [targsFull, [targs3dCombined; repmat( [possibleRot1(iRot1);possibleRot2(iRot2)], 1, size( targs3dCombined, 2 ) )]];
%     end
% end


% scale to unit length
targsFull = targsFull ./ repmat( norms(targsFull), size(targsFull,1),1 );


numTargetsInt = uint16(size(targsFull,2));
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));

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
setModelParam('exponentialGainBase', [1 1 1 1 1])



disp('press any key to unpauseExpt');
pause();
disp('Starting in 3 seconds!')
pause(3)
unpauseExpt

