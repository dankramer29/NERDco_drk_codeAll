% High-dimensional keyboard using an optimized FCC (face-centered cubic)
% arrangement with 3 depth layers. The number of rotational wedges that
% each spatial target is divided into is a parameter,
%
% Configured for T5 closed loop experiments% 
% May 3, 2017, Sergey Stavisky and Nir Even-Chen


numRadialWedges = 4; % how many radial wedges to divide each spatial target into.


setModelParam('hmmClickSpeedMax', double( 1e-4 ) ); % no max speed above which click locks
setModelParam('stopOnClick', double( true ) );

% Refractory period- can't select a target until this many ms into the
% trial.
setModelParam('selectionRefractoryMS', uint16( 1000 ) );
setModelParam('falseClickFails', true)

% Target sizes here are for graphics-only, since selection is based on
% which target is closest to the cursor at the time of selection.
setModelParam('targetDiameter', 0.050) 
setModelParam('cursorDiameter', 0.049)
setModelParam('holdTime', inf) % selection must be done with click.
setModelParam('numTrials', 13*12+1); %156 
setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('pause', true)
setModelParam('trialTimeout', 10000);
setModelParam('maxTaskTime',floor(1000*60*15)); % 15 minute max
setModelParam('randomSeed', 1);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_FCC));
setModelParam('showScores', false);
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('recenterOnFail', false);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);
setModelParam('preTrialLength', 20 );


% -----------------------------------------------------------------
%% Get the coordinates for all the  targets
% -----------------------------------------------------------------
targs3D = 0.05.*getFCCTargets(13, 1)'; % XY edges at 10 cm, Z edge at 8.17cm
% Generate radial coordiatnes
radialRange = [-0.10 0.10];
radialCoordinates = radialRange(1) +  range( radialRange )/(numRadialWedges+1) : ...
    range( radialRange )/(numRadialWedges+1) : ...
    radialRange(2) -  range( radialRange )/(numRadialWedges+1);
targsFull = [];
for i = 1 : numel( radialCoordinates );
    targsFull = [targsFull, [targs3D; repmat( radialCoordinates(i), 1, size( targs3D, 2 ) )] ];
end

%% Push the targets to model
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
numTargetsInt = uint16( size( targsFull, 2) );
targetIndsMat(1:4,1:numTargetsInt) = targsFull;

setModelParam('numTargets', numTargetsInt);
setModelParam('targetInds', single(targetIndsMat));

fprintf('%i unique targets (%i trials)\n', ...
    size( unique( targsFull, 'rows') ,2 ), getModelParam('numTrials') )


%%
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));
setModelParam('workspaceR2', double([0 0]));

%% Enable click
cursor_click_enable;

% neural click
loadDiscreteFilterParams;
updateHMMThreshold(0.92, 0, loadedModel); % open loop training params, prompt for block for recalc of likelihoods
% a bit brittle, will fail if hmm wasn't trained this time
setModelParam('clickHoldTime', uint16(60)); %number of ms it needs to be clicking to send a click



%% neural decode
loadFilterParams;

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;


% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);

% Linear gain?
gain_x = 1.7;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);

% Exponetial gain?
setModelParam('powerGain', 1)
setModelParam('powerGainUnityCrossing', 4.50e-05)

doResetBK = false;
unpauseOnAny(doResetBK);