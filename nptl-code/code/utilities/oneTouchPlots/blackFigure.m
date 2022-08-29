function [hf,figAxes] = whiteFigure(figNum, movieParams)
% WHITEFIGURE    
% 
% [hf,figAxes] = whiteFigure(figNum)


movieParams.foo = false;
movieParams = setDefault(movieParams, 'drawFiringRates', true, true);

hf = figure(figNum);
clf;

figHeight=300;

% are there multiple plots?
multiplePlots = movieParams.drawFiringRates || movieParams.drawSpeeds || movieParams.drawClickState || movieParams.drawSingleChannelDecode;
if multiplePlots
    cursorWindow=[0.01 0.01 0.48 0.99];
    set(hf,'position',[10 500 figHeight*2 figHeight]);
else
    cursorWindow=[0.01 0.01 0.99 0.99];
    set(hf,'position',[10 500 figHeight figHeight]);
end
% frHistWindow=[0.51 0.01 0.48 0.99];
frWidth=0.43;
frHistHeight=0.79;
frHistWindow=[0.51 0.10 frWidth frHistHeight];
popFrWindow=[0.51 0.91 frWidth 0.08];
movAvgWindow=[0.95 0.10 0.04 frHistHeight];

singleChDecodeWindow=[0.51 0.10 frWidth frHistHeight];

speedWidth = frWidth;
speedHeight = 0.3;
speedWindow = [0.51 0.51 speedWidth speedHeight];

accelWidth = frWidth;
accelHeight = 0.15;
accelWindow = [0.51 0.83 accelWidth accelHeight];

clickWidth = frWidth;
clickHeight = 0.35;
clickWindow = [0.51 0.11 clickWidth clickHeight];


set(hf, 'color', [0 0 0]);

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

if movieParams.drawSpeeds
    speedAxis=subplot('Position',speedWindow);
    set(speedAxis,'visible', 'off');
    figAxes.speedAxis = speedAxis;
end

if movieParams.drawAccel
    accelAxis=subplot('Position',accelWindow);
    set(accelAxis,'visible', 'off');
    figAxes.accelAxis = accelAxis;
end

if movieParams.drawClickState
    clickAxis=subplot('Position',clickWindow);
    set(clickAxis,'visible', 'off');
    figAxes.clickAxis = clickAxis;
end

if movieParams.drawSingleChannelDecode
    singleChDecodeAxis = subplot('Position',singleChDecodeWindow);
    set(singleChDecodeAxis,'visible', 'off');
    figAxes.singleChDecodeAxis = singleChDecodeAxis;
end

% set(gca,'visible', 'off');
%axis square;