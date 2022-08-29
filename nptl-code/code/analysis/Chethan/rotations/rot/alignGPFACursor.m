function ostr=alignGpfaCursor(ostr, setAlignOpts, showPlot);

whichSamples = setAlignOpts.whichSamples;

assert(length(setdiff([R.trialNum],[seqTrain.trialId]))==0,'alignGPFACursor: some trials missing?');

x=splitRByTarget(R);
% get rid of out->in trials
targets = [x.posTarget];
x = x(any(targets));
numDirs = length(x);
targsi = targets(1,:)+sqrt(-1)*targets(2,:);
alltargets = unique(targsi);

R2 = [x.R];
strials = [R2.trialId];

useNewCode = true;
%useNewCode = false;

if useNewCode
    %% using cross-cor dejumbling to align trials
    binWidth=dt;

    figOffset=0;
    for nf = 1:setAlignOpts.factorsToUse
        figure(nf+figOffset)
        clf
        figure(nf+figOffset+1)
        clf
    end

    for dir = 1:numDirs
        targi = x(dir).targeti;
        itarg = find(targi==alltargets);
        allTraces = [];

        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+figOffset)
            ah=directogram(itarg-1);
            figure(nf+1+figOffset)
            ah=directogram(itarg-1);
        end

        %% pre-dejumbled figure
        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+figOffset)
            for nt = 1:numel(x(dir).R)
                ns = x(dir).R(nt).trialId;
                tr1 = resample(seqTrain(ns).xorth(nf,:),binWidth,1);
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
            elseif tshifts(nt)>maxShiftHigh*0.95
                isOutlier(nt) = true;
            end
        end

        %% give the per-direction shifts zero-mean
        % disp(mean(tshifts(~isOutlier)))
        tshifts = tshifts - floor(mean(tshifts(~isOutlier)));
        for nt = 1:numel(x(dir).R)
            R(x(dir).R(nt).trialId).neuralMoveOnset = tshifts(nt);
            R(x(dir).R(nt).trialId).isOutlier = isOutlier(nt);
        end

        %% post-dejumbled figure
        allTraces = [];
        for nf = 1:setAlignOpts.factorsToUse
            figure(nf+1+figOffset)
            for nt = 1:numel(x(dir).R)
                ns = x(dir).R(nt).trialId;
                tr1 = resample(seqTrain(ns).xorth(nf,:),binWidth,1);

                tr1 = tr1(setAlignOpts.whichSamples+tshifts(nt) - floor(mean(tshifts)));
                tr1 = tr1 / range(tr1);
                allTraces(nf,nt,:) = tr1;

                %% store down the data in seqtrain, for later export
                if ~isOutlier(nt)
                    seqTrain(ns).moveOnset = tshifts(nt)+setAlignOpts.whichSamples(1);
                else
                    seqTrain(ns).moveOnset = [];
                end
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
    pause(0.1);
else
%% OLD CODE - TO DELETE

%% GPFA is agnostic to sign (positive/negative), so the large change on 
%%  factor 1 could be an increase or decrease. Check all trials and see if factor 1
%%  increases or decreases. Flip if necessary.
totTrials = 0;
for it = 1:numel(strials);
    nt=strials(it);
    %% get the factor of interest (use orthonormalized factors)
    tr = seqTrain(nt).xorth(1,:);
    tr = (tr-min(tr(whichSamples))) / (max(tr(whichSamples))-min(tr(whichSamples)));
    totTrials = totTrials+1;
    tr = tr(whichSamples);
    half1 = mean(tr(1:4));
    if half1>0.5
        flipped(totTrials)=1;
    else
        flipped(totTrials)=0;
    end
end
flipAllTrials = false;
if mean(flipped)>0.5
    flipAllTrials = true;
    disp('flipping all trials');
end

alignPt = 0.7;

for nt = 1:numel(seqTrain)
    try
        %% get the factor of interest (use orthonormalized factors)
        tr = seqTrain(nt).xorth(1,:);
        tr = (tr-min(tr(whichSamples))) / (max(tr(whichSamples))-min(tr(whichSamples)));
        %% resample the trace (interpolate)
        tr = resample(tr,dt,1);
        %% get the indices in resampled-space
        resampledInds = 1+((whichSamples(1)-1)*dt:(whichSamples(end)-1)*dt);
        tr = tr(resampledInds);

        if flipAllTrials
            tr = 1-tr;
        end
        %% find the point where values cross threshold
        crosspt = min(find(tr>alignPoint));
        [~,minpt] = min(tr);
        if crosspt < minpt
            crosspt = nan;
            disp(sprintf('trial %g - alignment point before minimum', nt));
        end

        %% offset by whatever the first sample is
        crosspt = crosspt+(whichSamples(1)-1)*dt+1;
    catch
        disp('weird issue with trial, skipping');
        crosspt = nan;
    end
    
    seqTrain(nt).moveOnset = crosspt;
end    

%% get the trials for each direction
if showPlot 
    figure;
    clf; 
    for nd = 1:numDirs
        trials=[x(nd).R.trialNum];
        stdir = seqTrain(trials);
        for nt = 1:length(stdir)
            try
                %% get the factor of interest (use orthonormalized factors)
                tr = stdir(nt).xorth(1,:);
                tr = (tr-min(tr(whichSamples))) / (max(tr(whichSamples))-min(tr(whichSamples)));
                tr = resample(tr,dt,1);
                %% get the indices in resampled-space
                resampledInds = 1+((whichSamples(1)-1)*dt:(whichSamples(end)-1)*dt); 
               tr = tr(resampledInds);
                if flipAllTrials
                    tr = 1-tr;
                end
                
                if showPlot
                    crosspt = stdir(nt).moveOnset;
                    subplot(2,numDirs,nd);
                    plot(tr);
                    hold on
                    axis('tight');
                    subplot(2,numDirs,nd+numDirs);
                    numVals = length(tr);
                    plot((1:numVals)-crosspt,tr);
                    hold on;
                    axis('tight');
                end
            catch
                continue
            end
        end
    end
    pause(0.1);
    % disp('paused'); 
    %pause
end
end