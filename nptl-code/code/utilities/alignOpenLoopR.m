function [R] = alignOpenLoopR(R,useChannels,thresholds, blockNums, Toptions)

global modelConstants

faopts.blockNums = blockNums;
faopts.useChannels = useChannels;
faopts.thresholds = thresholds;

preTrialLength = 500;

%% scratch that - this should've already been done
% % run FA
%processed = runFAonRstruct(R, faopts);
%R = processed.R;
%seqTrain = processed.seqTrain;
%dt = processed.binWidth;

for nn = 1:numel(R)
    R(nn).trialId = nn;
end

% get the target locations (complex values)
targs = [R.posTarget];
targsi = targs(1,:)+sqrt(-1)*targs(2,:);
lasttargs = [R.lastPosTarget];
lasttargsi = lasttargs(1,:)+sqrt(-1)*lasttargs(2,:);

alltargets = unique(targsi);
alllasttargets = unique(lasttargsi);

dt = Toptions.dt;

Rspl=splitRByTarget(R);
%% further split the outwards->in targets
outIn = ~abs([Rspl.targeti]);
R3 = splitRByPreviousTarget([Rspl(outIn).R]);
[R3.posTarget] = deal([0;0]);
[R3.targeti] = deal([0]);
Rspl = Rspl(~outIn);

%% tack the outward-> trials onto the end of Rspl
for nel = 1:numel(R3)
    Rspl(end+1).targeti = R3(nel).targeti;
    Rspl(end).lasttargeti = R3(nel).lasttargeti;
    Rspl(end).posTarget = R3(nel).posTarget;
    Rspl(end).R = R3(nel).R;
end


whichSamples = Toptions.minRescaleTimeMS+1:Toptions.maxRescaleTimeMS;
whichSamplesInward = (Toptions.minRescaleTimeMS+1:Toptions.maxRescaleTimeMS) - Toptions.backToCenterShift;


% figure out how many samples there are
setAlignOpts.allSamples = 1:min(arrayfun(@(x) size(x.minAcausSpikeBand,2),R))-Toptions.dt;
switch modelConstants.rig
    case 't6'
        setAlignOpts.rangeSoftNorm = 0.5;
        setAlignOpts.factorsToUse = 1;
        setAlignOpts.maxShiftPerIter = 50;
        setAlignOpts.maxIter = 40;
    case 't7'
        setAlignOpts.rangeSoftNorm = 2.5;
        setAlignOpts.factorsToUse = 2;
        setAlignOpts.factorRescaleValues = [1 1];
        setAlignOpts.maxShiftPerIter = 20;
        setAlignOpts.maxIter = 40;
end

%% clear some figures
numFigs = 2*setAlignOpts.factorsToUse*2;
numFacts = setAlignOpts.factorsToUse;
for nf = 1:numFigs
    figure(nf);
    clf;
end

