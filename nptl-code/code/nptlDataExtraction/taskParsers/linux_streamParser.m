function out = linux_streamParser(block)

taskConstants = processTaskDetails(block.taskDetails);

%% convert the peripheralTimestamp field from 16xuint8 to 2xint64
if isfield(block.continuous,'peripheralTimestamp')
    tmp = reshape(block.continuous.peripheralTimestamp',1,[]);
    block.continuous.peripheralTimestamp = reshape(typecast(tmp,'int64'),2,[])';
end

%% start by looking for the PREMOVE state
stateNames = {block.taskDetails.states.name};
stateIds = [block.taskDetails.states.id];

%% for linux task, there's no trial structure. just use the pause and unpause as boundaries

pauseToggle = [0; diff(block.continuous.pause)];
startinds = find(pauseToggle==-1);
if isempty(startinds),
    startinds = 1;  %BJ: if no toggle on, just start at start of block; added 
    %in case using RTI with non-tablet data (will work irrespective of effector)
end

endinds = find(pauseToggle==1);
if isempty(endinds),
    endinds = length(block.continuous.clock); % BJ: if no toggle off, just go to end of block
end

if length(endinds) < length(startinds)
    endinds = [endinds(:); length(pauseToggle)];
end
startpoints = block.continuous.clock(startinds);
endpoints = block.continuous.clock(endinds-1); %BJ: adding -1 to endinds because without it was consistently computing endindex to be 1 after the end of the block (which broke stuff downstream).

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

R(1).taskConstants = taskConstants; %added by BJ; needed for HMM RTI build (wasn't getting saved otherwise)
out = R;
