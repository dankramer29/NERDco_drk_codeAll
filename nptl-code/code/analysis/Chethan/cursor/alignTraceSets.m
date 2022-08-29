function [tshifts, err] = alignTraceSets(traceSets,opts)
%% iterative trial alignment process    
%% important options:
%% opts.maxIter

    opts.foo = false;

    if ~isfield(opts,'whichSamples')
        error('alignTraceSets: opts.whichSamples must be defined');
    end
    whichSamples = opts.whichSamples;

    if isfield(opts,'maxIter')
        maxIter = opts.maxIter;
    else
        maxIter = 30;
        fprintf('alignTraceSets: defaulting to %g iterations\n', maxIter);
    end

    if isfield(opts,'maxShiftPerIter')
        maxShiftPerIter = opts.maxShiftPerIter;
    else
        maxShiftPerIter = 40;
        fprintf('alignTraceSets: defaulting to max %g timestep shifts per iteration\n',maxShiftPerIter);
    end

    if isfield(opts,'excludeTrials')
        excludeTrials = opts.excludeTrials;
    else
        excludeTrials = [];
    end

    if isfield(opts,'factorsToUse')
        numFacts = opts.factorsToUse;
    else
        numFacts = size(traceSets,1);
        fprintf('alignTraceSets: using all %g factors passed in\n',numFacts);
    end

    if isfield(opts,'factorRescaleValues')
        factorRescaleValues = opts.factorRescaleValues;
    else
        factorRescaleValues = 1:numFacts;
        fprintf('alignTraceSets: using default rescale values\n');
    end

    if isfield(opts,'rangeSoftNorm')
        rangeSoftNorm = opts.rangeSoftNorm;
    else
        rangeSoftNorm = 0;
        fprintf('alignTraceSets: using default rangeSoftNorm: %g\n',rangeSoftNorm);
    end

    opts = setDefault(opts,'showDebug',false,true);
    showDebug = opts.showDebug;


    numTrials = size(traceSets,2);
    numTimepoints = size(traceSets,3);
    isOutlier = false(numTrials,1);

    numIter = 0;
    tshifts = zeros(numTrials,1);
    while numIter < maxIter
        numIter = numIter + 1;

        %% step 1: calculate the current means
        for nf = 1:numFacts
            trs{nf} = [];
            keepTrials = 0;
            for nt = 1:numTrials
                if ismember(nt, excludeTrials)
                    continue
                end
                keepTrials = keepTrials+1;
                %% preprocess - rescale by the range of each trace
                trRanges(nf,nt) = rangeSoftNorm + ...
                    range(squeeze(traceSets(nf,nt,whichSamples+tshifts(nt)))');
                rescaledTrace = squeeze(...
                    traceSets(nf,nt,whichSamples+tshifts(nt))) /...
                    trRanges(nf,nt);
                trRescaled(keepTrials,:) = rescaledTrace - mean(rescaledTrace);
            end
            %% take means
            %means(nf,:) = mean(squeeze(traceSets(nf,:,:)));
            means(nf,:) = mean(trRescaled,1);
            trs{nf} = trRescaled;
        end
        

        if showDebug
            for nf = 1:numFacts
                figure(3+nf-1); clf;
                plot(trs{nf}');
            end
            pause(0.1);
        end

        %% step2: iterate over samples, find optimal shift
        for nt = 1:numTrials
            if ismember(nt, excludeTrials)
                continue
            end
            tsToGet = tshifts(nt) + (whichSamples(1)-maxShiftPerIter:whichSamples(end)+maxShiftPerIter);

            %% get the cross corr
            for nf = 1:numFacts
                thisTrial(nf,:) = squeeze(traceSets(nf,nt,:))/trRanges(nf,nt);
                x(nf,:) = xcorr(thisTrial(nf,tsToGet),means(nf,:),maxShiftPerIter);
                x(nf,:) = x(nf,:) / factorRescaleValues(nf);
            end
            x = mean(x,1);
            
            [~,tind] = max(x);
            tshifts(nt) = (tind-maxShiftPerIter-1) + tshifts(nt);

        end
        %% now make the shifts zero-mean
        tshifts = tshifts - floor(mean(tshifts));



        %% make sure no trial goes out of bounds
        outliersLow = tshifts+whichSamples(1)-maxShiftPerIter<1;
        tshifts(outliersLow) = maxShiftPerIter-whichSamples(1)+1;
        outliersHigh = tshifts+whichSamples(end)+maxShiftPerIter>numTimepoints;
        tshifts(outliersHigh) = numTimepoints - ...
            maxShiftPerIter - whichSamples(end);
        isOutlier = outliersLow | outliersHigh;

        if nargout > 1
            %% calculate the error (single trial v. mean/template)
            if showDebug
                figure(20);clf;
            end
            for nt = 1:numTrials
                tsToGet = tshifts(nt) + (whichSamples(1):whichSamples(end));
                for nf = 1:numFacts
                    m=means(nf,:);
                    m = m-mean(m);
                    thisTrial(nf,:) = squeeze(traceSets(nf,nt,:))/trRanges(nf,nt);
                    tr = thisTrial(nf,tsToGet);
                    tr = tr-mean(tr);
                    errors(nf,nt) = sum((m-tr).^2) / factorRescaleValues(nf);
                    if showDebug
                        plot(m,'k');
                        hold on;
                        plot(tr);
                    end
                end
            end
            err = sum(errors,1);
        end

    end