function diffOut = targFirst_FRdiff(binnedR_All, rtBins, rtWindowSize)
% plot aligned to movement and stim in the same figure 
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
windowEarly_MO = -1500/20;   %ms before event onset / 20 ms per bin;
windowLate_MO  = 200/20;  % ms after event onset  / 20 ms per bin, should be all nan 
windowEarly_SO = -200/20;   %ms before event onset / 20 ms per bin;
windowLate_SO  = 2500/20;  %ms after event onset / 20 ms per bin;

iti = binnedR_All.state; %state values
iti(iti < 17.5) = nan; 

% get indices for where trials started- and iti precedes every trial (yes, even the first one in a block)
itiIdx = find(~isnan(iti)); %the indices for where ITI is in R struct
trialStartIdx = itiIdx(diff(itiIdx) > 1); % using the face that itiIdx is off by 1 length to our advantage
testSpikes = binnedR_All.zSpikes;
%testSpikes = binnedR_All.rawSpikes;
%testSpikes = binnedR_All.meanSSpikes;
binnedR_All.badMO = binnedR_All.speedMO; %SF doesn't like speedMO atm. save it and put it back later
binnedR_All.speedMO = binnedR_All.moveOnset; 

for trial = 1:length(binnedR_All.stimOnset) %length(trialStartIdx)
    if ~isnan(binnedR_All.stimOnset(trial))
        if trial < length(binnedR_All.stimOnset) %length(trialStartIdx)
            testSpikes(binnedR_All.speedMO(trial):trialStartIdx(trial+1),:) = nan;
        else
            testSpikes(binnedR_All.speedMO(trial):end,:) = nan;
        end
             preFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.stimOnset(trial)-5:binnedR_All.stimOnset(trial),:));
             postFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.stimOnset(trial)+5:binnedR_All.stimOnset(trial)+10,:));
           %  windowedFR(trial, :) = nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate,:));
            tgt(trial) = binnedR_All.tgt(trial);
            coh(trial) = binnedR_All.uCoh(trial);
            rt(trial)  = binnedR_All.moveOnset(trial) - binnedR_All.stimOnset(trial); %binnedR_All.speedRT(trial);
    end
