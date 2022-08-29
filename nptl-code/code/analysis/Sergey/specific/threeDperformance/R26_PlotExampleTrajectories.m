% Plots example trajectory of a block of interest from R26
% Sergey Stavisky March 2017


%% Data to analyze
clear

experiment = 't5.2017.02.15';
trajectoryPlotBlock = 6; % will make a plot of this block.

% experiment = 't5.2017.02.01';
% trajectoryPlotBlock = 10; % will make a plot of this block.

% experiment = 't5.2017.01.25';
% trajectoryPlotBlock = 12; % will make a plot of this block.


% Analysis parameters
params.plotInward = false;

%% Get the data
participant = experiment(1:2);
streamsPathRoot = ['/net/experiments/' participant '/'];
figuresPath = ['/net/derivative/user/sstavisk/Figures/threeDandClick/' experiment '/' ];



%% Prep
if ~isdir( figuresPath )
    mkdir( figuresPath );
end


% -------------------------------------------------------------
%% Get the R structures
% -------------------------------------------------------------
streamsPath = [streamsPathRoot experiment '/Data/FileLogger/']; 
fprintf('Generating R from %s block %i\n', streamsPath, trajectoryPlotBlock );


stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, trajectoryPlotBlock ), {'neural'} ); % note excluding neural, which I don't need here
R = onlineR( stream );
fprintf(' %i trials\n', numel( R ) );

[dataset, condition] = datasets_3D( experiment );

if isfield( condition, 'removeFirstNtrials' )
    if any(  condition.removeFirstNtrials(:,1) == myBlock  )
        R = R(condition.removeFirstNtrials( condition.removeFirstNtrials(:,1) == myBlock,2)+1:end);
        fprintf('  removed first %i trials of this block per analysis instructions\n', condition.removeFirstNtrials( condition.removeFirstNtrials(:,1) == myBlock,2))
    end
end

% Get block-level performance metrics;
if isfield( condition, 'radiusCounts') && condition.radiusCounts
    radiusCounts = true;
else
    radiusCounts = false;
end
stats = CursorTaskSimplePerformanceMetrics( R, 'radiusCounts', radiusCounts );
% Report these
fprintf('Block %i (%.1f minutes): %i/%i trials (%.1f%%) successful. %.1f successes per minute. mean %.1fms TTT.\n', ...
    stats.blockNumber, stats.blockDuration/60, stats.numSuccess, stats.numTrials, 100*stats.numSuccess/stats.numTrials, ...
    stats.successPerMinute, nanmean( stats.TTT ) );
fprintf('     Dial in time %.1fms. %.2f mean incorrect clicks. Path efficiency = %.3f\n', ...
    mean( stats.dialIn ), mean( stats.numIncorrectClicks ), nanmean( stats.pathEfficiency ) );
    





% -------------------------------------------------------------
%% Plot the example block
% -------------------------------------------------------------
blockNums = arrayfun(@(x) x.startTrialParams.blockNumber, R );
Rplot = R(SavetagInds(R, trajectoryPlotBlock));
% Trial restrictions
if ~params.plotInward
    Rplot = Rplot(~CenteringTrialInds(Rplot));
    fprintf('Restricting PLOTTING to %i outward trials in block %s\n', numel( Rplot ), mat2str( trajectoryPlotBlock ) )
end


if ~isdir( figuresPath )
    mkdir( figuresPath )
end

figh = figure;

% Isometric view
axh(1) = subplot(1,4,1);
Plot3Dtrajectories( Rplot, 'axh', axh(1) );
axh(1).GridLineStyle = 'none';

% XY view
axh(2) = subplot(1,4,2);
Plot3Dtrajectories( Rplot, 'axh', axh(2) );
axh(2).CameraPosition = [0 0 -0.6];

% ZY view
axh(3) = subplot(1,4,3);
Plot3Dtrajectories( Rplot, 'axh', axh(3) );
axh(3).CameraPosition = [-0.6 0 0];
axh(3).CameraUpVector = [0 -1 0];
axh(3).ZDir = 'normal'; % makes out (towards screen) on right

% XZ view
axh(4) = subplot(1,4,4);
Plot3Dtrajectories( Rplot, 'axh', axh(4) );
axh(4).CameraPosition = [0 0.6 0];
axh(4).CameraUpVector = [0 0 -1];
axh(4).ZDir = 'reverse'; % makes out (towards screen) on bottom


titlestr = sprintf('%sB%s', experiment, mat2str(trajectoryPlotBlock) );
figh.Name = titlestr;
saveas( figh, [figuresPath titlestr '_3views.fig'] );
% export_fig( [figuresPath titlestr '_iso'], '-eps' ) 

