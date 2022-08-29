function out = movementCue_streamParser(block)

%% convert the laptopTimestamp field from 16xuint8 to 2xint64
if isfield(block.continuous,'laptopTimeStamp')
    tmp = reshape(block.continuous.laptopTimeStamp',1,[]);
    block.continuous.laptopTimeStamp = reshape(typecast(tmp,'int64'),2,[])';
end

%% start by looking for the PREMOVE state
stateNames = {block.taskDetails.states.name};
stateIds = [block.taskDetails.states.id];

% trials start with "PRE_MOVE", end with "REST_CUE"
preMoveState = stateIds(strcmp(stateNames, 'STATE_PRE_MOVE'));
restCueState = stateIds(strcmp(stateNames, 'STATE_REST_CUE'));


%% segment the data by the premove state
pmstatevec = block.continuous.state == preMoveState;
pmstateinds = block.continuous.clock(find(pmstatevec));

rcstatevec = block.continuous.state == restCueState;
rcstateinds = block.continuous.clock(find(rcstatevec));

% get the start points
startpoints = [pmstateinds(1); pmstateinds(find(diff(pmstateinds)>1)+1)];
rcstateinds = rcstateinds(rcstateinds>pmstateinds(1));
endpoints = [rcstateinds(diff(rcstateinds)>1); rcstateinds(end)];
% get the end points
%endpoints = 

%% debugging check
% plot(pmstatevec)
% for nn=1:length(startpoints)
%     vline(startpoints(nn));
% end

if numel(startpoints) > numel(endpoints)
    disp('movementCue_streamParser: warning - unequal start and end');
    if startpoints(end) > endpoints(end)
        disp('movementCue_streamParser: trimming startpoints to match');
        startpoints = startpoints(1:end-1);
    else
        error('huh?');
    end
end
assert(length(startpoints) == length(endpoints), 'not equal start and end');
assert(all(startpoints < endpoints), 'endpoints before startpoints?');
assert(all(startpoints(2:end) > endpoints(1:end-1)), 'starts before prev trial is finished?');


out=block2trials(block, startpoints, endpoints);

out=swimPreprocessR(out);
