% Plots example single-dimension velocities trajectory of a block of interest
% Sergey Stavisky May 2017


%% Data to analyze
clear

% experiment = 't5.2017.02.15';
% trajectoryPlotBlock = 6; % will make a plot of this block.
% exampleTrials = [10:15];

% experiment = 't5.2017.02.01';
% trajectoryPlotBlock = 10; % will make a plot of this block.

experiment = 't5.2017.01.25';
trajectoryPlotBlock = 12; % will make a plot of this block.

% experiment = 't5.2017.02.08';
% trajectoryPlotBlock = 9; % will make a plot of this block.
% exampleTrials = [21:28];


% Low gain example:
% experiment = 't5.2017.03.22';
% trajectoryPlotBlock = 8; % will make a plot of this block.
% exampleTrials = [37:44]; % nice examples with 1dim, 2dim, 3dim
% trajectoryPlotBlock = 14; % will make a plot of this block.


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

% Restrict to trials of interest
fprintf('Restricting to trials %s\n', mat2str( exampleTrials ) );

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

figh = DrawSingleDimVelocities( Rbuffered, 'numDims', 3 );

titlestr = MakeValidFilename( sprintf('%sB%s trials %s vels', experiment, mat2str(trajectoryPlotBlock), mat2str( exampleTrials ) ) );
figh.Name = titlestr;
saveas( figh, [figuresPath titlestr], 'fig' );
saveas( figh, [figuresPath titlestr], 'eps' );
fprintf('Saved %s\n', [figuresPath titlestr])
