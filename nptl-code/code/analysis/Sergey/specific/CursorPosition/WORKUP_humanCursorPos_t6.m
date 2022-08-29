clear
% Dataset parameters

% mode = 'noMove'; 
mode = 'move'; 
switch mode
    case 'noMove'
       datasets = {'t6.2014.07.25'; 
           't6.2014.07.28'}; 
    case 'move'
        datasets = {'t6.2014.06.30';
            't6.2014.07.02';
            't6.2014.07.07'
            't6.2014.07.18'
            't6.2014.07.21'};
end


participant = datasets{1}(1:2);
params.processedDatasetDir = '/net/home/sstavisk/16cursorPos/v2/';
params.resultsPath = '/net/derivative/sstavisk/Results/cursorPos/';
params.gridLimitsX = [-443 443]; % this I checked by hand
params.gridLimitsY = [-443 443];

% Analysis paramaters
params.minDurationHeldBeforeSelection = 150; % accepted trials must meet this requirement of ms over correct target before click
params.holdStart = 'timeSelection-0.100';
params.holdAlign = 'timeSelection';
params.holdEnd = 'timeSelection';

params.moveStart = 'timeTargetOn';
params.moveAlign = 'timeTargetOn';
params.moveEnd = 'timeTargetOn+0.600';

params.moveFeature = 'HLFPpow_20ms';

params.divideWorkspaceInto = 2; % 2x2 division more appropriate for T6 lower trial counts
% params.divideWorkspaceInto = 3; % 3x3 division fine for monks and T5

params.plotElectrodes = true;
params.saveFiguresDir = '/net/derivative/sstavisk/Figures/cursorPos/';
params.pValue = 0.001; % fr differences below this are considered significant
meta.pValue = 0.001; % used for aggregated results without recomputing individual analyses

% used for setting consistent axis limits
meta.diffHistLimits = [0 40];
meta.percentHistLimits = [0 0.2];
meta.numBinsDiff = 10;
meta.numBinsPercent = 10;

%% Go through each dataset and load or generate its results 
% will alter be combined

mkdir( params.resultsPath );
results = {}; % will fill these in for each dataset
for iDataset = 1 : numel( datasets )
    fprintf('Dataset %i/%i: %s...', iDataset, numel( datasets ), datasets{iDataset} );
    results{iDataset}.dataset = datasets{iDataset};

    resultsFile = [params.resultsPath 'Results_' datasets{iDataset} structToFilename( params ) '.mat' ];
    try
        loaded = load( resultsFile );
        results{iDataset} = loaded.myres; % unpacking anoyance
        fprintf(' results LOADED\n')
    catch
        fprintf(' ready result not found. Analyzing...\n');
        results{iDataset} = humanCursorPosOneDatasetHLFP( datasets{iDataset}, params );
        fprintf('     saving %s.mat ...\n', resultsFile );
        myres = results{iDataset};
        save( resultsFile, 'myres' );
        fprintf(' OK\n')
    end
    
end
Nsessions = numel( results );

%% Aggregate results across sessions
% aggegate the acrossRegionsDiff
agg.acrossRegionsDiff = [];
agg.acrossRegionsPranksum = [];
agg.R8condRange = [];
agg.numGridTrials = [];
for iDataset = 1 : Nsessions
    agg.acrossRegionsDiff = [agg.acrossRegionsDiff; results{iDataset}.acrossRegionsDiff'];
    agg.acrossRegionsPranksum = [agg.acrossRegionsPranksum; results{iDataset}.acrossRegionsPranksum'];
    agg.R8condRange = [agg.R8condRange; results{iDataset}.R8condRange'];
    agg.numGridTrials = [agg.numGridTrials; size( results{iDataset}.allTrialsPosTarget, 1)];
end
agg.sigChans = agg.acrossRegionsPranksum < meta.pValue;
fprintf('%i/%i dataset-electrodes significantly modulated at p<%g (ranksum)\n', ...
    nnz( agg.sigChans ), numel( agg.sigChans ), meta.pValue );
fprintf('%i total Grid trials across %i datasets\n', sum( agg.numGridTrials ), Nsessions );

%% Aggregate Histograms
% hist once with all to get aggregate centers

edges = 0 : meta.diffHistLimits(2)/(meta.numBinsDiff) : meta.diffHistLimits(2);
centers = edges(1:end-1) + ((edges(2)-edges(1))/2); % also get centers, for bar plot
edges(end) = inf; % puts all outliers into right bin

fighHists = figure;
titlestr = sprintf('Workspace HLFP Diffs Histograms %s %s', participant, mode );
fighHists.Name = titlestr;
axDiffs = subplot(1,2,1); % left panel is the differences histogram
Nsig = histcounts( agg.acrossRegionsDiff(agg.sigChans), edges );
Nnotsig = histcounts( agg.acrossRegionsDiff(~agg.sigChans), edges );
bh = bar(centers,[Nsig' Nnotsig'], 'stacked', 'BarWidth', 1, 'EdgeColor', 'none');
colormap([0 0 0; .5 .5 .5]);
axDiffs.XLim = meta.diffHistLimits;
xlabel('FR Diff (uV^2)');
ylabel('Electrodes Count');
% plot mean and median
fprintf('HLFP Power Diff Mean = %g uV^2, Median = %g uV^2\n', ...
    mean( agg.acrossRegionsDiff ), median( agg.acrossRegionsDiff ) );
line([mean( agg.acrossRegionsDiff ) mean( agg.acrossRegionsDiff )], axDiffs.YLim, ...
    'Color', 'k', 'LineStyle', '-');
line([median( agg.acrossRegionsDiff ) median( agg.acrossRegionsDiff )], axDiffs.YLim, ...
    'Color', 'k', 'LineStyle', '--');

%% Histogram of hold diff divided by move range.
agg.normalizedHoldDiff =  agg.acrossRegionsDiff ./ agg.R8condRange;
axNormed = subplot(1,2,2); % right panel is the normalized histogram


edges = 0 : meta.percentHistLimits(2)/(meta.numBinsPercent) : meta.percentHistLimits(2);
centers = edges(1:end-1) + ((edges(2)-edges(1))/2); % also get centers, for bar plot
edges(end) = inf; % puts all outliers into right bin


histh = histogram( agg.normalizedHoldDiff, edges );
histh.FaceColor = 'k';
axNormed.XLim = meta.percentHistLimits;
xlabel('Hold/Move Range');
fprintf('Hold/Move Range Diff Mean = %g uV^2, Median = %g uV^2\n', ...
    mean( agg.normalizedHoldDiff ), median( agg.normalizedHoldDiff ) );
line([mean( agg.normalizedHoldDiff ) mean( agg.normalizedHoldDiff )], axNormed.YLim, ...
    'Color', 'k', 'LineStyle', '-');
line([median( agg.normalizedHoldDiff ) median( agg.normalizedHoldDiff )], axNormed.YLim, ...
    'Color', 'k', 'LineStyle', '--');


% Save this figure.
ExportFig( fighHists, [params.saveFiguresDir 'Aggregate Histograms/' titlestr]);

