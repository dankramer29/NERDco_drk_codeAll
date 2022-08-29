acc = cell(4,1);
bitRate = cell(4,1);

%1: single, 2: dual, 3: quad, 4: 32 target

%%
%accuracy
acc{1} = [[0.9424    0.9249    0.9568];
    [0.8588    0.8341    0.8810];
    [0.9356    0.9174    0.9509]];
acc{2} = [[0.8384    0.8125    0.8621];
    [0.8847    0.8619    0.9050];
    [0.8147    0.7875    0.8398]];
acc{3} = [[0.8316    0.8053    0.8557];
    [0.8689    0.8449    0.8905];
    [0.8802    0.8570    0.9009]];
acc{4} = [[0.9449    0.9208    0.9634];
    [0.9469    0.9232    0.9650];
    [0.9449    0.9208    0.9634]];

%%
%bit rate
bitRate{1} = [[2.0420    1.9614    2.1085];
    [1.6560    1.5420    1.7589];
    [2.0107    1.9265    2.0811]];
bitRate{2} = [[2.3274    2.1490    2.4901];
    [2.6460    2.4885    2.7856];
    [2.1642    1.9772    2.3367]];
bitRate{3} = [[2.5758    2.3714    2.7628];
    [2.8654    2.6787    3.0327];
    [2.9532    2.7727    3.1136]];
bitRate{4} = [[1.4679    1.3885    1.5289];
    [1.4746    1.3964    1.5344];
    [1.4679    1.3885    1.5289]];

projected_br = bitRate{4}*3;

%%
metrics = {bitRate, acc};
mNames = {'Achieved\newlineBit Rate (bps)','Accuracy'};
taskNames = {'Single 6','Dual 6','Quad 4','32 Target'};
yLimits = {[0.0,4.7],[0.0 1.0]};

figure('Position',[680   839   599   259]);
for m=1:length(metrics)
    subplot(1,2,m);
    hold on;
    
    metric = metrics{m};
    for taskIdx=1:length(metric)
        bar(taskIdx, mean(metric{taskIdx}(:,1)),'FaceColor','w','LineWidth',2);
        for entry=1:size(metric{taskIdx},1)
            offset = (entry-2)*0.1;
            plot(taskIdx+offset, metric{taskIdx}(entry,1), 'ko','LineWidth',2);
            plot([taskIdx, taskIdx]+offset, [metric{taskIdx}(entry,2), metric{taskIdx}(entry,3)],'k','LineWidth',2);
        end
    end
    
    %plot projected bit rate
    if m==1
        taskIdx = 4;
        for entry=1:size(projected_br,1)
            offset = (entry-2)*0.1;
            plot(taskIdx+offset, projected_br(entry,1), 'o','LineWidth',2,'Color',[0.6 0.6 0.6]);
            plot([taskIdx, taskIdx]+offset, [projected_br(entry,2), projected_br(entry,3)],'LineWidth',2,'Color',[0.6 0.6 0.6]);
        end        
    end
    
    set(gca,'XTick',1:4,'XTickLabel',taskNames,'XTickLabelRotation',45);
    ylabel(mNames{m});
    set(gca,'FontSize',16,'LineWidth',1);
    xlim([0.5 4.5]);
    ylim(yLimits{m});
end

paths = getFRWPaths();
outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding'];
mkdir(outDir);
    
saveas(gcf,[outDir filesep 'statSummary.fig'],'fig');
saveas(gcf,[outDir filesep 'statSummary.svg'],'svg');
saveas(gcf,[outDir filesep 'statSummary.png'],'png');