function [modScales, figHandles, modScalesZero] = oneFactor_dPCA_plot_mag( out, timeAxis, lineArgs, margNamesShort, bgSignal )

    margOrder = [1 2];
    nMarg = max(out.whichMarg);
    nPerMarg = 8;
    modScales = cell(nMarg, nPerMarg);
    modScalesZero = cell(nMarg, nPerMarg);
    [~,zeroIdx] = min(abs(timeAxis));
    
    figHandles(1) = figure('Position',[-112        1735        1727         306]);
    for n=1:nMarg
        yAxesAll = [];
        axHandles = [];
        margIdx = find(out.whichMarg==margOrder(n));
        for p=1:nPerMarg
            if p>length(margIdx)
                break;
            end
            subtightplot(nMarg, nPerMarg, (n-1)*nPerMarg + p,[0.02 0.02],[0.08 0.02],[0.02 0.02]);
            hold on;
            
            %plot a line for each condition
            tmpIdx = 1;
            for factor1 = 1:length(lineArgs)
                psth = squeeze(out.Z(margIdx(p),factor1,:));
                plot(timeAxis, psth, lineArgs{factor1}{:});
                tmpIdx = tmpIdx + 1;
                modScales{n,p} = [modScales{n,p}; sum(psth)];
                modScalesZero{n,p} = [modScalesZero{n,p}; psth(zeroIdx)];
            end
            
            %axis labeling and management
            set(gca,'YTick',[]);
            if n~=nMarg
                set(gca,'XTick',[]);
            end
            if p==1
                ylabel(margNamesShort{margOrder(n)});
            end
            set(gca,'FontSize',16);
            xlim([timeAxis(1), timeAxis(end)]);
            yAxesAll = [yAxesAll; get(gca,'YLim')];
            axHandles = [axHandles; gca];
            axis tight;
            text(0.6,0.8,[num2str(out.explVar.componentVar(margIdx(p)),4) '%'],'Units','normalized','FontSize',14);
            text(0.6,0.6,[num2str(out.explVar.componentVar(margIdx(p)),4) '%'],'Units','normalized','Color','w','FontSize',14);
        end
        
        yAxesFinal = [min(yAxesAll(:,1)), max(yAxesAll(:,2))];
        for axIdx = 1:length(axHandles)
           set(axHandles(axIdx), 'YLim', yAxesFinal);
        end

        for axIdx = 1:length(axHandles)
            if ~isempty(bgSignal)
                axes(axHandles(axIdx));
                plotBackgroundSignal( timeAxis, bgSignal );
            end
        end
    end
     
    figHandles(2) = figure('Position',[624         648        1011         330]);
    for n=1:nMarg
        for p=1:nPerMarg
            subtightplot(nMarg, nPerMarg, (n-1)*nPerMarg + p);
            hold on;
            plot(modScales{n,p},'-o','LineWidth',2);
            axis tight;
        end
    end
    
    figHandles(3) = figure('Position',[624         648        1011         330]);
    for n=1:nMarg
        for p=1:nPerMarg
            subtightplot(nMarg, nPerMarg, (n-1)*nPerMarg + p);
            hold on;
            plot(modScalesZero{n,p},'-o','LineWidth',2);
            axis tight;
        end
    end
end

