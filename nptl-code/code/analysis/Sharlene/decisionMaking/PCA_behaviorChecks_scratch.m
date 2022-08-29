trajLength = 75; % * 20 ms bins. 
trialStart = d.trialStart; 
pcaPSTH = nan(size(d.psth,1), length(trialStart), trajLength+1);
%testSpikes = d.zSpikes; 
usedCoh = unique(d.uCoh);
sum_stim = zeros(size(d.psth,2), size(d.psth,3), trajLength + 1);
psth_stim = nan( size(d.psth,2), size(d.psth,3), trajLength + 1);
condCount = zeros(4, length(usedCoh)); 
for trial = 1:length(trialStart)
        cohIdx = find(usedCoh == d.uCoh(trial));
    condCount(d.tgt(trial), cohIdx) = condCount(d.tgt(trial), cohIdx) + 1;
%     if trial < length(trialStart)
%         testSpikes(d.moveOnset(trial):d.trialStart(trial+1),:) = nan; 
%     else
%         testSpikes(d.moveOnset(trial):end,:) = nan; 
%     end
% using psth code to make averaged speed profiles: 
    sum_stim(d.tgt(trial), cohIdx, 1:trajLength+1) =(sum_stim(1, d.tgt(trial), cohIdx, :)) + d.calcSpeed(d.stimOnset(trial):d.stimOnset(trial)+trajLength);    
end
%% speed 
figure;
for trial = 1:length(d.trialStart)
        plot(d.calcSpeed(d.stimOnset(trial):d.stimOnset(trial)+trajLength), 'Color', colors(find(usedCoh == d.uCoh(trial)),:))
        hold on;
end
ax = gca;
ax.XTickLabel = ax.XTick .* 20; 
xlabel('Time from Stim Onset (ms)')
%% head position
colors = [237,248,233;...% lightest green, hardest
199,233,192;...
161,217,155;...;...
116,196,118;...
65,171,93;...
35,139,69;...
0,90,50]./255;
figure;
for trial = 1:length(d.trialStart)
        plot(d.effPosX(d.stimOnset(trial):d.stimOnset(trial)+trajLength),d.effPosY(d.stimOnset(trial):d.stimOnset(trial)+trajLength), 'Color', colors((usedCoh == d.uCoh(trial)),:))
        hold on;
end
ax = gca;
ax.XTickLabel = ax.XTick .* 50; 
xlabel('Time from Stim Onset (ms)')
%%
colors = [237,248,233;...% lightest green, hardest
199,233,192;...
161,217,155;...;...
116,196,118;...
65,171,93;...
35,139,69;...
0,90,50]./255;
figure;
for tgt = 1:4
    for coh = 1:usedCoh
    subplot(1,4,tgt)
    plot(psth_stim(:, tgt, coh, :), 'Color', colors(coh,:), 'LineWidth', 1.5)
    hold on;
    end
end
    