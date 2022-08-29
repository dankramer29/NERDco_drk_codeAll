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
windowEarly = -200/20;   %ms before event onset / 20 ms per bin;
windowLate  = 1200/20;  
%testSpikes = binnedR_All.zSpikes;
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
psthSO = nan(length(binnedR_All.tgt), 1+windowLate-windowEarly, sum(unitsIdx)); 
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
   % psth(trial,:,:) = binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   %SF: add logic to only fill in the trial length's spikes, this is likely bleeding into the next trial 
   %psth(trial,:,:) = testSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   psthSO(trial,:,:) = testSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   % subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),3)); %avg over units
    %subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),2)); % avg over time points
    %targIdx = targIdx + 1;
    end
end
%%
figure;
unitNums = find(unitsIdx); 
goodUnits_moveAlign = zeros(1,length(unitsIdx)); 
for unit = 1:length(unitNums)%length(unitsIdx) %find(incUnits)
   % figure;
    cCount = 1;
    for cohIdx = unique(coh)
        %by target, 1 = up, 2 = down, 3 = right, 4 = left
        subplot(1,2,1) %up, 1
            plot(windowEarly:windowLate, squeeze(nanmean(psthSO((tgt == 1)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            % down
            plot(windowEarly:windowLate, squeeze(nanmean(psthSO((tgt == 2)& (coh == cohIdx),:, unit))), '--','LineWidth', 2, 'Color', cohColors(cCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarly:10:windowLate];
            ax.XTickLabel = [windowEarly:10:windowLate] .* 20;
            axis square;
            title(['Up (-) and Down (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Stimulus Onset (ms)');
            ylabel('Firing Rate (Hz)');
            hold on;
            
        subplot(1,2,2) % left, 4
            plot(windowEarly:windowLate, squeeze(nanmean(psthSO((tgt == 4)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            plot(windowEarly:windowLate, squeeze(nanmean(psthSO((tgt == 3)& (coh == cohIdx),:, unit))), '--','LineWidth', 2, 'Color', cohColors(cCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarly:10:windowLate];
            ax.XTickLabel = [windowEarly:10:windowLate] .* 20;
            title(['Left (-) and Right (--) Unit #', num2str(unitNums(unit))]);

       cCount = cCount + 1;
    end
    subplot(1,2,1)
    line([0, 0], [0 15], 'Color', 'k', 'LineWidth', 2)
    subplot(1,2,2)
    line([0 0], [0 15],  'Color','k', 'LineWidth', 2)
    
    set(gcf, 'Position', [100 100 900 900])
    goodUnit = input('Is it a keeper? 1 = yes, 0 = no: ')
    if goodUnit
        goodUnits_moveAlign(unitNums(unit)) = 1;
        fh = gcf; 
        fh.Renderer = 'painters';
        saveas(fh, ['Users/sharlene/decisionMaking/Results/PSTH/Unit_', num2str(unitNums(unit)), '_HM_2018_06_25_StimAlign_byCoh_cond.svg'])
    end
    for spIdx = [2 4 6 8]
        subplot(3,3,spIdx)
        hold off
    end
end