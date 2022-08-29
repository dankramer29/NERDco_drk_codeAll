function taskParamsStruct = allTasks_buildWorkspace()
taskParamsStruct = createTunableStructure([],[], 'taskParamsBus',...
    'targetDiameter',single(60),... % made single from uint16 Dec 2016 SDS
    'maxTaskTime',uint32(0),...
    'holdTime', int16(500),... % SDS Dec 15 2016, changed from uint16 to int16 to allow negative "bonus" (or panlty) time in tasks
    'trialTimeout',uint16(15000),...
    'numTrials',uint16(100),...
    'randomSeed',double(1),...
    'expRandMu',double(0),... %[decisionTask]  
    'expRandMin',double(0),...%[decisionTask] 
    'expRandMax',double(0),... % random delays, not used these days
    'expRandBinSize',double(200),...
    'taskType',uint8(cursorConstants.TASK_CENTER_OUT),...
    'targetInds',single(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), cursorConstants.MAX_TARGETS])),...  % target LOCATIONS (bad name). Uses a fair number of bytes, lower if running out. SDS Dec 2016, changed from int16 to single to accomodate change to cm units
    'numTargets',uint16(0),...
    'gain',single(zeros(1,double(xkConstants.NUM_TARGET_DIMENSIONS)) ),... % SDS August 2016 added third and fourth dimensions
    'failurePenalty',uint16(0),...
    'cursorDiameter',single(30),... % made single from uint16 Dec 2016 SDS
    'inputType',uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE),...
    'gloveBias',uint16(zeros([1 double(xkConstants.NUM_STATE_DIMENSIONS)])),... % SDS July 2016 (was [1 5] before)
    'useRandomDelay',uint16(0),...
    'mouseOffset',uint16([3400 2950]),... % empirical values from dell laptop trackpad
    'workspaceX',single([-500 500]),...
    'workspaceY',single([-500 500]),...
    'workspaceZ',single([0 0]),... % depth boudns. Keep as zero unless this dim being used.
    'workspaceR',single([0 0]),... % rotate-around-Z rotation bounds. Keep as zero unless this dim being used.
    'workspaceR2', single([0 0]), ... %rotate-around-Y rotation bounds.
    'showScores',false,... [keyboardTask] [decisionTask will use too]
    'trialsPerScore',uint16(16),... [keyboardTask]
    'cursorColorClick',single([255 0 255]'),...  % Was , now making purple March 21 2017
    'recenterOnFail',false,...
    'recenterOnSuccess',false,...
    'recenterDelay',uint16(0),...
    'initialInput',uint16(cursorConstants.INPUT_TYPE_DECODE_V),...
    'clickPercentage',double(0),...
    'lockFingerPosition',false,...
    'fingerPositionTolerance',double(10),...
    'failOnLiftoff',false,...
    'errorAssistR',single( zeros(1, double( xkConstants.NUM_TARGET_DIMENSIONS ) ) ), ...      % slows wrong-direction movement (relative to cursor-target axis) in each dimension separately
    'errorAssistTheta',single( zeros(1, double( xkConstants.NUM_TARGET_DIMENSIONS ) ) ), ...  % attenuates orthogonal component of movement (relative to cursor-target axis) in each dimension separately
    'errorAssistAxis',single( zeros(1, double( xkConstants.NUM_TARGET_DIMENSIONS ) ) ), ...   % New October 2016, attentuates wrong-direction movement (relative to cardinal axes) in each dimension 
    'useGloveLPF', false,... 
    'gloveLPNumerator', double(zeros(1, 11)), ...
    'gloveLPDenominator', double(zeros(1, 11)), ...
    'gloveNonlinearCorrection', false,...
    'gloveYCorrection', double(2),...
    'gloveXCorrection', double(1.5),...
    'useMouseLPF', false,...
    'soundOnFail', true,...
    'soundOnGo', false,...
    'soundOnSuccess', true,...
    'soundOnOverTarget', false,...
    'mouseLPNumerator', double(zeros(1, 11)), ... % used in taskBlock, not in this specificTask, but still needed
    'mouseLPDenominator', double(zeros(1, 11)), ... % used in taskBlock, not in this specificTask, but still needed
    'stopOffTarget',true, ...
    'stopOnClick',true, ...
    'outputType', uint16(-1),... % not assigned to an output type, hopefully will be just ignored.  %     'outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR),...
    'xk2HorizontalPos', uint8(1), ... % SDS July 2016   which state element the game should treat as horizontal position
    'xk2HorizontalVel', uint8(2), ... % SDS July 2016  which state element the game should treat as horizontal velocity
    'xk2VerticalPos', uint8(3), ... % SDS July 2016 which state element the game should treat as vertical position
    'xk2VerticalVel', uint8(4), ... % SDS July 2016  which state element the game should treat as vertical velocity
    'xk2DepthPos', uint8(5), ... % SDS August 2016 which state element the game should treat as depth position
    'xk2DepthVel', uint8(6), ... % SDS August 2016  which state element the game should treat as depth velocity
    'xk2RotatePos', uint8(7), ... % SDS August 2016 which state element the game should treat as rotate-around-Z velocity
    'xk2RotateVel', uint8(8),... %SDS August 2016 which state element the game should treat as rotate-around-Z position
    'xk2Rotate2Pos', uint8(9), ... % SDS March 2017 which state element the game should treat as rotate-around-Y velocity
    'xk2Rotate2Vel', uint8(10),... %SDS March 2017 which state element the game should treat as rotate-around-Y position    
    'gridEdges', single( zeros( uint16(cursorConstants.MAX_TILES_PER_DIM), uint16(xkConstants.NUM_TARGET_DIMENSIONS) ) ), ... %  (N+1) x D array with the boundaries along each dimension for each of the tiles along the d'th gridlike task dimension. SDS December 2016
    'gridTilesEachDim', uint16( zeros( uint16(xkConstants.NUM_TARGET_DIMENSIONS),1 ) ), ... % will be used in task to index into gridEdges
    'selectionRefractoryMS', uint16(0), ... % [cursorTask] Sets holdTimer and clickTimer this negative at trial start, thus providing a refractory period for click and dwell. May 2017. Formerly called newTrialAddedDwell added Dec 2016 
    'autoplayReactionTime', uint16(250), ... % in ms SDS Dec 2016 
    'autoplayMovementDuration', uint16(1000), ... %in ms  SDS Dec 2016
    'powerGain', single( 1 ), ... % expontial gain base. 1 is special and means unity out/in mapping  SDS Feb 2016
    'powerGainUnityCrossing', single(5e-5),... % [all tasks] power gain. At speeds above this, output is > input SDS Feb 2016
    'targetRotDiameter', single(0.020), ... % ONLY USED WHEN >4D Rotatory diamter. Scalar for now while we're in 4D, later this could be expanded if we want different sizes in each rotatory dim SDS Feb 2017
    'autoplayRotationStart', uint16(250), ... % in MS, when (after the start of an autoplay trial) the autoplay rotation begins. % SDS BJ Feb 2017
    'autoplayRotationDuration', uint16(600), ... . Duration of autoplay rotation. In ms. SDS Feb 2017
    'randomTaskTargetDiameters', single(zeros(1, cursorConstants.MAX_DIAMETERS)), ... % For random target task, on each trial the target diameter  is randomly picked from the nonzero elements of this list SDS Mar 2017
    'randomTaskTargetRotDiameters', single(zeros(1, cursorConstants.MAX_DIAMETERS)), ... % For random target task, on each trial the target rotation diameter  is randomly picked from the nonzero elements of this list SDS Mar 2017
    'randomTaskBoundaries', single( [-.10 0.10; -0.10 0.10; -0.10 0.10; -0.10 0.10; -0.10 0.10] ), ... % in random task cursorTask variant, targets can appear within these bounda
    'numDisplayDims', uint8(3),... ... % Added to vizPacket, tells display machine what dimensionality visualizations to use. Means we don't need to recompile if going from 4D to 3D SDS Mar2017
    'cursorColorOpen', single([60 255 30]'), ...% [robotTask] in SCL shows grasp open state. 
    'cursorColorClosed', single([255 0 0]'), ...% [robotTask] in SCL shows grasp closed state. 
    'showXYZaura', boolean( true ),  ... [cursorTask] allows the task to tell graphics engine whether to show aura or not.
    'displayObject', uint8( cursorConstants.OBJECT_SPHERE ),  ... [cursorTask] can specify what graphics object to show, e.g. rod vs hammer.
    'preTrialLength',uint16(20), ... [cursorTask] waits this long in STATE_PRE_TRIAL % SDS April 29 2017
    'targetDiameters',uint16(repmat(100,[1 cursorConstants.MAX_DIAMETERS])), ... [fittsTask]
    'numTargetDiameters',uint16(0),... [fittsTask]
    'minTargetDistance',double(0),...  [fittsTask]
    'targetDelay',uint16(0),...  [fittsTask]
    'targetSpaceX',double([-500 500]),... [fittsTask]
    'targetSpaceY',double([-500 500]),... [fittsTask]
    'clickTargetColor',uint8('g'),... [fittsTask]
    'clickTargetHoverColor',uint8('b'),... [fittsTask]     
    'falseClickFails', boolean(false),... [cursorTask] if true, clicking outside the correct target fails trial. SDS May 2 2017
    'splitDimensions', boolean(false), ... [cursorTask] if true, tells display computer to render multiple cursors
    'vmrTheta', single(0), ... [cursorTask]
    'doHeadSpeedFail', boolean(false), ... [cursorTask]
    'headSpeedCap', single(10), ... [cursorTask]
    'eyeMode', uint16(0), ... [cursorTask]
    'speedTaskMode', uint16(0), ... [cursorTask]
    'delayPeriodGainScale', single(1), ... [cursorTask]
    'wiaMode', uint16(cursorConstants.WIA_NOT_ACTIVE), ... [cursorTask]
    'showWiaText', uint16(0), ... [cursorTask]
    'freePlayMode', uint16(0), ... [cursorTask]
    'drawNumbersOnTargets', uint8(0), ... [cursorTask]
    'xkRawSpeedCap', single(10000), ... %FRW Sep 2017
    'discreteOLMode', uint8(0), ... [cursorTask]
    'movementDuration',uint16(2000), ... %[movementCueTask]
    'holdDuration',uint16(1500), ... %[movementCueTask]
    'restDuration',uint16(2000), ... %[movementCueTask]
    'returnDuration',uint16(4000), ... %[movementCueTask]
    'repsPerBlock',uint16(5), ... %[movementCueTask]
    'whichMovements', zeros([1 50],'uint8'), ... %[movementCueTask]
    'movementOrder', zeros([1 movementConstants.MAX_CUED_MOVEMENTS+0],'uint8'), ... %[movementCueTask]
    'delayOrder', zeros([1 movementConstants.MAX_CUED_MOVEMENTS+0],'uint16'), ... %[movementCueTask]
    'textOverlayID',uint16(0), ... %[movementCueTask] for an optional overlay that explains meaning of the dual arrows in dual movement tasks
    'clickRefractoryPeriod', uint16(0),... %[linuxTask (maybe also keyboard?)]
    'xpcVelocityOutputPeriodMS', double(0),... %[linuxTask (maybe also keyboard?)]
    'outputVelocityScaling', single(1),... %[linuxTask (maybe also keyboard?)]
    'screenUpdateRate', uint32(1),... %[linuxTask (maybe also keyboard?)] 
    'targetDevice', uint16(0),... %[linuxTask (maybe also keyboard?)] 
    'playSpokenCues', false, ... %[movementCueTask]
    'numTargetsInSeq', uint8(10), ... %[sequenceTask]
    'targetSeq',uint8(zeros(100,1)), ... %[sequenceTask]
    'seqReadyTime',uint32(10000), ... %[sequenceTask]
    'seqRehearseTime',uint32(120000), ... %[sequenceTask]
    'rotateSeqCues',false, ... %[sequenceTask]
    'numRepsPerSeq',10, ... %[sequenceTask]
    'rehearsalOrder', uint8(zeros(128,1)), ... %[sequenceTask]
    'rehearsalTimes', uint32(zeros(128,1)), ... %[sequenceTask]
    'pathMode', uint8(0), ... %[sequenceTask]
    'memorizeMode', uint8(0), ... %[sequenceTask]
    'fixedSeqMode', false, ... %[sequenceTask]
    'sequenceMatrix', single(zeros(50, 2, sequenceConstants.MAX_TARG_IN_SEQ)), ... %[sequenceTask]
    'keyboard',uint16(keyboardConstants.KEYBOARD_QWERTY1),... % [keyboardTask]
    'resetDisplay',false,... % [keyboardTask]
    'cursorNeuralColor',[255; 255; 255],... % [keyboardTask]
    'cursorNonneuralColor',[255; 133; 0],... %[keyboardTask]
    'centerOffset',double([960; 540; 0; 0]),...  %[keyboardTask]  %SDS Dec 2016 was xyOffset before but now just centerOffset 
    'scoreTime',uint16(3000),... %[keyboardTask]
    'cuedTextLength',uint16(0),... %[keyboardTask]
    'cuedText',zeros([1 keyboardConstants.MAX_CUED_TEXT],'uint8'),...  %[keyboardTask]
    'keyboardDims',uint16([240 90 1440 900]),... %[keyboardTask]
    'recenterFullscreen',false,... %[keyboardTask]
    'soundOnError', false,... %[keyboardTask]
    'acquireMethods',uint8(keyboardConstants.ACQUIRE_DWELL),... %[keyboardTask]
    'cumulativeDwell',false, ... %[keyboardTask]
    'showBackspace',false,... %[keyboardTask]
    'showStartStop',false,... %[keyboardTask]
    'showTargetText', true,... %[keyboardTask]
    'showTypedText', true,... %[keyboardTask]
    'showCueOnTarget', false,... %[keyboardTask]
    'showCueOffTarget', true,... %[keyboardTask]
    'recenterOffset',int16(zeros(double(xkConstants.NUM_TARGET_DIMENSIONS),1)), ...  %[keyboardTask] %SDS Dec 2016 now Nd
    'dwellRefractoryPeriod',uint16(200),... %[keyboardTask]
    'keyPressedTime',uint16(100),... %[keyboardTask]
    'initialLockout',uint16(1000),... %[keyboardTask]
    'initialState',uint16(KeyboardStates.STATE_MOVE),... %[keyboardTask]
    'symbolMoveTimeOne',uint32(30000),... %[symbolTask]
    'symbolRehearseTime',uint32(30000),... %[symbolTask]
    'symbolGetReadyTime',uint32(30000),... %[symbolTask]
    'symbolMoveTimeTwo',uint32(30000), ... %[symbolTask] 
    'symbolVMRMode',uint8(0), ... %[symbolTask] 
    'symbolVMRRot',int8(0), ... %[symbolTask] 
    'pc1MouseInControlMode',uint8(0), ... %puts operator in control of the task using mouse input from pc1
    'gracePeriod',uint16(250),...; % [decisionTask]
	'maxFixDur',uint16(100),...; % [decisionTask] %max time spent fixating from variable delay
    'maxTargDur',uint16(100),...; % [decisionTask] %max time the targets only should be on from variable delay
    'maxStimDur',uint16(700),...; % [decisionTask] %max time the stimulus should be on from variable delay
	'moveThresh',single(0.25),...; % [decisionTask] %meters per millisecond
    'intertrialTime',uint16(1000),...; % [decisionTask]
    'cursorColors', uint16(zeros(3)),...% [decisionTask]
    'gridSize',uint16(200),...; % [decisionTask] %in pixels
    'crossSize', uint16(20),...% [decisionTask] %in pixels
    'makeGrid', uint16(0),... %flag for viz to generate texture or no
    'tau', single(0.5),... % [decisionTask] %for autoplay
    'taskOrder', uint16(0),... % [decisionTask] assumes targets first
    'stimDur', uint16(500),... % [decisionTask] keep checkerboard on for 500 ms in stimulus-first DM
    'coherences', uint16([0 4 7 10 15 30 80]),... % [decisionTask] default desired coherence values
    'contextIDs', uint16(zeros(cursorConstants.YANG_NUM_TASKS,1)), ... % [yangTask]
    'stimConds', uint16(zeros(1,2)), ... % [yangTask]
    'contextTime', uint16(1), ... % [yangTask]
    'stimTime', uint16(1), ... % [yangTask]
    ...'stimCondsMat', uint16(zeros(8,2)), ... % [yangTask]
    'delayTime', uint16(1), ... % [yangTask]
    'contextTimeVec', uint16([1 1500 1300 2000]), ... % [yangTask]
    'nextClickTarg', uint16(0),... % % [multiClick]. Current target. targets would be integers like 1-5 
    'clickTargs', uint16(zeros(1, cursorConstants.MAX_TARGETS)),... % [multiClick]. array of targets targets would be integers like 1-5 
    'rsgTargetSeq', uint16(zeros(cursorConstants.RSG_NUM_TRIALS,1)), ... % [rsgTask]
    'rsgTargetLoc', single(zeros(2,10)), ... % [rsgTask]
    'rsgCueDisplayTime', uint16(105), ... % [rsgTask]
    'rsgProductionTimes', uint16(zeros(cursorConstants.RSG_NUM_TRIALS,1)), ... % [rsgTask]
    'rsgPreReadyTimes', uint16(zeros(cursorConstants.RSG_NUM_TRIALS,1)), ... % [rsgTask]
    'rsgFixationRadius',single(40),... % [rsgTask]
    'multiclickColors', single([[255 24 29];[255 0 255]; [140 150 198]; [0 102 255]])... %SNF multiclick- color the cursor turns for clicks 1-4
    );
% note: we've overloaded the word "state" to mean: state in state machine,
% state in state vector, and state as in click state model. happy parsing of that logic -SF