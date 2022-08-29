setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  
setModelParam('taskType', uint32(cursorConstants.TASK_SEQ));
setModelParam('numDisplayDims', uint8(2) );
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_HEAD_MOUSE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

setModelParam('holdTime', 10);
setModelParam('targetDiameter', 150);
setModelParam('cursorDiameter', 45);

% so cursor is still during pre state
gain_x = 0; 
gain_y = gain_x;
gainCorrectDim =  getModelParam('gain');
gainCorrectDim(1) = gain_x;
gainCorrectDim(2) = gain_y;
setModelParam('gain', gainCorrectDim);
setModelParam('pause', true);

%%
gainCorrectDim =  zeros( size( getModelParam('gain') ) );
gainCorrectDim(1) = 5000; 
gainCorrectDim(2) = gainCorrectDim(1);

% set targets & workspace bounds
numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));

angles = linspace(0,2*pi,9);
angles = angles(1:8)';
targPattern = [cos(angles), sin(angles)];
targPattern(:,2) = -targPattern(:,2);
targetIndsMat(1:2,1:8)  = 409*targPattern';
targetIndsMat(1:2,9) = [0; 0];

setModelParam('symbolMoveTimeOne', uint32(60000));
setModelParam('symbolRehearseTime', uint32(240000));
setModelParam('symbolGetReadyTime', uint32(3000));
setModelParam('symbolMoveTimeTwo', uint32(60000));

setModelParam('headSpeedCap',single(0.065));
setModelParam('pc1MouseInControlMode', uint8(1));
setModelParam('symbolVMRMode', uint8(1));
setModelParam('symbolVMRRot', int8(3));

setModelParam('workspaceY', double([-540 539]));
setModelParam('workspaceX', double([-960 959]));
setModelParam('targetInds', single(targetIndsMat));

doResetBK = false;
unpauseOnAny(doResetBK);
setModelParam('gain', gainCorrectDim); % unlocks cursor
