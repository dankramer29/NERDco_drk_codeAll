function out = keyboard_streamParser(block)

taskConstants = processTaskDetails(block.taskDetails);

%% convert the peripheralTimestamp field from 16xuint8 to 2xint64
if isfield(block.continuous,'peripheralTimestamp')
    tmp = reshape(block.continuous.peripheralTimestamp',1,[]);
    block.continuous.peripheralTimestamp = reshape(typecast(tmp,'int64'),2,[])';
end

%% start by looking for the PREMOVE state
stateNames = {block.taskDetails.states.name};
stateIds = [block.taskDetails.states.id];

boundaries = block.discrete.clock;
startpoints = boundaries(1:end-1);
endpoints = boundaries(2:end)-1;

%% hack for very first block where i screwed up the recording
if block.continuous.clock(1) > startpoints(1)
    startpoints(1) = block.continuous.clock(1);
end


assert(length(startpoints) == length(endpoints), 'not equal start and end');
assert(all(startpoints < endpoints), 'endpoints before startpoints?');
assert(all(startpoints(2:end) > endpoints(1:end-1)), 'starts before prev trial is finished?');
R=block2trials(block, startpoints, endpoints);

%% calculate any helpful numbers here...

if ~isfield(R,'trialNum')
    for nn=1:length(R)
        R(nn).trialNum = nn;
    end
end

R = keyboardPreprocessR(R);

out = R;
