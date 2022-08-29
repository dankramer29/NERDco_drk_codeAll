function binnedR_All = PSTH_byRT_condensed(binnedR_All, effector, date)
%% INPUT: full session's worth of data (binnedR_All) and string (BC or HM)
%LFR = squeeze(nanmean(psth(tgt == 3,:,:)));  % avg over trials, time bins x units; 
%RFR = squeeze(nanmean(psth(tgt == 4,:,:)));  % avg over trials, time bins x units; 
%UFR = squeeze(nanmean(psth(tgt == 1,:,:)));  % avg over trials, time bins x units; 
%DFR = squeeze(nanmean(psth(tgt == 2,:,:)));  % avg over trials, time bins x units;
% tgt = aggR(5).HM.tgt; 
% coh = aggR(5).HM.uCoh; 
% cohColors = parula(length(unique(coh)));
% binnedR_All = aggR(sesh).HM;
tgt = binnedR_All.tgt; 
% coh = binnedR_All.uCoh; 
%cohColors = parula(length(unique(coh)));
switch effector
    case 'HM'
        rtBins = [500:150:1500]./20;
    case 'BC'
        rtBins = [250:150:1250]./20;
end
iti = binnedR_All.state; %state values
iti(iti < 17.5) = nan; 
% get indices for where trials started- and iti precedes every trial (yes, even the first one in a block)
itiIdx = find(~isnan(iti)); %the indices for where ITI is in R struct
trialStartIdx = itiIdx(diff(itiIdx) > 1); % using the face that itiIdx is off by 1 length to our advantage
windowEarlyMO = -2500/20;   %ms before event onset / 20 ms per bin;
windowLateMO  = 200/20;  
windowEarlySO = -200/20;   %ms before event onset / 20 ms per bin;
windowLateSO  = 1200/20;

testSpikes = binnedR_All.rawSpikes;
%SF hack to use the move onset metric she likes best: 
binnedR_All.speedMO = binnedR_All.moveOnset; 
for trial = 1:length(binnedR_All.stimOnset) %length(trialStartIdx)
    if ~isnan(binnedR_All.stimOnset(trial))
        if trial < length(binnedR_All.stimOnset) %length(trialStartIdx)
            testSpikes(binnedR_All.speedMO(trial):trialStartIdx(trial+1),:) = nan;
        else
            testSpikes(binnedR_All.speedMO(trial):end,:) = nan;
        end
            tgt(trial) = binnedR_All.tgt(trial);
%             coh(trial) = binnedR_All.uCoh(trial);
           % rt(trial) = binnedR_All.speedRT(trial);
            rt(trial) = binnedR_All.moveOnset(trial) - binnedR_All.stimOnset(trial);
    end
end
% tgt(isnan(coh)) = [];
% rt(isnan(coh)) = [];
% coh(isnan(coh)) = [];
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
psthMO = nan(length(binnedR_All.tgt), 1+windowLateMO-windowEarlyMO, sum(unitsIdx)); 
psthSO = nan(length(binnedR_All.tgt), 1+windowLateSO-windowEarlySO, sum(unitsIdx)); 
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
   % psth(trial,:,:) = binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   %SF: add logic to only fill in the trial length's spikes, this is likely bleeding into the next trial 
   %psth(trial,:,:) = testSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   psthMO(trial,:,:) = testSpikes(binnedR_All.speedMO(trial)+windowEarlyMO:binnedR_All.speedMO(trial)+windowLateMO, unitsIdx).*50; %in hz
   psthSO(trial,:,:) = testSpikes(binnedR_All.stimOnset(trial)+windowEarlySO:binnedR_All.stimOnset(trial)+windowLateSO, unitsIdx).*50; %in hz
   % subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),3)); %avg over units
    %subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),2)); % avg over time points
    %targIdx = targIdx + 1;
    end
