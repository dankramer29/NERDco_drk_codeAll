function ah = blankAxes(axPosition)
% BLANKAXES    
% 
% ah = blankAxes(axPosition)

    ah = axes('position', axPosition);
    set(ah,'box','off','visible','off');
    set(ah,'xtick',[],'ytick',[]);
