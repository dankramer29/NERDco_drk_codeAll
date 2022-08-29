function out = yang_streamParser(block)

taskConstants = processTaskDetails(block.taskDetails);

%% convert the peripheralTimestamp field from 16xuint8 to 2xint64
if isfield(block.continuous,'peripheralTimestamp')
    tmp = reshape(block.continuous.peripheralTimestamp',1,[]);
    block.continuous.peripheralTimestamp = reshape(typecast(tmp,'int64'),2,[])';
end

%% start by looking for the PREMOVE state
stateNames = {block.taskDetails.states.name};
stateIds = [block.taskDetails.states.id];

% trials start with "CONTEXT", end with "INTERTRIAL"
contextState = stateIds(strcmp(stateNames, 'STATE_CONTEXT'));
stimOnState = stateIds(strcmp(stateNames, 'STATE_STIMULUS_ONSET')); 
goState = stateIds(strcmp(stateNames, 'STATE_GO'));
acqState = stateIds(strcmp(stateNames, 'STATE_ACQUIRE'));
[~, nameInds, ~] = intersect(stateNames, {'STATE_SUCCESS', 'STATE_FAIL'});
restCueState = stateIds(nameInds);
failState = stateIds(strcmp(stateNames, 'STATE_FAIL'));
preTrialState = stateIds(strcmp(stateNames, 'STATE_PRE_TRIAL'));

%% segment the data by the premove state
ptstatevec = block.continuous.state == preTrialState;
ptstateinds = block.continuous.clock(ptstatevec); % pretrial states

rcstatevec = false(size(block.continuous.state));
for nn = 1:length(restCueState)
    rcstatevec(block.continuous.state == restCueState(nn)) = true;
end
rcstateinds = block.continuous.clock(rcstatevec); %rest cue states (success or failure)

% get the start points
startpoints = [block.discrete.clock(1:end-1)];
startpoints = startpoints(2:end); %remove context 1 LND

% cuts out first trial end if it precedes first trial start state.
rcstateinds = rcstateinds(rcstateinds>ptstateinds(1));
endpoints = [rcstateinds(diff(rcstateinds)>1); rcstateinds(end)];
if length(endpoints) > length(startpoints)
    endpoints = endpoints(1:end-1);
end

%% edit by CP,20130910
% 1 sample is getting cutoff - perhaps 
% discrete packets are sent on sample 1 of pre_trial instead of 0?
% if numel(startpoints) ~= numel(endpoints)
%     disp('decision_streamParser: start and ends not matching for some reason. throwing away 1 startpoint');
%     startpoints = startpoints(1:end-1);
% end
% 
% if endpoints(1:end-1)<startpoints(2:end)-1
%     [~,~,startinds] = intersect(startpoints,block.continuous.clock);
%     
%     if ismember( block.discrete.taskType, [double( cursorConstants.TASK_GRIDLIKE ), ...
%             double( cursorConstants.TASK_RANDOM), ...
%             double( cursorConstants.TASK_RAYS), ...
%             double( cursorConstants.TASK_FCC), ...
%             double( cursorConstants.TASK_CENTER_OUT )])
%         % Gridlike task results in very brief being in the init state, and
%         % for some reason this causes the below assertion to fail. I'm not
%         % sure of the details but am willing to ignroe this for now and
%         % trust that things are working correctly.
%         % Thus, below assertion will not happen in TASK_GRIDLIKE
%         % Also, for whatever reason the offset shouldn't happen to trial 1.
%         % Let's see if this stuff holds up, it's quite jenky...
%         % SDS Jan 2017
%         % Added TASK_CENTER_OUT on March 30 since its start state now
%         % different.
%         % SDS April 29 2017 TASK_RAYS included too
%         
%         startpoints(2:end) = startpoints(2:end)-1;
%     else
%         % verify that shifting startpoints by 1 will preserve the state
%         assert(all(block.continuous.state(startinds(2:end))==...
%             block.continuous.state(startinds(2:end)-1)),...
%             'simple shift wont fix alignment issue');
%         startpoints(2:end) = startpoints(2:end)-1;
%     end
% end

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
    R(nt).preTrialState = find(R(nt).state == preTrialState, 1, 'first' );
    if isempty(R(nt).preTrialState)
        R(nt).preTrialState = nan; 
    end
    R(nt).timeStimulusOn = find(R(nt).state == stimOnState, 1, 'first' );
    if isempty(R(nt).timeStimulusOn)
        R(nt).timeStimulusOn = nan; 
    end
    R(nt).timeGoCue = find(R(nt).state == goState, 1 , 'first');
    if isempty(R(nt).timeGoCue)
        R(nt).timeGoCue = nan; 
    end
    %acquire state is only 1 sample long
    R(nt).timeTargAcquire = find(R(nt).state == acqState);
   
    R(nt).trialNum = R(nt).startTrialParams.trialNum;
    R(nt).trialLength = size(R(nt).clock,2) - R(nt).timeStimulusOn;
    if isempty(R(nt).timeTargAcquire)
        R(nt).timeTargAcquire = nan;
         R(nt).goTime = nan;
    else
         R(nt).goTime = R(nt).timeGoCue; 
    end
end

% SDS Jan 2017: currentTarget should be removed. It's misleading since the value in continuous packets should be trusted. This one changes after 21 ms into the trial
for i = 1 : numel(R)
    R(i).startTrialParams = rmfield(R(i).startTrialParams, {'currentTarget'}); 
end

%% why are we deleting the last trial?? commenting this out (-CP,20130909)
%% ah. because the last trial doesn't have postarget.
R = R(1:end-1);

for i = 1:length(R)
    R(i).startTrialParams.isScoreTrial = false;
end

stp = [R.startTrialParams];
if isfield(R(1).startTrialParams,'trialsPerScore') & any([stp.showScores])
    %% leaving score trials in, but setting a flag in the Rstruct to handle them (-CP,20130909)
    % % Remove score trials and trials preceding score trials
    trialsPerScore = R(1).startTrialParams.trialsPerScore;
    scoreidx = false(size(R));
    scoreidx(trialsPerScore:trialsPerScore:end) = true;
    %% why are we removing trials before score trials...? commenting this out (-CP,20130909)
    % scoreidx(trialsPerScore-1:trialsPerScore:end) = true;

    for ni = find(scoreidx)
        R(ni).startTrialParams.isScoreTrial = true;
    end
    % % (no longer removing score trials, just flagging them)
    % R = R(~scoreidx);
end

%% early on, score trials did not get paired with discrete packets properly
%% so their posTarget field is blank. this affects the trials before score trials
%% search for these. try to determine their target. if it can't be found, set
%% it to NaN
%% -CP, 20130921
% allTargets = [R.posTarget];
% uTargets = unique(allTargets','rows')';
% for nn = 1:length(R)
%     if isempty(R(nn).posTarget)
%         R(nn).posTarget = nan(size(R(nn).posTarget,1),1);
%         %% if this was a successful trial, infer where the target is
%         [~,ia,~] = intersect(R(nn).state,[taskConstants.STATE_ACQUIRE taskConstants.STATE_SUCCESS]);
%         if ~isempty(ia)
%             %% find the closest target
%             cpos = R(nn).cursorPosition(:,ia(1));
%             [~,itarget] = min(sqrt(sum(bsxfun(@minus,uTargets,cpos))));
%             R(nn).posTarget = uTargets(:,itarget);
%         end
%     end
% end


out = R;
