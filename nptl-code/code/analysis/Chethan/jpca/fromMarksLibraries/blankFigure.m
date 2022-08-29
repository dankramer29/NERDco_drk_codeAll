% produces a blank figure with everything turned off
% hf = blankFigure(axLim)
% where axLim = [left right bottom top]
function hf = blankFigure(axLim, figNum)

if exist('figNum','var')
    hf = figure(figNum);clf;
else
    hf = figure; 
end
hold on; 
set(gca,'visible', 'off');
set(hf, 'color', [1 1 1]);
axis(axLim); axis square;