function coef = plot_dPCA_noisyRecon( pcaOut, pcaOut_model, pcaColors, lineStyles, timeAxis, E, backgroundSignal )
    nCon = size(pcaOut.Z,2);
    nRows = 4;
    firstDir = find(pcaOut.whichMarg==1);
    firstTime = find(pcaOut.whichMarg==2);
    firstDir = firstDir(1:min(7, length(firstDir)));
    firstTime = firstTime(1:min(7, length(firstTime)));
    axTypes = {firstDir, firstTime};
    yLimits = zeros(4,2,2);
    coef = cell(nRows, 2);
    modelProp = cell(nRows*2, 1);
    axHandles = zeros(nRows*2, 1);
    
    normE = E;
    for d=1:size(E,1)
        normE(d,:) = E(d,:)/norm(E(d,:));
    end
    
    modelFRA = [];
    for d=1:140
        tmp = squeeze(pcaOut_model.firingRatesAverage(d,:,:))';
        modelFRA = [modelFRA, tmp(:)];
    end
    modelProj = modelFRA*pcaOut.W;
    
    if nargin<7
        backgroundSignal = [];
    end

    figure('Position',[96   430   337   510]);
    for c=1:nRows
        for colIdx=1:2
            firstDim = axTypes{colIdx};
            axHandles(2*(c-1)+colIdx) = subtightplot(nRows,2,2*(c-1)+colIdx,[0.01 0.03],[0.1 0.01],[0.01 0.01]);
            hold on
            set(gca,'LineWidth',1.5);
            if length(firstDim)>=c
                modelProp{2*(c-1)+colIdx} = normE*pcaOut.W(:,firstDim(c));
                Z = modelProj(:,firstDim(c));
                Z = reshape(Z,[151 size(pcaOut.firingRatesAverage,2)]);
                for n=1:nCon
                    plot(timeAxis, Z(:,n),'Color',pcaColors(n,:),'LineStyle',lineStyles{n},'LineWidth',2);
                end
                set(gca,'XTickLabel',[],'FontSize',16);
                set(gca,'YTickLabel',[],'YTick',[]);
                axis tight;
                yLimits(c,colIdx,:) = get(gca,'YLim');
            else
                axis off;
            end
        end
    end
    
    maxCoef = max(abs(vertcat(modelProp{:})));
    fullLim = [min(yLimits(:)), max(yLimits(:))];
    for x=1:(nRows*2)
        axes(axHandles(x));
        hold on
        ylim(fullLim);
        plot([0 0],fullLim,'--k','LineWidth',1.5);
        if x>=(nRows*2-1)
            xlabel('Time (s)');
            set(gca,'XTick',[-1 0 1],'XTickLabel',[-1 0 1]);
        end
        
        if ~isempty(backgroundSignal)
            plotBackgroundSignal(timeAxis, backgroundSignal);
        end
        
        %bars
        barDat =  abs(modelProp{x});
        pAx = get(gca, 'Position');
        axes('Parent', gcf, 'Position', [pAx(1)+.3, pAx(2)+.15, 0.15, 0.075]);
        for coefIdx=1:4
            rectangle('Position',[coefIdx, 0, 1, barDat(coefIdx)], 'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
        end
        ylim([0 maxCoef]);
        axis off;
    end
end

