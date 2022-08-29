function bout = getFinalBiasEstimate(stream)

taskName = stream.taskDetails.taskName;

endInd1 = find(~stream.continuous.pause,1,'last');

switch taskName
    case 'cursor'
        endInd2 = find(stream.continuous.state==CursorStates.STATE_END,1);
    case 'keyboard'
        endInd2 = find(stream.continuous.state==KeyboardStates.STATE_END,1);
    otherwise
        warning('calculateBlockRuntime: don''t know how to process task %s', taskName);
        endInd2 =[];
end

endInd = min([endInd1 endInd2]);
bout = stream.continuous.xkModBiasEst(endInd,:);

