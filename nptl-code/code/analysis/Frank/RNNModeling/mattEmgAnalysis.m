%load('/Users/frankwillett/Downloads/mgolub%2FforFrank%2F2018-05-15%2Femg-rnn-with-data.mat');
load('/Users/frankwillett/Downloads/mgolub%2FforFrank%2F2018-05-30%2Femg-rnn-with-data.mat');

plotIdx = 96:195;

emg = emg(plotIdx,:,1:13:end);
hidden = hidden(plotIdx,:,1:13:end);
inputs = inputs(plotIdx,:,1:13:end);
realNeural = train_data.neural(plotIdx,:,1:13:end);

varNames = {'emg','hidden','inputs','realNeural'};
vars = {permute(emg, [2,3,1]), permute(hidden, [2,3,1]), permute(inputs, [2,3,1]), permute(realNeural, [2,3,1])};
saveDir = ['/Users/frankwillett/Data/Derived/armControlNets/dPCA/mattEMG' filesep];
mkdir(saveDir);
    
for varIdx = 1:length(vars)
    time = plotIdx*0.01;
    time = time - time(1);
    timeEvents = 0;
    
    var = vars{varIdx};
    var = repmat(var, 2, 1);
    if varIdx==3 || varIdx==2
        var = var + randn(size(var))*0.0000001;
    end
    
    combinedParams = {{1, [1 2]}, {2}};
    margNames = {'CD', 'CI'};
    margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;

    [W,V,whichMarg] = dpca(var, size(var,1), ...
        'combinedParams', combinedParams);

    explVar = dpca_explainedVariance(var, W, V, ...
        'combinedParams', combinedParams, ...
        'numOfTrials', ones(size(var,1), size(var,2)));
    
    out.W = W;
    out.whichMarg = whichMarg;
    out.V = V;
    out.explVar = explVar;
    
    Z = dpca_plot(var, W, V, @dpca_plot_default, ...
        'explainedVar', explVar, ...
        'marginalizationNames', margNames, ...
        'marginalizationColours', margColours, ...
        'whichMarg', whichMarg,                 ...
        'time', time,                        ...
        'timeEvents', timeEvents,               ...
        'timeMarginalization', 3,           ...
        'legendSubplot', 16);
    out.Z = Z;
    
    nCon = size(var,2);
    lineArgs = cell(nCon,1);
    targColors = jet(nCon)*0.8;
    for t=1:length(targColors)
        lineArgs{t} = {'Color',targColors(t,:),'LineWidth',2};
    end

    yAxesFinal = oneFactor_dPCA_plot( out, time, lineArgs, margNames, 'zoom');
    saveas(gcf, [saveDir varNames{varIdx} '.png'],'png');
end