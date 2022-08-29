% averaging over all FR_diffs 
% assumes you called diffOut(sesh) = targFirst_FRdiff(); for all sessions
%% for HM, the first entry will only have coherences 4:end, not 0.4:end. Add nans to level it out
diffOut(1).UD_SO_coh = [nan(1,length(diffOut(1).UD_SO_coh(1,:))); diffOut(1).UD_SO_coh];
diffOut(1).UD_MO_coh = [nan(1,length(diffOut(1).UD_MO_coh(1,:))); diffOut(1).UD_MO_coh];
diffOut(1).LR_MO_coh = [nan(1,length(diffOut(1).LR_MO_coh(1,:))); diffOut(1).LR_MO_coh];
diffOut(1).LR_SO_coh = [nan(1,length(diffOut(1).LR_SO_coh(1,:))); diffOut(1).LR_SO_coh];
%% reshape the variables to average over sessions
UD_SO_coh = nan(size(diffOut(1).UD_SO_coh(1,:),1), length(diffOut), size(diffOut(1).UD_SO_coh(1,:),2));
UD_MO_coh = nan(size(diffOut(1).UD_MO_coh(1,:),1), length(diffOut), size(diffOut(1).UD_MO_coh(1,:),2));
LR_MO_coh = nan(size(diffOut(1).LR_MO_coh(1,:),1), length(diffOut), size(diffOut(1).LR_MO_coh(1,:),2));
LR_SO_coh = nan(size(diffOut(1).LR_SO_coh(1,:),1), length(diffOut), size(diffOut(1).LR_SO_coh(1,:),2));

UD_SO_rt = nan(size(diffOut(1).UD_SO_rt(1,:),1), length(diffOut), size(diffOut(1).UD_SO_rt(1,:),2));
UD_MO_rt = nan(size(diffOut(1).UD_MO_rt(1,:),1), length(diffOut), size(diffOut(1).UD_MO_rt(1,:),2));
LR_MO_rt = nan(size(diffOut(1).LR_MO_rt(1,:),1), length(diffOut), size(diffOut(1).LR_MO_rt(1,:),2));
LR_SO_rt = nan(size(diffOut(1).LR_SO_rt(1,:),1), length(diffOut), size(diffOut(1).LR_SO_rt(1,:),2));

for sesh = 1:length(diffOut)
    for cohCount = 1:size(diffOut(1).UD_SO_coh,1)
        UD_SO_coh(cohCount, sesh, :) = diffOut(sesh).UD_SO_coh(cohCount,:);
        UD_MO_coh(cohCount, sesh, :) = diffOut(sesh).UD_MO_coh(cohCount,:);
        LR_SO_coh(cohCount, sesh, :) = diffOut(sesh).LR_SO_coh(cohCount,:);
        LR_MO_coh(cohCount, sesh, :) = diffOut(sesh).LR_MO_coh(cohCount,:);
    end
    for rtCount = 1:size(diffOut(1).UD_SO_rt,1)
        UD_SO_rt(rtCount, sesh, :) = diffOut(sesh).UD_SO_rt(rtCount,:);
        UD_MO_rt(rtCount, sesh, :) = diffOut(sesh).UD_MO_rt(rtCount,:);
        LR_SO_rt(rtCount, sesh, :) = diffOut(sesh).LR_SO_rt(rtCount,:);
        LR_MO_rt(rtCount, sesh, :) = diffOut(sesh).LR_MO_rt(rtCount,:);
    end
