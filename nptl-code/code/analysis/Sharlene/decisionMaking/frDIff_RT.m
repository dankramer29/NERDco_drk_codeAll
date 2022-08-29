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
% trialStartIdx = find(abs(diff(binnedR_All.stimCondMatrix(:,4)))>0);
iti = binnedR_All.state; %state values
iti(iti < 17.5) = nan; 
% get indices for where trials started- and iti precedes every trial (yes, even the first one in a block)
itiIdx = find(~isnan(iti)); %the indices for where ITI is in R struct
trialStartIdx = itiIdx(diff(itiIdx) > 1); % using the face that itiIdx is off by 1 length to our advantage
testSpikes = binnedR_All.zSpikes;
for trial = 1:length(binnedR_All.stimOnset)
    if ~isnan(binnedR_All.stimOnset(trial))
%         for windStep = windowEarly:windowLate
%             ts = ts+1;

        if trial < length(trialStartIdx)

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
   %SF: add logic to only fill in the trial length's spikes, this is likely bleeding into the next trial 
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

% figure; 
% plot(windowEarly:windowLate, nanmean(abs(V1),2),'g', 'LineWidth', 2);
% hold on;
% plot(windowEarly:windowLate, nanmean(abs(V2),2),'m', 'LineWidth', 2);
% ax = gca;
% ax.XTick = [windowEarly:abs(windowEarly):windowLate];
% ax.XTickLabel = [windowEarly:abs(windowEarly):windowLate].*20;
% xlabel('Time from Stim Onset (ms)');
% ylabel('Delta Population FR (Hz)');
% title('Difference in Population Firing Rate across Targets')
%%
rtBins = [750:750:2500]./20; %ms divided by 20 ms per bin
LFR_rt = nan(length(rtBins), 1+windowLate-windowEarly, sum(unitsIdx));
RFR_rt = nan(length(rtBins), 1+windowLate-windowEarly, sum(unitsIdx));
UFR_rt = nan(length(rtBins), 1+windowLate-windowEarly, sum(unitsIdx));
DFR_rt = nan(length(rtBins), 1+windowLate-windowEarly, sum(unitsIdx));
diffUD_rt = nan(length(rtBins), 1+windowLate-windowEarly);
diffLR_rt = nan(length(rtBins), 1+windowLate-windowEarly); 
figure;
rtCount = 0;
slopesUD = nan(length(rtBins),2);
slopesLR = nan(length(rtBins),2);
statsLR  = nan(length(rtBins),4); 
statsUD  = nan(length(rtBins),4); 

% colors =[ {[204,236,230;...
% 153,216,201;...
% 102,194,164;...
% 65,174,118;...
% 35,139,69;...
% 0,88,36;...
% 0, 0, 0]./255},...
% {[212,185,218;...
% 201,148,199;...
% 223,101,176;...
% 231,41,138;...
% 206,18,86;...
% 145,0,63;...
% 0 0 0]./255}];
colors = [{parula(length(rtBins))}, {parula(length(rtBins))}]; 
for rtIdx = rtBins
    rtCount = rtCount + 1;
    % this logic is wrong, rtIdx can never be below min(rtBins)
    if rtIdx < min(rtBins)
        rIdx = (rt < rtIdx) & (rt < (rtIdx+(500/20))); 
    % if above min and below max, be normal
    elseif rtIdx < max(rtBins)
        rIdx = (rt >= rtIdx) & (rt < (rtIdx+(500/20))); 
    else
        rIdx = rt >= rtIdx;
    end
    LFR_rt(rtCount,:,:) = squeeze(mean(psth(rIdx & (tgt == 3),:,:),1)); %average over trials of the same coh and targ
    RFR_rt(rtCount,:,:) = squeeze(mean(psth(rIdx & (tgt == 4),:,:),1));
    UFR_rt(rtCount,:,:) = squeeze(mean(psth(rIdx & (tgt == 1),:,:),1));
    DFR_rt(rtCount,:,:) = squeeze(mean(psth(rIdx & (tgt == 2),:,:),1));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_rt(rtCount,:) = squeeze(nanmean(abs(UFR_rt(rtCount,:,:) - DFR_rt(rtCount,:,:)),3));
    diffLR_rt(rtCount,:) = squeeze(nanmean(abs(LFR_rt(rtCount,:,:) - RFR_rt(rtCount,:,:)),3));
    subplot(2,1,1)
    plot(windowEarly:windowLate, diffUD_rt(rtCount,:) - nanmean(diffUD_rt(rtCount,1:abs(windowEarly)*2)), 'Color', colors{1}(rtCount,:), 'LineWidth',2)
    hold on;
  
    subplot(2,1,2)
    plot(windowEarly:windowLate,  diffLR_rt(rtCount,:) - nanmean(diffLR_rt(rtCount,1:abs(windowEarly)*2)), 'Color', colors{2}(rtCount,:), 'LineWidth',2)
    hold on;
    % calculate the slope on stim on + 100 to stim on + 300: 
    
     [slopesLR(rtCount,:), ~, ~, ~, statsLR(rtCount,:)] = regress(diffLR_rt(rtCount,slopeWindow)', [ones(1,length(slopeWindow)); slopeWindow]'); 
     [slopesUD(rtCount,:), ~, ~, ~, statsUD(rtCount,:)] = regress(diffUD_rt(rtCount,slopeWindow)', [ones(1,length(slopeWindow)); slopeWindow]'); 
end
subplot(2,1,1)
    ax = gca;
ax.XTick = [windowEarly:abs(windowEarly):windowLate];
ax.XTickLabel = [windowEarly:abs(windowEarly):windowLate].*20;
xlabel('Time from Stim Onset (ms)');
ylabel('Delta Population FR (Hz)');
title('Difference in Population Firing Rate across Up/Down Targets')
%line([slopeWindow(1)-abs(windowEarly), slopeWindow(1)-abs(windowEarly)], [4 13])
%line([slopeWindow(end)-abs(windowEarly), slopeWindow(end)-abs(windowEarly)], [4 13])
legend({num2str((rtBins.*20)')})
axis tight
subplot(2,1,2)
    ax = gca;
ax.XTick = [windowEarly:abs(windowEarly):windowLate];
ax.XTickLabel = [windowEarly:abs(windowEarly):windowLate].*20;
xlabel('Time from Stim Onset (ms)');
ylabel('Delta Population FR (Hz)');
title('Difference in Population Firing Rate across Left/Right Targets')
%line([slopeWindow(1)-abs(windowEarly), slopeWindow(1)-abs(windowEarly)], [4 13])
%line([slopeWindow(end)-abs(windowEarly), slopeWindow(end)-abs(windowEarly)], [4 13])
legend({num2str((rtBins.*20)')})
axis tight 
%%
[cohSlopesLR, ~, ~, ~, cohStatsLR] = regress(slopesLR(:,2), [ones(length(rtBins),1), rtBins']);
[cohSlopesUD, ~, ~, ~, cohStatsUD] = regress(slopesUD(:,2), [ones(length(rtBins),1), rtBins']);
% figure;
% plot(rtBins, slopesLR(:,2),'g');
% hold on;
% plot(rtBins, slopesUD(:,2),'m');
count = sesh;
slopeUDpVal(count) = cohStatsUD(3); 
slopeLRpVal(count) = cohStatsLR(3); 