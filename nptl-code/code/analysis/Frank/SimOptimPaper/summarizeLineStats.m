function summarizeLineStats(resultsDir, modelTypes)
    ls = cell(length(modelTypes),1);
    for m=1:length(modelTypes)
        ls{m} = load([resultsDir 'figures/optiPaper/lineStats_' modelTypes{m} '.mat']); 
    end
    
    stats = {'Dial-in Time (s)','Translation Time (s)','Movement Time (s)','Path Efficiency'};
    
    figure('Position',[680   887   885   211]);
    for statType=1:length(stats)
        subplot(1,4,statType);
        hold on;
        
        mnValues = zeros(3,1);
        ciValues = zeros(3,2);
        for mType=1:3
            %mnValues(mType) = ls{mType}.MAE(statType,1);
            %ciValues(mType,:) = ls{mType}.MAE(statType,2:3);
            mnValues(mType) = ls{mType}.allR2(statType,1);
            ciValues(mType,:) = ls{mType}.allR2CI(statType,1,:);
        end
        
        bar(mnValues,'FaceColor',[0.8 0.8 0.8],'LineWidth',2);
        errorbar(1:3,mnValues,mnValues-ciValues(:,1),ciValues(:,2)-mnValues,'k.','LineWidth',2);
        set(gca,'XTick',1:3,'XTickLabels',{'Slowest','Median','Fastest'},'LineWidth',2,'FontSize',16,'XTickLabelRotation',45);
        title(stats{statType});
        ylabel('FVAF');
        ylim([0,1.0]);
    end
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'summaryLineStats_R2'],'svg');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'summaryLineStats_R2'],'fig');

    figure('Position',[680   887   885   211]);
    for statType=1:length(stats)
        subplot(1,4,statType);
        hold on;
        
        mnValues = zeros(3,1);
        ciValues = zeros(3,2);
        for mType=1:3
            mnValues(mType) = ls{mType}.MAE(statType,1);
            ciValues(mType,:) = ls{mType}.MAE(statType,2:3);
        end
        
        bar(mnValues,'FaceColor',[0.8 0.8 0.8],'LineWidth',2);
        errorbar(1:3,mnValues,mnValues-ciValues(:,1),ciValues(:,2)-mnValues,'k.','LineWidth',2);
        set(gca,'XTick',1:3,'XTickLabels',{'Slowest','Median','Fastest'},'LineWidth',2,'FontSize',16,'XTickLabelRotation',45);
        title(stats{statType});
        ylabel('MAE');
        if statType<4
            ylim([0,0.5]);
        else
            ylim([0,0.1]);
        end
    end
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'summaryLineStats_MAE'],'svg');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'summaryLineStats_MAE'],'fig');
   
%     for subIdx=1:3
%         figure
%         for statType=1:length(stats)
%             subplot(2,2,statType);
%             hold on;
% 
%             mnValues = zeros(3,1);
%             ciValues = zeros(3,2);
%             for mType=1:3
%                 mnValues(mType) = ls{mType}.mae_sub{subIdx}(statType,1);
%                 ciValues(mType,:) = ls{mType}.mae_sub{subIdx}(statType,2:3);
%             end
% 
%             bar(mnValues,'FaceColor',[0.8 0.8 0.8]);
%             errorbar(1:3,mnValues,mnValues-ciValues(:,1),ciValues(:,2)-mnValues,'k.','LineWidth',2);
%         end
%     end
end

