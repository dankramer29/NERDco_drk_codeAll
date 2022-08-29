%count = count + 1;
%hunits = histogram(binnedR_All.rawSpikes, 80); 
%cutoff = quantile(hunits.Data', .35)
unitsIdx = [mean(binnedR_All.rawSpikes).*50 > 4];
windowedFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
preFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
postFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
tgt = nan(size(windowedFR,1),1);
coh = nan(size(tgt));
rt = nan(size(tgt));
trialNum = zeros(size(tgt));
windowEarly = -500/20;   %ms before decode event onset start/ 20 ms per bin;
windowLate  = 2500/20; 
slopeWindow =25+[10:35]; % 1+ abs(windowEarly) + [100/20  : 300/20];
trialStartIdx = find(abs(diff(binnedR_All.stimCondMatrix(:,4)))>0);
            testSpikes = binnedR_All.zSpikes;
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
%         for windStep = windowEarly:windowLate
%             ts = ts+1;

        if trial < length(binnedR_All.tgt)

            testSpikes(binnedR_All.speedMO(trial):trialStartIdx(trial+1),:) = nan;
        else

            testSpikes(binnedR_All.speedMO(trial):end,:) = nan;
        end
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
%unitsIdx = (incUnits & unitsIdx); 
sum(unitsIdx)
% mean FR per unit
psth = nan(length(binnedR_All.tgt), 1+windowLate-windowEarly, sum(unitsIdx)); 
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
   % psth(trial,:,:) = binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
    psth(trial,:,:) = testSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   % subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),3)); %avg over units
    %subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),2)); % avg over time points
    %targIdx = targIdx + 1;
    end
end
%%
LFR = squeeze(nanmean(psth(tgt == 3,:,:)));  % avg over trials, time bins x units; 
RFR = squeeze(nanmean(psth(tgt == 4,:,:)));  % avg over trials, time bins x units; 
UFR = squeeze(nanmean(psth(tgt == 1,:,:)));  % avg over trials, time bins x units; 
DFR = squeeze(nanmean(psth(tgt == 2,:,:)));  % avg over trials, time bins x units; 
%V = LFR-RFR; % time bins x units; 
V1 = LFR-RFR;
V2 = UFR-DFR;

figure; 
plot(windowEarly:windowLate, nanmean(abs(V1),2),'g', 'LineWidth', 2);
hold on;
plot(windowEarly:windowLate, nanmean(abs(V2),2),'m', 'LineWidth', 2);
ax = gca;
ax.XTick = [windowEarly:abs(windowEarly):windowLate];
ax.XTickLabel = [windowEarly:abs(windowEarly):windowLate].*20;
xlabel('Time from Stim Onset (ms)');
ylabel('Delta Population FR (Hz)');
title('Difference in Population Firing Rate across Targets')
%%
LFR_coh = nan(length(unique(coh)), 1+windowLate-windowEarly, sum(unitsIdx));
RFR_coh = nan(length(unique(coh)), 1+windowLate-windowEarly, sum(unitsIdx));
UFR_coh = nan(length(unique(coh)), 1+windowLate-windowEarly, sum(unitsIdx));
DFR_coh = nan(length(unique(coh)), 1+windowLate-windowEarly, sum(unitsIdx));
diffUD_coh = nan(length(unique(coh)), 1+windowLate-windowEarly);
diffLR_coh = nan(length(unique(coh)), 1+windowLate-windowEarly); 
figure;
cohCount = 0;
slopesUD = nan(length(unique(coh)),2);
slopesLR = nan(length(unique(coh)),2);
statsLR  = nan(length(unique(coh)),4); 
statsUD  = nan(length(unique(coh)),4); 

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
for cohIdx = unique(coh)'
    cohCount = cohCount + 1;
    cIdx = coh == cohIdx; 
    LFR_coh(cohCount,:,:) = squeeze(nanmean(psth(cIdx & (tgt == 3),:,:))); %average over trials of the same coh and targ
    RFR_coh(cohCount,:,:) = squeeze(nanmean(psth(cIdx & (tgt == 4),:,:)));
    UFR_coh(cohCount,:,:) = squeeze(nanmean(psth(cIdx & (tgt == 1),:,:)));
    DFR_coh(cohCount,:,:) = squeeze(nanmean(psth(cIdx & (tgt == 2),:,:)));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_coh(cohCount,:) = squeeze(nanmean(abs(UFR_coh(cohCount,:,:) - DFR_coh(cohCount,:,:)),3));
    diffLR_coh(cohCount,:) = squeeze(nanmean(abs(LFR_coh(cohCount,:,:) - RFR_coh(cohCount,:,:)),3));
    subplot(2,1,1)
    plot(windowEarly:windowLate, diffUD_coh(cohCount,:), 'Color', colors{1}(cohCount,:), 'LineWidth',2)
    hold on;
  
    subplot(2,1,2)
    plot(windowEarly:windowLate,  diffLR_coh(cohCount,:), 'Color', colors{2}(cohCount,:), 'LineWidth',2)
    hold on;
    % calculate the slope on stim on + 100 to stim on + 300: 
    
     [slopesLR(cohCount,:), ~, ~, ~, statsLR(cohCount,:)] = regress(diffLR_coh(cohCount,slopeWindow)', [ones(1,length(slopeWindow)); slopeWindow]'); 
     [slopesUD(cohCount,:), ~, ~, ~, statsUD(cohCount,:)] = regress(diffUD_coh(cohCount,slopeWindow)', [ones(1,length(slopeWindow)); slopeWindow]'); 
end
subplot(2,1,1)
    ax = gca;
ax.XTick = [windowEarly:abs(windowEarly):windowLate];
ax.XTickLabel = [windowEarly:abs(windowEarly):windowLate].*20;
xlabel('Time from Stim Onset (ms)');
ylabel('Delta Population FR (Hz)');
title('Difference in Population Firing Rate across Up/Down Targets')
line([slopeWindow(1)-abs(windowEarly), slopeWindow(1)-abs(windowEarly)], [4 13])
line([slopeWindow(end)-abs(windowEarly), slopeWindow(end)-abs(windowEarly)], [4 13])
legend({num2str(unique(coh))})
subplot(2,1,2)
    ax = gca;
ax.XTick = [windowEarly:abs(windowEarly):windowLate];
ax.XTickLabel = [windowEarly:abs(windowEarly):windowLate].*20;
xlabel('Time from Stim Onset (ms)');
ylabel('Delta Population FR (Hz)');
title('Difference in Population Firing Rate across Left/Right Targets')
line([slopeWindow(1)-abs(windowEarly), slopeWindow(1)-abs(windowEarly)], [4 13])
line([slopeWindow(end)-abs(windowEarly), slopeWindow(end)-abs(windowEarly)], [4 13])
legend({num2str(unique(coh))})

[cohSlopesLR, ~, ~, ~, cohStatsLR] = regress(slopesLR(:,2), [ones(length(unique(coh)),1), unique(coh)]);
[cohSlopesUD, ~, ~, ~, cohStatsUD] = regress(slopesUD(:,2), [ones(length(unique(coh)),1), unique(coh)]);
figure;
plot(unique(coh), slopesLR(:,2),'g');
hold on;
plot(unique(coh), slopesUD(:,2),'m');
count = 1;
slopeUDpVal(count) = cohStatsUD(3); 
slopeLRpVal(count) = cohStatsLR(3); 