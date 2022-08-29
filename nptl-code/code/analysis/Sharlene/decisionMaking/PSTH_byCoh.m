%LFR = squeeze(nanmean(psth(tgt == 3,:,:)));  % avg over trials, time bins x units; 
%RFR = squeeze(nanmean(psth(tgt == 4,:,:)));  % avg over trials, time bins x units; 
%UFR = squeeze(nanmean(psth(tgt == 1,:,:)));  % avg over trials, time bins x units; 
%DFR = squeeze(nanmean(psth(tgt == 2,:,:)));  % avg over trials, time bins x units;
% tgt = aggR(5).HM.tgt; 
% coh = aggR(5).HM.uCoh; 
% cohColors = parula(length(unique(coh)));
% binnedR_All = aggR(sesh).HM;
tgt = binnedR_All.tgt; 
coh = binnedR_All.uCoh; 
cohColors = parula(length(unique(coh)));

iti = binnedR_All.state; %state values
iti(iti < 17.5) = nan; 
% get indices for where trials started- and iti precedes every trial (yes, even the first one in a block)
itiIdx = find(~isnan(iti)); %the indices for where ITI is in R struct
trialStartIdx = itiIdx(diff(itiIdx) > 1); % using the face that itiIdx is off by 1 length to our advantage
windowEarly = -2500/20;   %ms before event onset / 20 ms per bin;
windowLate  = 200/20;  
testSpikes = binnedR_All.rawSpikes;

for trial = 1:length(binnedR_All.stimOnset) %length(trialStartIdx)
    if ~isnan(binnedR_All.stimOnset(trial))
%         for windStep = windowEarly:windowLate
%             ts = ts+1;

        if trial < length(binnedR_All.stimOnset) %length(trialStartIdx)

            testSpikes(binnedR_All.speedMO(trial):trialStartIdx(trial+1),:) = nan;
        else

            testSpikes(binnedR_All.speedMO(trial):end,:) = nan;
        end
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
% decUnits = zeros(1,192); 
% incUnits = zeros(1,192); 
% for unit = 1:192
%     if nanmean(preFR(:,unit)) > nanmean(postFR(:,unit))
%         decUnits(unit) = 1;
%     else
%         incUnits(unit) = 1;
%     end
% end
unitsIdx = mean(binnedR_All.rawSpikes).*50 > 10; %all spikes with ave FR > 10 Hz

%unitsIdx = (incUnits & unitsIdx); 
sum(unitsIdx)
% mean FR per unit
psth = nan(length(binnedR_All.tgt), 1+windowLate-windowEarly, sum(unitsIdx)); 
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
   % psth(trial,:,:) = binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   %SF: add logic to only fill in the trial length's spikes, this is likely bleeding into the next trial 
   %psth(trial,:,:) = testSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   psth(trial,:,:) = testSpikes(binnedR_All.speedMO(trial)+windowEarly:binnedR_All.speedMO(trial)+windowLate, unitsIdx).*50; %in hz
   % subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),3)); %avg over units
    %subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),2)); % avg over time points
    %targIdx = targIdx + 1;
    end
end
%%
figure;
unitNums = find(unitsIdx); 
goodUnits_moveAlign = zeros(1,length(unitsIdx)); 
for unit = 1:length(unitNums) %find(incUnits)
   % figure;
    cCount = 1;
    for cohIdx = unique(coh)
        %by target, 1 = up, 2 = down, 3 = right, 4 = left
        subplot(3,3,2) %up, 1
            plot(windowEarly:windowLate, squeeze(nanmean(psth((tgt == 1)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            axis square;
            title(['Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Movement Onset (ms)');
            ylabel('Z-scored FR (Hz)');
            ax = gca;
            ax.XTick = [windowEarly:25:windowLate];
            ax.XTickLabel = [windowEarly:25:windowLate] .* 20;
        subplot(3,3,4) % left, 4
            plot(windowEarly:windowLate, squeeze(nanmean(psth((tgt == 4)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            axis square;
            ax = gca;
            ax.XTick = [windowEarly:25:windowLate];
            ax.XTickLabel = [windowEarly:25:windowLate] .* 20;
        subplot(3,3,6) %right, 3
            plot(windowEarly:windowLate, squeeze(nanmean(psth((tgt == 3)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            axis square;
            ax = gca;
            ax.XTick = [windowEarly:25:windowLate];
            ax.XTickLabel = [windowEarly:25:windowLate] .* 20;
        subplot(3,3,8) %down, 2
            plot(windowEarly:windowLate, squeeze(nanmean(psth((tgt == 2)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            axis square;
            ax = gca;
            ax.XTick = [windowEarly:25:windowLate];
            ax.XTickLabel = [windowEarly:25:windowLate] .* 20;
       cCount = cCount + 1;
    end
    set(gcf, 'Position', [100 100 1000 1000])
    goodUnit = input('Is it a keeper? 1 = yes, 0 = no: ')
    if goodUnit
        goodUnits_moveAlign(unitNums(unit)) = 1;
        fh = gcf; 
        fh.Renderer = 'painters';
        saveas(fh, ['Users/sharlene/decisionMaking/Results/HM_20180516_MoveAlign_byCoh_Unit', num2str(unitNums(unit)), '.svg'])
    end
    for spIdx = [2 4 6 8]
        subplot(3,3,spIdx)
        hold off
    end
end