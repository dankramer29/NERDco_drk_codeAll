setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  
setModelParam('taskType', uint32(cursorConstants.TASK_SEQ));
setModelParam('numDisplayDims', uint8(2) );
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_HEAD_MOUSE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

setModelParam('holdTime', 10);
setModelParam('targetDiameter', 120);
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
targetIndsMat(1:2,1:9)  = [  0 289 409  289    0 -289 -409 -289 0; ...
                                       409 289   0 -289 -409 -289    0 289 0];
%(0,0) is top left of screen                                   
%targSeq = [1 9 2 9 5 9 8 9 4 9 7 9 3 9 6 9 1 9 4 9];
paths = cell(5,1);
for x=1:length(paths)
    paths{x} = zeros(2,20);
end
paths{1}(:,1:8) = [  466   139   337   159  -252   -35  -486  -373
                    -179  -461   325   486   469  -130    60  -231];
paths{2}(:,1:8) = [ 434   253  -353    72   -27    24   351    66
                    94  -499   187   434    50  -124  -261  -421];              
paths{3}(:,1:8) = [    236  -238   -18  -374   232  -420   262  -250  
                     -234   455   -90    84   138   343   477  -415      ];            
paths{4}(:,1:8) = [  301    85   111  -295   321    58   -60   413  
                    -394   -67   215  -418   201   406  -336    45     ];
paths{5}(:,1:8) = [  -345  -487    29  -424   464   463  -383   277  
                    -22   415  -101  -459   400  -436   262  -421     ];
                 
sequenceMatrix = single(zeros(50, 2, sequenceConstants.MAX_TARG_IN_SEQ));
for x=1:length(paths)
    sequenceMatrix(x,:,:) = paths{x};
end

ro = [zeros(16,1); zeros(16,1)];
ro = ro(randperm(length(ro)));
ro = repmat(ro, 4, 1);

setModelParam('sequenceMatrix', sequenceMatrix);
setModelParam('fixedSeqMode', true);

setModelParam('rehearsalOrder', uint8(ro));
setModelParam('rehearsalTimes',uint32(zeros(128,1)+60000*10));

setModelParam('pathMode', uint8(1));
setModelParam('memorizeMode', uint8(0));
setModelParam('rotateSeqCues', false);
setModelParam('numTargetsInSeq', uint8(8));
setModelParam('numRepsPerSeq', 20);

setModelParam('seqReadyTime', uint32(10000));
setModelParam('seqRehearseTime', uint32(1000));
setModelParam('headSpeedCap',single(0.12));
setModelParam('pc1MouseInControlMode', uint8(1));

setModelParam('workspaceY', double([-540 539]));
setModelParam('workspaceX', double([-960 959]));
setModelParam('targetInds', single(targetIndsMat));

doResetBK = false;
unpauseOnAny(doResetBK);
setModelParam('gain', gainCorrectDim); % unlocks cursor
