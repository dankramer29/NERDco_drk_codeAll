function Rout = trialAvgRmov(Rmov, options)
% TRIALAVGRMOV    
% 
% Rout = trialAvgRmov(Rmov)

    options.foo = false;


    allR = vertcat(Rmov.R);
    if isfield(allR,'goCue')
        minDelay = min([allR.goCue]);
    end

    cueOnsetDelay=0;
    if isfield(options,'preKeep')
        preKeep = options.preKeep;
    else
        preKeep = 0;
    end
    if isfield(options,'preMoveOnset')
        preMoveOnset = options.preMoveOnset;
    else
        preMoveOnset = 300;
    end
    if isfield(options,'postMoveOnset')
        postMoveOnset = options.postMoveOnset;
    else
        postMoveOnset = 1200;
    end
    if isfield(options,'useHLFP')
        useHLFP = options.useHLFP;
    else
        useHLFP = true;
    end
    %postMoveOnset = 4000;

    moveToKeep = preMoveOnset+postMoveOnset;

    %% iterate over all movements
    for nm = 1:length(Rmov)
        %% iterate over all trials
        numTrials = length(Rmov(nm).R);
        clear SBdelay HLFPdelay SBmove HLFPmove
        trialsKept = 0;
        for nt = 1:numTrials

            %% if the data has been aligned, but no moveOnset was found for this trial, skip this trial            
            if isfield(Rmov(nm).R(nt),'moveOnset') & isempty(Rmov(nm).R(nt).moveOnset)
                disp(sprintf('trialAvgRmov: moveOnset is empty. skipping move%g trial%g',nm,nt));
                continue;
            end

            if isfield(allR,'goCue')
                if isfield(Rmov(nm).R(nt),'moveOnset') & Rmov(nm).R(nt).moveOnset < Rmov(nm).R(nt).goCue
                    disp(sprintf('trialAvgRmov: moveOnset is before goCue. skipping move%g trial%g',nm,nt));
                    continue;
                end
            end

            if isfield(Rmov(nm).R(nt),'moveOnset')
                moveStart = Rmov(nm).R(nt).moveOnset-preMoveOnset;
                moveEnd = Rmov(nm).R(nt).moveOnset+postMoveOnset;
            elseif ~isfield(Rmov(nm).R(nt),'moveOnset')
                moveStart = Rmov(nm).R(nt).goCue-preMoveOnset;
                moveEnd = Rmov(nm).R(nt).goCue+postMoveOnset;
            end

            if moveStart <1
                disp(sprintf('skipping move%g trial%g - negative movement start time',nm,nt));
                continue;
            end

            if isfield(allR,'goCue')
                %% split into delay and aligned-move
                delayStart = Rmov(nm).R(nt).trialStart+cueOnsetDelay;
                delayEnd = minDelay;
            end


            if moveEnd < size(Rmov(nm).R(nt).SBsmoothed,2)
                if ~exist('SBdelay','var')
                    if isfield(allR,'goCue')
                        SBdelay = zeros(size(Rmov(nm).R(nt).SBsmoothed,1),numel(delayStart:delayEnd));
                        if useHLFP
                            HLFPdelay = zeros(size(Rmov(nm).R(nt).HLFPsmoothed,1),numel(delayStart:delayEnd));
                        end
                    end
                end
                if ~exist('SBmove','var')
                    SBmove = zeros(size(Rmov(nm).R(nt).SBsmoothed,1),numel(moveStart:moveEnd));
                    if useHLFP
                        HLFPmove = zeros(size(Rmov(nm).R(nt).HLFPsmoothed,1),numel(moveStart:moveEnd));
                    end
                end

                if isfield(allR,'goCue')
                    SBdelay = SBdelay+ Rmov(nm).R(nt).SBsmoothed(:,delayStart:delayEnd);
                    if useHLFP
                        HLFPdelay = HLFPdelay+ Rmov(nm).R(nt).HLFPsmoothed(:,delayStart:delayEnd).^2;
                    end
                end
                
                SBmove = SBmove+ Rmov(nm).R(nt).SBsmoothed(:,moveStart:moveEnd);
                if useHLFP
                    HLFPmove = HLFPmove+ Rmov(nm).R(nt).HLFPsmoothed(:,moveStart:moveEnd).^2;
                end
                trialsKept = trialsKept+1;

                %% keep the individual trial data
                for nc = 1:size(SBmove,1)
                    Rout(nm).channel(nc).trials(trialsKept,:) = Rmov(nm).R(nt).SBsmoothed(nc,moveStart:moveEnd);
                end
                if useHLFP
                    for nc = 1:size(SBmove,1)
                        Rout(nm).channel(nc).trialsHLFP(trialsKept,:) = Rmov(nm).R(nt).HLFPsmoothed(nc,moveStart:moveEnd);
                    end
                end
                %% keep individual delay trials too
                if isfield(allR,'goCue')
                    for nc = 1:size(SBdelay,1)
                        Rout(nm).channel(nc).trialsDelay(trialsKept,:) = Rmov(nm).R(nt).SBsmoothed(nc,delayStart:delayEnd);
                    end
                    if useHLFP
                        for nc = 1:size(SBdelay,1)
                            Rout(nm).channel(nc).trialsHLFPDelay(trialsKept,:) = Rmov(nm).R(nt).HLFPsmoothed(nc,delayStart:delayEnd);
                        end
                    end
                end

                if isfield(Rmov(nm).R,'velmag')
                    Rout(nm).velmag(trialsKept,:) = Rmov(nm).R(nt).velmag(moveStart:moveEnd);
                end
                if isfield(Rmov(nm).R,'neuralmag')
                    Rout(nm).neuralmag(trialsKept,:) = Rmov(nm).R(nt).neuralmag(moveStart:moveEnd);
                end
                if isfield(Rmov(nm).R,'sensor')
                    Rout(nm).sensor(trialsKept,:) = Rmov(nm).R(nt).sensor(moveStart:moveEnd);
                end
            end
        end
        Rout(nm).SBmove = SBmove/trialsKept;
        if useHLFP
            Rout(nm).HLFPmove = HLFPmove/trialsKept;
        end

        if isfield(allR,'goCue')
            Rout(nm).SBdelay = SBdelay/trialsKept;
            if useHLFP
                Rout(nm).HLFPdelay = HLFPdelay/trialsKept;
            end
        end
    end


