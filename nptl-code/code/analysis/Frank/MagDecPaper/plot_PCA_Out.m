function plot_PCA_Out( pcaOut, pcaColors, lineStyles, timeAxis, plotRecon, backgroundSignal )
    nCon = size(pcaOut.Z_pca,2);
    yLimits = zeros(4,2,2);
    if nargin<6
        backgroundSignal = [];
    end

    figure('Position',[96   430   337   510]);
    for c=1:4
        for colIdx=1:2
            pcaDim = 2*(c-1)+colIdx;
            
            subtightplot(4,2,pcaDim,[0.01 0.03],[0.1 0.01],[0.01 0.01]);
            hold on
            
            target = squeeze(pcaOut.Z_pca(pcaDim,:,:))';
            target = target(:);
            paStack = [];
            for d=1:4
                tmp = squeeze(pcaOut.popAverage(d,:,:))';
                paStack = [paStack, tmp(:)];
            end

            coef = paStack \ target;
            recon = paStack*coef;
            reconUnstack = reshape(recon, size(pcaOut.Z_pca,3), size(pcaOut.Z_pca,2));
                
            if plotRecon
                for n=1:nCon
                    plot(timeAxis, reconUnstack(:,n),'Color',pcaColors(n,:),'LineWidth',2,'LineStyle',lineStyles{n});
                end
            else
                for n=1:nCon
                    plot(timeAxis, squeeze(pcaOut.Z_pca(pcaDim,n,:)),'Color',pcaColors(n,:),'LineWidth',2,'LineStyle',lineStyles{n});
                end
            end
            
            set(gca,'XTickLabel',[]);
            set(gca,'YTickLabel',[],'YTick',[],'LineWidth',1.5);
            set(gca,'FontSize',16);
            axis tight;
            text(0.02, 0.8, [num2str(pcaOut.explVar_pca.componentVar(pcaDim),3) '%'], 'Units', 'normalized','FontSize',16);
            if isfield(pcaOut,'atten_pca')
                text(0.02, 0.6, num2str(pcaOut.atten_pca(pcaDim),2), 'Units', 'normalized','FontSize',16);
            end
            yLimits(c,colIdx,:) = get(gca,'YLim');
        end
    end
    
    fullLim = [min(yLimits(:)), max(yLimits(:))];
    for x=1:8
        subtightplot(4,2,x,[0.01 0.03],[0.1 0.01],[0.01 0.01]);
        hold on
        %plot([0 0],get(gca,'YLim'),'--k');
        plot([0 0],fullLim,'--k','LineWidth',1.5);
        if x==7 || x==8
            xlabel('Time (s)');
            set(gca,'XTick',[-1 0 1],'XTickLabel',[-1 0 1]);
        end
        ylim(fullLim);
        
        if ~isempty(backgroundSignal)
            plotBackgroundSignal(timeAxis, backgroundSignal);
        end
    end
end