for ntarg = 1:numel(Rspl)
    %% get the index of this target
    targi = Rspl(ntarg).targeti;
    %% get time windows appropriate for center-out or outward-back
    if abs(targi)
        setAlignOpts.whichSamples = whichSamples;
    else
        setAlignOpts.whichSamples = whichSamplesInward;
    end

    %% add the preTrial offset
    setAlignOpts.whichSamples = setAlignOpts.whichSamples+preTrialLength;

    %% get the velocity profile for this set
    cursorPos = double(R(1).cursorPosition(:,setAlignOpts.allSamples));
    dcp = diff(cursorPos')';
    cursorVelSum = cumsum(dcp');
    cursorVel = centraldiff(cursorVelSum(1:dt:end,:))';
    cursorSpeed = sqrt(sum(cursorVel.^2));
    cursorSpeedMS = resample(cursorSpeed,dt,1);
    velocityPeak = maxind(cursorSpeedMS);
    Rinds = [Rspl(ntarg).R.trialId];
    [R(Rinds).velocityPeak] = deal(velocityPeak);


    %% now skip outwards->in targets
    if ~abs(targi)
        figOffset = 2;
        targi = Rspl(ntarg).lasttargeti;
        itarg = find(targi==alltargets);
    else
        figOffset = 0;
        itarg = find(targi==alltargets);
    end

    %% create an axis for this direction    
    for nf = 1:numFacts*2
        figure(nf+figOffset);
        ah=directogram(itarg-1);
    end

    allTraces = [];
    for nf = 1:setAlignOpts.factorsToUse
        figure(nf+figOffset)
        minlength = preTrialLength*2+min(arrayfun(@(x) size(x.minAcausSpikeBand,2), Rspl(ntarg).R));
        for nt = 1:numel(Rspl(ntarg).R)
            ns = Rspl(ntarg).R(nt).trialId;
            %tr1 = resample(seqTrain(ns).xorth(nf,:),dt,1);
            %allTraces(nf,nt,:) = tr1(setAlignOpts.allSamples);
            allSamples = [Rspl(ntarg).R(nt).preTrial.xorth(nf,:) Rspl(ntarg).R(nt).xorth(nf,:) Rspl(ntarg).R(nt).postTrial.xorth(nf,:)];
            tr1 = allSamples; %Rspl(ntarg).R(nt).xorth(setAlignOpts.allSamples);
            allTraces(nf,nt,:) = tr1(1:minlength);
            tr1 = tr1(setAlignOpts.whichSamples);
            tr1 = tr1 / (range(tr1) + setAlignOpts.rangeSoftNorm);
            plot(tr1-mean(tr1));
            hold on
        end
        axis('tight');
    end
    


    maxShiftLow = setAlignOpts.whichSamples(1)-setAlignOpts.maxShiftPerIter;
    maxShiftHigh = size(allTraces,3) - (setAlignOpts.whichSamples(end)+setAlignOpts.maxShiftPerIter);

    %setAlignOpts.showDebug = true;
    tshifts=alignTraceSets(allTraces,setAlignOpts);
    
    isOutlier = false(size(tshifts));
    %% mark outliers, and save the aligned time
    for nt = 1:numel(Rspl(ntarg).R)
        if tshifts(nt)<-(maxShiftLow * 0.95)
            isOutlier(nt) = true;
        elseif tshifts(nt)>maxShiftHigh*0.95
            isOutlier(nt) = true;
        end
    end

    % %% give the per-direction shifts zero-mean
    % % disp(mean(tshifts(~isOutlier)))
    % tshifts = tshifts - floor(mean(tshifts(~isOutlier)));
    for nt = 1:numel(Rspl(ntarg).R)
        R(Rspl(ntarg).R(nt).trialId).neuralMoveOnset = tshifts(nt);
        R(Rspl(ntarg).R(nt).trialId).isOutlier = isOutlier(nt);
    end

    for nf = 1:setAlignOpts.factorsToUse
        figure(nf+numFacts+figOffset)
        minlength = preTrialLength*2+min(arrayfun(@(x) size(x.minAcausSpikeBand,2), Rspl(ntarg).R));
        allTraces = [];
        for nt = 1:numel(Rspl(ntarg).R)
            ns = Rspl(ntarg).R(nt).trialId;
            %tr1= Rspl(ntarg).R(nt).xorth;
            allSamples = [Rspl(ntarg).R(nt).preTrial.xorth(nf,:) Rspl(ntarg).R(nt).xorth(nf,:) Rspl(ntarg).R(nt).postTrial.xorth(nf,:)];
            %tr1 = resample(seqTrain(ns).xorth(nf,:),dt,1);
            tr1 = allSamples(1:minlength);
            tr1 = tr1(setAlignOpts.whichSamples+tshifts(nt) - floor(mean(tshifts)));
            tr1 = tr1 / (range(tr1)+setAlignOpts.rangeSoftNorm);
            allTraces(nf,nt,:) = tr1;
        end
        keepTraces = squeeze(allTraces(nf,~isOutlier,:));
        keepTraces = keepTraces-repmat(mean(keepTraces'),[size(allTraces,3) 1])';
        if mean(keepTraces(:,1)) > 0
            keepTraces = -keepTraces;
        end
        plot(keepTraces','r')
        hold on;
        plot(mean(keepTraces) - mean(mean(keepTraces)),'k');
        axis('tight');
    end


    %% now we want to calculate the shift amount that will make the neural peak 
    %%  line up with velocity peak

    %% for each trace, the startPoint is setAlignOpts.whichSamples + tshifts(nt)
    %%  estimate the peak point from that as startPoint + maxind(mean(keepTraces))
    %neuralPeaks = setAlignOpts.whichSamples(1) - preTrialLength + tshifts + ...
    %    maxind(mean(keepTraces));
    if abs(targi)
        % outward trial
        neuralPeaks = velocityPeak + tshifts;
    else
        % inward trial
        neuralPeaks = velocityPeak + tshifts - Toptions.backToCenterShift;
    end

    % assign alignment info back to the original rstruct
    for nt = 1:numel(neuralPeaks)
        R(Rspl(ntarg).R(nt).trialId).neuralPeak = neuralPeaks(nt);
        R(Rspl(ntarg).R(nt).trialId).velocityPeak = velocityPeak;
    end

end

%% save the figures
for nf = 1:numFigs
    try
        figure(nf);
        figOutDir = fullfile(modelConstants.sessionRoot, modelConstants.analysisDir, 'FilterBuildFigs');
        saveas(gcf,fullfile(figOutDir,sprintf('FA-%s-%g.fig',blocksStr,nf)));
        print('-dpng',fullfile(figOutDir,sprintf('FA-%s-%g.png',blocksStr,nf)));
    catch
        disp('alignOpenLoopR - warning: problems saving figures. continuing...');
    end
    %close
end
