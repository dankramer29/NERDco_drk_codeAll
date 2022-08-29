% Makes trial-averaged PSTHs from our high-DOF VR center-out-and-back datasets, and then
% applies jPCA to this data. Uses Mark Churchland's jPCA code published with Churchland et
% al 2012 Nature.
%
% Sergey Stavisky, 16 October 2017, Neural Prosthetics Translational Laboratory


clear

%% Select which data to analyze
experiment = 't5.2017.03.22';

% streamsPathRoot = ['/net/experiments/' participant '/']; % if on server
streamsPathRoot = [CachedDatasetsRoot '/NPTL/']; % if on my laptop
% figuresPath = ['/net/derivative/user/sstavisk/Figures/threeDandClick/' experiment '/' ];


datasetFunction = @datasets_3D;

%% Analysis Parameters
% TRIAL INCLUSION PARAMETERS
params.discardFirstTrial = true; % often first trial is centering.
% Only include blocks with gain . Note 'normal' was a range for t5.2017.03.22
params.minGain = 0.76;
params.maxGain = 1.21;
params.outwardOnly = true;
params.successfulOnly = true;
params.doubleSucccessfulOnly = true; % trial must have been preceded by successful trial

params.acceptTTTstd = 2; % accept only trials within this many s.d. of EACH TARGET's mean TTT
params.TTTevent = 'timeFirstTargetAcquire'; % can also define to timeLastTargetAcquire

% NEURAL PARAMETERS
params.thresholdRMSmultiplier = -4.5; % was standard for T5 for a while.
% params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts smoothed with Guassian of this std
params.neuralFeature = 'spikesBinnedRateGaussian_30ms'; % spike counts smoothed with Guassian of this std

params.downSampleEveryNms = 10; % will downsample firing rates this often. Needed for JPCA
% Channel exclusion same as in T5 analyses which found some weirdness in these channels
params.excludeChannels = sort( [[67, 68, 69, 73, 77, 78, 82], [2, 46, 66, 76, 83, 85, 86, 94, 95, 96] ] );


% ALIGNMENT PARAMETERS
% It grabs data with this alignment; jPCA is specified separately
params.alignEvent = 'timeGoCue';
params.startEvent = 'timeGoCue - 0.400';
params.endEvent = 'timeGoCue + 2.000';


% params.distanceThreshold = 0.00025; % trial start is when 0.5 cm from workspace center
% params.alignEvent = 'timeDistanceCrossing';
% params.startEvent = 'timeDistanceCrossing - 0.800';
% params.endEvent = 'timeDistanceCrossing + 0.700';



% It's nice to see some PSTHs, with the same color scheme as jPCA 
% These are chosen based on which channels were interesting from earlier PSTH analysis
% Should be an even number for a nicer plot
plotTheseElecs = {...
    'chan_1.6';
    'chan_1.7';
    'chan_1.9';
    'chan_2.4'; 
    'chan_2.7';
    'chan_2.32';
    'chan_2.85';
    'chan_2.86';
    'chan_2.89'; 
    'chan_2.92'...
    };


% TODO: I could bring AddTimeStartMovement.m up to date or do something like align to
% first crossing of some speed threshold

% Get things ready
figuresPath = [FiguresRoot '/NPTL/jPCA/' ];
if ~isdir( figuresPath )
    mkdir( figuresPath );
end

% Add jPCA code (from Churchland et al 2012, obtained from Chuchland lab website)
addpath( genpath( [CodeRootNPTL '/code/analysis/Sergey/generic/jPCA/'] ) );

%% Get the data
participant = experiment(1:2);

[dataset, condition] = datasetFunction( experiment );
% Restrict to blocks of specified gain
analyzeBlocks = condition.blocks(condition.gain >= params.minGain & condition.gain <= params.maxGain);
results.blocks = analyzeBlocks;
results.condition = condition;
results.dataset = dataset;

