clear

% This analysis is specific for T5 (this one I wrote first). The other
% one, for T6, has some differences to accomodate using HLFP
% Dataset parameters
datasets = {...
    't5.2016.10.12';
    't5.2016.10.13';
    't5.2016.10.24';
    };
participant = datasets{1}(1:2);
params.processedDatasetDir = '/net/home/sstavisk/16cursorPos/';
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
params.moveFeature = 'spikesBinnedRate_20ms';

params.divideWorkspaceInto = 3; % 3x3 division

params.plotElectrodes = true;
params.saveFiguresDir = '/net/derivative/sstavisk/Figures/cursorPos/';
params.pValue = 0.001; % fr differences below this are considered significant
meta.pValue = 0.001; % used for aggregated results without recomputing individual analyses


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
        results{iDataset} = humanCursorPosOneDataset( datasets{iDataset}, params );
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
[~, edges] = histcounts( agg.acrossRegionsDiff );
% also get centers, for bar plot
centers = edges(1:end-1) + ((edges(2)-edges(1))/2);

fighHists = figure;
titlestr = sprintf('Workspace FR Diffs Histograms %s', participant );
fighHists.Name = titlestr;
axDiffs = subplot(1,2,1); % left panel is the differences histogram
Nsig = histcounts( agg.acrossRegionsDiff(agg.sigChans), edges );
Nnotsig = histcounts( agg.acrossRegionsDiff(~agg.sigChans), edges );
bh = bar(centers,[Nsig' Nnotsig'], 'stacked', 'BarWidth', 1, 'EdgeColor', 'none');
colormap([0 0 0; .5 .5 .5]);
axDiffs.XLim = [0 max( agg.acrossRegionsDiff )];
xlabel('FR Diff (Hz)');
ylabel('Electrodes Count');
% plot mean and median
fprintf('FR Diff Mean = %g Hz, Median = %g Hz\n', ...
    mean( agg.acrossRegionsDiff ), median( agg.acrossRegionsDiff ) );
line([mean( agg.acrossRegionsDiff ) mean( agg.acrossRegionsDiff )], axDiffs.YLim, ...
    'Color', 'k', 'LineStyle', '-');
line([median( agg.acrossRegionsDiff ) median( agg.acrossRegionsDiff )], axDiffs.YLim, ...
    'Color', 'k', 'LineStyle', '--');

%% Histogram of hold diff divided by move range.
agg.normalizedHoldDiff =  agg.acrossRegionsDiff ./ agg.R8condRange;
axNormed = subplot(1,2,2); % right panel is the normalized histogram
histh = histogram( agg.normalizedHoldDiff );
histh.FaceColor = 'k';
axNormed.XLim = [0 histh.BinLimits(2)];
xlabel('Hold/Move Range');
fprintf('Hold/Move Range Diff Mean = %g Hz, Median = %g Hz\n', ...
    mean( agg.normalizedHoldDiff ), median( agg.normalizedHoldDiff ) );
line([mean( agg.normalizedHoldDiff ) mean( agg.normalizedHoldDiff )], axNormed.YLim, ...
    'Color', 'k', 'LineStyle', '-');
line([median( agg.normalizedHoldDiff ) median( agg.normalizedHoldDiff )], axNormed.YLim, ...
    'Color', 'k', 'LineStyle', '--');


% Save this figure.
ExportFig( fighHists, [params.saveFiguresDir 'Aggregate Histograms/' titlestr]);

