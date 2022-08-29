function rota = conditionAverage(rotr,opts)

opts.foo = false;

opts = setDefault(opts,'alignmentType','neural');

if ~isfield(opts,'window')
    disp('conditionAverage: no window around moveOnset specified. will try to construct from -preMove:postMove');

    if ~isfield(opts,'preMove')
        error('conditionAverage: must specify preMove length');
    end

    if ~isfield(opts,'postMove')
        error('conditionAverage: must specify postMove length');
    end

    window = -preMove:postMove;
else
    window = opts.window;
end

if ~isfield(opts,'channels')
    %    error('conditionAverage: must specify channels');
    channels = [];
else
    channels = opts.channels;
end

allSessions = {rotr.blocks.session};
uSessions = unique(allSessions);

for nSession = 1:numel(uSessions)
    sessBlocks = find(strcmp(allSessions,uSessions{nSession}));
    sessBlock = [rotr.blocks(sessBlocks).trials];
    ld1 = [rotr.blocks(sessBlocks).ld];
    lds = [ld1.trials];
    ldDts = [ld1.binWidth];
    if any(ldDts ~= ldDts(1))
        error('conditionAverage - different low dimensional bin widths');
    end
    ldDt = ldDts(1);
    
    switch (rotr.blocks(1).taskName)
        case 'cursor'
          sessSplit = splitRByTarget(sessBlock);
          % center-out only
          targets = [sessSplit.posTarget];
          sessSplit = sessSplit(any(targets));
        case 'movementCue'
          sessSplit = splitRByCondition(sessBlock,...
                                        rotr.blocks(sessBlocks(1)).taskConstants);
    end

    rota.blocks(nSession).session = uSessions{nSession};
    rota.blocks(nSession).blockNum = [rotr.blocks(sessBlocks).blockNum];
    rota.blocks(nSession).thresholds = rotr.blocks(sessBlocks(1)).thresholds;
    rota.blocks(nSession).halfGauss = rotr.blocks(sessBlocks(1)).halfGauss;
    rota.blocks(nSession).gaussSD = rotr.blocks(sessBlocks(1)).gaussSD;
    if isempty(channels)
        useChannels = rotr.blocks(nSession).channels;
    else
        useChannels = channels;
    end
    rota.blocks(nSession).channels = useChannels;
    numSkipped = 0;
    lastSkipped = 0;

    for nd = 1:length(sessSplit)
        switch (rotr.blocks(1).taskName)
          case 'cursor'
            rota.blocks(nSession).conditions(nd).posTarget = sessSplit(nd).posTarget;
            rota.blocks(nSession).conditions(nd).targeti = sessSplit(nd).targeti;
          case 'movementCue'
            rota.blocks(nSession).conditions(nd).moveName = sessSplit(nd).moveName;
            rota.blocks(nSession).conditions(nd).moveId = sessSplit(nd).moveId;
        end
        keepTrials = 0;
        allTrials = struct;
        posx = [];
        posy = [];
        speeds = [];
        for nt = 1:length(sessSplit(nd).R)
            switch opts.alignmentType
              case 'neural'
                moveOnset = sessSplit(nd).R(nt).neuralMoveOnset;
              case 'motor'
                moveOnset = sessSplit(nd).R(nt).motorMoveOnset;
              case {[],'none'}
                moveOnset = 1;
            end
            thisSkip = 0;

            % check the various reasons to skip this trial
            if isempty (moveOnset)
                skipstr = 'skipping trial - empty moveOnset - %03i skipped';
                thisSkip = 1;
            else 
                keepInds = moveOnset+(window);
                if any(keepInds<1)
                    skipstr = 'skipping trial - negative times - %03i skipped';
                    thisSkip = 2;
                end
                if any(keepInds>size(sessSplit(nd).R(nt).SBsmoothed,2))
                    skipstr = 'skipping trial - too large times - %03i skipped';
                    thisSkip = 3;
                end                
            end
            if thisSkip
                if lastSkipped == thisSkip
                    %erase the last output line
                    fprintf('%s',char(8) * ones(1,numel(skipstr)));
                else
                    fprintf('\n');
                    numSkipped = 0;
                end
                numSkipped = numSkipped+1;
                fprintf(skipstr,numSkipped);
                lastSkipped = thisSkip;
                continue; 
            end

            keepTrials = keepTrials+1;
            for ic = 1:numel(useChannels)
                nc = useChannels(ic);
                allTrials(nc).keep(keepTrials,:) = ...
                    sessSplit(nd).R(nt).SBsmoothed(nc,keepInds);
            end

            switch (rotr.blocks(1).taskName)
              case 'cursor'
                xtrace = sessSplit(nd).R(nt).cursorPosition(1,keepInds);
                ytrace = sessSplit(nd).R(nt).cursorPosition(2,keepInds);
                posx(keepTrials,:) = xtrace;
                posy(keepTrials,:) = ytrace;
                
                %xvelms1 = smooth(1:numel(xtrace)-1,diff(xtrace),0.1,'loess');
                %yvelms1 = smooth(1:numel(ytrace)-1,diff(ytrace),0.1,'loess');
                xvelms1 = sessSplit(nd).R(nt).cursorVelocity(1,keepInds);
                yvelms1 = sessSplit(nd).R(nt).cursorVelocity(2,keepInds);
            
                xvelms(keepTrials,:) = xvelms1;
                yvelms(keepTrials,:) = yvelms1;
                %speeds(keepTrials,:) = speedms;
              case 'movementCue'
                %% any data that needs averaging/saving down? (i.e. movt?)
            end
            %% get any low-D info available
            ldind = find(sessSplit(nd).R(nt).trialId == [lds.trialId]);
            if isempty(ldind)
                error('conditionAverage: cant find this trial in the low-dimensional data');
            end
            xorth1 = resample(lds(ldind).xorth(1,:),ldDt,1);
            xorths(keepTrials,:) = xorth1(keepInds);
        end
     for ic = 1:numel(useChannels)
            nc = useChannels(ic);
            rota.blocks(nSession).conditions(nd).Data(ic,:) = mean(allTrials(nc).keep,1);
        end
        switch (rotr.blocks(1).taskName)
          case 'cursor'
            rota.blocks(nSession).conditions(nd).cursorPosition(1,:) = mean(posx,1);
            rota.blocks(nSession).conditions(nd).cursorPosition(2,:) = mean(posy,1);
            rota.blocks(nSession).conditions(nd).cursorVel(1,:) = mean(xvelms,1);
            rota.blocks(nSession).conditions(nd).cursorVel(2,:) = mean(yvelms,1);
            rota.blocks(nSession).conditions(nd).speed(1,:) = ...
                sqrt(sum(rota.blocks(nSession).conditions(nd).cursorVel.^2));
          case 'movementCue'
            %% any data that needs averaging/saving down? (i.e. movt?)
        end
        rota.blocks(nSession).conditions(nd).times = window;
        rota.blocks(nSession).conditions(nd).xorth = mean(xorths,1);
    end
end