function [yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot_pretty( out, timeAxis, lineArgs, margNamesShort, axisType, bgSignal, forceAxes, ...
    dimCI, ciColors, timeBar)

    margOrder = [1 2 3 4];
    nMarg = max(out.whichMarg);
    nPerMarg = 7;
    allYAxes = cell(nMarg,1);
    
    if nargin<6
        bgSignal = [];
    end
    if nargin<7
        forceAxes = [];
    end
    if nargin<10
        timeBar = [];
    end
    
    allHandles = cell(nMarg, 1);
    figure('Position',[573         195        1575         847]);
    for n=1:nMarg
        yAxesAll = [];
        axHandles = [];
        margIdx = find(out.whichMarg==margOrder(n));
        if length(margIdx)==0
            continue;
        end
        for p=1:nPerMarg
            if p>length(margIdx)
                break;
            end
            subtightplot(nMarg, nPerMarg, (n-1)*nPerMarg + p,[0.03 0.01],[0.05 0.05],[0.02 0.02]);
            hold on;
            
            %plot a line for each condition
            tmpIdx = 1;
            for factor1 = 1:size(out.Z,2)
                for factor2 = 1:size(out.Z,3)
                    plot(timeAxis, squeeze(out.Z(margIdx(p),factor1,factor2,:)),lineArgs{factor1,factor2}{:});
                    if ~isempty(dimCI)
                        errorPatch( timeAxis', squeeze(dimCI(margIdx(p),factor1,factor2,:,:)), ciColors(factor1,:), 0.2 );
                    end
                
                    tmpIdx = tmpIdx + 1;
                end
            end
                      
            %axis labeling and management
            set(gca,'LineWidth',1.5,'FontSize',16);
            set(gca,'YTick',[]);
            if n~=nMarg
                set(gca,'XTick',[]);
            end
            if p==1
                ylabel(margNamesShort{margOrder(n)});
            end
            xlim([timeAxis(1), timeAxis(end)]);
            axHandles = [axHandles; gca];
            axis tight;
            yAxesAll = [yAxesAll; get(gca,'YLim')];
            text(-0.05,0.8,[num2str(out.explVar.componentVar(margIdx(p)),3) '%'],'Units','normalized','FontSize',18);
            
            axis off;
            set(gca,'FontSize',16);
        end
        
        if ~isempty(forceAxes)
            yAxesFinal = forceAxes;
        else
            yAxesFinal = [min(yAxesAll(:,1)), max(yAxesAll(:,2))];
        end
        allYAxes{n} = yAxesFinal;
        if strcmp(axisType,'sameAxes') || strcmp(axisType,'sameAxesGlobal')
            for axIdx = 1:length(axHandles)
                set(axHandles(axIdx), 'YLim', yAxesFinal);
            end
        end
        
        %plot zero ones
        for axIdx = 1:length(axHandles)
            if timeAxis(end)>0
                yLimits = get(axHandles(axIdx),'YLim');
                plot(axHandles(axIdx), [0 0], yLimits, '--k','LineWidth',2);
                if ~isempty(timeBar)
                    plot(axHandles(axIdx), timeBar, [yLimits(1), yLimits(1)], '-k','LineWidth',2);
                end
            end
            if ~isempty(bgSignal)
                axes(axHandles(axIdx));
                plotBackgroundSignal( timeAxis, bgSignal );
            end
        end
        allHandles{n} = axHandles;
    end
    
    if strcmp(axisType,'sameAxesGlobal')
        yAxesAll = vertcat(allYAxes{:});
        yAxesFinal = [min(yAxesAll(:,1)), max(yAxesAll(:,2))];
        for n=1:nMarg
            for axIdx = 1:length(allHandles{n})
                set(allHandles{n}(axIdx), 'YLim', yAxesFinal);
            end
        end
    end
end

