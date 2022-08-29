function out = cursorTask_streamParser(block)

%% start by looking for the PREMOVE state

stateNames = {block.taskDetails.states.name};
stateIds = [block.taskDetails.states.id];

% trials start with "PRE_MOVE", end with "REST_CUE"
preMoveState = stateIds(strcmp(stateNames, 'STATE_PRE_TRIAL'));
[~, nameInds, ~] = intersect(stateNames, {'STATE_SUCCESS', 'STATE_FAIL'});
restCueState = stateIds(nameInds);

failState = stateIds(strcmp(stateNames, 'STATE_FAIL'));
moveState = stateIds(strcmp(stateNames, 'STATE_MOVE'));
acqState = stateIds(strcmp(stateNames, 'STATE_ACQUIRE'));

clickTT = stateIds(strcmp(stateNames,'TARGET_TYPE_CLICK'));
if ~isempty(clickTT)
    moveStateClick = stateIds(strcmp(stateNames, 'STATE_MOVE_CLICK'));
end

%% segment the data by the premove state
pmstatevec = block.continuous.state == preMoveState;
pmstateinds = block.continuous.clock(find(pmstatevec));

rcstatevec = false(size(block.continuous.state));
for nn = 1:length(restCueState)
    rcstatevec(block.continuous.state == restCueState(nn)) = true;
end
rcstateinds = block.continuous.clock(find(rcstatevec));

% get the start points
%startpoints = [pmstateinds(1); pmstateinds(find(diff(pmstateinds)>1)+1)];

if block.taskDetails.versionId < 0.002
    startpoints = [pmstateinds(find(diff(pmstateinds)>1))];
else % for 0.002
    startpoints = [block.discrete.clock(1:end-1)];

end
        
rcstateinds = rcstateinds(rcstateinds>pmstateinds(1));
endpoints = [rcstateinds(diff(rcstateinds)>1); rcstateinds(end)];
% get the end points
%endpoints = 

%% debugging check
%  plot(pmstatevec)
%  for nn=1:length(startpoints)
%      vline(startpoints(nn));
%  end

assert(length(startpoints) == length(endpoints), 'not equal start and end');
assert(all(startpoints < endpoints), 'endpoints before startpoints?');
assert(all(startpoints(2:end) > endpoints(1:end-1)), 'starts before prev trial is finished?');

R=block2trials(block, startpoints, endpoints);

%% calculate trial statistics
for nt = 1:length(R)
    R(nt).isSuccessful = true;
    if any(R(nt).state == failState)
        R(nt).isSuccessful = false;        
    end

    %% check if this is a dwell or click target
    if ~isfield(R(nt),'currentTargetType') | isempty(clickTT) | all(R(nt).currentTargetType ~= clickTT)
        R(nt).timeTargetOn = min(find(R(nt).state == moveState));
        acqTimes = find(R(nt).state == acqState);
    else
        R(nt).timeTargetOn = min(find(R(nt).state == moveStateClick));
        %% this is a HACK for now! - should be pulling STATE_HOVER from the taskDetails data
        acqTimes = min(find(R(nt).state == CursorStates.STATE_HOVER));        
    end
    R(nt).timeFirstTargetAcquire = min(acqTimes);
    R(nt).timeLastTargetAcquire = min(acqTimes);
    tmp = find(diff(acqTimes)>1);
    if length(tmp)
        R(nt).timeLastTargetAcquire = acqTimes(tmp+1);
    end
    R(nt).trialNum = R(nt).startTrialParams.trialNum;
    R(nt).trialLength = size(R(nt).clock,2) - R(nt).timeTargetOn;
end

out = R;