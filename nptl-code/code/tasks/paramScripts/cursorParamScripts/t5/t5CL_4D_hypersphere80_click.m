% Targets are at the 80 combinatiosn of [-1,0,1] across all dimensions.
%
% closed loop for T5
% April 4 2017

setModelParam('holdTime', inf) 
%setModelParam('holdTime', 500) 

% % % "Giant" target sizes (dev)
% setModelParam('targetDiameter', 0.070) 
% setModelParam('cursorDiameter', 0.049)

% % % "Large" target sizes
setModelParam('targetDiameter', 0.050) 
setModelParam('cursorDiameter', 0.049)

% "Medium" target sizes
% setModelParam('targetDiameter', 0.040) 
% setModelParam('cursorDiameter', 0.039)

% "Small" target sizes
% setModelParam('targetDiameter', 0.030) 
% setModelParam('targetRotDiameter', 0.030) % 
% setModelParam('cursorDiameter', 0.029)

% setModelParam('hmmClickSpeedMax', double( 3e-3 ) ); 
setModelParam('hmmClickSpeedMax', double( inf ) ); % no max speed above which click locks
% setModelParam('stopOnClick', double( true ) ); % use later in training
setModelParam('stopOnClick', double( false ) ); % use for early training

% YES - false click causes failure
% setModelParam('falseClickFails', true)
% setModelParam('selectionRefractoryMS', uint16( 500 ) ); 

% NO - false click doesn't cause failure
setModelParam('falseClickFails', false)
setModelParam('selectionRefractoryMS', uint16( 0 ) );



setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('pause', true)
setModelParam('trialTimeout', 10000);
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

% YES bias killer
% enableBiasKiller;
% setBiasFromPrevBlock;
% setModelParam('biasCorrectionEnable',true);

% NO bias killer
setModelParam('biasCorrectionEnable',false);

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0); % sdoesnt' matter since meansTrackingEnable is false




%% Enable click
cursor_click_enable;

% neural click
loadDiscreteFilterParams;

% set absolute LL threshold itself so can stay constant across blocks 
% even if frequency of click changes (centile is sensitive to % of time
% spent clicking):
% curThresh = .85; % T5
curThresh = 0.9999; % rigH
fprintf(1, 'Setting absolute HMM likelihood threshold to %01.2f ...', curThresh);
% modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
setHMMThreshold(curThresh); % push variables

% a bit brittle, will fail if hmm wasn't trained this time
setModelParam('clickHoldTime', uint16(45)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 


% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
%%
% Linear gain?
gain_x = 1;
% gain_x = 0.5; % first CL block
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain_r2 = 0;
setModelParam('gain', [gain_x gain_y gain_z gain_r gain_r2]);
%%

% Exponetial gain?
setModelParam('powerGain', 1  )
% setModelParam('powerGainUnityCrossing', 1) 
% 
% what Beata had from last session:
% setModelParam('powerGain', 1.5 )
setModelParam('powerGainUnityCrossing', 0.0005) 


% setModelParam('powerGainUnityCrossing', 4.50e-05)

doResetBK = false;
unpauseOnAny(doResetBK);