function dPCA_sweep_plot( dPCA_out, timeAxis, movTypeText, movLegends )

    yLims = [];
    axHandles=[];
    plotIdx = 1;
    topN = 8;

    figure('Position',[272         108        1551         997]);
    for pIdx=1:length(dPCA_out)
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        for c=1:topN
            axHandles(plotIdx) = subtightplot(length(dPCA_out),topN,(pIdx-1)*topN+c);
            hold on

            colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
            for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
            end

            axis tight;
            yLims = [yLims; get(gca,'YLim')];
            plotIdx = plotIdx + 1;

            plot(get(gca,'XLim'),[0 0],'k');
            plot([0, 0],[-100, 100],'--k');
            if ismember(pIdx,[3 4])
                plot([2.5, 2.5],[-100, 100],'--k');
            elseif ismember(pIdx,[1 2 5 6])
                plot([1.5, 1.5],[-100, 100],'--k');
            end
            set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);
            
            if pIdx==length(dPCA_out)
                xlabel('Time (s)');
            else
                set(gca,'XTick',[]);
            end
            if pIdx==1
                text(0.025,0.8,'Prep','Units','Normalized','FontSize',12);
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);
                text(0.7,0.8,'Return','Units','Normalized','FontSize',12);
                title(['Condition-Dependent Dim ' num2str(c)],'FontSize',11)
            elseif pIdx==7
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);
            end

            if c==1
                text(-0.45,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
            end
            if c==topN
                lHandle = legend(movLegends{pIdx});
                lPos = get(lHandle,'Position');
                lPos(1) = lPos(1)+0.05;
                set(lHandle,'Position',lPos);
            end
        end
    end

    finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
    for p=1:length(axHandles)
        set(axHandles(p), 'YLim', finalLimits);
    end
end

