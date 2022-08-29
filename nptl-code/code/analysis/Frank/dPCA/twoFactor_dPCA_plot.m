function [yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot( out, timeAxis, lineArgs, margNamesShort, axisType, bgSignal, forceAxes )

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
            text(0.05,0.8,[num2str(out.explVar.componentVar(margIdx(p)),4) '%'],'Units','normalized','FontSize',18);
            
            title(['Component ' num2str(margIdx(p))]);
        end
        
        if ~isempty(forceAxes)
            yAxesFinal = forceAxes;
        else
            yAxesFinal = [min(yAxesAll(:,1)), max(yAxesAll(:,2))];
        end
        allYAxes{n} = yAxesFinal;
        if strcmp(axisType,'sameAxes')
            for axIdx = 1:length(axHandles)
                set(axHandles(axIdx), 'YLim', yAxesFinal);
            end
        end
        
        %plot zero ones
        for axIdx = 1:length(axHandles)
            if timeAxis(end)>0
                plot(axHandles(axIdx), [0 0], get(axHandles(axIdx),'YLim'), '--k','LineWidth',2);
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

