function plotBackgroundSignal( xAxis, bs )
    lineStyles = {{'LineWidth',4,'Color',[0.875 0.875 0.875],'LineStyle','-'}, ...
        {'LineWidth',4,'Color',[0.875 0.875 0.875],'LineStyle',':'}, ...
        {'LineWidth',4,'Color',[0.875 0.875 0.875],'LineStyle','-.'}, ...
        {'LineWidth',4,'Color',[0.875 0.875 0.875],'LineStyle','--'}, ...
        {'LineWidth',4,'Color',[0.875 0.875 0.875],'LineStyle','-'}, ...
        {'LineWidth',4,'Color',[0.875 0.875 0.875],'LineStyle',':'}, ...
        {'LineWidth',4,'Color',[0.875 0.875 0.875],'LineStyle','-.'}, ...
        {'LineWidth',4,'Color',[0.875 0.875 0.875],'LineStyle','--'}};
    yLimits = get(gca,'YLim');
    
    lineLimits = zeros(1,2);
    lineLimits(1) = min(bs(:));
    lineLimits(2) = max(bs(:));
    lineExtent = lineLimits(2)-lineLimits(1);
    scaleFactor = (yLimits(2)-yLimits(1))/lineExtent;
    offset = scaleFactor * lineLimits(1);
    
    for x=1:size(bs,2)
        rescaledLine = bs(:,x);
        rescaledLine = rescaledLine * scaleFactor;
        rescaledLine = rescaledLine + yLimits(1) - offset;
        tmpHandle = plot(xAxis, rescaledLine, lineStyles{x}{:});
        uistack(tmpHandle, 'bottom');
    end
    
    set(gca,'YLim',yLimits);
end