end
moveOnset = size(psthMO, 2) - windowLateMO;
%%
figure;
unitNums = find(unitsIdx); 
%rtColors = [{parula(length(rtBins))}, {parula(length(rtBins))}]; 
rtColors = parula(length(rtBins)); 
for unit = 1:length(unitNums) %find(incUnits)
   % figure;
    rtCount = 1;
    for rtIdx = rtBins
    %rtCount = rtCount + 1;

    %the minimum RT bin should catch all below: 
    if rtIdx == min(rtBins)
     %   rIdx = rt <= rtIdx & (rt < rtIdx+(500/20)); 
        rIdx = rt <= (rtIdx +(500/20)); 
    % if not the min and not the max, normal 500 ms window: 
    elseif rtIdx < max(rtBins)
        rIdx = (rt >= rtIdx) & (rt < rtIdx+(500/20)); 
    % the max should catch all above: 
    else
        rIdx = rt >= rtIdx;
    end
        %by target, 1 = up, 2 = down, 3 = right, 4 = left
        subplot(2,3,2) %up, 1
            plot(windowEarlyMO:windowLateMO, squeeze(mean(psthMO((tgt == 1)& rIdx,:, unit))), 'LineWidth', 2, 'Color', rtColors(rtCount,:))
            hold on;
            % down
            plot(windowEarlyMO:windowLateMO, squeeze(mean(psthMO((tgt == 2)& rIdx,:, unit))), '--','LineWidth', 2, 'Color', rtColors(rtCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlyMO:25:windowLateMO];
            ax.XTickLabel = [windowEarlyMO:25:windowLateMO] .* 20;
            axis square;
            title(['Up (-) and Down (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Movement Onset (ms)');
            ylabel('Firing Rate (Hz)');
            
        subplot(2,3,5) % left, 4
            plot(windowEarlyMO:windowLateMO, squeeze(mean(psthMO((tgt == 4)& rIdx,:, unit))), 'LineWidth', 2, 'Color', rtColors(rtCount,:))
            hold on;
            plot(windowEarlyMO:windowLateMO, squeeze(mean(psthMO((tgt == 3)& rIdx,:, unit))), '--','LineWidth', 2, 'Color', rtColors(rtCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlyMO:25:windowLateMO];
            ax.XTickLabel = [windowEarlyMO:25:windowLateMO] .* 20;
            title(['Left (-) and Right (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Movement Onset (ms)');
            
        subplot(2,3,1) %up, 1
            plot(windowEarlySO:windowLateSO, squeeze(mean(psthSO((tgt == 1)& rIdx,:, unit))), 'LineWidth', 2, 'Color', rtColors(rtCount,:))
            hold on;
            % down
            plot(windowEarlySO:windowLateSO, squeeze(mean(psthSO((tgt == 2)& rIdx,:, unit))), '--','LineWidth', 2, 'Color', rtColors(rtCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlySO:10:windowLateSO];
            ax.XTickLabel = [windowEarlySO:10:windowLateSO] .* 20;
            axis square;
            title(['Up (-) and Down (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Stimulus Onset (ms)');
            ylabel('Firing Rate (Hz)');
            
        subplot(2,3,4) % left, 4
            plot(windowEarlySO:windowLateSO, squeeze(mean(psthSO((tgt == 4)& rIdx,:, unit))), 'LineWidth', 2, 'Color', rtColors(rtCount,:))
            hold on;
            plot(windowEarlySO:windowLateSO, squeeze(mean(psthSO((tgt == 3)& rIdx,:, unit))), '--','LineWidth', 2, 'Color', rtColors(rtCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlySO:10:windowLateSO];
            ax.XTickLabel = [windowEarlySO:10:windowLateSO] .* 20;
            title(['Left (-) and Right (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Stimulus Onset (ms)');
            
            % plot number of trials per coherence
        subplot(2,3,6)
            plot(rtIdx, sum((rIdx) & ((tgt == 3)|(tgt == 4))), '*', 'LineWidth', 2, 'Color', rtColors(rtCount,:), 'MarkerSize', 10); 
            hold on;
            axis square;
            xlabel('Reaction Time Bin')
            ylabel('Number of Trials')
        subplot(2,3,3)
            plot(rtIdx, sum((rIdx) & ((tgt == 1)|(tgt == 2))), '*', 'LineWidth', 2, 'Color', rtColors(rtCount,:), 'MarkerSize', 10); 
            hold on;
            axis square;
            xlabel('Reaction Time Bin')
            ylabel('Number of Trials')
       rtCount = rtCount + 1;
    end
        subplot(2,3,1)
            line([0, 0], [0 15], 'Color', 'k', 'LineWidth', 2)
        subplot(2,3,4)
            line([0 0], [0 15],  'Color','k', 'LineWidth', 2)
        subplot(2,3,2)
           % line([moveOnset, moveOnset], [0 15], 'Color', 'k', 'LineWidth', 2)
            line([-1 -1], [0 15],  'Color','k', 'LineWidth', 2)           
        subplot(2,3,5)
           % line([moveOnset, moveOnset], [0 15], 'Color', 'k', 'LineWidth', 2)
           line([-1 -1], [0 15],  'Color','k', 'LineWidth', 2)    

    set(gcf, 'Position', [0 100 1500 1000])
    
%     goodUnit = input('Is it a keeper? 1 = yes, 0 = no: ')
%     if goodUnit
%         goodUnits(unitNums(unit)) = 1;
        fh = gcf; 
        fh.Renderer = 'painters';
      %  saveas(fh, ['Users/sharlene/decisionMaking/Results/PSTH/', date, '/Unit_', num2str(unitNums(unit)), '_', effector, '_', date, '_RT_noNanMean.svg'])
        saveas(fh, ['Users/sharlene/decisionMaking/Results/PSTH/', date, '/Unit_', num2str(unitNums(unit)), '_', effector, '_', date, '_RT_noNanMean.png'])
%     end
    for spIdx = [1:6]
        subplot(2,3,spIdx)
        hold off
    end
end
binnedR_All.psthSO_RT = psthSO; 
binnedR_All.psthMO_RT = psthMO; 
binnedR_All.windowEarlyMO_RT = windowEarlyMO;   %ms before event onset / 20 ms per bin;
binnedR_All.windowLateMO_RT = windowLateMO;  
binnedR_All.windowEarlySO_RT = windowEarlySO;   %ms before event onset / 20 ms per bin;
binnedR_All.windowLateSO_RT = windowLateSO;