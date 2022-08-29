function binnedR_All = PSTH_byCoh_condensed_CF(binnedR_All, effector, date)
%% INPUT: full session's worth of data (binnedR_All) and string (BC or HM)
%LFR = squeeze(nanmean(psth(tgt == 3,:,:)));  % avg over trials, time bins x units; 
%RFR = squeeze(nanmean(psth(tgt == 4,:,:)));  % avg over trials, time bins x units; 
%UFR = squeeze(nanmean(psth(tgt == 1,:,:)));  % avg over trials, time bins x units; 
%DFR = squeeze(nanmean(psth(tgt == 2,:,:)));  % avg over trials, time bins x units;
% tgt = aggR(5).HM.tgt; 
% coh = aggR(5).HM.uCoh; 
% cohColors = parula(length(unique(coh)));
% binnedR_All = aggR(sesh).HM;
tgt = binnedR_All.tgt'; 
coh = binnedR_All.uCoh; 

%binnedR_All.speedMO = binnedR_All.moveOnset; % SF doesn't like speedMO
% iti = binnedR_All.state; %state values
% iti(iti < 17.5) = nan; 
% % get indices for where trials started- and iti precedes every trial (yes, even the first one in a block)
% itiIdx = find(~isnan(iti)); %the indices for where ITI is in R struct
% trialStartIdx = itiIdx(diff(itiIdx) > 1); % using the face that itiIdx is off by 1 length to our advantage
trialStartIdx = binnedR_All.trialStart;
windowEarlyMO = -1000/20;   %ms before event onset / 20 ms per bin;
windowLateMO  = 200/20;  
windowEarlySO = -100/20;   %ms before event onset / 20 ms per bin;
windowLateSO  = 600/20;
windowEarlyTO = -200/20;   %ms before event onset / 20 ms per bin;
windowLateTO  = 1000/20;
testSpikesMO = binnedR_All.rawSpikes;
testSpikesSO = binnedR_All.rawSpikes;
%coh = nan(1, length(binnedR_All.stimOnset)); 
trialNum = nan(1, length(binnedR_All.stimOnset)); 
rt  = nan(1, length(binnedR_All.stimOnset)); %recalculating these
for trial = 1:length(binnedR_All.stimOnset) %length(trialStartIdx)
    if ~isnan(binnedR_All.stimOnset(trial))
        if trial < length(binnedR_All.stimOnset) %length(trialStartIdx)
            %go cue:end = nan
            testSpikesMO(binnedR_All.moveOnset(trial):trialStartIdx(trial+1),:) = nan;
            testSpikesSO(binnedR_All.targOnset(trial):trialStartIdx(trial+1),:) = nan;
        else
            testSpikesMO(binnedR_All.moveOnset(trial):end,:) = nan;
            testSpikesSO(binnedR_All.targOnset(trial):end,:) = nan;
        end
           % tgt(trial) = binnedR_All.tgt(trial);
          % trialNum(trial) = R(trial).trialNum;
           
           % coh(trial) = R(trial).coherence; %binnedR_All.uCoh(trial);
           % tgt(trial) = R(trial).targLoc; 
           % rt(trial)  = binnedR_All.moveOnset(trial) - binnedR_All.targOnset(trial); %binnedR_All.speedRT(trial);
            rt(trial)  = binnedR_All.speedMO(trial) - binnedR_All.targOnset(trial); %binnedR_All.speedRT(trial);
    end
