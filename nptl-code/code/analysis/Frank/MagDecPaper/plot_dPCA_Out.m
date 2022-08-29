function coef = plot_dPCA_Out( pcaOut, pcaColors, lineStyles, timeAxis, plotRecon, zoomIn, backgroundSignal )
    if nargin<6
        zoomIn = false;
    end
    if nargin<7
        backgroundSignal = [];
    end
    
    nCon = size(pcaOut.Z,2);
    nRows = 4;
    firstDir = find(pcaOut.whichMarg==1);
    firstTime = find(pcaOut.whichMarg==2);
    firstDir = firstDir(1:min(7, length(firstDir)));
    firstTime = firstTime(1:min(7, length(firstTime)));
    axTypes = {firstDir, firstTime};
    yLimits = zeros(4,2,2);
    coef = cell(nRows, 2);

    figure('Position',[96   430   337   510]);
    
    for c=1:nRows
        for colIdx=1:2
            firstDim = axTypes{colIdx};
            subtightplot(nRows,2,2*(c-1)+colIdx,[0.01 0.03],[0.1 0.01],[0.01 0.01]);
            hold on
            if length(firstDim)>=c
                target = squeeze(pcaOut.Z(firstDim(c),:,51:end))';
                target = target(:);
                
                paStack = [];
                paStackFull = [];
                for d=1:4
                    tmp = squeeze(pcaOut.popAverage(d,:,51:end))';
                    tmpFull = squeeze(pcaOut.popAverage(d,:,:))';
                    paStack = [paStack, tmp(:)];
                    paStackFull = [paStackFull, tmpFull(:)];
                end

                coef{c, colIdx} = paStack \ target;
                recon = paStackFull*coef{c, colIdx};
                reconUnstack = reshape(recon, size(pcaOut.Z,3), size(pcaOut.Z,2));
                %reconUnstack = gaussSmooth_fast(reconUnstack, 1.5);
                
                if plotRecon
                    for n=1:nCon
                        plot(timeAxis, reconUnstack(:,n),'Color',pcaColors(n,:),'LineStyle',lineStyles{n},'LineWidth',2);
                    end
                else
                    for n=1:nCon
                        plot(timeAxis, squeeze(pcaOut.Z(firstDim(c),n,:)),'Color',pcaColors(n,:),'LineStyle',lineStyles{n},'LineWidth',2);
                    end                
                end
                set(gca,'FontSize',16);
                set(gca,'XTickLabel',[]);
                set(gca,'YTickLabel',[],'YTick',[],'LineWidth',1.5);
                axis tight;
                text(0.02, 0.8, [num2str(pcaOut.explVar.componentVar(firstDim(c)),3) '%'], 'Units', 'normalized','FontSize',16);
                if isfield(pcaOut,'atten')
                    text(0.02, 0.6, [num2str(pcaOut.atten(firstDim(c)),2)], 'Units', 'normalized','FontSize',16);
                end
                yLimits(c,colIdx,:) = get(gca,'YLim');
            else
                axis off;
            end
        end
    end
    
    
    fullLim = [min(yLimits(:)), max(yLimits(:))];
    for x=1:(nRows*2)
        subtightplot(nRows,2,x,[0.01 0.03],[0.1 0.01],[0.01 0.01]);
        hold on

        if ~zoomIn
            plot([0 0],fullLim,'--k','LineWidth',1.5);
            ylim(fullLim);
        else
            plot([0 0],get(gca,'YLim'),'--k');
            xlim([1.0 2]);
        end
        
        %plot([0 0],get(gca,'YLim'),'--k');
        if x>=(nRows*2-1)
            xlabel('Time (s)');
            set(gca,'XTick',[-1 0 1],'XTickLabel',[-1 0 1]);
        end
        
        if ~isempty(backgroundSignal)
            plotBackgroundSignal(timeAxis, backgroundSignal);
        end
    end
    
end

