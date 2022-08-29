function binnedR_All = aggregateC4_R(binnedRs, moveBins) 
% INPUT: binned R struct that is an array of structs. So like multi-block R struct
% INPUT: moveBins = how many bins post moveOnset to average over to
% calculate target. This is typically low for head movement (3-5) and
% higher for BCI (10 ish) 
% OUTPUT: binned R struct that has all blocks concatenated and contains
% trial-specific indices
% OUTPUT: some PSTHes. 
psthPre = 75; %bins after
psthPost = 75; %bins before
numTargs = 4; 
%% find the transitions to align "movement onset" to
binnedR_All.rawSpikes = [];
binnedR_All.state = [];
binnedR_All.effPosX = [];
binnedR_All.effPosY = [];
binnedR_All.zSpikes = [];
binnedR_All.meanSSpikes = [];
binnedR_All.calcSpeed = [];
binnedR_All.contTarg = [];
for i = 1:length(binnedRs)
    binnedR_All.rawSpikes = [binnedR_All.rawSpikes; binnedRs(i).rawSpikes];
    binnedR_All.zSpikes = [binnedR_All.zSpikes; binnedRs(i).zScoreSpikes];
    binnedR_All.meanSSpikes = [binnedR_All.meanSSpikes; binnedRs(i).meanSubtractSpikes];
    binnedR_All.state = [binnedR_All.state; binnedRs(i).state]; 
    binnedR_All.effPosX = [binnedR_All.effPosX; binnedRs(i).cursorPosition(:,1)]; 
    binnedR_All.effPosY = [binnedR_All.effPosY; binnedRs(i).cursorPosition(:,2)];
    binnedR_All.calcSpeed = [binnedR_All.calcSpeed; binnedRs(i).rigidBodyPosXYZ_speed];
    temp = nan(size(binnedRs(i).currentTarget,1),1);
    for j = 1:size(binnedRs(i).currentTarget,1)
        if binnedRs(i).currentTarget(j, 1) > 100 %right targ = "3"
            temp(j) = 3;
        elseif binnedRs(i).currentTarget(j, 2) > 100 %up targ = "1"
            temp(j) = 1;
        elseif binnedRs(i).currentTarget(j, 2) < -100 %down targ = '2'
            temp(j) = 2;
        elseif binnedRs(i).currentTarget(j, 1) < -100 %left targ = "4"
            temp(j) = 4;
        else %otherwise, center targ
           temp(j) = 5;
        end
    end
    binnedR_All.contTarg = [binnedR_All.contTarg; temp]; 
end
%% 
trialStartIdx = find(abs(diff(binnedR_All.contTarg)) );
numTrials = length(trialStartIdx);
moveOnset = nan(numTrials,1);
stimOnset = nan(numTrials,1);
tgt = nan(numTrials,1); 
trialCount = 0;
for i = 1:numTrials
    %based on state change
    trialCount = trialCount + 1;
    if i < numTrials-1
        moveStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+1)) > 2, 1, 'first');
       % stimStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+2)) == 17, 1, 'first');
        if ~isempty(moveStart)
            moveOnset(trialCount) = trialStartIdx(i) + moveStart;
            tgt(trialCount) = binnedR_All.contTarg(moveOnset(trialCount));
        else
            moveOnset(trialCount) = nan;
            tgt(trialCount) = nan;
            %   trialCount = trialCount - 1; %overwrite this on the next iteration
        end
%         if ~isempty(stimStart)
%             stimOnset(trialCount) = trialStartIdx(i) + stimStart;
%         else
%             stimOnset(trialCount) = nan;
%         end
    else
        moveStart = find(binnedR_All.state(trialStartIdx(i):end) == 17, 1, 'last');
       % stimStart = find(binnedR_All.state(trialStartIdx(i):end) == 17, 1, 'first');
        if ~isempty(moveStart) 
            moveOnset(trialCount) = trialStartIdx(i) + moveStart;
            tgt(trialCount) = binnedR_All.contTarg(moveOnset(trialCount));
        else
            moveOnset(trialCount) = nan;
            tgt(trialCount) = nan;
        end
        
    end
end

binnedR_All.speedMO = zeros(1,trialCount); 
binnedR_All.speedRT = zeros(1,trialCount); 
for trial = 1:length(moveOnset) %find(~isnan(unsignedCoh)) %1:length(moveOnset)
    if ~isnan(moveOnset(trial))
        binnedR_All.speedMO(trial) = moveOnset(trial) + find(binnedR_All.calcSpeed(moveOnset(trial) - 20:moveOnset(trial)+20)  >= (0.05*max(binnedR_All.calcSpeed(moveOnset(trial) - 20:moveOnset(trial)+20))), 1, 'first') ; 
        binnedR_All.speedRT(trial) = binnedR_All.speedMO(trial) - stimOnset(trial); %stim onset is a state change, MO is calculated
    end
end
%% PSTH-it
% assign and split by target
psth = zeros(size(binnedR_All.rawSpikes,2), length(unique(tgt)), length([(-1*psthPre):psthPost]));
%tgt = binnedR_All.tgt; 
for trial = 1:length(binnedR_All.speedMO)
   % count(tgt(trial), UCohIdx == unsignedCoh(trial)) = count(tgt(trial), UCohIdx == unsignedCoh(trial))+1;
   if binnedR_All.speedMO(trial) 
   for unit = 1:192
        psth(unit, tgt(trial),  :) = squeeze(psth(unit, tgt(trial),  :)) + ...
            (binnedR_All.zSpikes(binnedR_All.speedMO(trial)-psthPre:binnedR_All.speedMO(trial)+psthPost, unit))*50; %make it in Hz, make it an average
   end
   end
end

%% make the outputs
binnedR_All.psth = psth; 
binnedR_All.psthBefore = psthPre; 
binnedR_All.psthAfter = psthPost; 
binnedR_All.moveOnset = moveOnset;
binnedR_All.stimOnset = stimOnset; 
binnedR_All.tgt = tgt; 
