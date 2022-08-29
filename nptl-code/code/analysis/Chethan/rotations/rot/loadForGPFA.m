function [rotclass] = loadForGPFA(sessions, opts)
% LOADFORGPFA    
% 
% [rotclass] = loadForGPFA(sessions, opts)
% sessions needs to contain 'date','blocks'

rotclass = rotRaw;

R=[];

opts = setDefault(opts,'velSmoothingWindow',50,false);

niceFieldsToHave = {'speedTarget','xorth'};

%% assume participant is first 2 letters of session name
pid = sessions(1).date(1:2);

rotclass.participant = pid;

ind = 0;
for ns = 1:length(sessions)
    opts1 = opts;
    if isfield(sessions(ns),'thresholds') & ~isempty(sessions(ns).thresholds)
        opts1.thresh = sessions(ns).thresholds;
    end
    disp(sessions(ns).date);
    if ~isfield(opts,'faopts')
        for nb = 1:length(sessions(ns).blocks)
            disp(sessions(ns).blocks(nb));
            tic;
            [Rs{nb} thresh] = loadAndSmoothR(...
                pid, sessions(ns).date, sessions(ns).blocks(nb), opts1);
            toc;
        end
    else
        [Rs thresh] = loadSmoothRWithFA(pid,sessions(ns).date,sessions(ns).blocks,opts1);
    end

    for nb = 1:length(sessions(ns).blocks)
        R1 = Rs{nb};

        %% s3 structs have special needs
        switch lower(pid)
          case 's3'
            R1 = s3PreprocessR(R1);
          otherwise
            %% different pre-processing depending on task type
            switch R1(1).taskDetails.taskName
              case 'movementCue'
                R1 = swimPreprocessR(R1);
              case 'cursor'
                if ~isfield(R1,'posTarget')
                    keyboard
                    for nt = 1:numel(R1)-1
                        R1(nt).posTarget = R1(nt+1).startTrialParams.currentTarget;
                    end
                    R1 = R1(1:end-1);
                end
            end
        end

        ind = ind+1;
        rotclass.blocks(ind).session = sessions(ns).date;
        rotclass.blocks(ind).blockNum = sessions(ns).blocks(nb);

        % save down channels if they were passed in
        if isfield(sessions(ns), 'channels')
            rotclass.blocks(ind).channels = sessions(ns).channels;
        end

        rotclass.blocks(ind).thresholds = thresh;
        rotclass.blocks(ind).gaussSD = opts.gaussSD;
        rotclass.blocks(ind).halfGauss = opts.useHalfGauss;

        rotclass.blocks(ind).taskName = R1(1).taskDetails.taskName;
        switch R1(1).taskDetails.taskName
            case 'movementCue'
                rotclass.blocks(ind).taskConstants = R1(1).taskConstants;
        end

        for nt = 1:length(R1)
            %% if no trialNum, make one up
            if ~isfield(R1,'trialNum')
                R1(nt).trialNum = nt;
            end

            rotclass.blocks(ind).trials(nt).trialNum = R1(nt).trialNum;
            if isfield(R1,'minAcausSpikeBand')
                rotclass.blocks(ind).trials(nt).minAcausSpikeBand = R1(nt).minAcausSpikeBand;
            end
            rotclass.blocks(ind).trials(nt).SBsmoothed = R1(nt).SBsmoothed;
            if isfield(R1(nt),'lfp');
                rotclass.blocks(ind).trials(nt).lfp = R1(nt).lfp;
            end

            %% different processing depending on task type
            switch R1(1).taskDetails.taskName
              case 'movementCue'
                % save timing variables...
                rotclass.blocks(ind).trials(nt).trialStart = R1(nt).trialStart;
                rotclass.blocks(ind).trials(nt).goCue = R1(nt).goCue;
                rotclass.blocks(ind).trials(nt).holdCue = R1(nt).holdCue;
                rotclass.blocks(ind).trials(nt).returnCue = R1(nt).returnCue;
                rotclass.blocks(ind).trials(nt).restCue = R1(nt).restCue;
                % save movement type
                rotclass.blocks(ind).trials(nt).startTrialParams.currentMovement = ...
                    R1(nt).startTrialParams.currentMovement;
                rotclass.blocks(ind).trials(nt).startTrialParams.currentMovement = R1(nt).startTrialParams.currentMovement;
              case 'cursor'
                % save target info...
                rotclass.blocks(ind).trials(nt).posTarget = R1(nt).posTarget;
                rotclass.blocks(ind).trials(nt).lastPosTarget = R1(nt).lastPosTarget;
                rotclass.blocks(ind).trials(nt).cursorPosition = R1(nt).cursorPosition;
                xtrace = rotclass.blocks(ind).trials(nt).cursorPosition(1,:);
                ytrace = rotclass.blocks(ind).trials(nt).cursorPosition(2,:);
                rotclass.blocks(ind).trials(nt).cursorVelocity(1,:) = smooth(diff(xtrace),opts.velSmoothingWindow,'loess');
                rotclass.blocks(ind).trials(nt).cursorVelocity(2,:) = smooth(diff(ytrace),opts.velSmoothingWindow,'loess');

                %% log the time of "State_Move" (for trials with delay period)
                rotclass.blocks(ind).trials(nt).stateMove = ...
                    find(R1(nt).state==CursorStates.STATE_MOVE,1);
            end
            %% get all the other fields we might want
            for nf = 1:numel(niceFieldsToHave)
                ftmp=niceFieldsToHave{nf};
                if isfield(R1,ftmp)
                    rotclass.blocks(ind).trials(nt).(ftmp) = R1(nt).(ftmp);
                end
            end

        end
    end
end


allSessions = {rotclass.blocks.session};
uSessions = unique(allSessions);
for nSession = 1:numel(uSessions)
    sessBlocks = find(strcmp(allSessions,uSessions{nSession}));

    trialId = 0;
    for ib = 1:length(sessBlocks)
        nb = sessBlocks(ib);
        for nt = 1:length(rotclass.blocks(nb).trials)
            trialId = trialId+1;
            rotclass.blocks(nb).trials(nt).trialId = trialId;
        end
    end
end
