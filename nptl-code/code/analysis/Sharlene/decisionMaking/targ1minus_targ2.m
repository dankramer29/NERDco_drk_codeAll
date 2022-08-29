% subtract mean(FR L) from mean(FR R), U from D. Align to stim onset for coh, move
% onset for RT 
unitsIdx = [sum(binnedR_All.rawSpikes) > 40000];
windowedFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
preFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
postFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
tgt = nan(size(windowedFR,1),1);
coh = nan(size(tgt));
rt = nan(size(tgt));
trialNum = zeros(size(tgt));
windowEarly = -40/20;   %ms before decode event onset start/ 20 ms per bin;
windowLate  = 500/20; 

for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
%         for windStep = windowEarly:windowLate
%             ts = ts+1;
            preFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.stimOnset(trial)-5:binnedR_All.stimOnset(trial),:));
            postFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.stimOnset(trial):binnedR_All.stimOnset(trial)+5,:));
            windowedFR(trial, :) = nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate,:));
            tgt(trial) = binnedR_All.tgt(trial);
            coh(trial) = binnedR_All.uCoh(trial);
            rt(trial) = binnedR_All.speedRT(trial);
            %trialNum(ts) = trial;
%         end
    end
end
tgt(isnan(coh)) = [];
rt(isnan(coh)) = [];
coh(isnan(coh)) = [];
decUnits = zeros(1,192); 
incUnits = zeros(1,192); 
for unit = 1:192
    if nanmean(preFR(:,unit)) > nanmean(postFR(:,unit))
        decUnits(unit) = 1;
    else
        incUnits(unit) = 1;
    end
end
unitsIdx = (incUnits & unitsIdx); 
%% subtract mean FR per unit
stimEarly = 5; 
psth = nan(length(binnedR_All.tgt), 1+windowLate-windowEarly, sum(unitsIdx)); 
subTrial = nan(length(binnedR_All.tgt), 1+windowLate-windowEarly); 
%subTrial = nan(length(binnedR_All.tgt), 192); 
%targIdx = 1; 
%for targ = 1:2:4
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
    psth(trial,:,:) = binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   % subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),3)); %avg over units
    %subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),2)); % avg over time points
    %targIdx = targIdx + 1;
    end
end

% subtract FR
figure;
plot(windowEarly:windowLate, abs(nanmean(subTrial(tgt == 2,:))- nanmean(subTrial(tgt == 1,:)))); %down - up
hold on;
plot(windowEarly:windowLate, abs(nanmean(subTrial(tgt == 4,:))- nanmean(subTrial(tgt == 3,:)))); %right - left
title('mean FR over all units');
legend({'Down - Up', 'Right - Left'})
ax = gca;
ax.XTick = [windowEarly:abs(stimEarly):windowLate];
ax.XTickLabel = [windowEarly:abs(stimEarly):windowLate].*20; %ms from stim on
xlabel('Time from Stim Onset (ms)');
% figure;
% plot( nanmean(subTrial(tgt == 2,:)), nanmean(subTrial(tgt == 1,:)), '.'); %down - up
% hold on;
% plot(nanmean(subTrial(tgt == 3,:)), nanmean(subTrial(tgt == 4,:)),'.'); %right - left
% title('mean FR over all units');
% legend({'Down - Up', 'Right - Left'})
% ax = gca;
% ax.XTick = [windowEarly:abs(stimEarly):windowLate];
% ax.XTickLabel = [windowEarly:abs(stimEarly):windowLate].*20; %ms from stim on
xlabel('Time from Stim Onset (ms)');

%% by coh: 
figure;
numTargs = 4; 
colors =[ {[204,236,230;...
153,216,201;...
102,194,164;...
65,174,118;...
35,139,69;...
0,88,36;...
0, 0, 0]./255},...
{[212,185,218;...
201,148,199;...
223,101,176;...
231,41,138;...
206,18,86;...
145,0,63;...
0 0 0]./255}];
tempCoh = unique(coh);
tempCoh = [tempCoh; 0];
subFRCoh = nan(2, length(tempCoh), 1+windowLate-windowEarly); 
slopes = nan(2, 5,2);
targCount = 0; 
for targIdx = 1:2:numTargs
    targCount = targCount + 1;
    cohCount = 0;
    if targCount == 1
        trialIdx2 = (tgt == targIdx); % 1 (up) or 3 (right)
        trialIdx1 = (tgt == targIdx+1); % 2 (down) or 4 (left)
    else
        trialIdx1 = (tgt == targIdx); % 1 (up) or 3 (right)
        trialIdx2 = (tgt == targIdx+1); % 2 (down) or 4 (left)
    end
    
for currentCoh = tempCoh(1:end-1)'%unique(coh)'  %tempCoh(1:2:end)'%unique(actualCoh)'
    cohCount = cohCount + 1;
    cohIdx = coh == currentCoh; 
    %subFRCoh(targCount, cohCount, :) = abs(squeeze(nanmean(nanmean(psth(trialIdx2 & cohIdx,:,:),3),1)- nanmean(subTrial(trialIdx1 & cohIdx,:)));
   % subFRCoh(targCount, cohCount, :) = abs(squeeze(nanmean(nanmean(psth(trialIdx2 & cohIdx,:,:),3)),1))- squeeze(nanmean(nanmean(psth(trialIdx1 & cohIdx,:,:),3),1)));
    [slopes(targCount,cohCount,:), ~, ~, ~, stats(targCount,cohCount,:)] = regress(squeeze(subFRCoh(targCount, cohCount,:)), [ones(1,length(windowEarly:windowLate)); windowEarly:windowLate]'); 
   % accOverTime_Coh(2, cohCount, :) = nansum(predictedTargLR(actualCohLR == currentCoh,:) == trialTgtLR(actualCohLR == currentCoh)) / sum(actualCohLR == currentCoh);
   subplot(2,1,targCount) 
   plot(windowEarly:windowLate, squeeze(subFRCoh(targCount, cohCount, :)), 'LineWidth', 2, 'Color', colors{targCount}(cohCount,:)); 
    hold on;
end

legend({num2str(tempCoh)})
[cohSlopes(targCount,:), ~, ~, ~, cohStats(targCount,:)] = regress(slopes(targCount,:,2)', [ones(cohCount,1), tempCoh(1:end-1)]);
end
figure;
plot(tempCoh(1:end-1), slopes(1,:,2), '*', 'MarkerSize', 8); 
hold on;
plot(tempCoh(1:end-1), slopes(2,:,2), '*', 'MarkerSize', 8); 
ax = gca;
ax.ColorOrderIndex = 1;
plot(tempCoh(1:end-1), cohSlopes(1,1)+(tempCoh(1:end-1).*cohSlopes(1,2)), 'LineWidth', 2); 
plot(tempCoh(1:end-1), cohSlopes(2,1)+(tempCoh(1:end-1).*cohSlopes(2,2)), 'LineWidth', 2); 