end
badIdx = (isnan(coh)) | (trialNum == 0);
tgt(badIdx) = [];
rt(badIdx) = [];
coh(badIdx) = [];
cohColors = parula(length(unique(coh)));
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
psthTO = nan(length(binnedR_All.tgt), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
        % nanned out anything that occurs after targ onset for pure stim onset response: 
        psthSO(trial,:,:) = testSpikesSO(binnedR_All.stimOnset(trial)+windowEarlySO:binnedR_All.stimOnset(trial)+windowLateSO, unitsIdx).*50; %in hz
        % nan out movement for targ onset and move onset PSTHs: 
        psthTO(trial,:,:) = testSpikesMO(binnedR_All.targOnset(trial)+windowEarlyTO:binnedR_All.targOnset(trial)+windowLateTO, unitsIdx).*50; %in hz
        %psthMO(trial,:,:) = testSpikesMO(binnedR_All.moveOnset(trial)+windowEarlyMO:binnedR_All.moveOnset(trial)+windowLateMO, unitsIdx).*50; %in hz
        psthMO(trial,:,:) = testSpikesMO(binnedR_All.speedMO(trial)+windowEarlyMO:binnedR_All.speedMO(trial)+windowLateMO, unitsIdx).*50; %in hz
    end
end
moveOnset = size(psthMO, 2) - windowLateMO;
%%
figure;
unitNums = find(unitsIdx); 
%goodUnits = zeros(1,length(unitsIdx)); 
for unit = 1:length(unitNums) %find(incUnits)
   % figure;
    cCount = 1;
    for cohIdx = unique(coh)'
        %by target, 1 = up, 2 = down, 3 = right, 4 = left
        subplot(2,4,3) %up, 1
            plot(windowEarlyMO:windowLateMO, squeeze(nanmean(psthMO((tgt == 1)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            % down
            plot(windowEarlyMO:windowLateMO, squeeze(nanmean(psthMO((tgt == 2)& (coh == cohIdx),:, unit))), '--','LineWidth', 2, 'Color', cohColors(cCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlyMO:25:windowLateMO];
            ax.XTickLabel = [windowEarlyMO:25:windowLateMO] .* 20;
            axis square;
            title(['Up (-) and Down (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Movement Onset (ms)');
            ylabel('Firing Rate (Hz)');
            
        subplot(2,4,7) % left, 4
            plot(windowEarlyMO:windowLateMO, squeeze(nanmean(psthMO((tgt == 4)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            plot(windowEarlyMO:windowLateMO, squeeze(nanmean(psthMO((tgt == 3)& (coh == cohIdx),:, unit))), '--','LineWidth', 2, 'Color', cohColors(cCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlyMO:25:windowLateMO];
            ax.XTickLabel = [windowEarlyMO:25:windowLateMO] .* 20;
            title(['Left (-) and Right (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Movement Onset (ms)');
            
        subplot(2,4,1) %up, 1
            plot(windowEarlySO:windowLateSO, squeeze(nanmean(psthSO((tgt == 1)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            % down
            plot(windowEarlySO:windowLateSO, squeeze(nanmean(psthSO((tgt == 2)& (coh == cohIdx),:, unit))), '--','LineWidth', 2, 'Color', cohColors(cCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlySO:10:windowLateSO];
            ax.XTickLabel = [windowEarlySO:10:windowLateSO] .* 20;
            axis square;
            title(['Up (-) and Down (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Stimulus Onset (ms)');
            ylabel('Firing Rate (Hz)');
            
        subplot(2,4,5) % left, 4
            plot(windowEarlySO:windowLateSO, squeeze(nanmean(psthSO((tgt == 4)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            plot(windowEarlySO:windowLateSO, squeeze(nanmean(psthSO((tgt == 3)& (coh == cohIdx),:, unit))), '--','LineWidth', 2, 'Color', cohColors(cCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlySO:10:windowLateSO];
            ax.XTickLabel = [windowEarlySO:10:windowLateSO] .* 20;
            title(['Left (-) and Right (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Stimulus Onset (ms)');
            
        subplot(2,4,2) 
            plot(windowEarlyTO:windowLateTO, squeeze(nanmean(psthTO((tgt == 1)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            % down
            plot(windowEarlyTO:windowLateTO, squeeze(nanmean(psthTO((tgt == 2)& (coh == cohIdx),:, unit))), '--','LineWidth', 2, 'Color', cohColors(cCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlyTO:10:windowLateTO];
            ax.XTickLabel = [windowEarlyTO:10:windowLateTO] .* 20;
            axis square;
            title(['Up (-) and Down (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Target Onset (ms)');
            ylabel('Firing Rate (Hz)');
            
        subplot(2,4,6) 
            plot(windowEarlyTO:windowLateTO, squeeze(nanmean(psthTO((tgt == 4)& (coh == cohIdx),:, unit))), 'LineWidth', 2, 'Color', cohColors(cCount,:))
            hold on;
            % down
            plot(windowEarlyTO:windowLateTO, squeeze(nanmean(psthTO((tgt == 3)& (coh == cohIdx),:, unit))), '--','LineWidth', 2, 'Color', cohColors(cCount,:))
            axis square;
            ax = gca;
            ax.XTick = [windowEarlyTO:10:windowLateTO];
            ax.XTickLabel = [windowEarlyTO:10:windowLateTO] .* 20;
            axis square;
            title(['Up (-) and Down (--) Unit #', num2str(unitNums(unit))]);
            xlabel('Time from Target Onset (ms)');
            ylabel('Firing Rate (Hz)');
        
        % plot number of trials per coherence
        subplot(2,4,4)
            plot(cohIdx, sum((coh == cohIdx) & ((tgt == 3)|(tgt == 4))), '*', 'LineWidth', 2, 'Color', cohColors(cCount,:), 'MarkerSize', 10); 
            hold on;
            axis square;
            xlabel('Coherence')
            ylabel('Number of Trials')
        subplot(2,4,8)
            plot(cohIdx, sum((coh == cohIdx) & ((tgt == 1)|(tgt == 2))), '*', 'LineWidth', 2, 'Color', cohColors(cCount,:), 'MarkerSize', 10); 
            hold on;
            axis square;
            xlabel('Coherence')
            ylabel('Number of Trials')
            
       cCount = cCount + 1;
    end
        subplot(2,4,1)
            line([0, 0], [0 15], 'Color', 'k', 'LineWidth', 2)
        subplot(2,4,5)
            line([0 0], [0 15],  'Color','k', 'LineWidth', 2)
        subplot(2,4,2)
           % line([moveOnset, moveOnset], [0 15], 'Color', 'k', 'LineWidth', 2)
            line([-1 -1], [0 15],  'Color','k', 'LineWidth', 2)           
        subplot(2,4,6)
           % line([moveOnset, moveOnset], [0 15], 'Color', 'k', 'LineWidth', 2)
           line([-1 -1], [0 15],  'Color','k', 'LineWidth', 2)  
       subplot(2,4,3)
            line([0, 0], [0 15], 'Color', 'k', 'LineWidth', 2)
        subplot(2,4,7)
            line([0 0], [0 15],  'Color','k', 'LineWidth', 2)
    set(gcf, 'Position', [0 100 1500 1000])
    
%     goodUnit = input('Is it a keeper? 1 = yes, 0 = no: ')
%     if goodUnit
%         goodUnits(unitNums(unit)) = 1;

        fh = gcf; 
        fh.Renderer = 'painters';
     %   saveas(fh, ['Users/sharlene/decisionMaking/Results/PSTH/', date, '/Unit_', num2str(unitNums(unit)), '_', effector, '_', date, '_Coh_CF.svg'])
        saveas(fh, ['Users/sharlene/decisionMaking/Results/PSTH/', date, '/Unit_', num2str(unitNums(unit)), '_', effector, '_', date, '_Coh_CF.png'])
%     end
    for spIdx = [1:8]
        subplot(2,4,spIdx)
        hold off
    end
end
binnedR_All.psthSO_Coh = psthSO; 
binnedR_All.psthMO_Coh = psthMO; 
binnedR_All.psthTO_Coh = psthTO; 
binnedR_All.windowEarlyMO_C = windowEarlyMO;   %ms before event onset / 20 ms per bin;
binnedR_All.windowLateMO_C = windowLateMO;  
binnedR_All.windowEarlySO_C = windowEarlySO;   %ms before event onset / 20 ms per bin;
binnedR_All.windowLateSO_C = windowLateSO;
binnedR_All.windowEarlyTO_C = windowEarlyTO;   %ms before event onset / 20 ms per bin;
binnedR_All.windowLateTO_C = windowLateTO;
binnedR_All.unitIdx = unitsIdx; 
binnedR_All.badTrialIdx = badIdx; 