streamsPath = [streamsPathRoot experiment '/Data/FileLogger/']; 
R = [];
fprintf('Generating R from %s...\n', streamsPath );
for iBlock = 1 : numel( results.blocks )    
    myBlock = results.blocks(iBlock);
    fprintf('block %i ', myBlock);
    stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, myBlock ) ); % note excluding neural, which I don't need here
    Rin = onlineR( stream );   
    
    % I want to know if preveding trials were successful too
    for i = 2 : numel( Rin )
        if Rin(i-1).isSuccessful
            Rin(i).prevIsSuccessful = true;
        end
    end
          
    if params.discardFirstTrial
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
    
    % Get block-level performance metricss
    results.stats{iBlock} = CursorTaskSimplePerformanceMetrics( Rin );

    % Report these
    fprintf('Block %i (%.1f minutes): %i/%i trials (%.1f%%) successful. %.1f successes per minute. mean %.1fms TTT. Path efficiency = %.3f\n', ...
        results.stats{iBlock}.blockNumber, results.stats{iBlock}.blockDuration/60, results.stats{iBlock}.numSuccess, ...
        results.stats{iBlock}.numTrials, 100*results.stats{iBlock}.numSuccess/results.stats{iBlock}.numTrials, ...
        results.stats{iBlock}.successPerMinute, nanmean( results.stats{iBlock}.TTT ), nanmean( results.stats{iBlock}.pathEfficiency ) );

