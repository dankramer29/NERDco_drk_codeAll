function yAxesFinal = oneFactor_dPCA_plot( out, timeAxis, lineArgs, margNamesShort, axisType, bgSignal, forceAxes )

    margOrder = [1 2 3 4];
    nMarg = max(out.whichMarg);
    nPerMarg = 5;

    if nargin<6
        bgSignal = [];
    end
    if nargin<7
        forceAxes = [];
    end
    nMarg=1;
    yAxesFinal = cell(nMarg,1);
    figure('Position',[33         435        1711         330]);
    for n=1:nMarg
        yAxesAll = [];
        axHandles = [];
        margIdx = find(out.whichMarg==margOrder(n));
        for p=1:nPerMarg
            if p>length(margIdx)
                break;
            end
            subtightplot(nMarg, nPerMarg, (n-1)*nPerMarg + p,[0.01 0.01],[0.1 0.01],[0.02 0.02]);
            hold on;
            
            %plot a line for each condition
            tmpIdx = 1;
            for factor1 = 1:size(out.Z,2)
                plot(timeAxis, squeeze(out.Z(margIdx(p),factor1,:)),lineArgs{factor1}{:});
                tmpIdx = tmpIdx + 1;
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
        end
        
        if ~isempty(forceAxes)
            yAxesFinal{n} = forceAxes;
        else
            yAxesFinal{n} = [min(yAxesAll(:,1)), max(yAxesAll(:,2))];
        end
        if strcmp(axisType,'sameAxes')
            for axIdx = 1:length(axHandles)
                set(axHandles(axIdx), 'YLim', yAxesFinal{n});
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
        
        %do again to make sure everything is as it should be, not disrupted
        %by above addition of lines
        if strcmp(axisType,'sameAxes')
            for axIdx = 1:length(axHandles)
                set(axHandles(axIdx), 'YLim', yAxesFinal{n});
            end
        end
    end
end

