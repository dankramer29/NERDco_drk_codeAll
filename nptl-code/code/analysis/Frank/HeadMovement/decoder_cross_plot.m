function decoder_cross_plot( decOut, bNumPerTrial, trlCodes, trlCodesRemap, eventIdx, ...
    timeAxis, movTypes, movLegends, movTypeText, timeWindow, binMS )

    axHandles = zeros(length(movTypes), 4);
    yLims = [];
    decTitle = {'X','Y','Z','Rot'};
    
    figure('Position',[680          82        1075        1016]);
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
        
        for decDim=1:4
            axHandles(pIdx, decDim) = subplot(length(movTypes), 4, decDim + (pIdx-1)*4);
            hold on;
            for c=1:length(conAvg)
                plot(timeAxis, conAvg{c}(:,decDim),'LineWidth',1.5);
            end
            
            if decDim==4 && ~isempty(movLegends)
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
                title(decTitle{decDim});
                text(0.025,0.2,'Prep','Units','Normalized','FontSize',12);
                text(0.3,0.2,'Go','Units','Normalized','FontSize',12);
                text(0.7,0.2,'Return','Units','Normalized','FontSize',12);
            end
            if pIdx<length(movTypes)
                set(gca,'XTickLabels',[]);
            end
            if decDim==1
                text(-0.45,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
            end
        end
    end    
    
    finalLims = [min(yLims(:,1)), max(yLims(:,2))];
    for pIdx=1:length(movTypes)
        for decDim=1:4
            set(axHandles(pIdx, decDim), 'YLim', finalLims);
            set(axHandles(pIdx, decDim),'LineWidth',1.5,'YTick',[]);
        end
    end
end

