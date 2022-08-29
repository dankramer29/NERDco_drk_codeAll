function [hf, figAxes] = oneTouchFigure(figNum)
% ONETOUCHFIGURE    
% 
% [hf, figAxes] = oneTouchFigure(figNum)
    
    % make a long axis
    hf=figure(figNum);
    clf;
    set(hf,'position',[30 420 1400 400]);
    set(hf, 'color', [1 1 1]);
    
    startLeft=0.04;
    startBottom=0.11;
    

    perfAxis = [startLeft startBottom 0.84 0.83];
    labAxis = [0.89 startBottom 0.07 0.83];
    
    % figAxes.performance = subplot(1,plotWidth,[1:timePlotWidth]);
    figAxes.performance = subplot('Position',perfAxis);

    %% make an axis for the labels (and hide it)
    %figAxes.labels = subplot(1,plotWidth,plotWidth);
    figAxes.labels = subplot('Position',labAxis);

    set(figAxes.labels,'xlim',[0 1],'ylim',[0 1]);
    set(gca,'xtick',[],'ytick',[]);
    set(gca,'box','off');
    set(gca,'visible','off');

    