end
%% average over sessions
windowEarly_MO = diffOut(1).parameters.windowEarly_MO;  %ms before event onset / 20 ms per bin;
windowLate_MO  = diffOut(1).parameters.windowLate_MO;  % ms after event onset  / 20 ms per bin, should be all nan 
windowEarly_SO = diffOut(1).parameters.windowEarly_SO;   %ms before event onset / 20 ms per bin;
windowLate_SO  = diffOut(1).parameters.windowLate_SO;  %ms after event onset / 20 ms per bin;
% ^ these should get returned in diffOut. 
figure;
% rt goes fastest (highest coh) = dark blue, slowest (lowest coh) = yellow. 
colorsRT = [{parula(size(diffOut(1).UD_SO_rt,1))}, {parula(size(diffOut(1).UD_SO_rt,1))}]; 
for rtCount = 1:size(diffOut(1).UD_SO_rt,1)
    subplot(4,2,1) % stim onset aligned, up/down
        SEM = nanstd(squeeze(UD_SO_rt(rtCount,:,:)))./sesh;
        errorbar(windowEarly_SO:windowLate_SO, nanmean(squeeze(UD_SO_rt(rtCount,:,:))) ,SEM, 'Color', colorsRT{1}(rtCount,:), 'LineWidth',2)
        hold on;
    subplot(4,2,2) % move onset aligned, up/down
        SEM = nanstd(squeeze(UD_MO_rt(rtCount,:,:)))./sesh;
        errorbar(windowEarly_MO:windowLate_MO, nanmean(squeeze(UD_MO_rt(rtCount,:,:))) , SEM, 'Color', colorsRT{1}(rtCount,:), 'LineWidth',2)
        hold on;

    subplot(4,2,3) % stim onset aligned, left/right
       SEM = nanstd(squeeze(LR_SO_rt(rtCount,:,:)))./sesh;
        errorbar(windowEarly_SO:windowLate_SO,  nanmean(squeeze(LR_SO_rt(rtCount,:,:))) , SEM, 'Color', colorsRT{2}(rtCount,:), 'LineWidth',2)
       hold on;
    subplot(4,2,4) % move onset aligned, left/right
       SEM = nanstd(squeeze(LR_MO_rt(rtCount,:,:)))./sesh;
        errorbar(windowEarly_MO:windowLate_MO,  nanmean(squeeze(LR_MO_rt(rtCount,:,:))) , SEM, 'Color', colorsRT{2}(rtCount,:), 'LineWidth',2)
       hold on;
end

subplot(4,2,1) % RT, stim onset aligned, up/down
    ax = gca;
    ax.XTick = [windowEarly_SO:abs(windowEarly_SO):windowLate_SO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
   % legend({num2str((rtBins.*20)')})
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
    %legend({num2str((rtBins.*20)')})
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
 
% coh
colorsCoh = [{parula(size(diffOut(1).UD_SO_coh,1))}, {parula(size(diffOut(1).UD_SO_coh,1))}]; 
for cohCount = 1:size(diffOut(1).UD_SO_coh,1)
   % cohCount = cohCount + 1;
   subplot(4,2,1+4) % stim onset aligned, up/down
        SEM = nanstd(squeeze(UD_SO_coh(cohCount,:,:)))./sesh;
        errorbar(windowEarly_SO:windowLate_SO, nanmean(squeeze(UD_SO_coh(cohCount,:,:))) ,SEM, 'Color', colorsCoh{1}(cohCount,:), 'LineWidth',2)
        hold on;
    subplot(4,2,2+4) % move onset aligned, up/down
        SEM = nanstd(squeeze(UD_MO_coh(cohCount,:,:)))./sesh;
        errorbar(windowEarly_MO:windowLate_MO, nanmean(squeeze(UD_MO_coh(cohCount,:,:))) , SEM, 'Color', colorsCoh{1}(cohCount,:), 'LineWidth',2)
        hold on;

    subplot(4,2,3+4) % stim onset aligned, left/right
       SEM = nanstd(squeeze(LR_SO_coh(cohCount,:,:)))./sesh;
        errorbar(windowEarly_SO:windowLate_SO,  nanmean(squeeze(LR_SO_coh(cohCount,:,:))) , SEM, 'Color', colorsCoh{2}(cohCount,:), 'LineWidth',2)
       hold on;
    subplot(4,2,4+4) % move onset aligned, left/right
       SEM = nanstd(squeeze(LR_MO_coh(cohCount,:,:)))./sesh;
        errorbar(windowEarly_MO:windowLate_MO,  nanmean(squeeze(LR_MO_coh(cohCount,:,:))) , SEM, 'Color', colorsCoh{2}(cohCount,:), 'LineWidth',2)
       hold on;
end

subplot(4,2,1+4) % RT, stim onset aligned, up/down
    ax = gca;
    ax.XTick = [windowEarly_SO:abs(windowEarly_SO):windowLate_SO];
    ax.XTickLabel = ax.XTick.*20;
    xlabel('Time from Stim Onset (ms)');
    ylabel('Delta Population FR (Hz)');
    title('Delta Population FR, Up-Down Targets')
   % legend({num2str((flipud(usedCoh)))})
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
    %legend({num2str((flipud(usedCoh)))})
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