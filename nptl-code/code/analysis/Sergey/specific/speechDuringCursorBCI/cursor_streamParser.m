% SDS Feb 2019: In Darrel's branch, the cursor stream parser is different than in deployed
% branch. This is copied from Darrel's branch. 
% Since the Dec 2018 t5 experiments were collected using Darrel's branch, I've
% moved this script into this analysis directory so it gets used. Remove it if analyzing
% older t5 speech dataset (t5-words from 2017)


function out = cursor_streamParser(block)

taskConstants = processTaskDetails(block.taskDetails);

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
restCueState = stateIds(nameInds);
succState = stateIds(strcmp(stateNames, 'STATE_SUCCESS'));

failState = stateIds(strcmp(stateNames, 'STATE_FAIL'));
moveState = stateIds(strcmp(stateNames, 'STATE_MOVE'));
targetOnState = stateIds(strcmp(stateNames, 'STATE_NEW_TARGET'));
acqState = stateIds(strcmp(stateNames, 'STATE_ACQUIRE'));

[~,nameInds,~] = intersect(stateNames,{'STATE_SCORE_PAUSE', 'STATE_SCORE_TARGET'});
%[~,nameInds,~] = intersect(stateNames,{'STATE_SCORE_PAUSE'});
scoreStates = stateIds(nameInds);

clickTT = stateIds(strcmp(stateNames,'TARGET_TYPE_CLICK'));
if ~isempty(clickTT)
    moveStateClick = stateIds(strcmp(stateNames, 'STATE_MOVE_CLICK'));
end
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

if block.taskDetails.versionId < 0.002
    startpoints = [pmstateinds(find(diff(pmstateinds)>1))];
else % for > 0.002
    startpoints = [block.discrete.clock(1:end-1)];
end

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
if ~isempty(scoreStates)
    scoreInds = find(block.continuous.state == scoreStates(1) | block.continuous.state == scoreStates(2));
else
    scoreInds =[];
end
if ~isempty(scoreInds)
    scoreStarts = block.continuous.clock([scoreInds(1); scoreInds(find(diff(scoreInds)>1)+1)]);
    %% find the next startpoint following each of these
    for nn = 1:length(scoreStarts)
        inds = find(startpoints>scoreStarts(nn));
        trialStartInd = min(inds);
        if ~isempty(trialStartInd)
            %% replace the startpoint so that it includes the score state
            startpoints(trialStartInd) = scoreStarts(nn);
            % disp(['replacing ' num2str(trialStartInd)]);
        end
    end
end
%% edit by CP,20130910
% DRD EDIT
if (numel(startpoints) ~= numel(endpoints))
    disp('cursor_streamParser: start and ends not matching for some reason. Running Darrel Cursor stream parser');

    start = double(startpoints);
    ends = double(endpoints);
    
    numStartPoints = numel(start);
    numEndPoints = numel(ends);
    
    newEnds = [];
    newStarts = [];
    
    firstEndFlag = 0;
    for i = 1 : numel(ends)
        currEndpoint = ends(i);
        differ = double(double(startpoints) - double(currEndpoint));
        small = differ >=1;
        large = differ <=5;
        foundStart = startpoints(small & large);
        
        if ~isempty(foundStart)
            if firstEndFlag == 0
                firstEndFlag = 1;
                startInd = find(startpoints == foundStart);
                newStarts = [newStarts; startpoints(startInd-1)];
            end
            newStarts = [newStarts; foundStart];
            newEnds = [newEnds; currEndpoint];
            
        end
        
        if i == numel(ends)
            newEnds = [newEnds; currEndpoint];
            
        end
    end
    
    startpoints = uint32(newStarts);
    endpoints = uint32(newEnds);
    
end

% DRD EDIT END

% 1 sample is getting cutoff - perhaps 
% discrete packets are sent on sample 1 of pre_trial instead of 0? % 
% SNF: ^ this is true, because on 'pause', pre_trial = 0 for a long time and
% you only want discrete packets sent one time, so they're sent on sample 1. 
if numel(startpoints) ~= numel(endpoints)
    disp('cursor_streamParser: start and ends not matching for some reason. throwing away 1 startpoint');
    startpoints = startpoints(1:end-1);
end

if endpoints(1:end-1)<startpoints(2:end)-1
    [~,~,startinds] = intersect(startpoints,block.continuous.clock);
    
    if ismember( block.discrete.taskType, [double( cursorConstants.TASK_GRIDLIKE ), ...
            double( cursorConstants.TASK_RANDOM), ...
            double( cursorConstants.TASK_RAYS), ...
            double( cursorConstants.TASK_FCC), ...
            double( cursorConstants.TASK_MULTICLICK ), ...
            double( cursorConstants.TASK_CENTER_OUT ), ...
            double( cursorConstants.TASK_CENTER_OUT_NO_BACK)])
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
        assert(all(block.continuous.state(startinds)==...
            block.continuous.state(startinds-1)),...
            'simple shift wont fix alignment issue');
        startpoints = startpoints-1;
    end
end

assert(length(startpoints) == length(endpoints), 'not equal start and end');
assert(all(startpoints < endpoints), 'endpoints before startpoints?');
assert(all(startpoints(2:end) > endpoints(1:end-1)), 'starts before prev trial is finished?');
%% make R struct: 
R=block2trials(block, startpoints, endpoints);

