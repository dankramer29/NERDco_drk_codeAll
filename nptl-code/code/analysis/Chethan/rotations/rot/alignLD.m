function ostr=alignLD(ostr, setAlignOpts);

whichSamples = setAlignOpts.whichSamples;

setAlignOpts = setDefault(setAlignOpts,'factorsToUse',1);

allSessions = {ostr.blocks.session};
uSessions = unique(allSessions);

for nSession = 1:numel(uSessions)
    % fold all trials from the same block together
    sessBlocks = find(strcmp(allSessions,uSessions{nSession}));
    R = [ostr.blocks(sessBlocks).trials];
    if ~isfield(R,'xorth')
        tmp=[ostr.blocks(sessBlocks).ld];
        seqTrain = [tmp.trials];
        binWidth=ostr.blocks(sessBlocks(1)).ld.binWidth;
    end

    switch (ostr.blocks(1).taskName)
        case 'cursor'
            x=splitRByTarget(R);
            % get rid of out->in trials
            targets = [x.posTarget];
            x = x(any(targets));
            targsi = targets(1,:)+sqrt(-1)*targets(2,:);
            alltargets = unique(targsi);
        case 'movementCue'
            x = splitRByCondition(R,ostr.blocks(sessBlocks(1)).taskConstants);
    end

    numConditions = numel(x);

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
    for dir = 1:numConditions
        switch (ostr.blocks(1).taskName)
          case 'cursor'
            targi = x(dir).targeti;
            itarg = find(targi==alltargets);
            clabel = '';
          case 'movementCue'
            itarg = 2*(dir);
            clabel = x(dir).moveName(6:end);
        end
        allTraces = [];

        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+figOffset)
            ah=directogram2(itarg-1);
            title(clabel)
            figure(nf+1+figOffset)
            ah=directogram2(itarg-1);
            title(clabel)
        end

        %% pre-dejumbled figure
        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+figOffset)
            for nt = 1:numel(x(dir).R)
                %% see if xorth was calculated with the Rstruct originally
                if isfield(x(dir).R(nt),'xorth')
                    tr1 = x(dir).R(nt).xorth(nf,:);
                else
                    rind = x(dir).R(nt).trialId;
                    stind = [seqTrain.trialId] == rind;
                    tr1 = resample(seqTrain(stind).xorth(nf,:),binWidth,1);
                end
                allTraces(nf,nt,:) = tr1(setAlignOpts.allSamples);

                tr1 = tr1(setAlignOpts.whichSamples);
                tr1 = tr1 / (range(tr1) + setAlignOpts.rangeSoftNorm);

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
            elseif tshifts(nt)>maxShiftHigh*0.95
                isOutlier(nt) = true;
            end
        end
        fprintf('outliers: %g / %g\n', sum(isOutlier), numel(isOutlier));

        %% give the per-direction shifts zero-mean
        % disp(mean(tshifts(~isOutlier)))
        tshifts = tshifts - floor(mean(tshifts(~isOutlier)));

        %% assign neuralMoveOnset in the original ostr
        for nt = 1:numel(x(dir).R)
            assigned = false;
            for nn = 1:numel(sessBlocks)
                rind = x(dir).R(nt).trialId;
                oind = find([ostr.blocks(sessBlocks(nn)).trials.trialId] == rind);
                if ~isempty(oind)
                    assigned = true;
                    if ~isOutlier(nt)
                        ostr.blocks(sessBlocks(nn)).trials(oind).neuralMoveOnset = tshifts(nt)+1;
                    else
                        ostr.blocks(sessBlocks(nn)).trials(oind).neuralMoveOnset = [];
                    end
                end
            end
            if ~assigned
                error('alignLD: couldnt find trial');
            end
        end

        %% post-dejumbled figure
        allTraces2 = [];
        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+1+figOffset)
            for nt = 1:numel(x(dir).R)
                rind = x(dir).R(nt).trialId;
                if isfield(x(dir).R(nt),'xorth')
                    tr1 = x(dir).R(nt).xorth(nf,:);
                else
                    stind = [seqTrain.trialId] == rind;
                    tr1 = resample(seqTrain(stind).xorth(nf,:),binWidth,1);
                end
                tr1 = tr1(setAlignOpts.whichSamples+tshifts(nt) - floor(mean(tshifts)));
                tr1 = tr1 / (range(tr1) + setAlignOpts.rangeSoftNorm);
                allTraces2(nf,nt,:) = tr1;
            end
            keepTraces = squeeze(allTraces2(1,~isOutlier,:));
            keepTraces = keepTraces-repmat(mean(keepTraces,2)',[size(allTraces2,3) 1])';
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
end
