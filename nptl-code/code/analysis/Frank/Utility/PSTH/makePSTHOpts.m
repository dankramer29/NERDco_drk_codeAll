function [ opts ] = makePSTHOpts( )
    opts.neuralData = {randn(10000,10), randn(10000,10)};
    
    opts.timeStep = 0.02;
    opts.timeWindow = [-10 100];
    opts.verticalLineEvents = 0;
    opts.trialEvents = cell(100,1);
    opts.trialConditions = randi(8,200,1);

    opts.gaussSmoothWidth = 1; 
    opts.blendBetweenEvents = false;
    
    opts.marg_h = [0.1, 0.03];
    opts.marg_w = [0.1, 0.03];
    opts.fontSize = 14;
    
    dirColors = hsv(4)*0.8;
    distColors = [253 204 138; 179 0 0]/255;
    colors = [dirColors; distColors];
    opts.lineArgs = {{'Color',colors(1,:),'LineWidth',1}; ...
        {'Color',colors(2,:),'LineWidth',1}; ...
        {'Color',colors(3,:),'LineWidth',1}; ...
        {'Color',colors(4,:),'LineWidth',1}; ...
        {'Color',colors(5,:),'LineWidth',1}; ...
        {'Color',colors(6,:),'LineWidth',1}};
    
    opts.doPlot = true;
    opts.plotDir = [];
    opts.plotsPerPage = 5;
    opts.conditionGrouping = {1:4, 5:8};
    opts.orderBySNR = true;
    opts.plotCI = false;
    opts.plotUnits = false;
    
    opts.subtractConMean = false;
    opts.doPCAAnalysis = false;
end

