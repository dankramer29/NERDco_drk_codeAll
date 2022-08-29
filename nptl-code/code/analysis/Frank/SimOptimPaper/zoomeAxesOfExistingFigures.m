figFiles = {'fittsBySession1','fittsBySession2','gsBySession1','gsBySession2'};
for f=1:length(figFiles)
    figH = open(['/Users/frankwillett/Data/CaseDerived/figures/optiPaper/' figFiles{f} '.fig']);
    
    for axIdx = 1:length(figH.Children)
        axisObj = figH.Children(axIdx).Children;
        
        if length(axisObj)<=3
            set(figH.Children(axIdx),'FontSize',14);
        else
            xDat = [];
            yDat = [];
            for objIdx = 1:length(axisObj)
                try
                    if strcmp(axisObj(objIdx).LineStyle,'-')
                        xDat = [xDat, axisObj(objIdx).XData];
                        yDat = [yDat, axisObj(objIdx).YData];
                    end
                    axisObj(objIdx).LineWidth = 1;
                    axisObj(objIdx).MarkerSize = 6;
                end
                try
                    axisObj(objIdx).FontSize = axisObj(objIdx).FontSize*1.75;
                end
            end

            allDat = [xDat, yDat];
            squareLims = [min(allDat), max(allDat)];

            set(figH.Children(axIdx),'XLim',squareLims,'YLim',squareLims,'FontSize',14);

            squareLims(1) = squareLims(1) + diff(squareLims)*0.1;
            squareLims(2) = squareLims(2) - diff(squareLims)*0.1;
            set(figH.Children(axIdx),'XTick',squareLims,'XTickLabel',{num2str(squareLims(1),2), num2str(squareLims(2),2)});
            set(figH.Children(axIdx),'YTick',squareLims,'YTickLabel',{num2str(squareLims(1),2), num2str(squareLims(2),2)});
        end
    end
    
    saveas(figH, ['/Users/frankwillett/Documents/Simulation Optimization Paper/' figFiles{f} '_zoomedAxes.fig'],'fig');
    saveas(figH, ['/Users/frankwillett/Documents/Simulation Optimization Paper/' figFiles{f} '_zoomedAxes.svg'],'svg');
end