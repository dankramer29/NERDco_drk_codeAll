function diffOut = checkFirst_FRdiff(binnedR_All, rtBins, rtWindowSize)
% plot aligned to movement, targs, and stim in the same figure 
% wrt Coh and RT
% subplot:  rows: RT, coh. cols: stim onset (SO), move onset (MO) 

% rtBinsBC = [250:150:1250]./20;  %ms divided by 20 ms per bin
% rtBinsHM = [750:150:2000]./20; %ms divided by 20 ms per bin

%hunits = histogram(binnedR_All.rawSpikes, 80); 
%cutoff = quantile(hunits.Data', .35)
unitsIdx = mean(binnedR_All.rawSpikes).*50 > 15; %all spikes with ave FR > 5 Hz

%rtBins = bins; 
figure;

%windowedFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
preFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
postFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
tgt = nan(length(binnedR_All.tgt),1); %why isn't this pulled straight from binnedR_All? 
coh = nan(size(tgt)); %why isn't this pulled straight from binnedR_All? 
rt = nan(size(tgt)); %why isn't this pulled straight from binnedR_All? 
%trialNum = zeros(size(tgt));
%zeroingWind = -300/20; 

trialStartIdx = binnedR_All.trialStart;
trialStartIdx(binnedR_All.badIdx) = [];
windowEarlyMO = -1000/20;   %ms before event onset / 20 ms per bin;
windowLateMO  = 200/20;  
windowEarlySO = -100/20;   %ms before event onset / 20 ms per bin;
windowLateSO  = 600/20;
windowEarlyTO = -200/20;   %ms before event onset / 20 ms per bin;
windowLateTO  = 600/20;
testSpikesMO = binnedR_All.rawSpikes;
testSpikesSO = binnedR_All.rawSpikes;

for trial = 1:length(binnedR_All.stimOnset) %length(trialStartIdx)
    if ~isnan(binnedR_All.stimOnset(trial))
        if trial < length(binnedR_All.stimOnset) %length(trialStartIdx)
            %testSpikesMO(binnedR_All.moveOnset(trial):trialStartIdx(trial+1),:) = nan;
            testSpikesMO(binnedR_All.speedMO(trial):trialStartIdx(trial+1),:) = nan;
            testSpikesSO(binnedR_All.targOnset(trial):trialStartIdx(trial+1),:) = nan;
        else
            %testSpikesMO(binnedR_All.moveOnset(trial):end,:) = nan;
            testSpikesMO(binnedR_All.speedMO(trial):end,:) = nan;
            testSpikesSO(binnedR_All.targOnset(trial):end,:) = nan;
        end
            tgt(trial) = binnedR_All.tgt(trial);
            coh(trial) = binnedR_All.uCoh(trial);
           % rt(trial)  = binnedR_All.moveOnset(trial) - binnedR_All.targOnset(trial); %binnedR_All.speedRT(trial);
            rt(trial)  = binnedR_All.speedMO(trial) - binnedR_All.targOnset(trial); %binnedR_All.speedRT(trial);
    end
end
badTrials = isnan(coh); 
tgt(isnan(coh)) = [];
rt(isnan(coh)) = [];
coh(isnan(coh)) = [];
usedCoh = unique(coh); 
%%
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
psthMO = nan(length(binnedR_All.tgt), 1+windowLateMO-windowEarlyMO, sum(unitsIdx)); 
psthSO = nan(length(binnedR_All.tgt), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
psthTO = nan(length(binnedR_All.tgt), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
%for trial = 1:length(binnedR_All.tgt)
for trial = 1:length(tgt)
    if ~isnan(binnedR_All.stimOnset(trial)) && ~isnan(coh(trial))
        psthMO(trial,:,:) = testSpikesMO((binnedR_All.speedMO(trial)+windowEarlyMO)  :(binnedR_All.speedMO(trial)+windowLateMO)  , unitsIdx).*50; %in hz
        psthSO(trial,:,:) = testSpikesSO((binnedR_All.stimOnset(trial)+windowEarlySO):(binnedR_All.stimOnset(trial)+windowLateSO), unitsIdx).*50; %in hz
        psthTO(trial,:,:) = testSpikesMO((binnedR_All.targOnset(trial)+windowEarlyTO):(binnedR_All.targOnset(trial)+windowLateTO), unitsIdx).*50; %in hz
   end
end
%% kept for reference
% LFR = squeeze(nanmean(psthMO(tgt == 3,:,:)));  % avg over trials, time bins x units; 
% RFR = squeeze(nanmean(psthMO(tgt == 4,:,:)));  % avg over trials, time bins x units; 
% UFR = squeeze(nanmean(psthMO(tgt == 1,:,:)));  % avg over trials, time bins x units; 
% DFR = squeeze(nanmean(psthMO(tgt == 2,:,:)));  % avg over trials, time bins x units; 
% %V = LFR-RFR; % time bins x units; 
% V1 = LFR-RFR;
% V2 = UFR-DFR;

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
%% RT, movement onset aligned 
LFR_rt_MO = nan(length(rtBins), 1+windowLateMO-windowEarlyMO, sum(unitsIdx));
RFR_rt_MO = nan(length(rtBins), 1+windowLateMO-windowEarlyMO, sum(unitsIdx));
UFR_rt_MO = nan(length(rtBins), 1+windowLateMO-windowEarlyMO, sum(unitsIdx));
DFR_rt_MO = nan(length(rtBins), 1+windowLateMO-windowEarlyMO, sum(unitsIdx));
diffUD_rt_MO = nan(length(rtBins), 1+windowLateMO-windowEarlyMO);
diffLR_rt_MO = nan(length(rtBins), 1+windowLateMO-windowEarlyMO); 
% stim onset aligned
LFR_rt_SO = nan(length(rtBins), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
RFR_rt_SO = nan(length(rtBins), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
UFR_rt_SO = nan(length(rtBins), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
DFR_rt_SO = nan(length(rtBins), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
diffUD_rt_SO = nan(length(rtBins), 1+windowLateSO-windowEarlySO);
diffLR_rt_SO = nan(length(rtBins), 1+windowLateSO-windowEarlySO); 
% target onset aligned
LFR_rt_TO = nan(length(rtBins), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
RFR_rt_TO = nan(length(rtBins), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
UFR_rt_TO = nan(length(rtBins), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
DFR_rt_TO = nan(length(rtBins), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
diffUD_rt_TO = nan(length(rtBins), 1+windowLateTO-windowEarlyTO);
diffLR_rt_TO = nan(length(rtBins), 1+windowLateTO-windowEarlyTO); 

%% Coh, movement onset aligned 
LFR_coh_MO = nan(length(usedCoh), 1+windowLateMO-windowEarlyMO, sum(unitsIdx));
RFR_coh_MO = nan(length(usedCoh), 1+windowLateMO-windowEarlyMO, sum(unitsIdx));
UFR_coh_MO = nan(length(usedCoh), 1+windowLateMO-windowEarlyMO, sum(unitsIdx));
DFR_coh_MO = nan(length(usedCoh), 1+windowLateMO-windowEarlyMO, sum(unitsIdx));
diffUD_coh_MO = nan(length(usedCoh), 1+windowLateMO-windowEarlyMO);
diffLR_coh_MO = nan(length(usedCoh), 1+windowLateMO-windowEarlyMO); 
% stim onset aligned
LFR_coh_SO = nan(length(usedCoh), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
RFR_coh_SO = nan(length(usedCoh), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
UFR_coh_SO = nan(length(usedCoh), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
DFR_coh_SO = nan(length(usedCoh), 1+windowLateSO-windowEarlySO, sum(unitsIdx));
diffUD_coh_SO = nan(length(usedCoh), 1+windowLateSO-windowEarlySO);
diffLR_coh_SO = nan(length(usedCoh), 1+windowLateSO-windowEarlySO); 
% target onset aligned 
LFR_coh_TO = nan(length(usedCoh), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
RFR_coh_TO = nan(length(usedCoh), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
UFR_coh_TO = nan(length(usedCoh), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
DFR_coh_TO = nan(length(usedCoh), 1+windowLateTO-windowEarlyTO, sum(unitsIdx));
diffUD_coh_TO = nan(length(usedCoh), 1+windowLateTO-windowEarlyTO);
diffLR_coh_TO = nan(length(usedCoh), 1+windowLateTO-windowEarlyTO); 
%% RT
rtCount = 0;
% rt goes fastest (highest coh) = dark blue, slowest (lowest coh) = yellow. 
colorsRT = [{parula(length(rtBins))}, {parula(length(rtBins))}]; 

for rtIdx = rtBins
    rtCount = rtCount + 1;
    %the minimum RT bin should catch all below: 
    if rtIdx == min(rtBins)
     %   rIdx = rt <= rtIdx & (rt < rtIdx+(500/20)); 
        rIdx = rt <= (rtIdx +(rtWindowSize/20)); 
    % if not the min and not the max, normal 500 ms window: 
    elseif rtIdx < max(rtBins)
        rIdx = (rt >= rtIdx) & (rt < rtIdx+(rtWindowSize/20)); 
    % the max should catch all above: 
    else
        rIdx = rt >= rtIdx;
    end
    % RT, aligned to MO
    LFR_rt_MO(rtCount,:,:) = squeeze(nanmean(psthMO(rIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_rt_MO(rtCount,:,:) = squeeze(nanmean(psthMO(rIdx & (tgt == 4),:,:),1));
    UFR_rt_MO(rtCount,:,:) = squeeze(nanmean(psthMO(rIdx & (tgt == 1),:,:),1));
    DFR_rt_MO(rtCount,:,:) = squeeze(nanmean(psthMO(rIdx & (tgt == 2),:,:),1));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_rt_MO(rtCount,:) = squeeze(nanmean(abs(UFR_rt_MO(rtCount,:,:) - DFR_rt_MO(rtCount,:,:)),3));
    diffLR_rt_MO(rtCount,:) = squeeze(nanmean(abs(LFR_rt_MO(rtCount,:,:) - RFR_rt_MO(rtCount,:,:)),3));
    % still RT, now aligned to SO
    LFR_rt_SO(rtCount,:,:) = squeeze(nanmean(psthSO(rIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_rt_SO(rtCount,:,:) = squeeze(nanmean(psthSO(rIdx & (tgt == 4),:,:),1));
    UFR_rt_SO(rtCount,:,:) = squeeze(nanmean(psthSO(rIdx & (tgt == 1),:,:),1));
    DFR_rt_SO(rtCount,:,:) = squeeze(nanmean(psthSO(rIdx & (tgt == 2),:,:),1));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_rt_SO(rtCount,:) = squeeze(nanmean(abs(UFR_rt_SO(rtCount,:,:) - DFR_rt_SO(rtCount,:,:)),3));
    diffLR_rt_SO(rtCount,:) = squeeze(nanmean(abs(LFR_rt_SO(rtCount,:,:) - RFR_rt_SO(rtCount,:,:)),3));
    % RT, aligned to TO
    LFR_rt_TO(rtCount,:,:) = squeeze(nanmean(psthTO(rIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_rt_TO(rtCount,:,:) = squeeze(nanmean(psthTO(rIdx & (tgt == 4),:,:),1));
    UFR_rt_TO(rtCount,:,:) = squeeze(nanmean(psthTO(rIdx & (tgt == 1),:,:),1));
    DFR_rt_TO(rtCount,:,:) = squeeze(nanmean(psthTO(rIdx & (tgt == 2),:,:),1));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_rt_TO(rtCount,:) = squeeze(nanmean(abs(UFR_rt_TO(rtCount,:,:) - DFR_rt_TO(rtCount,:,:)),3));
    diffLR_rt_TO(rtCount,:) = squeeze(nanmean(abs(LFR_rt_TO(rtCount,:,:) - RFR_rt_TO(rtCount,:,:)),3));
    
    subplot(4,3,1) % RT, stim onset aligned, up/down
        plot(windowEarlySO:windowLateSO, diffUD_rt_SO(rtCount,:) , 'Color', colorsRT{1}(rtCount,:), 'LineWidth',2)
        hold on;
    subplot(4,3,2) % RT, target onset aligned, up/down
        plot(windowEarlyTO:windowLateTO, diffUD_rt_TO(rtCount,:) , 'Color', colorsRT{1}(rtCount,:), 'LineWidth',2)
        hold on;
    subplot(4,3,3) % RT, move onset aligned, up/down
        plot(windowEarlyMO:windowLateMO, diffUD_rt_MO(rtCount,:) , 'Color', colorsRT{1}(rtCount,:), 'LineWidth',2)
        hold on;

    subplot(4,3,4) % RT, stim onset aligned, left/right
       plot(windowEarlySO:windowLateSO,  diffLR_rt_SO(rtCount,:) , 'Color', colorsRT{2}(rtCount,:), 'LineWidth',2)
       hold on;
    subplot(4,3,5) % RT, stim onset aligned, left/right
       plot(windowEarlyTO:windowLateTO,  diffLR_rt_TO(rtCount,:) , 'Color', colorsRT{2}(rtCount,:), 'LineWidth',2)
       hold on;   
    subplot(4,3,6) % RT, move onset aligned, left/right
       plot(windowEarlyMO:windowLateMO,  diffLR_rt_MO(rtCount,:) , 'Color', colorsRT{2}(rtCount,:), 'LineWidth',2)
       hold on;
end

subplot(4,3,1) % RT, stim onset aligned, up/down
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlySO:abs(windowEarlySO):windowLateSO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
    legend({num2str((rtBins.*20)')})
    axis([windowEarlySO windowLateSO -inf inf])
    
subplot(4,3,2) % RT, target onset aligned, up/down
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlyTO:abs(windowEarlyTO)/.5:windowLateTO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Target Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
    %legend({num2str((rtBins.*20)')})
    axis([windowEarlyTO windowLateTO -inf inf])
    
subplot(4,3,3) % RT, move onset aligned, up/down
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlyMO:abs(windowEarlyMO)/2.5:windowLateMO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Move Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
    %legend({num2str((rtBins.*20)')})
    axis([windowEarlyMO windowLateMO -inf inf])
    
subplot(4,3,4) % RT, stim onset aligned, left/right
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlySO:abs(windowEarlySO):windowLateSO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    legend({num2str((rtBins.*20)')})
    axis([windowEarlySO windowLateSO -inf inf])
subplot(4,3,5)
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlyTO:abs(windowEarlyTO)/.5:windowLateTO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Target Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    %legend({num2str((rtBins.*20)')})
    axis([windowEarlyTO windowLateTO -inf inf])
subplot(4,3,6)
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlyMO:abs(windowEarlyMO)/2.5:windowLateMO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Move Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    %legend({num2str((rtBins.*20)')})
    axis([windowEarlyMO windowLateMO -inf inf])
%legend({num2str((rtBins.*20)')})
%% coherence
    
cohCount = 0;
% rt goes fastest (highest coh) = dark blue, slowest (lowest coh) = yellow. 
colorsCoh = [{parula(length(usedCoh))}, {parula(length(usedCoh))}]; 

for cohIdx = (flipud(usedCoh))' %flipping = color coordination
    cohCount = cohCount + 1;
    cIdx = [coh == cohIdx];     
    % Coh, aligned to MO
    LFR_coh_MO(cohCount,:,:) = squeeze(nanmean(psthMO(cIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_coh_MO(cohCount,:,:) = squeeze(nanmean(psthMO(cIdx & (tgt == 4),:,:),1));
    UFR_coh_MO(cohCount,:,:) = squeeze(nanmean(psthMO(cIdx & (tgt == 1),:,:),1));
    DFR_coh_MO(cohCount,:,:) = squeeze(nanmean(psthMO(cIdx & (tgt == 2),:,:),1));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_coh_MO(cohCount,:) = squeeze(nanmean(abs(UFR_coh_MO(cohCount,:,:) - DFR_coh_MO(cohCount,:,:)),3));
    diffLR_coh_MO(cohCount,:) = squeeze(nanmean(abs(LFR_coh_MO(cohCount,:,:) - RFR_coh_MO(cohCount,:,:)),3));
    % still Coh, now aligned to SO
    LFR_coh_SO(cohCount,:,:) = squeeze(nanmean(psthSO(cIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_coh_SO(cohCount,:,:) = squeeze(nanmean(psthSO(cIdx & (tgt == 4),:,:),1));
    UFR_coh_SO(cohCount,:,:) = squeeze(nanmean(psthSO(cIdx & (tgt == 1),:,:),1));
    DFR_coh_SO(cohCount,:,:) = squeeze(nanmean(psthSO(cIdx & (tgt == 2),:,:),1));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_coh_SO(cohCount,:) = squeeze(nanmean(abs(UFR_coh_SO(cohCount,:,:) - DFR_coh_SO(cohCount,:,:)),3));
    diffLR_coh_SO(cohCount,:) = squeeze(nanmean(abs(LFR_coh_SO(cohCount,:,:) - RFR_coh_SO(cohCount,:,:)),3));
    % still Coh, now aligned to TO
    LFR_coh_TO(cohCount,:,:) = squeeze(nanmean(psthTO(cIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_coh_TO(cohCount,:,:) = squeeze(nanmean(psthTO(cIdx & (tgt == 4),:,:),1));
    UFR_coh_TO(cohCount,:,:) = squeeze(nanmean(psthTO(cIdx & (tgt == 1),:,:),1));
    DFR_coh_TO(cohCount,:,:) = squeeze(nanmean(psthTO(cIdx & (tgt == 2),:,:),1));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_coh_TO(cohCount,:) = squeeze(nanmean(abs(UFR_coh_TO(cohCount,:,:) - DFR_coh_TO(cohCount,:,:)),3));
    diffLR_coh_TO(cohCount,:) = squeeze(nanmean(abs(LFR_coh_TO(cohCount,:,:) - RFR_coh_TO(cohCount,:,:)),3));
    
    subplot(4,3,1+6) % coh, stim onset aligned, up/down
        plot(windowEarlySO:windowLateSO, diffUD_coh_SO(cohCount,:) , 'Color', colorsCoh{1}(cohCount,:), 'LineWidth',2)
        hold on;
    subplot(4,3,2+6) % coh, move onset aligned, up/down
        plot(windowEarlyTO:windowLateTO, diffUD_coh_TO(cohCount,:) , 'Color', colorsCoh{1}(cohCount,:), 'LineWidth',2)
        hold on;
    subplot(4,3,3+6) % coh, move onset aligned, up/down
        plot(windowEarlyMO:windowLateMO, diffUD_coh_MO(cohCount,:) , 'Color', colorsCoh{1}(cohCount,:), 'LineWidth',2)
        hold on;
        
    subplot(4,3,4+6) % coh, stim onset aligned, left/right
       plot(windowEarlySO:windowLateSO,  diffLR_coh_SO(cohCount,:) , 'Color', colorsCoh{2}(cohCount,:), 'LineWidth',2)
       hold on;
    subplot(4,3,5+6) % coh, move onset aligned, left/right
       plot(windowEarlyTO:windowLateTO,  diffLR_coh_TO(cohCount,:) , 'Color', colorsCoh{2}(cohCount,:), 'LineWidth',2)
       hold on;
    subplot(4,3,6+6) % coh, move onset aligned, left/right
       plot(windowEarlyMO:windowLateMO,  diffLR_coh_MO(cohCount,:) , 'Color', colorsCoh{2}(cohCount,:), 'LineWidth',2)
       hold on;
  
%     % plot number of trials per RT bin
%     subplot(2,2,4)
%     plot(cohIdx, sum(rIdx & ((tgt == 3)|(tgt == 4))), '*', 'Color', colorsRT{1}(cohCount,:), 'MarkerSize', 10); 
%     hold on;
%     
%     subplot(2,2,2)
%     plot(cohIdx, sum(rIdx & ((tgt == 1)|(tgt == 2))), '*', 'Color', colorsRT{2}(cohCount,:), 'MarkerSize', 10); 
%     hold on;
end

subplot(4,3,1+6) % RT, stim onset aligned, up/down
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlySO:abs(windowEarlySO):windowLateSO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
    legend({num2str((flipud(usedCoh)))})
    axis([windowEarlySO windowLateSO -inf inf])
    
subplot(4,3,2+6) % RT, move onset aligned, up/down
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlyTO:abs(windowEarlyTO)/.2:windowLateTO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Target Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
   % legend({num2str((usedCoh)')})
    axis([windowEarlyTO windowLateTO -inf inf])   
    
subplot(4,3,3+6) % RT, move onset aligned, up/down
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlyMO:abs(windowEarlyMO)/.5:windowLateMO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Move Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
   % legend({num2str((usedCoh)')})
    axis([windowEarlyMO windowLateMO -inf inf])

subplot(4,3,4+6) % RT, stim onset aligned, left/right
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlySO:abs(windowEarlySO):windowLateSO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    legend({num2str((flipud(usedCoh)))})
    axis([windowEarlySO windowLateSO -inf inf])
subplot(4,3,5+6)
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlyTO:abs(windowEarlyTO)/.2:windowLateTO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Target Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    %legend({num2str((usedCoh)')})
    axis([windowEarlyTO windowLateTO -inf inf])
    
subplot(4,3,6+6)
    line([0 0], [0 5], 'Color', 'k', 'LineWidth', 2);
    ax = gca;
    ax.XTick = [windowEarlyMO:abs(windowEarlyMO)/.5:windowLateMO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Move Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    %legend({num2str((usedCoh)')})
    axis([windowEarlyMO windowLateMO -inf inf])

bigfonts(14)

diffOut.UD_SO_coh =  diffUD_coh_SO;
diffOut.UD_MO_coh =  diffUD_coh_MO;
diffOut.LR_SO_coh =  diffLR_coh_SO;
diffOut.LR_MO_coh =  diffLR_coh_MO;

diffOut.UD_SO_rt =  diffUD_rt_SO;
diffOut.UD_MO_rt =  diffUD_rt_MO;
diffOut.LR_SO_rt =  diffLR_rt_SO;
diffOut.LR_MO_rt =  diffLR_rt_MO;

diffOut.parameters.windowEarlyMO = windowEarlyMO;   %ms before event onset / 20 ms per bin;
diffOut.parameters.windowLateMO  = windowLateMO;  % ms after event onset  / 20 ms per bin, should be all nan 
diffOut.parameters.windowEarlySO = windowEarlySO;   %ms before event onset / 20 ms per bin;
diffOut.parameters.windowLateSO  = windowLateSO;  %ms after event onset / 20 ms per bin;
diffOut.parameters.rtBins = rtBins;
diffOut.parameters.rtWindowSize = rtWindowSize; 