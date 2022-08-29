function binnedR_All = aggregateDM_R(binnedR) 
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
binnedR_All.stimCondMatrix = [];
binnedR_All.state = [];
binnedR_All.effPosX = [];
binnedR_All.effPosY = [];
binnedR_All.zSpikes = [];
binnedR_All.meanSSpikes = [];
binnedR_All.calcSpeed = [];
for i = 1:length(binnedR)
    binnedR_All.rawSpikes = [binnedR_All.rawSpikes; binnedR(i).rawSpikes];
    binnedR_All.zSpikes = [binnedR_All.zSpikes; binnedR(i).zScoreSpikes];
    binnedR_All.meanSSpikes = [binnedR_All.meanSSpikes; binnedR(i).meanSubtractSpikes];
    binnedR_All.stimCondMatrix = [binnedR_All.stimCondMatrix; binnedR(i).stimCondMatrix];
    binnedR_All.state = [binnedR_All.state; binnedR(i).state]; 
    binnedR_All.effPosX = [binnedR_All.effPosX; binnedR(i).effectorCursorPos(:,1)]; 
    binnedR_All.effPosY = [binnedR_All.effPosY; binnedR(i).effectorCursorPos(:,2)];
    binnedR_All.calcSpeed = [binnedR_All.calcSpeed; binnedR(i).rigidBodyPosXYZ_speed];
end
%% 
% trialStartIdx = find(abs(diff(binnedR_All.stimCondMatrix(:,4)))>0); %this is wrong -SF June 2018
iti = binnedR_All.state; %state values
stimFirstFlag = nanmax(iti) == 19; %Stim First = extra state = 19
%iti((iti < 17.8) | (iti > 18.5)) = nan; 
iti((iti < 18) | (iti > 18)) = nan; 

% get indices for where trials started- and iti precedes every trial (yes, even the first one in a block)
itiIdx = find(~isnan(iti)); %the indices for where ITI is in R struct
trialStartIdx = itiIdx(diff(itiIdx) > 1); % using the face that itiIdx is off by 1 length to our advantage
% trialStartIdx([diff(trialStartIdx)] > 800) = [];
numTrials = length(trialStartIdx);
moveOnset = nan(numTrials,1);
stimOnset = nan(numTrials,1);
targOnset = nan(numTrials,1);
coh = nan(numTrials,1);
trialCount = 0;
for i = 1:numTrials
    %based on state change
    trialCount = trialCount + 1;
    if i < numTrials-1
        % mostly for StimFirst paradigm: 
        if stimFirstFlag
            % the targets appear when the checkerboard turns off
            targStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+1)) == 19, 1, 'last') + 1;
            moveStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+1)) == 3, 1, 'first');
            stimStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+1)) == 17, 1, 'first');
        else
            % otherwise, the targets are presented at state 2
            targStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+1)) == 2, 1, 'first');
            moveStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+1)) == 17, 1, 'last');
            stimStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+1)) == 17, 1, 'first');
        end

        %
    else
        if stimFirstFlag
            % the targets appear when the checkerboard turns off
            targStart = find(binnedR_All.state(trialStartIdx(i):end) == 19, 1, 'last') + 1;
            moveStart = find(binnedR_All.state(trialStartIdx(i):end) == 3, 1, 'first');
            stimStart = find(binnedR_All.state(trialStartIdx(i):end) == 17, 1, 'first');
        else
            % otherwise, the targets are presented at state 2
            targStart = find(binnedR_All.state(trialStartIdx(i):end) == 2, 1, 'first');
            moveStart = find(binnedR_All.state(trialStartIdx(i):end) == 17, 1, 'last');
            stimStart = find(binnedR_All.state(trialStartIdx(i):end) == 17, 1, 'first');
        end
%         if ~isempty(moveStart) && ((trialStartIdx(i) + moveStart) <= size(binnedR_All.stimCondMatrix,1))
%             moveOnset(trialCount) = trialStartIdx(i) + moveStart;
%             coh(trialCount) = binnedR_All.stimCondMatrix(moveOnset(trialCount),4);
%         else
%             moveOnset(trialCount) = nan;
%             coh(trialCount) = nan;
%         end
%         if ~isempty(stimStart) && ((trialStartIdx(i) + stimStart) <= size(binnedR_All.stimCondMatrix,1))
%            stimOnset(trialCount) = trialStartIdx(i) + stimStart;
%         else
%            stimOnset(trialCount) = nan;
%         end
%          % mostly for StimFirst paradigm: 
% %         if stimFirstFlag
% %             % the targets appear when the checkerboard turns off
% %             targStart = find(binnedR_All.state(trialStartIdx(i):end) == 19, 1, 'last') + 1;
% %         else
% %             % otherwise, the targets are presented at state 2
% %             targStart = find(binnedR_All.state(trialStartIdx(i):end) == 2, 1, 'first');
% %         end
%         if isempty(targStart)
%             targOnset(trialCount) = nan;
%         else
%             targOnset(trialCount) = trialStartIdx(i) + targStart; 
%         end
        %
    end
        if ~isempty(moveStart)
            moveOnset(trialCount) = trialStartIdx(i) + moveStart;
            coh(trialCount) = binnedR_All.stimCondMatrix(moveOnset(trialCount),4);
        else
            moveOnset(trialCount) = nan;
            coh(trialCount) = nan;
            %   trialCount = trialCount - 1; %overwrite this on the next iteration
        end
        
        if ~isempty(stimStart)
            stimOnset(trialCount) = trialStartIdx(i) + stimStart;
        else
            stimOnset(trialCount) = nan;
        end
        
        if ~isempty(targStart)
            targOnset(trialCount) =  trialStartIdx(i) + targStart; 
        else
            targOnset(trialCount) = nan;
        end
