% look at FR differences in phases of delayed movement task
Rs = R([R.isSuccessful]); 
Rs([Rs.timeGoCue] < 200) = []; 
%trialNum    = [Rs.trialNum]+1;
%trialDelay  = [Rs.timeGoCue];
%trialLength = [Rs.trialLength];
%minDelay = min(trialDelay(trialDelay > 200));
%maxTrialTime = max(trialDelay(trialDelay > 200));
%timeBefore = min(500, minDelay);
%timeAfter = min(500, min(trialLength - trialDelay));
%%
binSize = 10; %ms 
%PSTH = zeros(size(Rs(1).spikeRaster, 1), timeBefore+timeAfter+1);
delayFR = nan(size(Rs(1).spikeRaster,1), length(Rs)); 
reachFR = nan(size(Rs(1).spikeRaster,1), length(Rs)); 
baseFR = nan(size(reachFR)); 
%meanFR_hold = zeros(size(Rs(1).spikeRaster,1), length(Rs)); 
%compare modulation depth during last 500 ms of delay, go+200:go+700 
timeBefore = 499; % ms before go cue
timeAfterGo = 200; %ms after go cue to start counting reach
reachPeriod = 499; %ms of reach time
%for unit = 1:size(PSTH,1)
    for trial = 1:length(Rs)
        delayFR(:, trial) = nansum(Rs(trial).spikeRaster(:, (Rs(trial).timeGoCue-timeBefore): (Rs(trial).timeGoCue)),2).*2; %to get in Hz
        reachFR(:, trial) = nansum(Rs(trial).spikeRaster(:, (Rs(trial).timeGoCue+timeAfterGo): (Rs(trial).timeGoCue+timeAfterGo+reachPeriod)),2).*2; %to get in Hz
        baseFR(:, trial) = nansum(Rs(trial).spikeRaster(:,1:Rs(trial).timeTargetOn),2)./ (Rs(trial).timeTargetOn) .* 1000; %Hz
        % bin counts over 10 ms bins, convert to FR 
%         binnedTemp = temp; 
%         for i = 1:timeBefore
%             binnedTemp(i) = nanmean(temp(i:i+20));
%         end
       % meanFR(unit, trial) = nansum(temp); %Hz 
       % temp = [];
    end
%end
baseMOD = max(baseFR)-min(baseFR);
delayMOD = max(delayFR)-min(delayFR); 
reachMOD = max(reachFR)-min(reachFR); 
figure; 
boxplot([baseMOD; delayMOD; reachMOD]'); 
ax = gca;
ax.XTick = 1:3;
ax.XTickLabel = {'Baseline', 'Delay', 'Reach'}; 
ylabel('Depth of Modulation (Hz)')
axis square; 

figure;
ecdf(bsxfun(@rdivide, delayMOD, reachMOD))
xlabel('Ratio of delay modulation to reach')
ylabel('Proportion of Channels')
hold on;
line([0 2], [0.5 0.5])
line([1 1], [0 1])
axis tight
ax = gca;
ax.FontSize = 14;
xlabel('Delay Modulation / Reach Modulation')
%% visualize/sort by target direction
targets = reshape([Rs.posTarget], 5, [])'; %x = (1,:), y = (2,:)
% assign target ID 
possibleTargs = unique(targets, 'rows');
for trial = 1:length(targets) 
    targID(trial) = intersect(find(possibleTargs(:,1) == targets(trial,1)), find(possibleTargs(:,2) == targets(trial,2)));
end
%%
targDelayFR = nan(size(Rs(1).spikeRaster,1), size(possibleTargs,1));
targReachFR = nan(size(targDelayFR)); 
sparseDelayFR = nan(10, 10, size(Rs(1).spikeRaster,1)); 
sparseReachFR = nan(size(sparseDelayFR)); 
for targ = unique(targID)
    targDelayFR(:,targ) = (nansum(delayFR(:, targID == targ),2).*2); %average FR
    targReachFR(:,targ) = (nansum(reachFR(:, targID == targ),2).*2); %average FR
    sparseDelayFR(ceil((possibleTargs(targ,1)+500)/100), ceil((possibleTargs(targ,2)+500)/100),:) = targDelayFR(:,targ); 
    sparseReachFR(ceil((possibleTargs(targ,1)+500)/100), ceil((possibleTargs(targ,2)+500)/100),:) = targReachFR(:,targ); 
end
%% visualize/sort by distance
