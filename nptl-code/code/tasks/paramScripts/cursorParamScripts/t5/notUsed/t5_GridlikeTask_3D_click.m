% Work in progress to implement a 3D grid task, this one specifically with
% a 6x6x6 division of the workspace.
%
% Sergey Stavisky 2016-12-12


% Ask operator how many dimensions
evalResponse = input( 'How many tiles per dimension? ' );
assert( evalResponse > 0 );
assert( evalResponse < 255 );
tilesPerDim = evalResponse;

setModelParam('numDisplayDims', uint8(3) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % SCL Visualizatin
setModelParam('pause', true)
setModelParam('holdTime', Inf)
setModelParam('selectionRefractoryMS', uint16( 500 ) ); % grace period. Used for both click and dwell
setModelParam('cursorDiameter', 0.020) % arbitary, picked based on what looks nice.
setModelParam('trialTimeout', 10000);
setModelParam('maxTaskTime',floor(1000*60*5));
setModelParam('numTrials', 96);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_GRIDLIKE)); % THIS WILL CHANGE
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);


%% Gain and assist-related parametetrs
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
setModelParam('gain', [gain_x gain_y gain_z gain_r ]);
setModelParam('mouseOffset', [0 0]);


%% Target-related parameters
% These will be fed into highDgridCoordinates.m and then the outptus of
% that used to set targetInds.
numTargetsPerDimension = tilesPerDim; 
gridBoundaryX = [-0.11 0.11];
gridBoundaryY = [-0.11 0.11];
gridBoundaryZ = [-0.11 0.11];


%% Workspace-related parameters
setModelParam('workspaceY', double([-0.12 0.12]));
setModelParam('workspaceX', double([-0.12 0.12]));
setModelParam('workspaceZ', double([-0.12 0.12]));



%% Below here should happen automatically

[targetCenters, targetEdges] = highDgridCoordinates( [gridBoundaryX; gridBoundaryY; gridBoundaryZ], numTargetsPerDimension );
% scatter3( targetCenters(:,1), targetCenters(:,2), targetCenters(:,3) ) % sanity check target locations
diameter = targetEdges(2,1)-targetEdges(1,1); % for now I'm still using sphereical displayed targets. May want to present actual target boundary cubes later.

% SHIFTING TO THESE
% tilesEachDim used in task to know which dimensions, and how many tiles,
% to look into gridEdges for.
tilesEachDim = uint16( zeros( double(xkConstants.NUM_TARGET_DIMENSIONS),1 ) );
D = size( targetEdges, 2 ); % number of active gridlike task dimensions
tilesEachDim(1:D ) = numTargetsPerDimension;

gridEdges = single( zeros( uint16(cursorConstants.MAX_TILES_PER_DIM), uint16(xkConstants.NUM_TARGET_DIMENSIONS) ) ); % this is its default size
gridEdges(1:size(targetEdges,1), 1:size( targetEdges,2)) = targetEdges;
setModelParam('gridEdges', gridEdges );
setModelParam('gridTilesEachDim', tilesEachDim );
setModelParam('targetDiameter', diameter) % THIS WILL HAVE TO CHANGE


%% Click parameters
cursor_click_enable;
setModelParam('stopOnClick', double( true ) );


%% neural decode
loadFilterParams;

% startContinuousMeansTracking(true, true);

enableBiasKiller;
setBiasFromPrevBlock;


% neural click
loadDiscreteFilterParams; %will return loadedModel
updateHMMThreshold(0.90, 0, loadedModel); 
setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 
setModelParam('clickHoldTime', uint16(15)); %number of ms it needs to be clicking to send a click

setModelParam('exponentialGainBase', 1.4)
% setModelParam('exponentialGainBase', 1)
setModelParam('exponentialGainUnityCrossing', 4.0000e-05)

doResetBK = true;
unpauseOnAny(doResetBK);

