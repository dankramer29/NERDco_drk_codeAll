function bout = calculateBlockRuntime(stream)

taskName = stream.taskDetails.taskName;

xpcStart = stream.continuous.clock(find(~stream.continuous.pause,1));

switch taskName
    case 'cursor'
        endInd = find(stream.continuous.state==CursorStates.STATE_END,1);
    case 'keyboard'
        endInd = find(stream.continuous.state==KeyboardStates.STATE_END,1);
    otherwise
        warning('calculateBlockRuntime: don''t know how to process task %s', taskName);
        endInd =[];
end

if isempty(endInd),endInd = numel(stream.continuous.clock); end
xpcEnd = stream.continuous.clock(endInd);
bout = double(xpcEnd) - double(xpcStart);
