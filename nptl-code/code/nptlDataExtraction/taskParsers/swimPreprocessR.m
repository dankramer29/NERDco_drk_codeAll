function R = preprocess(R,taskDetails)
    if ~exist('taskDetails','var')
        taskDetails = R(1).taskDetails;
    end
    tc = processTaskDetails(taskDetails);

    %% deal with dual-array
    if isfield(R(1),'minAcausSpikeBand1')
        streamFields = {'clock','LFP1','HLFP1','LFP2','HLFP2','minAcausSpikeBand1','minAcausSpikeBand2'};
    else
        streamFields = {'clock','LFP','HLFP','minAcausSpikeBand'};
    end
    postTrialKeep=500;
    preTrialKeep=500;

    % fix the wonky startTrialParams
    fieldsToFix = {'delayPeriodDuration','movementDuration','holdDuration','restDuration','repsPerBlock',...
                   'whichMovements','cycleNum','numMovements','numTrials','currentTrial','currentMovement',...
                   'movementOrderStart','movementNum'};
    for nt= 1:numel(R)
        for nf = 1:numel(fieldsToFix)
            if isfield(R(nt).startTrialParams,fieldsToFix{nf})
                R(nt).startTrialParams.(fieldsToFix{nf}) = R(nt).startTrialParams.(fieldsToFix{nf})(:,end);
            end
        end
    end
        

    %% iterate over all trials in rstruct, validate data, get important markers
    for nt= 1:numel(R)
        if isfield(R,'currentMovement') & ~isfield(R(1).startTrialParams, 'currentMovement')
            %% figure out what the current movement is
            moves = R(nt).currentMovement(R(nt).state~=tc.STATE_PRE_MOVE);
            assert(all(moves == moves(1)), ...
                   'movement not constant for trial...?');
            R(nt).startTrialParams.currentMovement = R(nt).currentMovement(min( ...
                find(R(nt).state==tc.STATE_MOVEMENT_TEXT)));
        end
        
        %% get the time of each trial phase
        R(nt).trialStart = min(find(R(nt).state == tc.STATE_MOVEMENT_TEXT));
        R(nt).goCue = min(find(R(nt).state == tc.STATE_GO_CUE));
        R(nt).holdCue = min(find(R(nt).state == tc.STATE_HOLD_CUE));
        R(nt).returnCue = min(find(R(nt).state == tc.STATE_RETURN_CUE));
        R(nt).restCue = min(find(R(nt).state == tc.STATE_REST_CUE));
        
        startInd = R(nt).clock(1);
        
        %% get pre and post-trial data
        R(nt).preTrial=[];
        R(nt).postTrial=[];
        for nf = 1:numel(streamFields)
            f=streamFields{nf};
            if isfield(R(nt),f)
                if nt>1
                    if size(R(nt-1).(f),2) >= preTrialKeep
                        R(nt).preTrial.(f) = R(nt-1).(f)(:,end-preTrialKeep+1:end);
                    else
                        R(nt).preTrial.(f) = [];
                    end
                end
                if nt<length(R)
                    if size(R(nt+1).(f),2) >= postTrialKeep
                        R(nt).postTrial.(f) = R(nt+1).(f)(:,1:postTrialKeep);
                    else
                        R(nt).postTrial.(f) = [];
                    end
                end
            end
        end
                
    end
    [R.taskConstants] = deal(tc);
    
    
