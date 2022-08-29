%% Get spiking info
rmsMultiplier = -4.5;
[rms, allms] = channelRMS(R);
R = RastersFromMinAcausSpikeBand(R, rms.*rmsMultiplier);
numUnits = size(R(1).spikeRaster,1);
%% get movement onset for each trial
usedCoh = unique(abs([R.coherence])); 
for i = 1:length(R)
    R(i).headVel(1,:) = [0, diff(R(i).rigidBodyPosXYZ(1,:))];
    R(i).headVel(2,:) = [0, diff(R(i).rigidBodyPosXYZ(2,:))];
    R(i).headVel(3,:) = [0, diff(R(i).rigidBodyPosXYZ(3,:))];
    R(i).headVel(4,:) = sqrt(sum(R(i).headVel.^2)); %magnitude
   % make this the max of targets on phase? 
    R(i).movementOnset = find(R(i).headVel(4,R(i).timeStimulusOn:end)>= (0.25*max(R(i).headVel(4,R(i).timeStimulusOn:end))),1, 'first') + R(i).timeStimulusOn;
    % get RT while we're looping anyway
   % R(i).reactionTime = R(i).movementOnset - R(i).timeStimulusOn;
end

for cIdx = 1:length(usedCoh)
      subplot(length(usedCoh), 1, cIdx)
    h = histogram([R([R.coherence] == usedCoh(cIdx)).reactionTime]);
    h.BinEdges = [300:50:3500];
end
xlabel('Reaction Time (s)', 'FontSize', 16);
subplot(cIdx, 1, 1)
title('Reaction Times - raw head pos')
%% split by coherence 
longestRT = max([R.movementOnset] - [R.timeStimulusOn]);
clear psth; 
%psth = zeros(length(usedCoh), numUnits, longestRT); 

for cIdx = 1:length(usedCoh)
    psth{cIdx} = zeros(numUnits, longestRT); 
    % for the trials in that coherence: 
    trials = [R([R.coherence] == cIdx).trialNum];
    for tIdx = trials
        rt = R(tIdx).movementOnset - R(tIdx).timeStimulusOn; 
        psth{cIdx}( :, (longestRT-rt):end) = psth{cIdx}( :, (longestRT-rt):end) + R(tIdx).spikeRaster(:, (R(tIdx).movementOnset-rt) :R(tIdx).movementOnset);
    end
end
%% plot for each unit 
figure;
for unit = 1:size(rms,2)
    for coh = 1:6
        plot(smooth(sum(psth{coh}(unit,:)))); 
        hold on;
    end
    pause
    hold off
end
%%  split by RT
% rtBins = 1001:1000:max([R.reactionTime]); 
% for i = 1:length(rtBins)
%     %trials = [R(([R.reactionTime] <= rtBins(i)) & ([R.reactionTime] >= rtBins(i)-1000)).trialNum];
%      
% end