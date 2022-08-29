function [hf,figAxes] = whiteFigure(figNum, movieParams)
% WHITEFIGURE    
% 
% [hf,figAxes] = whiteFigure(figNum)

movieParams.foo = false;
movieParams = setDefault(movieParams, 'drawFiringRates', true, true);

figHeight=300;

if movieParams.drawFiringRates
    cursorWindow=[0.01 0.01 0.48 0.99];
else
    cursorWindow=[0.01 0.01 0.99 0.99];
end
% frHistWindow=[0.51 0.01 0.48 0.99];
frWidth=0.43;
frHistHeight=0.79;
frHistWindow=[0.51 0.10 frWidth frHistHeight];
popFrWindow=[0.51 0.91 frWidth 0.08];
movAvgWindow=[0.95 0.10 0.04 frHistHeight];

hf = figure(figNum);
clf;
if movieParams.drawFiringRates
    set(hf,'position',[10 500 figHeight*2 figHeight]);
else
    set(hf,'position',[10 500 figHeight figHeight]);
end
set(hf, 'color', [1 1 1]);

cursorAxis=axes('Position',cursorWindow);
hold(cursorAxis,'on');
set(cursorAxis,'visible', 'off');
figAxes.cursorAxis = cursorAxis;

if movieParams.drawFiringRates
    frAxis=subplot('Position',frHistWindow);
    set(frAxis,'visible', 'off');

    popFrAxis=subplot('Position',popFrWindow);
    set(popFrAxis,'visible', 'off');
    
    movAvgAxis=subplot('Position',movAvgWindow);
    set(movAvgAxis,'visible', 'off');
    
    figAxes.frAxis = frAxis;
    figAxes.popFrAxis = popFrAxis;
    figAxes.movAvgAxis = movAvgAxis;
end

% set(gca,'visible', 'off');
%axis square;