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

%make sure there's not too much clumpiness in rehearsal vs. non rehearsal
%trials
nSeq = 16;
badSeq = true;
while badSeq
    ro = [ones(nSeq/2,1); zeros(nSeq/2,1)];
    ro = ro(randperm(length(ro)));

    prevVal = 0;
    repeatCounter = 0;
    badSeq = false;
    for x=1:length(ro)
        if ro(x)==prevVal
            repeatCounter = repeatCounter + 1;
        else
            repeatCounter = 0;
        end
        prevVal = ro(x);
        if repeatCounter>2
            disp('reject');
            badSeq = true;
            break;
        end
    end
end

roFinal = zeros(128,1);
roFinal(1:nSeq) = ro;
roFinal((nSeq+1):end) = randi(2,128-nSeq,1)-1;

setModelParam('rehearsalOrder', uint8(zeros(128,1)));
%setModelParam('rehearsalTimes', uint32(zeros(128,1)+5000));
setModelParam('rehearsalTimes',uint32(zeros(128,1)+60000));

setModelParam('pathMode', uint8(1));
setModelParam('memorizeMode', uint8(0));
setModelParam('rotateSeqCues', false);
setModelParam('numTargetsInSeq', uint8(8));
setModelParam('numRepsPerSeq', 6);

setModelParam('headSpeedCap',single(0.065));

setModelParam('seqReadyTime', uint32(10000));
setModelParam('seqRehearseTime', uint32(1000));

setModelParam('workspaceY', double([-540 539]));
setModelParam('workspaceX', double([-960 959]));
setModelParam('targetInds', single(targetIndsMat));

doResetBK = false;
unpauseOnAny(doResetBK);
setModelParam('gain', gainCorrectDim); % unlocks cursor