%% calculate trial statistics
for nt = 1:length(R)
    R(nt).isSuccessful = true;
    if any(R(nt).state == failState)
        R(nt).isSuccessful = false;        
    end
    %% check if this is a dwell or click target
    if ~isfield(R(nt),'currentTargetType') | isempty(clickTT) | all(R(nt).currentTargetType ~= clickTT)
        %% this is a dwell target.
        %R(nt).timeTargetOn = min(find(R(nt).state == moveState));
        %% changed by chethan, 20130829 - targetOn should be linked to STATE_NEW_TARGET, and 
        %% go cue should be linked to STATE_MOVE
        R(nt).timeTargetOn = min(find(R(nt).state == targetOnState));
        R(nt).timeGoCue = min(find(R(nt).state == moveState));
        acqTimes = find(R(nt).state == acqState);
    else %% this is a click target
        %R(nt).timeTargetOn = min(find(R(nt).state == moveStateClick));
        %% changed by chethan 20130829, same issue as above
        R(nt).timeTargetOn = min(find(R(nt).state == targetOnState));
        R(nt).timeGoCue = min(find(R(nt).state == moveStateClick));
        
        %% this is a HACK for now! - should be pulling STATE_HOVER from the taskDetails data
        acqTimes = min(find(R(nt).state == CursorStates.STATE_HOVER));        
    end
    
    % time target acquired is different for the RAYS variant of this task 
    if ismember( block.discrete.taskType(nt), double( cursorConstants.TASK_RAYS) )
    	% Counting only successful target acquisition a targetAcquire
        acqTimes = min( find(R(nt).state == succState ) );
    end
    
    
    R(nt).timeFirstTargetAcquire = min(acqTimes);
    R(nt).timeLastTargetAcquire = min(acqTimes);
    tmp = find(diff(acqTimes)>1);
    if length(tmp)
        R(nt).timeLastTargetAcquire = acqTimes(tmp(end)+1);
    end
    R(nt).trialNum = R(nt).startTrialParams.trialNum;
    R(nt).trialLength = size(R(nt).clock,2) - R(nt).timeTargetOn;
end


% Get target pos (fix for model time alignment error) [and click target -SF]
for i = 1:length(R) - 1
    R(i).posTarget = double(R(i+1).startTrialParams.currentTarget);
    if isfield(R(i).startTrialParams,'nextClickTarg')
        R(i).clickTarget = double(R(i).startTrialParams.nextClickTarg);  %SNF multiclick
    end
%     R(i).startTrialParams = rmfield(R(i).startTrialParams, {'currentTarget', 'nextTarget'});
end
R(1).lastPosTarget = [0;0];
for i = 2:length(R)
    R(i).lastPosTarget = double(R(i).startTrialParams.currentTarget);
    %R(i).startTrialParams = rmfield(R(i).startTrialParams, {'currentTarget', 'nextTarget'});
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

if block.taskDetails.versionId  >= 3.02-0.001     % need - small number due to single rounding
    % Since I don't know for sure how older tasks worked, I don't want to automatically add
    % this to them. So I'll do this for task versions that I know firsthand. 
    R(1).clickTimes = []; % adds this to the struct
    allClicks = [R.clickState]; %this doesn't include dwell target 'clicks' which are needed for multiclick -SF
    if any( allClicks ) % check will speed up parsing for non-click blocks
        runningClickSamples = 0; % will run through the trial click state and see when clicks happen
        canClickAgain = true; %will be used as a latch so click events happen on rise
        for iTrial = 1 : numel( R )
            for t = 1 : numel( R(iTrial).clickState )
                if logical( R(iTrial).clickState(t) )
                    runningClickSamples = runningClickSamples + 1;
                else
                    runningClickSamples = 0; % reset to zero
                    canClickAgain = true; % latch reset
                end
                if canClickAgain
                    if runningClickSamples >= R(iTrial).startTrialParams.clickHoldTime 
                        % it's a click!
                        R(iTrial).clickTimes(end+1) = t;
                        canClickAgain = false; % clicked, can't again until not-clicking
                    end
                end                 
            end  
        end
    end
end
%%% why are we deleting the last trial?? commenting this out (-CP,20130909)
%%% ah. because the last trial doesn't have postarget.
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
allTargets = [R.posTarget];
uTargets = unique(allTargets','rows')';
for nn = 1:length(R)
    if isempty(R(nn).posTarget)
        R(nn).posTarget = nan(size(R(nn).posTarget,1),1);
        %% if this was a successful trial, infer where the target is
        [~,ia,~] = intersect(R(nn).state,[taskConstants.STATE_ACQUIRE taskConstants.STATE_SUCCESS]);
        if ~isempty(ia)
            %% find the closest target
            cpos = R(nn).cursorPosition(:,ia(1));
            [~,itarget] = min(sqrt(sum(bsxfun(@minus,uTargets,cpos))));
            R(nn).posTarget = uTargets(:,itarget);
        end
    end
end
% glove garbage that no one uses: 
R=cursorPreprocessR(R);

out = R;
