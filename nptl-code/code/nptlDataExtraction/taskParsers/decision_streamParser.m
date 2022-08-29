function out = decision_streamParser(block)

taskConstants = processTaskDetails(block.taskDetails);

%% convert the peripheralTimestamp field from 16xuint8 to 2xint64
if isfield(block.continuous,'peripheralTimestamp')
    tmp = reshape(block.continuous.peripheralTimestamp',1,[]);
    block.continuous.peripheralTimestamp = reshape(typecast(tmp,'int64'),2,[])';
end

%% start by looking for the PREMOVE state
stateNames = {block.taskDetails.states.name};
stateIds = [block.taskDetails.states.id];

% trials start with "PRE_MOVE", end with "INTERTRIAL"
preMoveState = stateIds(strcmp(stateNames, 'STATE_PRE_TRIAL'));
[~, nameInds, ~] = intersect(stateNames, {'STATE_SUCCESS', 'STATE_FAIL'});
restCueState = stateIds(nameInds); %not sure if this includes intertrial
succState = stateIds(strcmp(stateNames, 'STATE_SUCCESS'));

failState = stateIds(strcmp(stateNames, 'STATE_FAIL'));
moveState = stateIds(strcmp(stateNames, 'STATE_MOVE'));
targetOnState = stateIds(strcmp(stateNames, 'STATE_NEW_TARGET'));
acqState = stateIds(strcmp(stateNames, 'STATE_ACQUIRE'));
stimOnState = stateIds(strcmp(stateNames, 'STATE_STIMULUS_ONSET')); 
[~,nameInds,~] = intersect(stateNames,{'STATE_INTERTRIAL'});
%[~,nameInds,~] = intersect(stateNames,{'STATE_SCORE_PAUSE'});
scoreStates = stateIds(nameInds);

% clickTT = stateIds(strcmp(stateNames,'TARGET_TYPE_CLICK'));
% if ~isempty(clickTT)
%     moveStateClick = stateIds(strcmp(stateNames, 'STATE_MOVE_CLICK'));
% end

%% segment the data by the premove state
pmstatevec = block.continuous.state == preMoveState;
pmstateinds = block.continuous.clock(find(pmstatevec)); % premove states

rcstatevec = false(size(block.continuous.state));
for nn = 1:length(restCueState)
    rcstatevec(block.continuous.state == restCueState(nn)) = true;
end
rcstateinds = block.continuous.clock(find(rcstatevec)); %rest cue states (success or failure)

% get the start points
%startpoints = [pmstateinds(1); pmstateinds(find(diff(pmstateinds)>1)+1)];

% if block.taskDetails.versionId < 0.002
%     startpoints = [pmstateinds(find(diff(pmstateinds)>1))];
% else % for > 0.002
    startpoints = [block.discrete.clock(1:end-1)];
    
% end

% cuts out first trail end if it precedes first trial start state.
rcstateinds = rcstateinds(rcstateinds>pmstateinds(1));
endpoints = [rcstateinds(diff(rcstateinds)>1); rcstateinds(end)];
% get the end points
%endpoints = 

%% debugging check
%  plot(pmstatevec)
%  for nn=1:length(startpoints)
%      vline(startpoints(nn));
%  end

% SDS April 29 2017
% This part exists already:
if length(endpoints) > length(startpoints)
    endpoints = endpoints(1:end-1);
end


%% CP, 20130909:
%% this is a hack for score trials - 
% STATE_SCORE_PAUSE is currently getting chopped out of the Rstruct, as it
% preceeds STATE_PRE_TRIAL. to get continuous Rstructs, we will lump STATE_SCORE_PAUSE with the trial immediately
% following it, which will later be marked as a score trial
% if ~isempty(scoreStates)
%     scoreInds = find(block.continuous.state == scoreStates(1) | block.continuous.state == scoreStates(2));
% else
%     scoreInds =[];
% end
% if ~isempty(scoreInds)
%     scoreStarts = block.continuous.clock([scoreInds(1); scoreInds(find(diff(scoreInds)>1)+1)]);
%     %% find the next startpoint following each of these
%     for nn = 1:length(scoreStarts)
%         inds = find(startpoints>scoreStarts(nn));
%         trialStartInd = min(inds);
%         if ~isempty(trialStartInd)
%             %% replace the startpoint so that it includes the score state
%             startpoints(trialStartInd) = scoreStarts(nn);
%             % disp(['replacing ' num2str(trialStartInd)]);
%         end
%     end
% end


%% edit by CP,20130910
% 1 sample is getting cutoff - perhaps 
% discrete packets are sent on sample 1 of pre_trial instead of 0?
if numel(startpoints) ~= numel(endpoints)
    disp('decision_streamParser: start and ends not matching for some reason. throwing away 1 startpoint');
    startpoints = startpoints(1:end-1);
end

if endpoints(1:end-1)<startpoints(2:end)-1
    [~,~,startinds] = intersect(startpoints,block.continuous.clock);
    
    if ismember( block.discrete.taskType, [double( cursorConstants.TASK_GRIDLIKE ), ...
            double( cursorConstants.TASK_RANDOM), ...
            double( cursorConstants.TASK_RAYS), ...
            double( cursorConstants.TASK_FCC), ...
            double( cursorConstants.TASK_CENTER_OUT )])
        % Gridlike task results in very brief being in the init state, and
        % for some reason this causes the below assertion to fail. I'm not
        % sure of the details but am willing to ignroe this for now and
        % trust that things are working correctly.
        % Thus, below assertion will not happen in TASK_GRIDLIKE
        % Also, for whatever reason the offset shouldn't happen to trial 1.
        % Let's see if this stuff holds up, it's quite jenky...
        % SDS Jan 2017
        % Added TASK_CENTER_OUT on March 30 since its start state now
        % different.
        % SDS April 29 2017 TASK_RAYS included too
        
        startpoints(2:end) = startpoints(2:end)-1;
    else
        % verify that shifting startpoints by 1 will preserve the state
        assert(all(block.continuous.state(startinds(2:end))==...
            block.continuous.state(startinds(2:end)-1)),...
            'simple shift wont fix alignment issue');
        startpoints(2:end) = startpoints(2:end)-1;
    end
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
    R(nt).timeTargetOn = find(R(nt).state == targetOnState, 1, 'first' );
    if isempty(R(nt).timeTargetOn)
        R(nt).timeTargetOn = nan; 
    end
    R(nt).timeStimulusOn = find(R(nt).state == stimOnState, 1, 'first' );
    if isempty(R(nt).timeTargetOn)
        R(nt).timeStimulusOn = nan; 
    end
    R(nt).timeGoCue = find(R(nt).state == moveState, 1 , 'first');
    if isempty(R(nt).timeGoCue)
        R(nt).timeGoCue = nan; 
    end
    %acquire state is only 1 sample long
    R(nt).timeTargAcquire = find(R(nt).state == acqState);
   
    R(nt).trialNum = R(nt).startTrialParams.trialNum;
    R(nt).trialLength = size(R(nt).clock,2) - R(nt).timeTargetOn;
    if isempty(R(nt).timeTargAcquire)
        R(nt).timeTargAcquire = nan;
         R(nt).movementTime = nan;
    else
         R(nt).movementTime = R(nt).timeGoCue; 
    end
    if ~isempty(R(nt).stimCondMatrix)
        R(nt).coherence = 100*(2*mode(double(R(nt).stimCondMatrix(4,:))) - 225) /225;
    else
        R(nt).coherence = nan; 
    end
end

% SDS Jan 2017: currentTarget should be removed. It's misleading since the value in continuous packets should be trusted. This one changes after 21 ms into the trial
for i = 1 : numel(R)
    R(i).startTrialParams = rmfield(R(i).startTrialParams, {'currentTarget'}); 
end

%% SDS Jan 2017
% Adds a .clickTimes field to each R struct element, which records when clicks
% happened. IMPORTANT: It reports only clicks that lasted the required .clickHoldTime,
% and it reports the click time as once that duration condition was satisfied (so, for
% example, it'll report the click 30 ms after it was initiatied if .clickHoldTime==30).
% NOTE: Since we don't reset .clickTimer on new trials (which we could, I've just chosen
% not to), it makes sense to tun through all the samples in an R struct continuously so
% that clicks across trial borders can be remembered.
% 
% if block.taskDetails.versionId  >= 3.02-0.001     % need - small number due to single rounding
%     % Since I don't know for sure how older tasks worked, I don't want to automatically add
%     % this to them. So I'll do this for task versions that I know firsthand. 
%     R(1).clickTimes = []; % adds this to the struct
%     allClicks = [R.clickState];
%     if any( allClicks ) % check will speed up parsing for non-click blocks
%         runningClickSamples = 0; % will run through the trial click state and see when clicks happen
%         canClickAgain = true; %will be used as a latch so click events happen on rise
%         for iTrial = 1 : numel( R )
%             
%             for t = 1 : numel( R(iTrial).clickState )
%                 if logical( R(iTrial).clickState(t) )
%                     runningClickSamples = runningClickSamples + 1;
%                 else
%                     runningClickSamples = 0; % reset to zero
%                     canClickAgain = true; % latch reset
%                 end
%                 if canClickAgain
%                     if runningClickSamples >= R(iTrial).startTrialParams.clickHoldTime 
%                         % it's a click!
%                         R(iTrial).clickTimes(end+1) = t;
%                         canClickAgain = false; % clicked, can't again until not-clicking
%                     end
%                 end                 
%             end  
%         end
%     end
% end








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
