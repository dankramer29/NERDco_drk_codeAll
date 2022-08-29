function decoder_cross_plot_norm( decOut, bNumPerTrial, trlCodes, trlCodesRemap, eventIdx, ...
    timeAxis, movTypes, movLegends, movTypeText, timeWindow, binMS )

    axHandles = zeros(length(movTypes), 1);
    yLims = [];
    
    figure('Position',[180   113   458   992]);
    for pIdx = 1:size(movTypes,1)
        trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
        if strcmp(movTypes{pIdx,2},'cursor_CL')
            %ignore return
            trlIdx(trlCodes(trlIdx)>9)=false;
        end
       
        trlIdx = find(trlIdx);
        tmpCodes = trlCodesRemap(trlIdx);
        codeList = unique(tmpCodes);
        conAvg = cell(length(codeList),1);
        
        for c=1:length(codeList)
            innerIdx = find(tmpCodes == codeList(c));
            ta = triggeredAvg(decOut, eventIdx(trlIdx(innerIdx)), timeWindow/binMS);
            conAvg{c} = squeeze(mean(ta));
        end
        
        axHandles(pIdx) = subplot(length(movTypes), 1, pIdx);
        hold on;
        for c=1:length(conAvg)
            plot(timeAxis, matVecMag(conAvg{c},2),'LineWidth',1.5);
        end

        if ~isempty(movLegends)
            lHandle = legend(movLegends{pIdx},'AutoUpdate','off');
            lPos = get(lHandle,'Position');
            lPos(1) = lPos(1)+0.05;
            set(lHandle,'Position',lPos);
        end

        axis tight;
        yLims = [yLims; get(gca,'YLim')];

        plot(get(gca,'XLim'),[0 0],'k');
        plot([0, 0],[-100, 100],'--k');
        if ismember(pIdx,[3 4])
            plot([2.5, 2.5],[-100, 100],'--k');
        elseif ismember(pIdx,[1 2 5 6])
            plot([1.5, 1.5],[-100, 100],'--k');
        end

        set(gca,'FontSize',14);
        if pIdx==1
            text(0.025,0.2,'Prep','Units','Normalized','FontSize',12);
            text(0.3,0.2,'Go','Units','Normalized','FontSize',12);
            text(0.7,0.2,'Return','Units','Normalized','FontSize',12);
        end
        if pIdx<length(movTypes)
            set(gca,'XTickLabels',[]);
        end
        text(-0.15,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
    end    
    
    finalLims = [min(yLims(:,1)), max(yLims(:,2))];
    for pIdx=1:length(movTypes)
        set(axHandles(pIdx), 'YLim', finalLims);
        set(axHandles(pIdx),'LineWidth',1.5,'YTick',[]);
    end
    
    %%
    %all on same plot
    colors = jet(size(movTypes,1))*0.8;
    
    figure
    hold on
    for pIdx = 1:size(movTypes,1)
        trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
        if strcmp(movTypes{pIdx,2},'cursor_CL')
            %ignore return
            trlIdx(trlCodes(trlIdx)>9)=false;
        end
       
        trlIdx = find(trlIdx);
        tmpCodes = trlCodesRemap(trlIdx);
        codeList = unique(tmpCodes);
        conAvg = cell(length(codeList),1);
        
        for c=1:length(codeList)
            innerIdx = find(tmpCodes == codeList(c));
            ta = triggeredAvg(decOut, eventIdx(trlIdx(innerIdx)), timeWindow/binMS);
            conAvg{c} = squeeze(mean(ta));
        end
        
        normLines = [];
        for c=1:length(conAvg)
            normLines = [normLines; matVecMag(conAvg{c},2)'];
        end
        meanLine = nanmean(normLines);
        meanLine = meanLine - nanmean(meanLine(1:100));
        
        plot(timeAxis, meanLine, 'Color', colors(pIdx,:), 'LineWidth', 2);

        set(gca,'FontSize',14);
        if pIdx==1
            text(0.025,0.2,'Prep','Units','Normalized','FontSize',12);
            text(0.3,0.2,'Go','Units','Normalized','FontSize',12);
            text(0.7,0.2,'Return','Units','Normalized','FontSize',12);
        end
    end   
    legend(movTypeText,'AutoUpdate','off');
    axis tight;
    
    plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
    plot([2.5, 2.5],get(gca,'YLim'),'--k','LineWidth',2);
    plot([1.5, 1.5],get(gca,'YLim'),'--k','LineWidth',2);
        
    xlabel('Time');
    ylabel('Neural Push');
    set(gca,'FontSize',16,'LineWidth',2);
end