end

unsignedCoh = abs((2.*coh - 225)/225);
badTrl = isnan(unsignedCoh);
unsignedCoh(badTrl) = [];
coh(badTrl) = [];
moveOnset(badTrl) = [];
stimOnset(badTrl) = [];
targOnset(badTrl) = [];
binnedR_All.moveOnset = moveOnset; 
binnedR_All.speedMO = zeros(size(moveOnset)); 
binnedR_All.speedRT = zeros(size(moveOnset)); 
for trial = 1:length(moveOnset) %find(~isnan(unsignedCoh)) %1:length(moveOnset)
    binnedR_All.speedMO(trial) = moveOnset(trial) + find(binnedR_All.calcSpeed(moveOnset(trial) - 20:moveOnset(trial)+20)  >= (0.05*max(binnedR_All.calcSpeed(moveOnset(trial) - 20:moveOnset(trial)+20))), 1, 'first') ; 
    binnedR_All.speedRT(trial) = binnedR_All.speedMO(trial) - stimOnset(trial); %stim onset is a state change, MO is calculated
end
%% PSTH-it
% assign and split by target
psth = zeros(size(binnedR_All.rawSpikes,2), numTargs, length(unique(unsignedCoh)), length([(-1*psthPre):psthPost]));
count = zeros(numTargs, length(unique(unsignedCoh)));
UCohIdx = unique(unsignedCoh);
tgt = zeros(1, length(unsignedCoh));
for trial = 1:length(binnedR_All.moveOnset)
    if stimFirstFlag
        if binnedR_All.stimCondMatrix(binnedR_All.moveOnset(trial),1) == 1 %if up/down axis
            if binnedR_All.effPosY(binnedR_All.moveOnset(trial) + 5) > 0 %updated 10/26 SF updated 10/4/18 SF
                tgt(trial) = 1; %up
            else
                tgt(trial) = 2; %down
            end
        else %if left/right axis
            if binnedR_All.effPosX(binnedR_All.moveOnset(trial) + 5) > 0
                tgt(trial) = 3; %right
            else
                tgt(trial) = 4; %left
            end
        end
    else
        if trial < length(binnedR_All.moveOnset)
            if binnedR_All.stimCondMatrix(binnedR_All.moveOnset(trial),1) == 1 %if up/down axis
                if binnedR_All.effPosY(binnedR_All.moveOnset(trial) + find(binnedR_All.state(binnedR_All.moveOnset(trial):trialStartIdx(trial+1)) == 3, 1, 'last')) > 0 %updated 10/4/18 SF
                    tgt(trial) = 1; %up
                else
                    tgt(trial) = 2; %down
                end
            else %if left/right axis
                if binnedR_All.effPosX(binnedR_All.moveOnset(trial) + find(binnedR_All.state(binnedR_All.moveOnset(trial):trialStartIdx(trial+1)) == 3, 1, 'last')) > 0
                    tgt(trial) = 3; %right
                else
                    tgt(trial) = 4; %left
                end
            end
        else
            if binnedR_All.stimCondMatrix(binnedR_All.moveOnset(trial),1) == 1
                if binnedR_All.effPosY(binnedR_All.moveOnset(trial) + find(binnedR_All.state(binnedR_All.moveOnset(trial):end) == 3, 1, 'last')) > 0
                    tgt(trial) = 1; %up
                else
                    tgt(trial) = 2; %down
                end
            else
                if binnedR_All.effPosX(binnedR_All.moveOnset(trial) + find(binnedR_All.state(binnedR_All.moveOnset(trial):end) == 3, 1, 'last')) > 0
                    tgt(trial) = 3; %right
                else
                    tgt(trial) = 4; %left
                end
            end
        end
    end
    count(tgt(trial), UCohIdx == unsignedCoh(trial)) = count(tgt(trial), UCohIdx == unsignedCoh(trial))+1;
    for unit = 1:192
        psth(unit, tgt(trial), UCohIdx == unsignedCoh(trial), :) = squeeze(psth(unit, tgt(trial),  UCohIdx == unsignedCoh(trial), :)) + ...
            (binnedR_All.zSpikes(binnedR_All.speedMO(trial)-psthPre:binnedR_All.speedMO(trial)+psthPost, unit))*50; %make it in Hz, make it an average
    end
end

%% make the outputs
binnedR_All.psth = psth; 
binnedR_All.psthBefore = psthPre; 
binnedR_All.psthAfter = psthPost; 
binnedR_All.moveOnset = moveOnset;
binnedR_All.stimOnset = stimOnset; 
binnedR_All.targOnset = targOnset;
binnedR_All.tgt = tgt; 
binnedR_All.uCoh = unsignedCoh; 
binnedR_All.trialStart = trialStartIdx; 
binnedR_All.badIdx = badTrl; 