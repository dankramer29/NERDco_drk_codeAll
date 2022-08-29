% Plots example trajectory of a block of interest from R26 block
% with targets shown and colored based on whether they are so-called "1D', "2D", or "3D"
% change-required datasets.
%
% Sergey Stavisky August 2017


%% Data to analyze
clear

experiment = 't5.2017.02.27';
trajectoryPlotBlock = [13, 14, 15]; % will make a plot of this block.



% FIGURE PARAMETERS
params.plotInward = false;
params.plotEachSet = [true; false; true];  % whether to plot the [cardinal axis, 2-corner, 3corner] target set
params.showTarget = true;
params.displayTargetRadius = 0.015; % note that actual task also had 10 cm radius cursor which counted
params.colorEachSet = [0 0.8 0; % cardinal axis targets
    0 0 1; % 2D corner targets
    0.8 0.8 0]; % 3D corner targets


%% Get the data
participant = experiment(1:2);
if ismac
    streamsPathRoot = [CachedDatasetsRootNPTL '/NPTL/']; %
else
    streamsPathRoot =  ['/net/experiments/' participant filesep];
end
figuresPath = [FiguresRootNPTL '/NPTL/threeD/targetSetFigs/' ];



%% Prep
if ~isdir( figuresPath )
    mkdir( figuresPath );
end


% -------------------------------------------------------------
%% Get the R structures
% -------------------------------------------------------------
streamsPath = [streamsPathRoot experiment '/Data/FileLogger/']; 

R = [];
for iBlock = 1 : numel( trajectoryPlotBlock )
    fprintf('Generating R from %s block %i\n', streamsPath, trajectoryPlotBlock(iBlock) );
    stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, trajectoryPlotBlock(iBlock) ), {'neural'} ); % note excluding neural, which I don't need here
    Rin = onlineR( stream );
    fprintf(' %i trials\n', numel( Rin) );
    R = [R,Rin];
end

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


%% Restrict by target set 
[targetIdx, uniqueTargets, ~, distFromZero] = SortTrialsBy3Dtarget( Rplot );
Rsets = []; % will build this using just trials I care about
trialColors = [];
for dofVaried = 1 : 3 
    % which targets vary from 0 in this many dimensions?
    myTargets =  find( sum( abs( uniqueTargets ) > 0, 2 ) == dofVaried );
    myTrials = ismember( targetIdx, myTargets );    
    fprintf('%i targets have %i dofVaried. %i trials go to these targets.\n', ...
        numel( myTargets ), dofVaried, nnz( myTrials ) );

    if params.plotEachSet(dofVaried)
        trialColors = [trialColors; repmat( params.colorEachSet(dofVaried,:), nnz( myTrials ), 1 )];
        Rsets = [Rsets, Rplot(myTrials)];
    end
    
    stats = CursorTaskSimplePerformanceMetrics( Rplot(myTrials), 'radiusCounts', radiusCounts );
    fprintf('  mean PE = %.3f\n', mean( stats.pathEfficiency ) )
end



if ~isdir( figuresPath )
    mkdir( figuresPath )
end






%% MULTIPLE VIEWS
figh = figure;
% Isometric view
axh(1) = subplot(1,4,1);
Plot3Dtrajectories( Rsets, 'axh', axh(1), 'colors', trialColors, 'showTarget', params.showTarget, 'targetRadius', params.displayTargetRadius  );
axh(1).GridLineStyle = 'none';

% XY view
axh(2) = subplot(1,4,2);
Plot3Dtrajectories( Rsets, 'axh', axh(2), 'colors', trialColors, 'showTarget', params.showTarget, 'targetRadius', params.displayTargetRadius  );
axh(2).CameraPosition = [0 0 -0.6];

% ZY view
axh(3) = subplot(1,4,3);
Plot3Dtrajectories( Rsets, 'axh', axh(3), 'colors', trialColors, 'showTarget', params.showTarget, 'targetRadius', params.displayTargetRadius  );
axh(3).CameraPosition = [-0.6 0 0];
axh(3).CameraUpVector = [0 -1 0];
axh(3).ZDir = 'normal'; % makes out (towards screen) on right

% XZ view
axh(4) = subplot(1,4,4);
Plot3Dtrajectories( Rsets, 'axh', axh(4), 'colors', trialColors, 'showTarget', params.showTarget, 'targetRadius', params.displayTargetRadius  );
axh(4).CameraPosition = [0 0.6 0];
axh(4).CameraUpVector = [0 0 -1];
axh(4).ZDir = 'reverse'; % makes out (towards screen) on bottom



% JUST ISOMETRIC
figh = figure;
axh = axes;

% plot cardinal axes
cardinalEdge = 0.13;
line([-cardinalEdge cardinalEdge], [0,0], [0,0], 'Color', 'k')
line([0,0], [-cardinalEdge cardinalEdge], [0,0], 'Color', 'k')
line([0,0], [0,0], [-cardinalEdge cardinalEdge], 'Color', 'k')


Plot3Dtrajectories( Rsets, 'axh', axh, 'colors', trialColors, 'showTarget', params.showTarget, 'targetRadius', params.displayTargetRadius  );


axh.GridLineStyle = 'none';


titlestr = sprintf('%sB%s', experiment, mat2str(trajectoryPlotBlock) );
figh.Name = titlestr;

% export_fig( [figuresPath titlestr '_iso'], '-eps' ) 


% saveas( figh, [figuresPath titlestr '_3views.fig'] );

print('-painters', [figuresPath titlestr '_iso.eps'], '-depsc' ) 
epsclean( [figuresPath titlestr '_iso.eps'] )
