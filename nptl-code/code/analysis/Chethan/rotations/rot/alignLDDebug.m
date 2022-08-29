function ostr=alignLD(ostr, setAlignOpts);

whichSamples = setAlignOpts.whichSamples;

allSessions = {ostr.blocks.session};
uSessions = unique(allSessions);

for nSession = 1:numel(uSessions)
    % fold all trials from the same block together
    sessBlocks = find(strcmp(allSessions,uSessions{nSession}));
    R = [ostr.blocks(sessBlocks).trials];
    tmp=[ostr.blocks(sessBlocks).ld];
    seqTrain = [tmp.trials];
    binWidth=ostr.blocks(sessBlocks(1)).ld.binWidth;

    switch (ostr.blocks(1).taskName)
        case 'cursor'
            x=splitRByTarget(R);
            % get rid of out->in trials
            targets = [x.posTarget];
            x = x(any(targets));
            numDirs = length(x);
            targsi = targets(1,:)+sqrt(-1)*targets(2,:);
            alltargets = unique(targsi);
        case 'movementCue'
            x = splitRByCondition(R,ostr.blocks(sessBlocks(1)).taskConstants);
    end

    R2 = [x.R];
    strials = [R2.trialId];

    %% using cross-cor dejumbling to align trials

    figOffset=0;
    for nf = 1:setAlignOpts.factorsToUse
        figure(nf+figOffset)
        clf
        figure(nf+figOffset+1)
        clf
    end

    %% iterate over all conditions
    for dir = 1:numDirs
        targi = x(dir).targeti;
        itarg = find(targi==alltargets);
        allTraces = [];

        %% first off, forget about trials that are e.g. 50% too long
        trialLengths = arrayfun(@(x) size(x.minAcausSpikeBand,2), x(dir).R);
        tooLong = find(trialLengths > mean(double(trialLengths))*1.5);
        setAlignOpts.excludeTrials = tooLong;

        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+figOffset)
            ah=directogram2(itarg-1);
            figure(nf+1+figOffset)
            ah=directogram2(itarg-1);
        end

        %% pre-dejumbled figure
        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+figOffset)
            for nt = 1:numel(x(dir).R)
                rind = x(dir).R(nt).trialId;
                stind = [seqTrain.trialId] == rind;
                tr1 = resample(seqTrain(stind).xorth(nf,:),binWidth,1);
                allTraces(nf,nt,:) = tr1(setAlignOpts.allSamples);

                tr1 = tr1(setAlignOpts.whichSamples);
                tr1 = tr1 / range(tr1);

                plot(tr1-mean(tr1));
                hold on
            end
            axis('tight');
        end
        maxShiftLow = setAlignOpts.whichSamples(1)-setAlignOpts.maxShiftPerIter;
        maxShiftHigh = size(allTraces,3) - (setAlignOpts.whichSamples(end)+setAlignOpts.maxShiftPerIter);

        tshifts=alignTraceSets(allTraces,setAlignOpts);

        isOutlier = false(size(tshifts));
        %% mark outliers, and save the aligned time
        for nt = 1:numel(x(dir).R)
            if tshifts(nt)<-(maxShiftLow * 0.95)
                isOutlier(nt) = true;
                %fprintf('trial %g: outlier\n',nt);
            elseif tshifts(nt)>maxShiftHigh*0.95
                isOutlier(nt) = true;
                %fprintf('trial %g: outlier\n',nt);
            end
        end

        fprintf('outliers: %g / %g\n', sum(isOutlier), numel(isOutlier));

        %% give the per-direction shifts zero-mean
        % disp(mean(tshifts(~isOutlier)))
        tshifts = tshifts - floor(mean(tshifts(~isOutlier)));
        %% assign moveOnset in the original ostr
        for nt = 1:numel(x(dir).R)
            assigned = false;
            for nn = 1:numel(sessBlocks)
                rind = x(dir).R(nt).trialId;
                oind = find([ostr.blocks(sessBlocks(nn)).trials.trialId] == rind);
                if ~isempty(oind)
                    assigned = true;
                    if ~isOutlier(nt)
                        ostr.blocks(sessBlocks(nn)).trials(oind).moveOnset = tshifts(nt)+1;
                    else
                        ostr.blocks(sessBlocks(nn)).trials(oind).moveOnset = [];
                    end
                end
            end
            if ~assigned
                error('alignLD: couldnt find trial');
            end
        end

        %% post-dejumbled figure
        allTraces = [];
        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+1+figOffset)
            for nt = 1:numel(x(dir).R)
                rind = x(dir).R(nt).trialId;
                stind = [seqTrain.trialId] == rind;
                tr1 = resample(seqTrain(stind).xorth(nf,:),binWidth,1);

                tr1 = tr1(setAlignOpts.whichSamples+tshifts(nt) - floor(mean(tshifts)));
                tr1 = tr1 / range(tr1);
                allTraces(nf,nt,:) = tr1;
            end
            keepTraces = squeeze(allTraces(1,~isOutlier,:));
            keepTraces = keepTraces-repmat(mean(keepTraces'),[size(allTraces,3) 1])';
            if mean(keepTraces(:,1)) > 0
                keepTraces = -keepTraces;
            end
            plot(keepTraces','r')
            hold on;
            plot(mean(keepTraces) - mean(mean(keepTraces)),'k');
            axis('tight');
        end

    end
    pause(0.01);
end