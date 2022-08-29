setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  
setModelParam('taskType', uint32(cursorConstants.TASK_SEQ));
setModelParam('numDisplayDims', uint8(2) );
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_HEAD_MOUSE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

setModelParam('holdTime', 10);
setModelParam('targetDiameter', 160);
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
numTargetsInt = uint16(9);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:2,1:9)  = [  0 289 409  289    0 -289 -409 -289 0; ...
                                       409 289   0 -289 -409 -289    0 289 0];
%(0,0) is top left of screen                                   
%targSeq = [1 9 2 9 5 9 8 9 4 9 7 9 3 9 6 9 1 9 4 9];

ro = [zeros(16,1); ones(16,1)];
ro = ro(randperm(length(ro)));
ro = repmat(ro, 4, 1);

setModelParam('rehearsalOrder', uint8(ro));
%setModelParam('rehearsalTimes', uint32(zeros(128,1)+5000));
setModelParam('rehearsalTimes',uint32(zeros(128,1)+60000));

setModelParam('pathMode', uint8(0));
setModelParam('memorizeMode', uint8(0));
setModelParam('rotateSeqCues', true);
setModelParam('numTargetsInSeq', uint8(16));
setModelParam('numRepsPerSeq', 2);

setModelParam('seqReadyTime', uint32(10000));
setModelParam('seqRehearseTime', uint32(1000));

setModelParam('workspaceY', double([-540 539]));
setModelParam('workspaceX', double([-960 959]));
setModelParam('targetInds', single(targetIndsMat));

doResetBK = false;
unpauseOnAny(doResetBK);
setModelParam('gain', gainCorrectDim); % unlocks cursor
