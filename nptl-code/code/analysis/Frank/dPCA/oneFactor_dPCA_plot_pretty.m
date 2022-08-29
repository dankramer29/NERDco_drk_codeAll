function yAxesFinal = oneFactor_dPCA_plot_pretty( out, timeAxis, lineArgs, margNamesShort, axisType, bgSignal, forceAxes, dimCI, ciColors )

    margOrder = [1 2];
    nMarg = max(out.whichMarg);
    nPerMarg = 8;

    if nargin<6
        bgSignal = [];
    end
    if nargin<7
        forceAxes = [];
    end
    if nargin<8
        dimCI = [];
    end
    
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
                if ~isempty(dimCI)
                    errorPatch( timeAxis', squeeze(dimCI(margIdx(p),factor1,:,:)), ciColors(factor1,:), 0.2 );
                end
                
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
            
            text(0.7,0.8,[num2str(out.explVar.componentVar(margIdx(p)),3) '%'],'Units','normalized','FontSize',18);
            axis off;
               
            if n==nMarg && p==1
                yLimits = get(gca,'YLim');
                plot([0,0.5],[yLimits(1), yLimits(1)]+diff(yLimits)*0.1,'-k','LineWidth',2);
            end
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
                %plot(axHandles(axIdx), [0 0], get(axHandles(axIdx),'YLim'), '--k','LineWidth',2);
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

