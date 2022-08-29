% Plot an example trial's kinematics during 3 DOF robot arm control.
%
%
% Sergey D Stavisky, October 20, 2017




%% Data to analyze
clear


experiment = 't5.2017.10.02';
trajectoryPlotBlock = 19; % will make a plot of this block.


% interpeting the robot data stream for this session (note: this is
% probably changing often, don't trust it for other sessions.


%% Plot the blocks/minute of each block. This is based on manual counting by Paymon

functionalMetric.block     = [11, 12, 15, 16, 18, 19]; % block number; not really inherently meaningful.
functionalMetric.successes = [11, 14, 13, 13, 18, 19]; % in a five minute block
functionalMetric.mistakes  = [4,  6,  3,  9,  1,  2];

figh = figure;
bar(functionalMetric.successes./(5) );
xlabel( 'Block' );
ylabel( 'Transfers/Minute' );

%% Get the data
participant = experiment(1:2);
streamsPathRoot = ['/net/experiments/' participant '/'];
figuresPath = ['/net/derivative/user/sstavisk/Figures/threeDandClick/' experiment '/' ];

% Prep
if ~isdir( figuresPath )
    mkdir( figuresPath );
end

% Get the R structure
streamsPath = [streamsPathRoot experiment '/Data/FileLogger/']; 
fprintf('Generating R from %s block %i\n', streamsPath, trajectoryPlotBlock );
stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, trajectoryPlotBlock ), {'neural'} ); % note excluding neural, which I don't need here
totalMS = double( stream.continuous.clock(end) - stream.continuous.clock(1) );
fprintf(' %.2f minutes\n', totalMS/(60*1000) );

%% 

% When to plot, in ms. There aren't trials, just a continous stream.
msStart = 120*1e3;
msEnd = 150*1e3;


% Estimate latency of getting things back from robot
loopLatency = double( [stream.continuous.clock] ) - double( [stream.continuous.robotTimestamp] );
meanDelay = mean( loopLatency);
fprintf('Mean latency of getting robot position back is %.1fms\n', meanDelay );

% stream.continuous.robotPosition(:, 1:3) are xSet, ySet, zSet 
% column 6 is grip set
% columns 7,8,9 are actual x,y,z pos

% Plot the output velocity

t = msStart:msEnd;
robotT = [msStart: msEnd] + round( meanDelay ); % account for latency;


x = stream.continuous.xk(msStart:msEnd,2);
y = stream.continuous.xk(msStart:msEnd,4);
z = stream.continuous.xk(msStart:msEnd,6);
graspState = stream.continuous.robotPosition(robotT,6) / 10000; % divide by 10000 so same scale

figh = figure; 
% plot commanded velocity
axh(1) = subplot(2,1,1);
title('Commanded Velocity')
hold on;
plot( t, x, 'Color', 'r');
plot( t, y, 'Color', 'g' );
plot( t, z, 'Color', 'b' );
plot( t, graspState, 'Color', [1 0 1]);

% now let's plot hand XYZ
% conver to cm and flip all signs 
handX = -1 * 100.*stream.continuous.robotPosition(robotT,7);
handY = -1 * 100.*stream.continuous.robotPosition(robotT,8);
handZ = -1 * 100.*stream.continuous.robotPosition(robotT,9);
axh(2) = subplot(2,1,2); 
hold on;
title('Hand Position (cm)')
plot( t, handX, 'Color', 'r', 'LineStyle', '-')
plot( t, handY, 'Color', 'g', 'LineStyle', '-')
plot( t, handZ, 'Color', 'b', 'LineStyle', '-')