%     
%     if iBlock > 1
%         % Sometimes there are fields missing in incoming R struct (or vice versa), so just add it (hopefully it
%         % wont be one I need to use in all of them
%         [inRnotRin, inRinNotR] = CompareFieldsTwoStructs( R, Rin );
%         if ~isempty( inRnotRin )
%             for iMissing = 1 : numel( inRnotRin )
%                 Rin(1).(inRnotRin{iMissing}) = [];
%             end
%         end
%         if ~isempty( inRinNotR )
%             for iMissing = 1 : numel( inRinNotR )
%                 R(1).(inRinNotR{iMissing}) = [];
%             end
%         end        
%     end
    
    R = [R,Rin]; % add this block to all the other block being analyzed
end

% Apply trial restrictions
if params.outwardOnly
    R(CenteringTrialInds( R )) = [];
    fprintf('%i Outward trials\n', numel( R ) );
end

if params.successfulOnly
    R(~[R.isSuccessful]) = [];
    fprintf('%i Successful trials\n', numel( R ) );
end

if params.doubleSucccessfulOnly
    R(~[R.prevIsSuccessful]) = [];
    fprintf('%i Double-Successful trials\n', numel( R ) );
end

%% Create aligned neural feature
    
allTargs = [R.posTarget]';
numDims = nnz( sum( abs(allTargs) ,1 ) );% how many dimensions activey varied

switch numDims
    case 3
        [ targetIdx, uniqueTargets ] = SortTrialsBy3Dtarget( R );
        [ prevTargetIdx, uniquePrevTargets ] = SortTrialsBy3DpreviousTarget( R );
    case 4
        [ targetIdx, uniqueTargets ] = SortTrialsBy4Dtarget( R );
        [ prevTargetIdx, uniquePrevTargets ] = SortTrialsBy4DpreviousTarget( R );
    otherwise
        error('not defined for %i dimensions, numDims');
end

fprintf('%i Unique targets across %i DOF control\n', size( uniqueTargets, 1 ), numDims );



%% EVENT ALIGNMENT

% Try to do it based on distance from center
if strfind( params.alignEvent, 'timeDistanceCrossing')
    figh = figure;
    subplot(1,2,1);
    hold on;
    for iTrial = 1 : numel( R )
        myDistanceToCenter = sum( double( R(iTrial).cursorPosition ).^2, 1 );
        R(iTrial).distanceFromCenter = myDistanceToCenter;
        plot( myDistanceToCenter )
        R(iTrial).timeDistanceCrossing = find( R(iTrial).distanceFromCenter > params.distanceThreshold, 1, 'first' );
    end
    ylabel('Distance From Center (m)');
    xlabel('MS into trial')
    line( get( gca, 'XLim'), [params.distanceThreshold params.distanceThreshold], 'Color', 'k');
    
    subplot(1,2,2);
    histogram( [R.timeDistanceCrossing] );
    xlabel('Time Distance Crossing');
end

% 
% % Here's when I tried to do this using cursor speed. I don't think this is a great idea.
% % Add speed to each trial
% figh = figure;
% axh = axes; hold on;
% xlabel('Trial MS');
% for iTrial = 1 : numel( R )
%     % convert positions to speeds 
%     mySpeed = abs( diff( double( R(iTrial).cursorPosition' ) ) );
%     mySpeed = mySpeed(:,1:numDims);
%     % speed across all dims
%     mySpeed = sqrt( sum( mySpeed.^2, 2 ) );
%     R(iTrial).cursorSpeed = [mySpeed(1) mySpeed']; % replicates first sample to make same number of samples as other fields
% 
%     R(iTrial).peakSpeed = max( R(iTrial).cursorSpeed );
%     % normalize to MAXIMUM, not to range. 0 still means 0 m.s
%     R(iTrial).normalizedCursorSpeed = R(iTrial).cursorSpeed ./ R(iTrial).peakSpeed;
% %     plot( R(iTrial).normalizedCursorSpeed );
%     plot( R(iTrial).cursorSpeed );
% 
% end
% ylabel('speed( normalized)');
% fprintf('Mean/max peak speed is %g, %g\n', mean([R.peakSpeed]), max([R.peakSpeed]));
% 
% % Let's try setting a peak speed of 20% of mean
% speedThreshold = 0.5 * mean([R.peakSpeed]);
% % speedThreshold = 0.2 * max([R.peakSpeed]);
% for iTrial = 1 : numel( R )
%     R(iTrial).timeSpeedThreshold = find( R(iTrial).cursorSpeed >= speedThreshold, 1, 'first' );
% end
% figure; histogram(  [R.timeSpeedThreshold] ); title( sprintf( 'Crossing %g', speedThreshold ) );
% xlabel('MS'); ylabel('Count');

% plot initial cursor positions
% % loop
% figh = figure;
% axh = axes; hold on
% for iTrial = 1 : numel( R )
%     scatter3( R(iTrial).cursorPosition(1, R(iTrial).timeSpeedThreshold), ...
%         R(iTrial).cursorPosition(2, R(iTrial).timeSpeedThreshold), ...
%         R(iTrial).cursorPosition(3, R(iTrial).timeSpeedThreshold));
% end
% xlim([-0.1 0.1]);
% ylim([-0.1 0.1]);
% zlim([-0.1 0.1]);



%%

results.thresholds = params.thresholdRMSmultiplier .* channelRMS( R );  
% Do the data prepend so I can grab more
updateEventFields = {'trialLength', 'timeFirstTargetAcquire', 'timeLastTargetAcquire', ...
    'timeTargetOn', 'timeGoCue', 'timeDistanceCrossing'};
for iTrial = 1 : numel( R )
    prependMS = size( R(iTrial).preTrial.minAcausSpikeBand, 2 );
    R(iTrial).minAcausSpikeBand = [R(iTrial).preTrial.minAcausSpikeBand, R(iTrial).minAcausSpikeBand];
    for iField =1 : numel( updateEventFields )
        if isfield( R, updateEventFields{iField} )
            R(iTrial).(updateEventFields{iField}) = prependMS + R(iTrial).(updateEventFields{iField}) ;
        end
    end
end


% Add neural feature
R = RastersFromMinAcausSpikeBand( R, results.thresholds );
R = AddFeature( R, params.neuralFeature );
if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
end



%% Format the data for jPCA
jenga = AlignedMultitrialDataMatrix( R, 'featureField', params.neuralFeature, ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
jenga = TrimToSolidJenga( jenga );

% Subsample every X ms (Mark's code won't subsample itself)
% round to nearest params.downSampleEveryNms (avoids getting for example 1, 11, 21 ms
tMS = round( jenga.t.*1000 );
alignInd = find( tMS == 0 );
startInd = find( mod( tMS, params.downSampleEveryNms ) == 0, 1, 'first');
jenga.t = jenga.t(startInd:params.downSampleEveryNms:end);
jenga.dat = jenga.dat(:,startInd:params.downSampleEveryNms:end,:);
jenga.numSamples = size( jenga.t, 2 );
    
    
% This involves the key trial-averaging operation.
uniqueLabels = unique( targetIdx );
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels(iLabel);
    myTrials = find( targetIdx == myLabel );
    
    % Mean TTT for this trial
    myMeanTTT = mean( [R(myTrials).(params.TTTevent)] );
    myStdTTT = std( [R(myTrials).(params.TTTevent)] );
    tooFast = [R(myTrials).(params.TTTevent)] < myMeanTTT - params.acceptTTTstd*myStdTTT;
    tooSlow = [R(myTrials).(params.TTTevent)] > myMeanTTT + params.acceptTTTstd*myStdTTT;
    myTrials(tooFast | tooSlow) = [];
    fprintf('Label %s: excluding %i and %i trials (too fast/slow %s). %i trials left for jPCA\n', ...
       mat2str( myLabel ), nnz( tooFast ), nnz( tooSlow ), params.TTTevent, numel( myTrials ) ); 
    
    % trial-average within this condition   
    % in doing so, round to nearest step size
    Data(iLabel).A = squeeze( mean( jenga.dat(myTrials,:,:), 1 ) );
    Data(iLabel).times = round( 1000.*jenga.t)'; % converted to ms 
end

%% Make jPCA Plots
params.jPCA_params.softenNorm = 10;
params.jPCA_params.suppressBWrosettes = true;
params.jPCA_params.suppressHistograms = true;
params.jPCA_params.meanSubtract = true;
params.jPCA_params.numPCs = 6;


% GO CUE ALIGNMENT;
[Projection, Summary] = jPCA( Data, 50:params.downSampleEveryNms : 450, params.jPCA_params );
% 
% DISTANCE CROSSING ALIGNMENT
% [Projection, Summary] = jPCA( Data, -450:params.downSampleEveryNms : -050, params.jPCA_params );
% 


% plot
plotParams.planes2plot = [1]; % PLOT
[colorStruct, haxP, vaxP] = phaseSpace( Projection, Summary, plotParams );
fprintf('%i PCs used capture %.4f overall variance (%s)\n', ...
    params.jPCA_params.numPCs, sum(Summary.varCaptEachPC(1:end)), mat2str( Summary.varCaptEachPC , 4 ) )

% identify the groups 
[ indsLeftToRight, cmap ] = whichGroupIsWhichJpca( Projection );

% Label the end points of each condition with its label. Note this won't work if more than
% one plane was plotted (because it'll try to plot on the last plane using data from first
% plane. So make plotParams.planes2plot = 1 to use this .
figh = gcf;
for iLabel = 1 : numel( uniqueLabels )
   myH = Projection(iLabel).proj(end,1);
   myV = Projection(iLabel).proj(end,2);
   th(iLabel) = text( myH, myV, mat2str( uniqueLabels(iLabel) ) );
end

%% Also plot PCs for context
figh = figure;
figh.Color = 'w';
numPCs = size( Summary.PCs, 2 );
t = Projection(1).times;
for iPC = 1 : numPCs
    axh(iPC) = subplot( 2, numPCs/2, iPC );
    hold on;
    for iLabel = 1 : numel( uniqueLabels )
        myThisPC = Projection(iLabel).tradPCAproj(:,iPC);
        hplot(iLabel) = plot( t, myThisPC, 'Color', cmap(iLabel,:) );
    end
    xlim( [t(1) t(end)] );
    title( sprintf('PC%i (%.1f%%)', iPC, 100*Summary.varCaptEachPC(iPC)) );
end

%% Sanity Check, plot a few electrodes
% should be even number of channels
figh = figure;
figh.Color = 'w';
numPlots = numel( plotTheseElecs );
t = Data(1).times;
elecsMinHz = inf; % will be used to standardize 
elecsMaxHz = -inf;
for iChan = 1 :numPlots
    axh(iChan) = subplot( 2, numPlots/2, iChan );
    myChanInd = strcmp( R(1).(params.neuralFeature).channelName, plotTheseElecs{iChan} );
    hold on;
    for iLabel = 1 : numel( uniqueLabels )
        myFR = Data(iLabel).A(:,myChanInd);
        hplot(iLabel) = plot( t, myFR, 'Color', cmap(iLabel,:) );
        elecsMinHz = min( [elecsMinHz, min( myFR )] );
        elecsMaxHz = max( [elecsMaxHz, max( myFR )] );
    end
    xlim( [t(1) t(end)] );
    title( sprintf('%s', plotTheseElecs{iChan} ), 'Interpreter', 'none' );
    
    
    
end
linkaxes( axh );
xlim( [t(1) t(end) ])
ylim( [elecsMinHz elecsMaxHz] )

% mark analysis epoch for jPCA

for iChan = 1 : numPlots
   axes( axh(iChan) );
   myYlim = get( gca, 'YLim' );
   line( [ Projection(1).times(1) Projection(1).times(1)], myYlim, ...
       'Color', [0.5 0.5 0.5], 'LineWidth', 0.5 );
    line( [ Projection(1).times(end) Projection(1).times(end)], myYlim, ...
       'Color', [0.5 0.5 0.5], 'LineWidth', 0.5 )
end

%% Make a movie
movParams.times = -300:10:1500; % GO CUE ALIGNMENT


movParams.pixelsToGet = [600 500 560 420]; % depends on monitor
MV = phaseMovie(Projection, Summary, movParams);
figure; movie(MV); % shows the movie in a matlab figure window
movie2avi(MV, 'jPCA movie', 'FPS', 12, 'compression', 'none'); % 'MV' now contains the movie