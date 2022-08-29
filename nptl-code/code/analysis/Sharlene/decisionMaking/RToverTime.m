% load all data, calc RT by coh over time 
for i = 1:length(aggR)
    aggR(i).HM = [];
    aggR(i).HM = aggR(i).BC; 
end
close all
%%
meanRT = nan(length(unique(aggR(end).HM.uCoh)), length(aggR)); 
medianRT = nan(length(unique(aggR(end).HM.uCoh)), length(aggR)); 
stdRT =  nan(length(unique(aggR(end).HM.uCoh)), length(aggR)); 
% assumes you've run the HM part of aggDM.m
allCoh = unique([aggR(1).HM.uCoh, aggR(2).HM.uCoh]);
RTS = cell(1,length(allCoh));
%allCoh = unique(aggR.uCoh);
for sesh = 1:length(aggR)
   % figure;
    cohCount = 0;
for cohI = unique(allCoh)
    cohCount = cohCount + 1;
    subplot(length(allCoh), 1, cohCount)
    hold on;
    if any(aggR(sesh).HM.uCoh == cohI)
    h = histogram(aggR(sesh).HM.moveOnset(aggR(sesh).HM.uCoh == cohI)-aggR(sesh).HM.stimOnset(aggR(sesh).HM.uCoh == cohI));
    h.BinEdges = 0:10:450;
    ax = gca;
    ax.XTick = 0:50:450;            % bins
    ax.XTickLabel = ax.XTick .* 20; % 20 ms per bin
    meanRT(cohCount, sesh)   =   nanmean(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    medianRT(cohCount, sesh) = nanmedian(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    stdRT(cohCount, sesh)    =    nanstd(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    RTS{cohCount} = [RTS{cohCount}, aggR(sesh).HM.moveOnset(aggR(sesh).HM.uCoh == cohI)-aggR(sesh).HM.stimOnset(aggR(sesh).HM.uCoh == cohI)];
    end
end
end
%%
figure(1); 
figure(2);
for i = 1:length(RTS)
    figure(1)
    subplot(length(RTS), 1, i)
    h = histogram(RTS{i});
    h.BinEdges = 0:10:450;
    ax = gca;
    ax.XTick = 0:50:450;            % bins
    ax.XTickLabel = ax.XTick .* 20; % 20 ms per bin
    axis([0 5000/20 -inf inf])
    hold on;
    line([nanmean(RTS{i}), nanmean(RTS{i})], [0, max(h.BinCounts)], 'Color', 'k', 'LineWidth', 2); 
    line([nanmean(RTS{i}) - nanstd(RTS{i}), nanmean(RTS{i}) - nanstd(RTS{i})], [0, max(h.BinCounts)], 'Color', 'r', 'LineWidth', 2); 
    line([nanmean(RTS{i}) + nanstd(RTS{i}), nanmean(RTS{i}) + nanstd(RTS{i})], [0, max(h.BinCounts)], 'Color', 'r', 'LineWidth', 2); 
    title(['Coherence = ', num2str(allCoh(i))]);
    figure(2)
    %subplot(length(RTS), 1, i)
    ecdf(RTS{i});
    ax = gca;
    ax.XTick = 0:50:450;            % bins
    ax.XTickLabel = ax.XTick .* 20; % 20 ms per bin
    axis([0 5000/20 -inf inf])
    hold on;

%     line([nanmean(RTS{i}), nanmean(RTS{i})], [0, max(h.BinCounts)], 'Color', 'k', 'LineWidth', 2); 
%     line([nanmean(RTS{i}) - nanstd(RTS{i}), nanmean(RTS{i}) - nanstd(RTS{i})], [0, max(h.BinCounts)], 'Color', 'r', 'LineWidth', 2); 
%     line([nanmean(RTS{i}) + nanstd(RTS{i}), nanmean(RTS{i}) + nanstd(RTS{i})], [0, max(h.BinCounts)], 'Color', 'r', 'LineWidth', 2); 
%     title(['Coherence = ', num2str(allCoh(i))]);
end
figure(2)
    xlabel('RT (ms)')
    ylabel('Proportion of Trials')
    legend(num2str(allCoh'))
%% all coh grouped, subplot = session
figure;
% subplot(2,1,1)
plot(allCoh, medianRT, 'LineWidth', 2)
hold on;
ax = gca;
ax.ColorOrderIndex = 1;
plot(allCoh, meanRT, '--', 'LineWidth', 5)
ax.YTickLabel = ax.YTick.*20;
ylabel('Reaction Time (ms)');
%legend({dmDates, 'Means'})
% subplot(2,1,2)
%     plot(allCoh, stdRT, 'LineWidth', 2)
figure;
for sesh = 1:length(aggR)
    subplot(length(aggR), 1, sesh)
    cohCount = 0;
%for cohI = unique(allCoh)'
%    cohCount = cohCount + 1;
    
%    if any(aggR.uCoh == cohI)
    h = histogram(aggR(sesh).HM.moveOnset-aggR(sesh).HM.stimOnset);
    h.BinEdges = 0:5:450;
    ax = gca;
    ax.XTick = 0:50:450;            % bins
    ax.XTickLabel = ax.XTick .* 20; % 20 ms per bin
end
%% alternate view: 
figure;
%allCoh = unique([aggR(1).HM.uCoh; aggR(2).HM.uCoh]);
for sesh = 1:length(aggR)
    %figure;
    cohCount = 0;
for cohI = unique(allCoh)
    cohCount = cohCount + 1;
   % subplot(length(allCoh), 1, cohCount)
    if any(aggR(sesh).HM.uCoh == cohI)
    %h = histogram(aggR.moveOnset(aggR.uCoh == cohI)-aggR.stimOnset(aggR.uCoh == cohI));
    %h.BinEdges = 0:10:450;
    ecdf(aggR(sesh).HM.moveOnset(aggR(sesh).HM.uCoh == cohI)-aggR(sesh).HM.stimOnset(aggR(sesh).HM.uCoh == cohI))
    hold on;
    ax = gca;
    ax.XTick = 0:50:450;            % bins
    ax.XTickLabel = ax.XTick .* 20; % 20 ms per bin
    meanRT(cohCount, sesh) = nanmean(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    medianRT(cohCount, sesh) = nanmedian(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    stdRT(cohCount, sesh) = nanstd(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    axis([0 6000/20 0 1])
    end
end
end
%% now group by date, color = coh
figure;
allCoh = unique([aggR(1).HM.uCoh; aggR(2).HM.uCoh]);
for sesh = 1:length(aggR)
    %figure;
    cohCount = 0;
    subplot(length(aggR), 1, sesh)
for cohI = unique(allCoh)'
    cohCount = cohCount + 1;
    
    if any(aggR(sesh).HM.uCoh == cohI)
    %h = histogram(aggR.moveOnset(aggR.uCoh == cohI)-aggR.stimOnset(aggR.uCoh == cohI));
    %h.BinEdges = 0:10:450;
    ecdf(aggR(sesh).HM.moveOnset(aggR(sesh).HM.uCoh == cohI)-aggR(sesh).HM.stimOnset(aggR(sesh).HM.uCoh == cohI))
    hold on;
    ax = gca;
    ax.XTick = 0:50:450;            % bins
    ax.XTickLabel = ax.XTick .* 20; % 20 ms per bin
    meanRT(cohCount, sesh) = nanmean(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    medianRT(cohCount, sesh) = nanmedian(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    stdRT(cohCount, sesh) = nanstd(aggR(sesh).HM.speedRT(aggR(sesh).HM.uCoh == cohI)); 
    axis([0 6000/20 0 1])
    
    end
    title(dmDates(sesh))
end
end