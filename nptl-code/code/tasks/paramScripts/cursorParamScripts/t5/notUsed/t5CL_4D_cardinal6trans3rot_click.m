% Targets are at the 6 cardinal endpoints of a 3D axis,
% plus the +max, 0, -max in the rot1 dimension. This is nice and easy 
% to understand.
% Closed loop
% Feb 22 2017 SDS

% "Large" target sizes
setModelParam('targetDiameter', 0.040) 
setModelParam('targetRotDiameter', 0.040) % add half of cursor diameter, since rot checking is by center-point and not edge overlap 

% "Medium" target sizes
% setModelParam('targetDiameter', 0.030) 
% setModelParam('targetRotDiameter', 0.030+0.010) % add half of cursor diameter, since rot checking is by center-point and not edge overlap 

setModelParam('cursorDiameter', 0.020)
setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('pause', true)
setModelParam('holdTime', Inf)
setModelParam('trialTimeout', 20000); % 10 second time out
setModelParam('maxTaskTime',floor(1000*60*10)); % 10 minute max
setModelParam('numTrials', 144);  % 4 outwards to each unique target 
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
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);


gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
setModelParam('gain', [gain_x gain_y gain_z gain_r]);
setModelParam('mouseOffset', [0 0]);

numTargetsInt = uint16(18);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));


% Get the coordinates for all the radial targets
radius = 0.09; % 9 cm. This ensures that with 3cm diameter targets, can't succeed along edge
targsCardinal = [ -1 0 1  0 0  0  -1 0 1  0 0  0   -1  0  1  0  0  0 ; ... 
                   0 1 0 -1 0  0   0 1 0 -1 0  0    0  1  0 -1  0  0 ; ...
                   0 0 0  0 1 -1   0 0 0  0 1 -1    0  0  0  0  1 -1 ; ...
                   0 0 0  0 0  0   1 1 1  1 1  1   -1 -1 -1 -1 -1 -1 ];

targetIndsMat(1:4,1:numTargetsInt) = [radius.*targsCardinal];

setModelParam('workspaceY', double([-0.12 0.12]));
setModelParam('workspaceX', double([-0.12 0.12]));
setModelParam('workspaceZ', double([-0.12 0.12]));
setModelParam('workspaceR', double([-0.12 0.12]));
setModelParam('targetInds', single(targetIndsMat));


%% Click parameters
cursor_click_enable;
setModelParam('stopOnClick', double( true ) );
setModelParam('hmmClickSpeedMax', double( 1e-3 ) ); % make more like 1e-5 for real



%% neural decode
loadFilterParams;


 
% now disable mean updating
% startContinuousMeansTracking(true, true);
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;



% neural click
loadDiscreteFilterParams;
updateHMMThreshold(0.85, 0, loadedModel); % open loop training params, prompt for block for recalc of likelihoods
% a bit brittle, will fail if hmm wasn't trained this time
setModelParam('clickHoldTime', uint16(15)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 



gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
% Linear gain?
setModelParam('gain', [gain_x gain_y gain_z gain_r]);
% Exponetial gain?
% setModelParam('exponentialGainBase', [1.3 1.3 1.3 1.3])
setModelParam('exponentialGainBase', [1 1 1 1])
setModelParam('exponentialGainUnityCrossing', ...
    [4.00e-05 4.00e-5 4.00e-5 3.00e-5])

doResetBK = true;
unpauseOnAny(doResetBK);