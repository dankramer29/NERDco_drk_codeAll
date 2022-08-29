% Uses the breath sensor data (respiratory breath transducer) to detect breaths, and then aligns firing rates to that.
%
%
% Note: The raw data (both neural and breath sensor, which was an analog input to the NSP)
% are pre-processed from the .ns5 by processBreathingDataset.m and then
% thresholdContinuousBreathingSPikeBand.m
%
% Chance firing rate modulations are done with a faux breath shuffle. To make this memory
% tractable, I loop through each shuffle to do the complete analysis (ending in
% trial-averaging), otherwise it'd demand too much memory.
%
% Plots mean +- SEM example channels. Can handle sorted or unsorted RMS waveforms,
% depending on pre-processing.
%
% Sergey Stavisky 13 November 2018
clear
rng(1);

saveResultsRoot = [ResultsRootNPTL '/speech/breathing/'];



% viz.pvalue = 0.002; % plot chance distribution boundary at this p value (two-sided it's 0.001)
viz.pvalue = 0.02; % plot chance distribution boundary at this p value (two-sided it's 0.01)

viz.numBreathsToPlot = 200; % downsample to make it manageable
viz.plotExampleChans = [23, 72, 186]; % threshold crossings
% viz.plotExampleChans = []; % if sorted, figure plots appear in top 8 anyway

% List files here. Script will automatically append _audio.mat and _spikeRasters.mat
% Each file corresponds to one block.

%% Free breathing
participant = 't5';

params.forceDeadChannels = []; % by default, find dead channels from data

% ORIGINAL eLIFE SUBMISSION

% params.clipSecondsStart = 0; % no need for excising data at start/stop of block
% params.clipSecondsEnd = 0;
% % 
% dataFiles = {...
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_0'];
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_1'];
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_2'];
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_3'];
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_4'];
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_5'];
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_6'];
%     [CachedDatasetsRoot '/NPTL/t5.2018.10.24_Breathing_Fitts/block_passive'];
%     };

% dataFiles = {...
%     [CachedDatasetsRoot '/NPTL/t5.2018.10.24_Breathing_Fitts/block_passive'];
%     };
% passive only

% pre artifact
% dataFiles = {...
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_0'];
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_1'];
%     [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/block_2'];
%     };
% dataFiles = {...
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_0';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_1';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_2';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_3';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_4';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_5';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_6';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_passive';
%     };

% % or just load complete neural pre-processing/shuffle analyses
% load( '/Users/sstavisk/Results/speech/breathing/block_0_cb414d8b2ddb662af9efe48f71f2ef6e_a5c6ae275c3b9cb3335175352b4d8a8b.mat') % TC
% load( '/Users/sstavisk/Results/speech/breathing/block_0_784605db34ea6a27a947197202a5bb1a_72ab13c5c49bd08ce5e6aa4f1e3d5215.mat' ); % SORTED
% params.forceDeadChannels = [];


%% Instructed breathing
dataFiles = { ...
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_9';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_10';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_11';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_12';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_13';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_14';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_15';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_16';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_17';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_18';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_19';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_20';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_21';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_22';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_23';
    };
% 
% dataFiles = { ...
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_9';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_10';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_11';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_12';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_13';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_14';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_15';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_16';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_17';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_18';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_19';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_20';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_21';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_22';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.10.24_Breathing_Fitts/block_23';
%     };
params.clipSecondsStart = 30; % avoids start and end of the block where breath meter is recording but task isn't running yet
params.clipSecondsEnd = 15;
% % 
% % 
% or just load complete neural pre-processing/shuffle analyses
load( '/Users/sstavisk/Results/speech/breathing/block_9_3c77739bb821e06b13b105ed2cb22e90_bffeb6bb51d170c0fc5613df9240fd9e.mat' ); % TCs
% load( '/Users/sstavisk/Results/speech/breathing/block_9_7e422918c4cdc38987d0a430bfe65869_bffeb6bb51d170c0fc5613df9240fd9e.mat' ); %SORTED


% use dead channels list from the unattended analysis (which more overall trials), so we end up comapring the same
% group of channels
inUnattended = load( '/Users/sstavisk/Results/speech/breathing/readyToPlot_block_0_1f64586ac2ba660b628ca2bdba7176b6_a5c6ae275c3b9cb3335175352b4d8a8b.mat' );
params.forceDeadChannels = inUnattended.deadChans;

% alternatively, find dead channels from this data (not recommended)
% params.forceDeadChannels = [];

%%
datasetName = regexprep( pathToLastFilesep(dataFiles{1},1), {'.mat', 'R_'}, '');

switch participant
    case 't5'
        arrayMaps ={'T5_lateral', 'T5_medial'};
    case 't8'
        arrayMaps = {'T8_lateral', 'T8_medial'};
end


%% Breath detection parameters


% These are parameters for the findBreaths.m function, which looks for breath peaks
params.removeDiffGreaterThan = 50; % outlier values have diff of this
params.filterAp = 0.2; % passband ripple
params.filterPb = 3; % passband (Hz)
params.filterAst = 50; % stop band attenuation (dB)
params.minPeakDistance = 1; % in seconds
params.minPeakProminenceFractionOfBigPeak = 0.3; % look for breaths at least this big compared to median 'big' breaths

% for plotting breath-aligned stretch sensor and neural data. 
% This function saves the 30ksps breath sensor data at 1 ms resolution (simple
% downsampling)
params.breath.secsBeforeBreath = 2;
params.breath.secsAfterBreath = 1.5;
params.psthSmoothingGaussianSD = 25; % in milliseconds. Matches what was used for PSTHS during speaking.

% Shuffle test
params.numShuffles = 1001;

% Use sorted spikes?
% params.useSorted = true;
params.useSorted = false;



% Dev (speeds up analyses)
% params.numShuffles = 2;
% viz.pvalue = 0.5; % plot chance distribution boundary at this p value


%% Generate Gaussian kernel for smoothing
% need to know its length to avoid edges)
% Gaussian smooth the rasters
numSTD = 3; % will make the kernel out to this many standard deviations
% now make the Gaussian kernel out to 3 standard deviations
x = -numSTD*params.psthSmoothingGaussianSD:1:numSTD*params.psthSmoothingGaussianSD;
gkern = normpdf( x, 0, params.psthSmoothingGaussianSD );
% normalize to area 1
gkern = gkern ./ sum( gkern );
nShift = floor( numel( gkern ) / 2 ); % shift back neural data so the Gaussian smoothing doesn't add latency
bufferS = (nShift+2)/1000; % avoid edge of files by this much more so no nans in trial average


%% Load breath times
breathTimesEachBlock = {}; % in seconds
allBreathTraces = []; % will fill with data
% Populate breath-aligned sensor times for each block
for iBlock = 1 : numel( dataFiles )
    myBreathFile = [dataFiles{iBlock} '_audio.mat'];
    inB = load( myBreathFile );
    myBlockName = pathToLastFilesep( dataFiles{iBlock}, 1 );
    [bTimesThisBlock, smoothBreath] = findBreaths( inB, params, 'blockName', myBlockName, 'showPlots', true );
    % don't accept breaths that happen too early or late in a block, since we won't be able to get the
    % neural data.
    startCutoff = max( (params.breath.secsBeforeBreath+bufferS), params.clipSecondsStart )*inB.FsRaw;   % extra 100 ms buffer for the Gaussian smoothing
    tooEarlyBreaths = find( bTimesThisBlock < startCutoff );
    bTimesThisBlock(tooEarlyBreaths) = [];
    endCutoff =  numel( smoothBreath ) - inB.FsRaw * max( params.breath.secsAfterBreath+bufferS, params.clipSecondsEnd );
    tooLateBreaths = find( bTimesThisBlock > (numel( smoothBreath ) - (params.breath.secsAfterBreath+bufferS)*inB.FsRaw) );
    bTimesThisBlock(tooLateBreaths) = [];
    
    breathTimesEachBlock{iBlock} = bTimesThisBlock ./ inB.FsRaw;
    myBreaths = nan( numel( bTimesThisBlock ), numel( -params.breath.secsBeforeBreath :0.001:params.breath.secsAfterBreath  ) );
    for i = 1 : numel( bTimesThisBlock )
        mySamples = bTimesThisBlock(i) - (params.breath.secsBeforeBreath*inB.FsRaw) : inB.FsRaw/1000 : bTimesThisBlock(i) + (params.breath.secsAfterBreath*inB.FsRaw);
        myBreaths(i,:) = smoothBreath(mySamples);
    end
    allBreathTraces = [allBreathTraces; myBreaths];
end
FsBreath = inB.FsRaw;
clear('inB');
% get average breath
meanBreathTrace = mean( allBreathTraces, 1 );


%% Plot the breaths
figh = figure;
figh.Name = 'All breaths';
title('All breaths');
breathT = -params.breath.secsBeforeBreath : 0.001 : params.breath.secsAfterBreath;
totalNumberBreaths = size( allBreathTraces, 1 );
fprintf('Plotting %i/%i breaths\n', viz.numBreathsToPlot, totalNumberBreaths )
% pick breaths
plotTheseBreaths = indexEvenSpaced( totalNumberBreaths, viz.numBreathsToPlot);
plot( breathT, allBreathTraces(plotTheseBreaths,:), 'Color', [.7 .7 .7], 'LineWidth', 0.5 );
hold on;
% plot the mean
plot( breathT, meanBreathTrace, 'Color', 'k', 'LineWidth', 2 )
xlabel('Time after breath peak (s)');
ylabel('Abdomen diameter (AU)')
axh = figh.Children;
axh.TickDir = 'out';

% keyboard
%% Load the neural data, smooth it, save for subsequent breath-evoked trial averaging
smoothNeuralEachBlock = {};
spikeBand_RMS = [];
for iBlock = 1 : numel( dataFiles )
    if params.useSorted 
        myNeuralFile = [dataFiles{iBlock} '_sortedSpikeRasters.mat'];
    else
        myNeuralFile = [dataFiles{iBlock} '_spikeRasters.mat'];
    end
    fprintf( 'Loading and smoothing %s...\n', myNeuralFile)

    inN = load( myNeuralFile );
    if params.useSorted
       sortInfo.ssSortQualityFiles = inN.ssSortQualityFiles;
       sortInfo.unitArray = inN.unitArray;
       sortInfo.unitChannel = inN.unitChannel;
       sortInfo.unitSortRating = inN.unitSortRating;
       sortInfo.ssTxtFiles = inN.ssTxtFiles;
    else
        sortInfo = nan;
    end
        
    Nchans = size( inN.spikeRasters, 2 );
       
    spikeBand_RMS = [spikeBand_RMS; inN.spikeBand_RMS];
    smoothNeural = double( 1000.*inN.spikeRasters );
    smoothNeural = filter( gkern, 1, smoothNeural );
    smoothNeural = smoothNeural(nShift+1:end,:);
    smoothNeural = [smoothNeural; nan( nShift, size( smoothNeural,2) )];
    smoothNeuralEachBlock{iBlock} = smoothNeural;
end
FsNeural = inN.FsSpikeBand;
clear('inN');

%% Concatenated firing rates across all blocks
% I'm using this to find when the abrupt firing rate shift on array 2 happened
allBlocksSmoothed = cell2mat( [smoothNeuralEachBlock'] );
blockEnds = cumsum( cellfun( @(x) size(x,1), smoothNeuralEachBlock ) );
figh = figure; 
figh.Name = 'Big Waterfall';
imh = imagesc( allBlocksSmoothed );
axh = gca;
for i = 1 : numel( blockEnds )
    line( axh.XLim, [blockEnds(i), blockEnds(i)], 'Color', 'w' );
end
fprintf('These end at t = %.1fs\n', size( allBlocksSmoothed, 1 )/FsNeural )

% figh = figure;
% imagesc( spikeBand_RMS ); 
% figh.Name = 'Spike Band RMS Each Block';



%% Loop through the real data and the shuffles to get breath-triggered trial-average firing rates
% make breath-aligned rasters


% will end up filling these variables
trialAverageFR = [];
trialAverageFR_shuffle = []; 

% in seconds, also used to figure out how many neural samples I'll grab around each breath
rasterT = -params.breath.secsBeforeBreath : 1/FsNeural : params.breath.secsAfterBreath;
for iLoop = 1 : 1 + params.numShuffles
    allRasters = []; % will be filled for either shuffle or real data
    
    fprintf('Loop %i/%i, block: ', iLoop, 1 + params.numShuffles )  
    for iBlock = 1 : numel( smoothNeuralEachBlock )    
        fprintf('%i ', iBlock )
        % get this block's breath times. Convert to ms to match sampling rate of rasters
        myBreathSamples = round( breathTimesEachBlock{iBlock}*FsNeural );
        
        if iLoop > 1 % is this a shuffle?
            % SHUFFLE TEST
            % what are the earliest and latest I can sample?
            earliestPossible = ceil( params.breath.secsBeforeBreath * FsNeural ) + nShift + 1;
            latestPossible = floor( size( smoothNeuralEachBlock{iBlock}, 1 ) - params.breath.secsAfterBreath * FsNeural ) - nShift - 1;
            % uniformly distributed samples, same number as actual trials.
            myBreathSamples = round( (latestPossible-earliestPossible).*rand( numel( myBreathSamples ), 1 ) + earliestPossible );
        end
        
        
        myRasters = nan( numel( myBreathSamples ), numel( rasterT ), Nchans ); % trials x samples x channels
        for iTrial = 1 : numel( myBreathSamples )
            mySamples = myBreathSamples(iTrial) - (params.breath.secsBeforeBreath*FsNeural) : myBreathSamples(iTrial) + (params.breath.secsAfterBreath*FsNeural);
            myRasters(iTrial,:,:) = smoothNeuralEachBlock{iBlock}(mySamples,:);
        end
        allRasters = cat( 1, allRasters, myRasters );
    end    
    fprintf('\n');    
    if iLoop == 1 % real data
       trialAverageFR = squeeze( mean(  allRasters, 1 ) ); % time x channel
       for iChan = 1 : Nchans
           trialSEMFR(:,iChan) =  nansem( squeeze( allRasters(:,:,iChan) ) ); % time x channel
       end
    else % shuffle
        trialAverageFR_shuffle = cat( 3, trialAverageFR_shuffle,  squeeze( mean(  allRasters, 1 ) ) ); % time x channel x shuffle
    end
end
numTrials = size( allRasters, 1 );

%% Save the results
resultsFilename = [saveResultsRoot datasetName structToFilename( params ) '_'  DataHash( CellsWithStringsToOneString( dataFiles ) ) '.mat'];
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end
% saving the processed data (so they can be compared between datasets, for example, would
% happen here.
fprintf('Saving results to \n%s', ...
    resultsFilename );
save( resultsFilename, 'params', 'dataFiles', 'trialAverageFR_shuffle', 'trialSEMFR', ...
    'rasterT', 'FsNeural', 'numTrials', 'trialAverageFR', 'sortInfo', '-v7.3' )
fprintf(' DONE\n')

% *****
% continue from here if loading completed results
% *****

% Nchans = 96; % ignore array 2

%% Channels with < 1 Hz firing rates are considered dead
fprintf('%i trials\n', numTrials);
Nchans = size( trialAverageFR, 2 );

if isempty( params.forceDeadChannels  )
    deadChans = find( mean( trialAverageFR, 1 ) < 1 );
    fprintf('%i channels had firing rate < 1 Hz. Considered dead for subsequent analyses\n', numel( deadChans ) );
else
    deadChans = params.forceDeadChannels;
    fprintf('using forced dead channels from a file; %i channels considered dead for subsequent analyses\n', numel( deadChans ) )
end
liveChans = setdiff( 1:Nchans, deadChans );
numLiveChans = numel( liveChans );

    
%% Calculate confidence bound for each channel
% two sided, so use half the p value for each side
Nshuffles = size( trialAverageFR_shuffle, 3 );
upperBoundInd = round( (1 - 0.5*viz.pvalue) * Nshuffles );
lowerBoundInd = round( (0.5*viz.pvalue) * Nshuffles );

timeBoundsEachChan = nan( size( trialAverageFR, 1 ), Nchans, 2 ); % will be time x chan x 2 where last dimension is (lower, upper)
significantChannels = []; % which channels significantly break above or below the chance bound.
fprintf('Calculating significance bounds chan: ')
for iChan = 1 : Nchans
    fprintf('%i ', iChan );
%     % This way looks at the highest point amongst all shuffles at any given time point. I decided this wasn't fair (it's overly generous to the fluctuations
%     % of the shuffles. 
%     for t = 1 : size( trialAverageFR, 1 )
%        myTshuffles =  sort(  squeeze( trialAverageFR_shuffle(t,iChan,:) ), 'ascend' );
%        timeBoundsEachChan(t,iChan,1:2) = myTshuffles([lowerBoundInd,upperBoundInd]);       
%     end

    % This way looks at the highest and lowest value the shuffle takes at any given time point
    highestShuffle = sort( max( squeeze( trialAverageFR_shuffle(:,iChan,:) ), [], 1  ), 'ascend' ); % FIXED
    lowestShuffle = sort( min( squeeze( trialAverageFR_shuffle(:,iChan,:) ), [], 1  ), 'ascend' );
    timeBoundsEachChan(:,iChan,2) =  highestShuffle(upperBoundInd);
    timeBoundsEachChan(:,iChan,1) =  lowestShuffle(lowerBoundInd);

    
    highCrossings = find( trialAverageFR(:,iChan) > timeBoundsEachChan(:,iChan,2) );
    lowCrossings = find( trialAverageFR(:,iChan) < timeBoundsEachChan(:,iChan,1) );
    if ~isempty( highCrossings ) || ~isempty( lowCrossings )
        significantChannels(end+1) = iChan;
    end
end
fprintf('\n')

significantChannels = setdiff( significantChannels, deadChans );
fprintf('%i/%i (%.1f%%) channels significantly modulate at p=%g (each side, choose index %i and %i of %i shuffles)\n', ...
    numel( significantChannels ), numLiveChans, 100*numel( significantChannels )/numLiveChans, ...
    viz.pvalue, upperBoundInd, lowerBoundInd, Nshuffles )



%% across-channels firing rate
figh = figure;
hold on
grandMean = mean( trialAverageFR(:,liveChans), 2 );
% grandSEM = nansem( meanRasters' );
% plot(rasterSamples, grandMean - grandSEM, 'Color', 'k', 'LineWidth', 0.5 )
% plot(rasterSamples, grandMean + grandSEM, 'Color', 'k', 'LineWidth', 0.5 )
plot( rasterT,  grandMean , 'Color', 'k', 'LineWidth', 2 )
xlabel('Time after breath peak (s)');
ylabel('Population Firing Rate (Hz)')
titlestr = 'Grand Mean FR';
figh.Name = titlestr;

%% Modulation depth
modulationDepth = nan( Nchans, 1 ); % max - minimum in the analysis window
for iChan = 1 : Nchans
    modulationDepth(iChan) = max( trialAverageFR(:,iChan) ) - min( trialAverageFR(:,iChan) );
end
modulationDepth(deadChans) = -inf;
[vals, chanInd] = sort( modulationDepth, 'descend' );
fprintf('Top 10 by modulation depth: chans %s\n', mat2str( chanInd(1:10) ) )
modulationDepth(deadChans) = nan;
fprintf('Mean modulation depth = %.3f Hz, median = %.3fHz\n', nanmean( modulationDepth ), nanmedian( modulationDepth ) );

%% can save essential results so that they can be loaded in FIGURE_breathModDepths
resultsEssentialFilename = [saveResultsRoot 'readyToPlot_' datasetName structToFilename( params ) '_'  DataHash( CellsWithStringsToOneString( dataFiles ) ) '.mat'];

if ~exist( 'sortInfo' )
    sortInfo = [];
end

% saving the processed data (so they can be compared between datasets, for example, would
% happen here.
fprintf('Saving results to \n%s', ...
    resultsEssentialFilename );
pvalue = viz.pvalue;
save( resultsEssentialFilename, 'params', 'dataFiles', 'modulationDepth', 'grandMean', ...
    'rasterT', 'FsNeural', 'numTrials', 'sortInfo', 'deadChans', 'significantChannels', 'pvalue', '-v7.3' )
fprintf(' DONE\n')






%% Modulation depth overhead plot
chanMap = channelAnatomyMap (arrayMaps, 'drawMap', false);
figh = figure;
figh.Renderer = 'painters';
titlestr = sprintf('Array tuning modulation' );
figh.Name = titlestr;
graymap = flipud( bone( 256 ) ); 
% start it at a light gray
graymap = graymap(26:end,:);
drawnAlready = []; % will track which electrodes were drawn as having something on them
axh = axes;
hold on;
axh.XLim = chanMap.xlim;
axh.YLim = chanMap.ylim;
axis equal
disabledSize = 4;
disabledColor = graymap(1,:);
% need to know the values range to scale the color map.


MDminMax = [floor( min( modulationDepth(liveChans) ) ) ceil( max( modulationDepth(liveChans) ) )];
for iChan = 1 : Nchans
    % Data to plot.
    if ismember( iChan, liveChans )
        % special bonus plot: sum across how many are tuned.
        myDat = modulationDepth(iChan);
        myColor =  graymap( floor( size(graymap,1)*(myDat-MDminMax(1))/range( MDminMax ) )+1 ,:);
        mySize = 36;
        
    else
        % Disabled chans
        mySize = disabledSize;
        myColor = disabledColor;
    end
    if isfield( params, 'useSorted') && params.useSorted
        myChanNum = 96*(sortInfo.unitArray(iChan)-1) + sortInfo.unitChannel(iChan);
    else
        myChanNum = iChan;
    end
    x = chanMap.x(myChanNum);
    y = chanMap.y(myChanNum);
    
    % draw the point
    scatter( x, y, mySize, myColor, 'filled' )
end
colormap( graymap );
cmaph =colorbar;
for i = 1 : numel( cmaph.TickLabels )
    cmaph.TickLabels{i} = [];
end
cmaph.TickLabels{1} = MDminMax(1);
cmaph.TickLabels{end} = MDminMax(end);
cmaph.Label.String = 'Modulation Depth (Hz)';
    
%% Plot an example channel
examplesToShow = [chanInd(1:10); chanInd(ceil( Nchans/2 )-2:ceil( Nchans/2 )+2)]; % show most modulating and some in-between ones
% examplesToShow = deadChans(1:5)
% examplesToShow = [7,8,10,17];
examplesToShow = [examplesToShow; viz.plotExampleChans'];
for iChan = 1 : numel( examplesToShow )
    myChan = examplesToShow(iChan);
    if isfield( params, 'useSorted') && params.useSorted
        myName = sprintf('unit%i.%iquality%.1f', sortInfo.unitArray(myChan), sortInfo.unitChannel(myChan), sortInfo.unitSortRating(myChan) );
    else
        myName = sprintf('elec%i', myChan );
    end
    figh = figure;
    hold on;
    
    % plot shuffles bounds
    plot( rasterT, squeeze( timeBoundsEachChan(:, myChan, : ) ), 'Color', [.5 .5 .5], 'LineWidth', 0.5 )
    
    % plot real data
    plot( rasterT, trialAverageFR(:, myChan ) - trialSEMFR(:, myChan ), 'Color', 'k', 'LineWidth', 0.5 );
    plot( rasterT, trialAverageFR(:, myChan ) + trialSEMFR(:, myChan ), 'Color', 'k', 'LineWidth', 0.5 );    
    plot( rasterT, trialAverageFR(:, myChan ), 'Color', 'k', 'LineWidth', 2 );
    titlestr = sprintf('breath-triggered %s FR, MD = %.2fHz, signif=%i', myName, modulationDepth(myChan), ismember( myChan, significantChannels ) );
    figh.Name = titlestr;
    title( titlestr );    
end
    



%% Magnitude change from mean
meanFReachChan = mean( trialAverageFR, 1 );
deviationEachChan = abs( trialAverageFR - repmat( meanFReachChan, size( trialAverageFR,1 ), 1 ) );
grandDeviation = mean( deviationEachChan, 2 );
figh = figure;
hold on
plot( rasterT,  grandDeviation , 'Color', 'k', 'LineWidth', 2 )
xlabel('Time after breath peak (s)');
ylabel('Population Deviation From Mean (Hz)')
titlestr = 'Grand Deviation from Mean FR';
figh.Name = titlestr;



% below plots example channels to show what I'm doing
for iChan = 1 : numel( examplesToShow )
    myChan = examplesToShow(iChan);
    figh = figure;
    hold on;
    
    plot( rasterT, trialAverageFR(:, myChan ), 'Color', [0.5 0.5 0.5], 'LineWidth', 1 );
    line( [rasterT(1), rasterT(end)], [meanFReachChan(myChan) meanFReachChan(myChan)], 'Color', [.3 .3 .3], 'LineWidth', 1 )
    plot( rasterT, deviationEachChan(:, myChan), 'Color', 'k', 'LineWidth', 2 )
    titlestr = sprintf('breath-triggered chan%i deviation from mean', myChan );
    figh.Name = titlestr;
    title( titlestr );    
end