end
tgt(isnan(coh)) = [];
rt(isnan(coh)) = [];
coh(isnan(coh)) = [];
usedCoh = unique(coh); 

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
psthMO = nan(length(binnedR_All.tgt), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx)); 
psthSO = nan(length(binnedR_All.tgt), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
        psthMO(trial,:,:) = testSpikes((binnedR_All.speedMO(trial)+windowEarly_MO):(binnedR_All.speedMO(trial)+windowLate_MO), unitsIdx).*50; %in hz
        psthSO(trial,:,:) = testSpikes((binnedR_All.stimOnset(trial)+windowEarly_SO):(binnedR_All.stimOnset(trial)+windowLate_SO), unitsIdx).*50; %in hz
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
LFR_rt_MO = nan(length(rtBins), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx));
RFR_rt_MO = nan(length(rtBins), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx));
UFR_rt_MO = nan(length(rtBins), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx));
DFR_rt_MO = nan(length(rtBins), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx));
diffUD_rt_MO = nan(length(rtBins), 1+windowLate_MO-windowEarly_MO);
diffLR_rt_MO = nan(length(rtBins), 1+windowLate_MO-windowEarly_MO); 
% stim onset aligned
LFR_rt_SO = nan(length(rtBins), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
RFR_rt_SO = nan(length(rtBins), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
UFR_rt_SO = nan(length(rtBins), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
DFR_rt_SO = nan(length(rtBins), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
diffUD_rt_SO = nan(length(rtBins), 1+windowLate_SO-windowEarly_SO);
diffLR_rt_SO = nan(length(rtBins), 1+windowLate_SO-windowEarly_SO); 
%% Coh, movement onset aligned 
LFR_coh_MO = nan(length(usedCoh), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx));
RFR_coh_MO = nan(length(usedCoh), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx));
UFR_coh_MO = nan(length(usedCoh), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx));
DFR_coh_MO = nan(length(usedCoh), 1+windowLate_MO-windowEarly_MO, sum(unitsIdx));
diffUD_coh_MO = nan(length(usedCoh), 1+windowLate_MO-windowEarly_MO);
diffLR_coh_MO = nan(length(usedCoh), 1+windowLate_MO-windowEarly_MO); 
% stim onset aligned
LFR_coh_SO = nan(length(usedCoh), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
RFR_coh_SO = nan(length(usedCoh), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
UFR_coh_SO = nan(length(usedCoh), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
DFR_coh_SO = nan(length(usedCoh), 1+windowLate_SO-windowEarly_SO, sum(unitsIdx));
diffUD_coh_SO = nan(length(usedCoh), 1+windowLate_SO-windowEarly_SO);
diffLR_coh_SO = nan(length(usedCoh), 1+windowLate_SO-windowEarly_SO); 
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
    LFR_rt_MO(rtCount,:,:) = squeeze(mean(psthMO(rIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_rt_MO(rtCount,:,:) = squeeze(mean(psthMO(rIdx & (tgt == 4),:,:),1));
    UFR_rt_MO(rtCount,:,:) = squeeze(mean(psthMO(rIdx & (tgt == 1),:,:),1));
    DFR_rt_MO(rtCount,:,:) = squeeze(mean(psthMO(rIdx & (tgt == 2),:,:),1));
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

    subplot(4,2,1) % RT, stim onset aligned, up/down
        plot(windowEarly_SO:windowLate_SO, diffUD_rt_SO(rtCount,:) , 'Color', colorsRT{1}(rtCount,:), 'LineWidth',2)
        hold on;
    subplot(4,2,2) % RT, move onset aligned, up/down
        plot(windowEarly_MO:windowLate_MO, diffUD_rt_MO(rtCount,:) , 'Color', colorsRT{1}(rtCount,:), 'LineWidth',2)
        hold on;

    subplot(4,2,3) % RT, stim onset aligned, left/right
       plot(windowEarly_SO:windowLate_SO,  diffLR_rt_SO(rtCount,:) , 'Color', colorsRT{2}(rtCount,:), 'LineWidth',2)
       hold on;
    subplot(4,2,4) % RT, move onset aligned, left/right
       plot(windowEarly_MO:windowLate_MO,  diffLR_rt_MO(rtCount,:) , 'Color', colorsRT{2}(rtCount,:), 'LineWidth',2)
       hold on;
end

subplot(4,2,1) % RT, stim onset aligned, up/down
    ax = gca;
    ax.XTick = [windowEarly_SO:abs(windowEarly_SO):windowLate_SO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
    legend({num2str((rtBins.*20)')})
    axis([windowEarly_SO windowLate_SO -inf inf])
    
subplot(4,2,2) % RT, move onset aligned, up/down
    ax = gca;
    ax.XTick = [windowEarly_MO:abs(windowEarly_MO)/2.5:windowLate_MO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Move Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
    %legend({num2str((rtBins.*20)')})
    axis([windowEarly_MO windowLate_MO -inf inf])

subplot(4,2,3) % RT, stim onset aligned, left/right
    ax = gca;
    ax.XTick = [windowEarly_SO:abs(windowEarly_SO):windowLate_SO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    legend({num2str((rtBins.*20)')})
    axis([windowEarly_SO windowLate_SO -inf inf])
subplot(4,2,4)
    ax = gca;
    ax.XTick = [windowEarly_MO:abs(windowEarly_MO)/2.5:windowLate_MO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Move Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    %legend({num2str((rtBins.*20)')})
    axis([windowEarly_MO windowLate_MO -inf inf])

%legend({num2str((rtBins.*20)')})
%% coherence
    
cohCount = 0;
% rt goes fastest (highest coh) = dark blue, slowest (lowest coh) = yellow. 
colorsCoh = [{parula(length(usedCoh))}, {parula(length(usedCoh))}]; 

for cohIdx = (flipud(usedCoh))' %flipping = color coordination
    cohCount = cohCount + 1;
    cIdx = [coh == cohIdx];     
    % Coh, aligned to MO
    LFR_coh_MO(cohCount,:,:) = squeeze(mean(psthMO(cIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_coh_MO(cohCount,:,:) = squeeze(mean(psthMO(cIdx & (tgt == 4),:,:),1));
    UFR_coh_MO(cohCount,:,:) = squeeze(mean(psthMO(cIdx & (tgt == 1),:,:),1));
    DFR_coh_MO(cohCount,:,:) = squeeze(mean(psthMO(cIdx & (tgt == 2),:,:),1));
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
    
    subplot(4,2,1+4) % RT, stim onset aligned, up/down
        plot(windowEarly_SO:windowLate_SO, diffUD_coh_SO(cohCount,:) , 'Color', colorsCoh{1}(cohCount,:), 'LineWidth',2)
        hold on;
    subplot(4,2,2+4) % RT, move onset aligned, up/down
        plot(windowEarly_MO:windowLate_MO, diffUD_coh_MO(cohCount,:) , 'Color', colorsCoh{1}(cohCount,:), 'LineWidth',2)
        hold on;

    subplot(4,2,3+4) % RT, stim onset aligned, left/right
       plot(windowEarly_SO:windowLate_SO,  diffLR_coh_SO(cohCount,:) , 'Color', colorsCoh{2}(cohCount,:), 'LineWidth',2)
       hold on;
    subplot(4,2,4+4) % RT, move onset aligned, left/right
       plot(windowEarly_MO:windowLate_MO,  diffLR_coh_MO(cohCount,:) , 'Color', colorsCoh{2}(cohCount,:), 'LineWidth',2)
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

subplot(4,2,1+4) % RT, stim onset aligned, up/down
    ax = gca;
    ax.XTick = [windowEarly_SO:abs(windowEarly_SO):windowLate_SO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
    legend({num2str((flipud(usedCoh)))})
    axis([windowEarly_SO windowLate_SO -inf inf])
    
subplot(4,2,2+4) % RT, move onset aligned, up/down
    ax = gca;
    ax.XTick = [windowEarly_MO:abs(windowEarly_MO)/2.5:windowLate_MO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Move Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
   % legend({num2str((usedCoh)')})
    axis([windowEarly_MO windowLate_MO -inf inf])

subplot(4,2,3+4) % RT, stim onset aligned, left/right
    ax = gca;
    ax.XTick = [windowEarly_SO:abs(windowEarly_SO):windowLate_SO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    legend({num2str((flipud(usedCoh)))})
    axis([windowEarly_SO windowLate_SO -inf inf])
subplot(4,2,4+4)
    ax = gca;
    ax.XTick = [windowEarly_MO:abs(windowEarly_MO)/2.5:windowLate_MO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Move Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Left-Right Targets')
    %legend({num2str((usedCoh)')})
    axis([windowEarly_MO windowLate_MO -inf inf])

bigfonts(14)

diffOut.UD_SO_coh =  diffUD_coh_SO;
diffOut.UD_MO_coh =  diffUD_coh_MO;
diffOut.LR_SO_coh =  diffLR_coh_SO;
diffOut.LR_MO_coh =  diffLR_coh_MO;

diffOut.UD_SO_rt =  diffUD_rt_SO;
diffOut.UD_MO_rt =  diffUD_rt_MO;
diffOut.LR_SO_rt =  diffLR_rt_SO;
diffOut.LR_MO_rt =  diffLR_rt_MO;

diffOut.parameters.windowEarly_MO = windowEarly_MO;   %ms before event onset / 20 ms per bin;
diffOut.parameters.windowLate_MO  = windowLate_MO;  % ms after event onset  / 20 ms per bin, should be all nan 
diffOut.parameters.windowEarly_SO = windowEarly_SO;   %ms before event onset / 20 ms per bin;
diffOut.parameters.windowLate_SO  = windowLate_SO;  %ms after event onset / 20 ms per bin;
diffOut.parameters.rtBins = rtBins;
diffOut.parameters.rtWindowSize = rtWindowSize; 