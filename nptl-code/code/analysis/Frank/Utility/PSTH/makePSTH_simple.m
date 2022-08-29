function [ out ] = makePSTH_simple( opts )
    %option formatting
    conditionList = unique(opts.trialConditions);
    nCon = length(conditionList);
    if size(opts.timeWindow,1)==1
        opts.timeWindow = repmat(opts.timeWindow, nCon, 1);
    end
    
    %smooth data
    nNeuralTypes = length(opts.neuralData);
    for t=1:nNeuralTypes
        if opts.gaussSmoothWidth>0
            opts.neuralData{t} = gaussSmooth_fast(opts.neuralData{t}, opts.gaussSmoothWidth);
        end
    end
    
    %make psth
    nDim = size(opts.neuralData{1}, 2);
    psth = cell(nCon, nNeuralTypes);
    timeAxis = cell(nCon,1);
    for n=1:nCon
        disp(['Making PSTH for Condition ' num2str(n)]);
        timeAxis{n} = (opts.timeWindow(n,1):opts.timeWindow(n,2))*opts.timeStep;
        nBins = length(timeAxis{n});

        %averaging
        trlIdx = opts.trialConditions==conditionList(n);
        for t=1:nNeuralTypes
            tmp = triggeredAvg( opts.neuralData{t}, opts.trialEvents(trlIdx), opts.timeWindow(n,:) );
            psth{n,t} = zeros(nBins, nDim, 3);
            if size(opts.neuralData{t},2)==1
                %special case of only a single channel
                for x=1:nBins
                    input = squeeze(tmp(:,x,:));
                    nanIdx = any(isnan(input),2);
                    [tmpMean,~,tmpCI] = normfit(input(~nanIdx,:));
                    psth{n,t}(x,:,1) = tmpMean;
                    psth{n,t}(x,:,2:3) = tmpCI';
                end                
            else
                for x=1:nBins
                    input = squeeze(tmp(:,x,:));
                    nanIdx = any(isnan(input),2);
                    if size(input,2)>1
                        [tmpMean,~,tmpCI] = normfit(input(~nanIdx,:));
                        psth{n,t}(x,:,1) = tmpMean;
                        psth{n,t}(x,:,2:3) = tmpCI';
                    else
                        psth{n,t}(x,:,1) = input;
                    end
                end
            end
        end
    end
        
    %subtract cross-condition mean
    if opts.subtractConMean
        nChan = size(psth{1},2);
        for n=1:nChan
            crossMean = [];
            for c=1:nCon
                crossMean = [crossMean; squeeze(psth{c}(:,n,1))'];
            end
            crossMean = mean(crossMean)';
            for c=1:nCon
                psth{c}(:,n,:) = psth{c}(:,n,:) - crossMean;
            end
        end
    end
    
    %psth SNR
    if ~isfield(opts,'dimSNR')
        %use fraction of variance explained
        dimSNR = zeros(nDim, nNeuralTypes);
        for t=1:nNeuralTypes
            for d=1:nDim
                disp(['FVAF ' num2str(d) '/' num2str(nDim)]);
                allData = [];
                for n=1:nCon
                    trlIdx = opts.trialConditions==conditionList(n);
                    raw = triggeredAvg( opts.neuralData{t}(:,d), opts.trialEvents(trlIdx), opts.timeWindow(n,:) );
                    sub = bsxfun(@plus, raw, -squeeze(psth{n,t}(:,d,1))');
                    allData = [allData; [raw(:), sub(:)]];
                end
                dimSNR(d,t) = 1 - nanvar(allData(:,2))/nanvar(allData(:,1));
            end
        end
    else
        %allows caller to specify an SNR-ordering
        dimSNR = opts.dimSNR;
    end
    
    %format return
    out.psth = psth;
    out.dimSNR = dimSNR;
    out.timeAxis = timeAxis;
    
    if ~opts.doPlot
        return;
    end
    
    %plot psth
    if opts.orderBySNR
        [~,snrIdx] = sort(dimSNR(:,1),'descend');
    else
        snrIdx = 1:nDim;
    end
    
    nPlot = opts.plotsPerPage;
    nPages = ceil(length(snrIdx)/nPlot);
    nGroups = length(opts.conditionGrouping);
    if ~exist(opts.plotDir,'dir')
        mkdir(opts.plotDir);
    end
    
    for pageIdx=1:nPages
        
        figure('Position',[45, 50, 173.5*nGroups, 89.6*nPlot]);
        for p=1:nPlot
            if p>length(snrIdx)
                break;
            end
            featIdx = snrIdx(p);
            if isempty(opts.featLabels)
                featLabel = ['Unit ' num2str(featIdx)];
            else
                featLabel = opts.featLabels{featIdx};
            end
            
            yLimitsAll = [];
            axAll = [];
            for groupIdx = 1:nGroups
                nCodes = length(opts.conditionGrouping{groupIdx});
                if ~opts.plotUnits
                    axAll(groupIdx) = subtightplot(nPlot,nGroups,(p-1)*nGroups+groupIdx,[0.01 0.03],opts.marg_h,opts.marg_w);
                else
                    axAll(groupIdx) = subtightplot(nPlot,nGroups,(p-1)*nGroups+groupIdx,[0.01 0.03],opts.marg_h,opts.marg_w);
                    ylabel(opts.unitLabels{featIdx},'FontSize',9);
                end
                set(gca,'LineWidth',1.5);
                
                %PSTH lines
                hold on;
                for d=1:nCodes
                    globalCodeIdx = opts.conditionGrouping{groupIdx}(d);
                    plot(timeAxis{globalCodeIdx}, psth{globalCodeIdx,1}(:,featIdx,1), opts.lineArgs{globalCodeIdx}{:});
                    if nNeuralTypes>1
                        plot(timeAxis{globalCodeIdx}, psth{globalCodeIdx,2}(:,featIdx,1),opts.lineArgs{globalCodeIdx}{:},'LineStyle',':');
                    end
                    if opts.plotCI
                        errorPatch(timeAxis{globalCodeIdx}', squeeze(psth{globalCodeIdx,1}(:,featIdx,2:3)), opts.CIColors(globalCodeIdx,:), 0.2);
                    end
                end
                if ~opts.plotUnits
                    set(gca,'XTickLabel',[]);
                    set(gca,'YTickLabel',[],'YTick',[]);
                else
                    if p~=nPlot
                        set(gca,'XTickLabel',[]);
                    end
                end
                axis tight;
                if opts.plotUnits
                    yLimits = get(gca,'YLim');
                    ylim([0 yLimits(end)]);
                end
                
                yLimitsAll = [yLimitsAll; get(gca,'YLim')];
                text(0,0.8,featLabel,'Units','normalized','FontSize',16);
                
                %optional bars
                if isfield(opts,'bar') && (groupIdx == nGroups)
                    barDat = opts.bar{featIdx};
                    pAx = get(gca, 'Position');
                    if nGroups==3
                        xOffset = 0.2;
                    else
                        xOffset = 0.3;
                    end
                    axes('Parent', gcf, 'Position', [pAx(1)+xOffset, pAx(2)+0.04, 0.3/nGroups, 0.03]);
                    for coefIdx=1:4
                        rectangle('Position',[coefIdx, 0, 1, barDat(coefIdx)], 'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k','LineWidth',1.5);
                    end
                    axis off;
                end
                if p==1 && isfield(opts,'titles')
                    title(opts.titles{groupIdx});
                end
            end
            
            sharedLimits = [min(yLimitsAll(:,1)), max(yLimitsAll(:,2))];
            for groupIdx = 1:nGroups
                if isfield(opts,'sharedLimits') && opts.sharedLimits==false
                    continue;
                end
                set(axAll(groupIdx),'YLim',sharedLimits);
                if ~isempty(opts.verticalLineEvents)
                    for vIdx = 1:length(opts.verticalLineEvents)
                        plot(axAll(groupIdx),[opts.verticalLineEvents(vIdx), opts.verticalLineEvents(vIdx)], ...
                            sharedLimits,'--k','LineWidth',1.5);
                    end
                end
            end
            if isfield(opts,'bgSignal')
                plotBackgroundSignal( timeAxis{globalCodeIdx}, opts.bgSignal );
            end
        end
        for groupIdx = 1:nGroups
            xTicks = round(timeAxis{globalCodeIdx}(1):timeAxis{globalCodeIdx}(end));
            if ~any(xTicks==0)
                xTicks = [xTicks, 0];
                xTicks = sort(xTicks,'ascend');
            end
            set(axAll(groupIdx),'XTick',xTicks,'XTickLabel',mat2stringCell(xTicks),'FontSize',opts.fontSize);
            set(get(axAll(groupIdx),'XLabel'),'String','Time(s)');
        end
        
        set(gcf,'Renderer','painters');
        set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
        saveas(gcf,[opts.plotDir filesep opts.prefix ' page ' num2str(pageIdx) '.png'],'png');
        %saveas(gcf,[opts.plotDir filesep opts.prefix ' page ' num2str(pageIdx) '.svg'],'svg');
        %close(gcf);
        
        snrIdx = snrIdx((nPlot+1):end);
    end
end

