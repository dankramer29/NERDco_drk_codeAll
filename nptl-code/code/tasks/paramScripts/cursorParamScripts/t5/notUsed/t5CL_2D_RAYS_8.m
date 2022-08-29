% Radial Angle-Yolked Selection communications interface.
% Radial Targets are at the 8 combinatiosn of [-1,0,1] across only 2 dimensions.
%
% June 17 2017 Sergey Stavisky

                       
% When cursor is half the targetRotDiameter from origin, a selection is made.
% Thus, this is a critical parameter for this task.
% (I'm basically overloading this parameter);
setModelParam('targetRotDiameter', 0.110) 

% effects visualization only
setModelParam('targetDiameter', 0.050) 
setModelParam('cursorDiameter', 0.049)

% "Medium" target sizes
% setModelParam('targetDiameter', 0.040) 
% setModelParam('cursorDiameter', 0.039)

% "Small" target sizes
% setModelParam('targetDiameter', 0.030) 
% setModelParam('cursorDiameter', 0.029)

setModelParam('failurePenalty', 0); % lets one see failures
% recenterDelay shows next target but locks the cursor
setModelParam('recenterDelay',450); % if 0 then it doesn't do recentering pause, but does still recenter
setModelParam('preTrialLength',150 ); % how long it shows previous target's success or failure, before new target comes on

setModelParam('numTrials', 160); 
setModelParam('numDisplayDims', uint8(4) ); % note still displayed as rod. Can change to 3 for sphere 
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('pause', true)
setModelParam('trialTimeout', 10000);
setModelParam('maxTaskTime',floor(1000*60*15)); % 15 minute max
setModelParam('randomSeed', 1);
setModelParam('taskType', uint32(cursorConstants.TASK_RAYS));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', true);




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
            possibleCoordinates(i2)];
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
targetIndsMat(1:2,1:numTargetsInt) = targsFull;

setModelParam('numTargets', numTargetsInt);
setModelParam('targetInds', single(targetIndsMat));
fprintf('%i unique radial targets (%i trials)\n', ...
    size( unique( targsFull, 'rows') ,2 ), 2*numTargetsInt )


%%
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([0 0]));
setModelParam('workspaceR', double([0 0]));
setModelParam('workspaceR2', double([0 0]));


%% neural decode
loadFilterParams;

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
% setBiasFromPrevBlock;

%%
% Linear gain?
gain_x = 1/3000;
gain_y = gain_x;
gain_z = 0;
gain_r = 0;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);
%%
% Exponetial gain?
setModelParam('powerGain', 1)
setModelParam('powerGainUnityCrossing', 4.50e-05)

doResetBK = false;
unpauseOnAny(doResetBK);