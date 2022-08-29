function [R sopts] = alignRstruct(R, sopts)

sopts.foo = false;
sopts=setDefault(sopts,'rangeSoftNorm', 0.1);
sopts=setDefault(sopts,'factorsToUse', 1);
sopts=setDefault(sopts,'factorRescaleValues', [1]);
sopts=setDefault(sopts,'prekeep',-200);
sopts=setDefault(sopts,'postkeep',300);
sopts=setDefault(sopts,'outwardOnly', true);
sopts=setDefault(sopts,'backtocentershift', 100, true);
sopts=setDefault(sopts,'maxShiftPerIter', 80);
sopts=setDefault(sopts,'maxIter', 40);
sopts=setDefault(sopts,'showDebug', false);
sopts=setDefault(sopts,'showBeforeAfter', true);
sopts=setDefault(sopts,'splitConditions', true, true);
sopts=setDefault(sopts,'ldField', 'xorth', true);

if sopts.showBeforeAfter
    BEFOREFIG = 10;
    AFTERFIG = 11;
    figure(BEFOREFIG); clf;
    figure(AFTERFIG); clf;
    xplotstart = -0;
    xplotend = 0;
end

preTrialLength = 500;

%% make sure every trial has a unique id
for nn = 1:numel(R)
    R(nn).trialId = nn;
end

%% limit to minimum trial length
minlength = min(arrayfun(@(x) size(x.(sopts.ldField),2), R));
whichSamplesOutward = (1-sopts.prekeep:minlength+sopts.postkeep)+preTrialLength;
sopts.whichSamplesOutward = whichSamplesOutward;
if ~sopts.outwardOnly
    whichSamplesInward = ((1-sopts.prekeep:minlength-sopts.postkeep)-sopts.backtocentershift)+preTrialLength;
    sopts.whichSamplesInward = whichSamplesInward;
end

allSamples = 1:minlength+1000;

%% split Rstruct by direction
Rspl = splitRByTrajectory(R);
if sopts.outwardOnly
    Rspl = Rspl(any([Rspl.posTarget]));
end

if ~sopts.splitConditions
    Rspl2 = Rspl;
    Rspl = struct;
    Rspl.R = vertcat(Rspl2.R);
    Rspl.posTarget = [1 1];
end

% prepare for plots
if sopts.showBeforeAfter
    numDirs = numel(Rspl);
    xplotrange = [preTrialLength+xplotstart-sopts.prekeep preTrialLength+xplotend+minlength+sopts.postkeep];
end

for nd = 1:numel(Rspl)
    numTrials = numel(Rspl(nd).R);
    numSamples = numel(allSamples);
    % initialize stuff
    Rspl(nd).tshifts = nan(numTrials,1);
    Rspl(nd).errors = nan(numTrials,1);
    if any(Rspl(nd).posTarget)
        %% outward direction
        sopts.whichSamples = whichSamplesOutward;
    else
        %% inward direction
        if sopts.outwardOnly
            continue
        else
            sopts.whichSamples = whichSamplesInward;
        end
    end

    sopts.excludeTrials = false(numTrials,1);
    allTraces = [];
    for nf = 1:sopts.factorsToUse
        allTraces(nf,:,:) = zeros(numTrials,numSamples);
        for nt = 1:numel(Rspl(nd).R)
            if isempty(Rspl(nd).R(nt).preTrial) || isempty(Rspl(nd).R(nt).postTrial)
                sopts.excludeTrials(nt) = true;
            else
                % combine the pretrial, trial, and posttrial data
                fulltrace = [Rspl(nd).R(nt).preTrial.(sopts.ldField)(nf,:) Rspl(nd).R(nt).(sopts.ldField)(nf,:) Rspl(nd).R(nt).postTrial.(sopts.ldField)(nf,:)];
                allTraces(nf,nt,:) = fulltrace(allSamples);
            end
        end
    end

    if sopts.showBeforeAfter
        figure(BEFOREFIG)
        if numDirs == 8
            ah=directogram2(nd);
        else
            ah = subplot(ceil(sqrt(numDirs)), ...
                         ceil(sqrt(numDirs)), nd);
        end
        for nt = 1:numel(Rspl(nd).R)
            if sopts.excludeTrials(nt), continue; end
            tr=squeeze(allTraces(1,nt,:))';
            tr = tr / (range(tr(sopts.whichSamplesOutward)) + sopts.rangeSoftNorm);
            tr = tr-mean(tr(sopts.whichSamplesOutward));
            plot(tr,'b');
            hold on;
        end
        %axis('tight');
        set(gca,'xlim',xplotrange);
        set(gca,'ylim',[-0.75 0.75]);
    end
    [Rspl(nd).tshifts Rspl(nd).errors]=alignTraceSets(allTraces,sopts);
    if sopts.showBeforeAfter
        figure(AFTERFIG)
        if numDirs == 8
            ah=directogram2(nd);
        else
            ah = subplot(ceil(sqrt(numDirs)), ...
                         ceil(sqrt(numDirs)), nd);
        end
        for nt = 1:numel(Rspl(nd).R)
            if sopts.excludeTrials(nt), continue; end
            tr=squeeze(allTraces(1,nt,:))';
            tr = tr / (range(tr(sopts.whichSamplesOutward + Rspl(nd).tshifts(nt))) + sopts.rangeSoftNorm);
            tr = tr-mean(tr(sopts.whichSamplesOutward + Rspl(nd).tshifts(nt)));
            plot(-Rspl(nd).tshifts(nt) + allSamples, tr,'r');
            hold on;
        end
        %axis('tight');
        set(gca,'xlim',xplotrange);
        set(gca,'ylim',[-0.75 0.75]);
        pause(0.1)
    end

end

rinds = [R.trialId];
for nd = 1:numel(Rspl)
    for nt = 1:numel(Rspl(nd).R)
        sind = Rspl(nd).R(nt).trialId;
        ri=find(rinds==sind);
        if isempty(ri), error('alignRstruct: couldnt find trial index in rstruct');
        end
        R(ri).tshift = Rspl(nd).tshifts(nt);
        R(ri).lowDErr = Rspl(nd).errors(nt);
    end
end

