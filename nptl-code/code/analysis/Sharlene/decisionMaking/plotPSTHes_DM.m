function plotPSTHes_DM(psth, date)
%% plot em
cd( ['Users/sharlene/CachedData/t5.', date, '/'])
cohColors = [255,255,204;...
    199,233,180;...
    127,205,187;...
    65,182,196;...
    29,145,192;...
    34,94,168;...
    12,44,132]./255;
keepIdx = zeros(1,192);
for unit = 1:192
    ymax = max([max(max(squeeze(psth(unit, 1, :, :))'./count(1,:))), max(max(squeeze(psth(unit, 2, :, :))'./count(2,:))),...
        max(max(squeeze(psth(unit, 3, :, :))'./count(3,:))), max(max(squeeze(psth(unit, 4, :, :))'./count(4,:)))]);
    if ymax > 4
        figure;
        for cIdx = 1:size(psth,3)
            subplot(3,3,2)
            ax = gca;
            ax.ColorOrderIndex = cIdx;
            plot(squeeze(psth(unit, 1, cIdx, :))./count(1,cIdx), 'LineWidth', 2, 'Color', cohColors(cIdx,:))
            hold on;
            %line([75 75], [0 max(squeeze(psth(unit, 1, cIdx, :))./count(1,cIdx))], 'Color', 'r')
            line([75 75], [0 ymax], 'Color', 'r')
            ax.XTick = 0:25:125;
            ax.XTickLabel = [-75:25:50].*20;
            %axis tight;
            axis([0 126 0 ymax])
            title(['Unit #', num2str(unit)]);
            
            subplot(3,3,4)
            ax = gca;
            ax.ColorOrderIndex = cIdx;
            plot(squeeze(psth(unit, 4, cIdx, :))./count(4,cIdx), 'LineWidth', 2, 'Color', cohColors(cIdx,:))
            hold on;
            %line([75 75], [0 max(squeeze(psth(unit, 4, cIdx, :))./count(4,cIdx))], 'Color', 'r')
            % line([75 75], [0 ymax], 'Color', 'r')
            ax.XTick = 0:25:125;
            ax.XTickLabel = [-75:25:50].*20;
            axis([0 126 0 ymax])
            
            subplot(3,3,6)
            ax = gca;
            ax.ColorOrderIndex = cIdx;
            plot(squeeze(psth(unit, 3, cIdx, :))./count(3,cIdx), 'LineWidth', 2, 'Color', cohColors(cIdx,:))
            hold on;
            %line([75 75], [0 max(squeeze(psth(unit, 3, cIdx, :))./count(3,cIdx))], 'Color', 'r')
            line([75 75], [0 ymax], 'Color', 'r')
            ax.XTick = 0:25:125;
            ax.XTickLabel = [-75:25:50].*20;
            axis([0 126 0 ymax])
            
            subplot(3,3,8)
            ax = gca;
            ax.ColorOrderIndex = cIdx;
            plot(squeeze(psth(unit, 2, cIdx, :))./count(2,cIdx), 'LineWidth', 2, 'Color', cohColors(cIdx,:))
            hold on;
            % line([75 75], [0 max(squeeze(psth(unit, 2, cIdx, :))./count(2,cIdx))], 'Color', 'r')
            line([75 75], [0 ymax], 'Color', 'r')
            ax.XTick = 0:25:125;
            ax.XTickLabel = [-75:25:50].*20;
            axis([0 126 0 ymax])
            xlabel('Time to Movement Onset (ms)')
        end
        
        subplot(3,3,4)
        line([75 75], [0 ymax], 'Color', 'r')
        legend([num2str(round(UCohIdx.*100)); 'MO'])
        
        keepIdx(unit) = input('Is it a keeper? 1 = y/0 = n: ');
        if keepIdx(unit)
            print(['unit', num2str(unit), '_HM0418'], '-fillpage', '-dpdf');
        end
        close all;
    end
end