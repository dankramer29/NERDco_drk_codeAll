% Plots example single-dimension velocities trajectory of a block of interest
% Also plots rasters for one of those trials (good for making "Intro" type
% figure walking through the data --> velocity decode --> cursor movement
% flow).
% Sergey Stavisky October 2017


%% Data to analyze
clear

%% Select Data
% Guessing this is for APG foundation (fourDOF)
experiment = 't5.2017.04.24';
trajectoryPlotBlock = 5; % will make a plot of this block.
exampleTrials = 26:29; % shows position for these trials
rasterTrial = 1; % shows rasters for this trial (index into exampleTrials)
RMSmult = -4.5; % RMS multiplier, for generating the rasters

% Recent 4.1 DOF
% experiment = 't5.2018.11.14';
% trajectoryPlotBlock = 6; % will make a plot of this block.
% exampleTrials = 35:38; % shows position for these trials
% 
% rasterTrial = 1; % shows rasters for this trial (index into exampleTrials)
% RMSmult = -4.5; % RMS multiplier, for generating the rasters

% Analysis parameters
params.plotInward = true;

%% Get the data
participant = experiment(1:2);
% streamsPathRoot = ['/net/experiments/' participant '/'];
% figuresPath = ['/net/derivative/user/sstavisk/Figures/fourD/' experiment '/' ];

streamsPathRoot = [CachedDatasetsRootNPTL '/NPTL/'];
figuresPath = [FiguresRootNPTL '/fourD/' experiment '/' ];


%% Prep
if ~isdir( figuresPath )
    mkdir( figuresPath );
end


% -------------------------------------------------------------
%% Get the R structures
% -------------------------------------------------------------
streamsPath = [streamsPathRoot experiment '/Data/FileLogger/']; 
fprintf('Generating R from %s block %i\n', streamsPath, trajectoryPlotBlock );


stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, trajectoryPlotBlock ) ); 
R = onlineR( stream );
fprintf(' %i trials\n', numel( R ) );

[dataset, condition] = datasets_4D( experiment );

if isfield( condition, 'removeFirstNtrials' )
    if any(  condition.removeFirstNtrials(:,1) == myBlock  )
        R = R(condition.removeFirstNtrials( condition.removeFirstNtrials(:,1) == myBlock,2)+1:end);
        fprintf('  removed first %i trials of this block per analysis instructions\n', condition.removeFirstNtrials( condition.removeFirstNtrials(:,1) == myBlock,2))
    end
end

%%

exampleTrials = 36:39; % shows position for these trials

% Restrict to trials of interest
fprintf('Restricting to trials %s\n', mat2str( exampleTrials ) );

% Get block-level performance metrics;
if isfield( condition, 'radiusCounts') && condition.radiusCounts
    radiusCounts = true;
else
    radiusCounts = false;
end

Rex = R(exampleTrials);
stats = CursorTaskSimplePerformanceMetrics( Rex, 'radiusCounts', radiusCounts );
% Report these
fprintf('Performance (%.1f seconds): %i/%i trials (%.1f%%) successful. %.1f successes per minute. mean %.1fms TTT.\n', ...
    stats.blockDuration, stats.numSuccess, stats.numTrials, 100*stats.numSuccess/stats.numTrials, ...
    stats.successPerMinute, nanmean( stats.TTT ) );
fprintf('     Dial in time %.1fms. %.2f mean incorrect clicks. Path efficiency = %.3f\n', ...
    mean( stats.dialIn ), mean( stats.numIncorrectClicks ), nanmean( stats.pathEfficiency ) );
    

% Get an extra trial on each end so I can smooth velocities
if max( diff( exampleTrials ) ) > 1 || max( diff( [R(exampleTrials).trialNum] ) ) > 1
    error('This script should be run on contiguous trial indices! \n')
end
bufferedInds = [exampleTrials(1)-1, exampleTrials, exampleTrials(end)+1 ];
Rbuffered = R(bufferedInds);




% -------------------------------------------------------------
%% Plot the example trials
% -------------------------------------------------------------

if ~isdir( figuresPath )
    mkdir( figuresPath )
end

% velocities are cm/s
figh = DrawSingleDimPositions( Rbuffered, 'numDims', 4 ); 

titlestr = MakeValidFilename( sprintf('%sB%s trials %s pos', experiment, mat2str(trajectoryPlotBlock), mat2str( exampleTrials ) ) );
figh.Name = titlestr;
saveas( figh, [figuresPath titlestr], 'fig' );
saveas( figh, [figuresPath titlestr], 'epsc' );
fprintf('Saved %s\n', [figuresPath titlestr])


%% Plot rasters for example trial

Rraster = Rex(rasterTrial);
rms = channelRMS( R );
Rraster = RastersFromMinAcausSpikeBand( Rraster, RMSmult.*rms );
figh = figure;
axh = axes;

%  using imagesc
% imagesc( Rraster.spikeRaster );
% colormap([1 1 1; 0 0 0])
% axh.TickDir = 'out';

% vectorized
rasterCells = {};
for i = 1 : size( Rraster.spikeRaster, 1 );
    rasterCells{i} = find( Rraster.spikeRaster(i,:) );
end

xlim = [ 0 size( Rraster.spikeRaster, 2 ) ];
axh = drawRasters( axh, rasterCells, xlim, 'tickColor', 'k', 'tickWidth', 2 );
axh.TickDir = 'out';

titlestr = MakeValidFilename( sprintf('%sB%s trial %s rasters', experiment, mat2str(trajectoryPlotBlock), mat2str( exampleTrials(rasterTrial) ) ) );
figh.Name = titlestr;
saveas( figh, [figuresPath titlestr], 'fig' );
saveas( figh, [figuresPath titlestr], 'eps' );
