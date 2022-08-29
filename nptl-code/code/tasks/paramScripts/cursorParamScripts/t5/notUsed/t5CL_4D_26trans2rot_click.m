% Targets are at the 26 cardinal and diagonal endpoints of what woudl sort
% of be a 3x3x3 lattice, except that all the distances from the center are
% the same (9 cm). There are 5 rotation targets possible at each radial
% location at {-1,0,1}, where -1 corresponds to as far along the
% rotation range as each radial target is along its x,y,z range.
%
% Also includes [0,0,0,1] and [0,0,0,-1], i.e. rotation only
%
% closed loop for T5
% March 10 2017

% "Large" target sizes
setModelParam('targetDiameter', 0.050) 
setModelParam('targetRotDiameter', 0.050) % 
setModelParam('cursorDiameter', 0.049)

% "Medium" target sizes
% setModelParam('targetDiameter', 0.040) 
% setModelParam('targetRotDiameter', 0.040) % 
% setModelParam('cursorDiameter', 0.039)

% "Small" target sizes
% setModelParam('targetDiameter', 0.030) 
% setModelParam('targetRotDiameter', 0.030) % 
% setModelParam('cursorDiameter', 0.029)



setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('pause', true)
setModelParam('holdTime', inf)
setModelParam('trialTimeout', 10000);
setModelParam('maxTaskTime',floor(1000*60*15)); % 15 minute max
setModelParam('numTrials', 160); % gets through each target (and back) once
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);



setModelParam('mouseOffset', [0 0]);



% Get the coordinates for all the radial targets
radius = 0.10; % 10.5 cm
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
possibleRot1 = [-1, 0, 1];
targsFull = [];
for iRot = 1 : numel( possibleRot1 )
    targsFull = [targsFull, [targs3dCombined; repmat( possibleRot1(iRot), 1, size( targs3dCombined, 2 ) )]];
end
% add rotation only
targsFull = [targsFull, [0;0;0; 1],[0;0;0; -1]];
% scale to unit length
targsFull = targsFull ./ repmat( norms(targsFull), size(targsFull,1),1 );

numTargetsInt = uint16(size(targsFull,2));
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));

targetIndsMat(1:4,1:numTargetsInt) = targsFull;
targetIndsMat(1:4,1:numTargetsInt) = targetIndsMat(1:4,1:numTargetsInt).*radius;


setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));
setModelParam('targetInds', single(targetIndsMat));

%% Click parameters
cursor_click_enable;
setModelParam('stopOnClick', double( true ) );
setModelParam('hmmClickSpeedMax', double( 1e-3 ) ); % make more like 1e-5 for real


%% neural decode
loadFilterParams;


% neural click
loadDiscreteFilterParams;
updateHMMThreshold(0.92, 0, loadedModel); % open loop training params, prompt for block for recalc of likelihoods
% a bit brittle, will fail if hmm wasn't trained this time
setModelParam('clickHoldTime', uint16(15)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 


% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;


% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);

% Linear gain?
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
setModelParam('gain', [gain_x gain_y gain_z gain_r]);

% Exponetial gain?
% Exponetial gain?
% setModelParam('exponentialGainBase', [1.3 1.3 1.3 1.3])
setModelParam('exponentialGainBase', [1 1 1 1])
setModelParam('exponentialGainUnityCrossing', ...
    [4.00e-05 4.00e-5 4.00e-5 3.00e-5])

doResetBK = false;
unpauseOnAny(doResetBK);