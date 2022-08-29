% calculate difference per target by unit, calc slopes for those
% note: psth is from frDiff_scratch and has nans for spikes after movement
% onset! 40 ms before stim onset : 1.5 sec after
figure;
cohColors = [255,255,204;...
    199,233,180;...
    127,205,187;...
    65,182,196;...
    29,145,192;...
    34,94,168;...
    12,44,132]./255;
psthSO = psth; 
%%
psthMO = nan(size(psth)); 
for trial = 1:length(tgt)
    psthMO(trial, :, :) = testSpikes(binnedR_All.speedMO(trial) - windowLate-1:binnedR_All.speedMO(trial) - windowEarly -1,unitsIdx);
end
%%
for unit = 1:length(unitsIdx)
    cohCount = 0;
    for cohIdx = unique(coh)'
        cohCount = cohCount + 1;
    subplot(3,3,2)
    plot(nanmean(psthMO((tgt == 1) & (coh == cohIdx),:,unit)), 'Color', cohColors(cohCount,:),'LineWidth', 2);
    hold on;
    
    subplot(3,3,4)
    plot(nanmean(psthMO((tgt == 3) & (coh == cohIdx),:,unit)), 'Color', cohColors(cohCount,:),'LineWidth', 2);
    hold on;
    
    subplot(3,3,6)
    plot(nanmean(psthMO((tgt == 4) & (coh == cohIdx),:,unit)), 'Color', cohColors(cohCount,:),'LineWidth', 2);
    hold on;
    
    subplot(3,3,8)
    plot(nanmean(psthMO((tgt == 2) & (coh == cohIdx),:,unit)), 'Color', cohColors(cohCount,:),'LineWidth', 2);
    hold on;
    end
    subplot(3,3,2)
    hold off;
    subplot(3,3,4)
    hold off;
    subplot(3,3,6)
    hold off;
    subplot(3,3,8)
    hold off;
    pause
end