% randomTargetTaskOneDataset.m
% Loads and analyzes one NPTL dataset where a Random Target Task (e.g. 5D
% Random Target Task) was run. Looks at various kinematics measurements, with an eye
% to quantifying performance.
% Now expanded to work for 4D or 5D (spherical coordinate) variants, by
% passing in a datasetFunction.
%
% Called by WORKUP_RandomTargetTaskPerf.m
%
% USAGE: [ results, figh ] = randomTargetTaskOneDataset( dataset, params, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     dataset                   query into a datsets lookup function. E.g. 't5.2017.03.20'
%     params                    Analysis parameters
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS
%     results          Results file that can then be quickly loaded for
%                      across-datasets analysis.
%     figh             If a figure is generated, this is its handle.
%
% Created by Sergey Stavisky on 24 April 2017 using MATLAB version 9.0.0.341360 (R2016a)

 function [ results, figh ] = randomTargetTaskKinematicsOneDataset( dataset, params, varargin )
def.datasetFunction = @datasets_5D;
def.streamsPathRoot = ['/net/experiments/'];
def.participant = dataset(1:2);
def.randomTargetTaskValue = 7; % how I coded the Random Target task in my datasetFunction.
def.discardFirstTrial = true; % first trial often weird, just ignore. 
params = structargs( def, params );
assignargs( def, varargin );

results.params = params;
 
% -------------------------------------------------------------
%% Get the R structures
% -------------------------------------------------------------
[dataset,condition] = datasetFunction( dataset );
% restrict to hypersphere task.
if isfield( condition, 'task' );
    analyzeBlocks = condition.blocks(condition.task == randomTargetTaskValue);
else
    analyzeBlocks = condition.blocks;
end
results.blocks = analyzeBlocks;
results.condition = condition;
results.dataset = dataset;
streamsPath= [params.streamsPathRoot  participant '/' dataset '/Data/FileLogger/'];
R = [];
fprintf('Generating R from %s...\n', streamsPath );
for iBlock = 1 : numel( results.blocks )    
    myBlock = results.blocks(iBlock);
    fprintf('block %i ', myBlock);
    stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, myBlock ), {'neural'} ); % note excluding neural, which I don't need here
    Rin = onlineR( stream );     
    if discardFirstTrial
        Rin(1) = [];
    end  
    fprintf(' %i trials loaded\n', numel( Rin ) );

    % Am I supposed to remove any trials from this block?
    if isfield( condition, 'removeFirstNtrials' )
        if any(  condition.removeFirstNtrials(:,1) == myBlock  )
            Rin = Rin(condition.removeFirstNtrials( condition.removeFirstNtrials(:,1) == myBlock,2)+1:end);
            fprintf('  removed first %i trials of this block per analysis instructions\n', condition.removeFirstNtrials( condition.removeFirstNtrials(:,1) == myBlock,2))
        end
    end
    
    % Get block-level performance metrics;
    if isfield( condition, 'radiusCounts') && condition.radiusCounts
        radiusCounts = true;
    else
        radiusCounts = false;
    end
    stats{iBlock} = CursorTaskSimplePerformanceMetrics( Rin, 'radiusCounts', radiusCounts );

    % Report these
    fprintf('Block %i (%.1f minutes): %i/%i trials (%.1f%%) successful. %.1f successes per minute. mean %.1fms TTT.\n', ...
        stats{iBlock}.blockNumber, stats{iBlock}.blockDuration/60, stats{iBlock}.numSuccess, stats{iBlock}.numTrials, 100*stats{iBlock}.numSuccess/stats{iBlock}.numTrials, ...
        stats{iBlock}.successPerMinute, nanmean( stats{iBlock}.TTT ) );
    fprintf('     Dial in time %.1fms. %.2f mean incorrect clicks. Path efficiency = %.3f\n', ...
        mean( stats{iBlock}.dialIn ), mean( stats{iBlock}.numIncorrectClicks ), nanmean( stats{iBlock}.pathEfficiency ) );
    
    if iBlock > 1
        % Sometimes there are fields missing in incoming R struct (or vice versa), so just add it (hopefully it
        % wont be one I need to use in all of them
        [inRnotRin, inRinNotR] = CompareFieldsTwoStructs( R, Rin );
        if ~isempty( inRnotRin )
            for iMissing = 1 : numel( inRnotRin )
                Rin(1).(inRnotRin{iMissing}) = [];
            end
        end
        if ~isempty( inRinNotR )
            for iMissing = 1 : numel( inRinNotR )
                R(1).(inRinNotR{iMissing}) = [];
            end
        end        
    end
    
    R = [R,Rin]; % add this block to all the other block being analyzed
end
results.stats = stats; % save block-level stats

% Calculate whole block metrics. 
results.wholeDatasetStats = CursorTaskSimplePerformanceMetrics( R, 'radiusCounts', radiusCounts  );

%% Compute peak speed and other trial-wise metrics on each trial
%( across the whole trial)
allTargs = [R.posTarget]';
numDims = nnz( sum( abs(allTargs) ,1 ) );% how many dimensions activey varied

results.peakSpeedEachDim = nan( numel(R), numDims );
results.peakSpeed = nan( numel(R), 1 );
results.isSuccessful = logical( [R.isSuccessful] );
for iTrial = 1 : numel( R )
    % convert positions to speeds 
    mySpeed = abs( diff( R(iTrial).cursorPosition' ) );
    mySpeed = mySpeed(1:numDims);
    % speed across all dims
    results.peakSpeedEachDim(iTrial,:) = max( mySpeed );
    results.peakSpeed(iTrial) = max( sqrt( sum( diff( R(iTrial).cursorPosition' ).^2,2 ) ) );
end





end