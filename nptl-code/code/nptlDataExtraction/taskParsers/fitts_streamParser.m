function out = fitts_streamParser(block)

%% convert the peripheralTimestamp field from 16xuint8 to 2xint64
if isfield(block.continuous,'peripheralTimestamp')
    tmp = reshape(block.continuous.peripheralTimestamp',1,[]);
    block.continuous.peripheralTimestamp = reshape(typecast(tmp,'int64'),2,[])';
end

%% start by looking for the PREMOVE state
stateNames = {block.taskDetails.states.name};
stateIds = [block.taskDetails.states.id];


% trials start with "PRE_MOVE", end with "REST_CUE"
preMoveState = stateIds(strcmp(stateNames, 'STATE_PRE_TRIAL'));

[~, nameInds, ~] = intersect(stateNames, {'STATE_SUCCESS', 'STATE_FAIL'});
trialEndState = stateIds(nameInds);

failState = stateIds(strcmp(stateNames, 'STATE_FAIL'));
%moveState = stateIds(strcmp(stateNames, 'STATE_MOVE'));
moveStates = [FittsStates.STATE_MOVE FittsStates.STATE_MOVE_CLICK];
%acqState = stateIds(strcmp(stateNames, 'STATE_ACQUIRE'));
acqStates = [FittsStates.STATE_ACQUIRE FittsStates.STATE_HOVER];
succState = [FittsStates.STATE_SUCCESS];

%% segment the data by the premove state
pmstatevec = block.continuous.state == preMoveState;
pmstateinds = block.continuous.clock(find(pmstatevec));

rcstatevec = false(size(block.continuous.state));
for nn = 1:length(trialEndState)
    rcstatevec(block.continuous.state == trialEndState(nn)) = true;
end
rcstateinds = block.continuous.clock(find(rcstatevec));

% get the start points
startpoints = [pmstateinds(1); pmstateinds(find(diff(pmstateinds)>1)+1)];
% startpoints = [block.discrete.clock];
        

% get the end points
rcstateinds = rcstateinds(rcstateinds>pmstateinds(1));
endpoints = [rcstateinds(diff(rcstateinds)>1); rcstateinds(end)];

%% debugging check
%  plot(pmstatevec)
%  for nn=1:length(startpoints)
%      vline(startpoints(nn));
%  end
if length(endpoints) > length(startpoints)
    endpoints = endpoints(1:end-1);
end
if length(startpoints) > length(endpoints)
    startpoints = startpoints(1:end-1);
end
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
    R(nt).timeTargetOn = min(find(ismember(R(nt).state, moveStates)));
    acqTimes = find(ismember(R(nt).state,acqStates));
    R(nt).timeFirstTargetAcquire = min(acqTimes);
    R(nt).timeLastTargetAcquire = min(acqTimes);
    R(nt).timeSuccess = find(R(nt).state==succState);
    tmp = find(diff(acqTimes)>1);
    if length(tmp)
        R(nt).timeLastTargetAcquire = acqTimes(tmp(end)+1);
    end
    R(nt).trialNum = R(nt).startTrialParams.trialNum;
    R(nt).trialLength = size(R(nt).clock,2) - R(nt).timeTargetOn;
end


% Get target pos
for i = 1:length(R) 
     R(i).posTarget = R(i).startTrialParams.currentTarget;
     if isfield(R(i).startTrialParams, 'currentTargetDiameter')
         R(i).targetDiameter = R(i).startTrialParams.currentTargetDiameter;
     end
     %R(i).startTrialParams = rmfield(R(i).startTrialParams, {'currentTarget', 'nextTarget'});
end

R(1).lastPosTarget = [0;0];
for i = 2:length(R)
    R(i).lastPosTarget = R(i-1).startTrialParams.currentTarget;
end

for i = 1:length(R) 
    R(i).distanceToTarget = sqrt(sum((double(R(i).posTarget(:)) - double(R(i).lastPosTarget(:))).^2));
end


%%  this is all done in the block2trials script now
% %% add "pretrial" and "posttrial" for smoothing
% streamFields = {'clock','LFP','HLFP','minAcausSpikeBand','xorth','SBsmoothed','HLFPsmoothed'};
% postTrialKeep=500;
% preTrialKeep=500;
% for nt= 1:length(R)
%     for nf = 1:numel(streamFields)
%         f=streamFields{nf};
%         if isfield(R(nt),f)
%             if nt>1
%                 if size(R(nt-1).(f),2) >= preTrialKeep
%                     R(nt).preTrial.(f) = R(nt-1).(f)(:,end-preTrialKeep+1:end);
%                 else
%                     R(nt).preTrial.(f) = [];
%                 end
%             end
%             if nt<length(R)
%                 if size(R(nt+1).(f),2) >= postTrialKeep
%                     R(nt).postTrial.(f) = R(nt+1).(f)(:,1:postTrialKeep);
%                 else
%                     R(nt).postTrial.(f) = [];
%                 end
%             end
%         end
%     end
% end
% R = R(1:end-1);

out = R;
