% Calculates neural data in some window for each channel.
% Then can look for which channels are tuned using a comparison to silence or ANOVA.
%
% Sergey Stavisky, December 17 2017
%
% There was an earlier version of this called WORKUP_cueAndSpeechPSTHs.m that operated on
% pilot data. This is a more cleaned up version that does some additional nice things.
clear


saveResultsRoot = [ResultsRootNPTL '/speech/tuning/'];




%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted.3 The RESPONSE label ('ga' in above example) is used as the label for this trial.


% t5.2017.10.23 Phonemes
% participant = 't5';
% % Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-phonemes.mat'; 
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-phonemes_lfpPow_125to5000_50ms.mat'; % has spikes
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10.23-phonemes' );
% params.acceptWrongResponse = true;


% t5.2017.10.23 Movements
% participant = 't5';
% % Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-movements.mat';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-movements_lfpPow_125to5000_50ms.mat'; % has spikes
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10.23-movements' );
% params.acceptWrongResponse = false;


% t5.2017.10.25 Words
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10.25-words' );
% params.acceptWrongResponse = false;

% t8.2017.10.17 Phonemes
% participant = 't8';
% % Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-phonemes.mat';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10.17-phonemes' );
% params.acceptWrongResponse = true;
% saturateMapOneBelow = true; % so that the two plots in Fig 1 have same scale desptie t5 missing a phoneme

% t8.2017.10.17 Movements
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-movements_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10.17-movements' );
% params.acceptWrongResponse = false;

% t8.2017.10.18 Words
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10.18-words' );
% params.acceptWrongResponse = false;

%% Added datasets for revision

% t5.2018.12.12 Standalone
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12-words_noRaw.mat';
% params.excludeChannels = datasetChannelExcludeList( 't5.2018.12.12-words_-4.5RMSexclude' );
% params.acceptWrongResponse = false;

% t5.2018.12.17 Standalone 
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-words_noRaw.mat';
params.excludeChannels = datasetChannelExcludeList( 't5.2018.12.17-words_-4.5RMSexclude' );
params.acceptWrongResponse = false;



%%
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly


includeLabels = labelLists( Rfile ); % lookup;
numArrays = 2; % don't anticipate this changing
switch participant
    case 't5'
        arrayMaps ={'T5_lateral', 'T5_medial'};
    case 't8'
        arrayMaps = {'T8_lateral', 'T8_medial'};
end

%% Processing Parameters

% Spike-sorted
% params.neuralFeature = 'sortedspikesBinnedRate_1ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% params.thresholdRMS = [];
% params.minimumQuality = 3; % this is a 'neuron science' result so exclude ambiguous units.
% sortQuality = speechSortQuality( datasetName ); % manual entry since I forgot to include this in R struct : (

% RMS thresholds:
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRate_1ms'; % firing rates, binned every 1ms. I'll


params.minSpikesPerSecond = 1; % exclude electrodes with fewer than this many spikes per second.
params.allowRemoveOfChannelWithUnits = false; % set to false to prevent removing low-rate channels with a unit

% Align to when audible speaking started (based on hand-annotated audio data)
% then average across range of interest.
params.alignEvent = 'handResponseEvent'; % VOT
params.startEvent = 'handResponseEvent - 0.5';
params.endEvent = 'handResponseEvent + 0.5';

params.Rfile = Rfile;
result.params = params;
result.params.Rfile = Rfile;



%% Analysis parameters - for the data analyses done on the data
% Anova for tuning
% simpleAnova.reportChannelsBelowPvalue = 0.001;
% simpleAnova.reportChannelsBelowPvalue = 0.01;
simpleAnova.reportChannelsBelowPvalue = 0.05;

simpleAnova.reportTopN = 20; % provide a list of the top N channels by tuning.

% Responding to each label
channelResponders.reportChannelsBelowPvalue = 0.05; % note: it gets Bonferonni corrected later


%% Load the data
in = load( Rfile );
R = in.R;
clear('in')
% exclude some trials?
if isfield( params, 'excludeTrials' ) && ~isempty( params.excludeTrials )
    excludeInds =  find( ismember( [R.trialNumber], params.excludeTrials ) .* ismember( [R.blockNumber], params.excludeTrialsBlocknum ) );
    fprintf('Excluding trials %s from blocks %s (%i trials)\n', ...
        mat2str( params.excludeTrials ), mat2str( params.excludeTrialsBlocknum ), numel( excludeInds ) );
    R(excludeInds) = [];
end




%% Annotate the data
% Scan for whether event labels files exist for these blocks. 
% Accept trials with wrong response to cue, if it was one of the included responses
if params.acceptWrongResponse
    numCorrected = 0;
    for iTrial = 1 : numel( R )
        myLabel = R(iTrial).label;
        if contains( myLabel, '-' ) 
            myResponse = myLabel(strfind( myLabel , '-' )+1:end);
            if ismember( myResponse, includeLabels )
                R(iTrial).label = myResponse;
                numCorrected = numCorrected + 1;
            end
        end
    end
    fprintf('%i trials with wrong response included based on their RESPONSE\n', numCorrected )
end

uniqueLabels = includeLabels( ismember( includeLabels, unique( {R.label} ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [R.blockNumber] );
% Restrict to trials of the labels we care about
R = R(ismember(  {R.label}, uniqueLabels ));
fprintf('PSTHs from %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.label, uniqueLabels{iLabel} ), R ) ) )
end
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;
allLabels = {R.label};


% Determine the critical alignment points
% note I choose to do this for each block, since this will better address ambient
% noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
% silence speech time estimation)
if any( cell2mat( strfind( params.alignEvent, 'vot' ) ) )
    fprintf('VOT alignment required, will add those now...\n')
    alignMode = 'VOTdetection';
else
    alignMode = 'handLabels';
end
uniqueBlocks = unique( [R.blockNumber] );
Rnew = [];
for blockNum = uniqueBlocks
    myTrials = [R.blockNumber] == blockNum; 
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode )];
end
R = Rnew; 
clear( 'Rnew' );



%% Generate neural feature
% Apply RMS thresholding
if strfind( params.neuralFeature, 'sorted' )
    % Quick and easy way to do it: replace rasters with the spike sorted one
    fprintf('Using spike sorted data \n');
    [ R, sorted ] = ReplaceRastersWithSorted( R, 'numArrays', numArrays, ...
        'minimumQuality', params.minimumQuality, 'sortQuality', sortQuality, ...
        'manualExcludeList', speechSortedUnitExclusions( datasetName ) );
    params.neuralFeature = regexprep( params.neuralFeature, 'sorted', '');
    R = AddFeature( R, params.neuralFeature, 'channelName', sorted.unitString );
    
elseif ~isempty( params.thresholdRMS )
    fprintf('Thresholding at %g RMS\n', params.thresholdRMS );
    for iTrial = 1 : numel( R )
        
        for iArray = 1 : numArrays
            switch iArray
                case 1
                    rasterField = 'spikeRaster';
                otherwise
                    rasterField = sprintf( 'spikeRaster%i', iArray );
            end
            ACBfield = sprintf( 'minAcausSpikeBand%i', iArray );
            myACB = R(iTrial).(ACBfield);
            RMSfield = sprintf( 'RMSarray%i', iArray );
            R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( myACB, 2 ) ) );
        end
    end
    R = AddFeature( R, params.neuralFeature  );
    
    if ~isempty( params.excludeChannels )
        fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
        R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
    end
    
    
    
    %% RMS Channel exclusion management
    allRaster = [[R.spikeRaster]; [R.spikeRaster2]];
    allFR = sum( allRaster, 2 ) ./ size( allRaster, 2 ) .* 1000; % spikes/second
    
    
    % PROVIDE INFO ABOUT HAND-EXCLUDED CHANNELS
    if isfield( R(1), 'electrodeEachUnitArray1' ) % new (unsorted) datasets don't have these
        channelsWithSortedUnits = [R(1).electrodeEachUnitArray1, 96 + R(1).electrodeEachUnitArray2];
    else
        fprintf('Note: no sorted units, so not guarding these from min FR channel exclusion rule\n')
        channelsWithSortedUnits = [];
    end
    
    if ~isempty( params.excludeChannels )
        % are there sorted units on any excluded channels (that'd suggest exclusion was a poor
        % choice)
        excludedButHasSorted = intersect( params.excludeChannels, channelsWithSortedUnits );
        if ~isempty( excludedButHasSorted )
            fprintf( 2, 'Warning: channels [%s] were hand excluded but had units.\n', ...
                mat2str( excludedButHasSorted ) );
        end
        
        excludedFR = allFR(params.excludeChannels);
        % report what would have been the rate of channels I excluded
        fprintf('The %i hand-excluded channels had rates ranging from %.1f to %.1f Hz (mean %.1fHz)\n', ...
            numel( excludedFR ), min( excludedFR ), max( excludedFR ), mean( excludedFR ) );
    end
    
    % REMOVE CHANNELS THAT HAVE TOO LOW A FIRING RATE
    % These are electrodes that presumably don't record spikes well. Excluding them provides a
    % (somewhat) improved sense of which electrodes are not recording meaningful activity versus just not
    % responding to speech.
    if ~isempty( params.minSpikesPerSecond )
        fprintf('Applying %.1f Hz minimum firing rate requirement to RMS RASTERS\n', ...
            params.minSpikesPerSecond );
        lowRateChannels = allFR < params.minSpikesPerSecond;
        % some of these might already be excluded manually
        lowRateChannels = setdiff( find( lowRateChannels ), params.excludeChannels );
        % Do any of these low rate channels have sorted units?
        lowRateButHasSorted = intersect( lowRateChannels, channelsWithSortedUnits );
        
        if ~isempty( lowRateButHasSorted )
            if params.allowRemoveOfChannelWithUnits
                % throw a warning
                fprintf( 2, 'Warning, channels %s will be removed due to low rate but do have sorted units!\n', ...
                    mat2str( lowRateButHasSorted ) );
            else
                fprintf( 2, 'Blocking removing low-ratechannels %s because they have sorted units!\n', ...
                    mat2str( lowRateButHasSorted ) );
                lowRateChannels = setdiff( lowRateChannels, lowRateButHasSorted );
            end
        end
        
        if ~isempty( lowRateChannels )
            lowRateChannelNames = chanNumToName( lowRateChannels );
            % needs to have 'chan_' prepend to match what is in the continuous data
            lowRateChannelNames = cellfun( @(x) ['chan_' x], lowRateChannelNames, 'UniformOutput', false );
            fprintf('Removing %i additional electrodes for having too low a rate\n', ...
                numel( lowRateChannelNames ) );
        else
            lowRateChannelNames = [];
        end
        
        if ~strfind( params.neuralFeature, 'spikesBinnedRate' )
            keyboard
            % uhh you probaly didn't mean to do this because you're analyzing a feature that isn't
            % RMS spikes but are deleteing channels based on this...
        end
        
        % Do the actual removal
        R = RemoveChannelsFromR( R, lowRateChannelNames, 'sourceFeature', params.neuralFeature );
        fprintf('Final list of excluded channels is:\n%s\n', ...
            mat2str( setdiff( 1:192, ChannelNameToNumber( R(1).(params.neuralFeature).channelName ) ) ) );
    end
end


%% Should I be concerned that some of the features have cross-talk?
Z = struct();
for i = 1 : numel( R )
    Z(i).dat = R(i).(params.neuralFeature).dat;
end
allDat = double( [Z.dat] );
corrDat = corrcoef(allDat');
% remove diagonal
for i = 1 : size( corrDat, 1 )
    corrDat(i,i) = 0;
end
figh = figure;
axh = axes;
imagesc( corrDat );
axh.CLim = [0 1];
colorbar
titlestr = sprintf('Cross-correlations %s %s', params.neuralFeature, datasetName );
title( titlestr, 'Interpreter', 'none' );
figh.Name = titlestr;

correlatedPairs = {};
for i = 1 : size( corrDat, 1 )
    for j = i + 1 : size( corrDat, 1 )
        if corrDat(i,j) > 0.5
            correlatedPairs{end+1} = [i,j];
            fprintf(2, 'Warning: %s (%i) and %s (%i) have correlation %.4f\n', ...
                R(1).(params.neuralFeature).channelName{i}, i, R(1).(params.neuralFeature).channelName{j}, j, ...
                corrDat(i,j) );
            % some more metrics:
            spikeTimes_i = allDat(i,:);
            spikeTimes_j = allDat(j,:);
            fprintf('  %.1f%% of first channel spike events co-occur with the second channel''s spike, and %.1f%% vice-versa\n', ...
                100*nnz( logical( spikeTimes_i ) & logical( spikeTimes_j ) )  / nnz(spikeTimes_i), ...
                100*nnz( logical( spikeTimes_i ) & logical( spikeTimes_j ) )  / nnz(spikeTimes_j) )
        end
    end
end

% keyboard
% lets me visualize some of these rasters:
% figure;
% imagesc( allDat([36,37],:) );



%% Get time-averaged activity grouped by label.
% I'm going to create a cell with each trial's trial-averaged mean/std/se,
% firing rate in the plot window.
% Here I also get a single average rate for each channel per trial.
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, uniqueLabels{iLabel} );
    jenga = TrimToSolidJenga( AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent ) );
    result.(myLabel).t = jenga.t; 
    result.(myLabel).numTrials = jenga.numTrials;
    result.(myLabel).meanWindowActivity = squeeze( mean( jenga.dat, 2 ) ); % trials x channels
    % channel names had best be the same across events/groups, so put them in one place
    result.channelNames = R(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
end



% At this point the data is ready for various analyses 


%% A simple ANOVA to look for tuning, one electrode at a time.

% INCLUDING SILENCE
numChans = numel( result.channelNames );
for iChan = 1 : numChans
    myRates = [];
    myLabels = {};
    for iGroup = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels{iGroup};
        myLabels = [myLabels; repmat( {myLabel}, numel( result.(myLabel).meanWindowActivity(:,iChan) ), 1 )];
        myRates = [myRates; result.(myLabel).meanWindowActivity(:,iChan)];
    end
    % Compare
    [p,tbl] = anova1( myRates, myLabels, 'off' );
    result.simpleAnovaWithSilence.p(iChan,1) = p;
    result.simpleAnovaWithSilence.F(iChan,1) = tbl{2,5};
end

significantWithSilence =  find( result.simpleAnovaWithSilence.p < simpleAnova.reportChannelsBelowPvalue );
reportTop = min( simpleAnova.reportTopN, numel( significantWithSilence ) );
Fvals = result.simpleAnovaWithSilence.F(significantWithSilence);
[~,rankF] = sort( Fvals, 'descend');
mostSignifChannels = significantWithSilence(rankF(1:reportTop));
mostSignifChannels_names = arrayfun( @(x) result.channelNames{x},  mostSignifChannels, 'UniformOutput', false ); % Convert these to strings
fprintf('WITH SILENCE: %i/%i (%.1f%%) electrodes tuned (p<%g, anova1), highest F vals are: %s\n', ...
    numel(significantWithSilence), numChans, 100*numel(significantWithSilence)/numChans,...
    simpleAnova.reportChannelsBelowPvalue, CellsWithStringsToOneString( mostSignifChannels_names ) );


% EXCLUDING SILENCE (so tuned between different sounds)
for iChan = 1 : numChans
    myRates = [];
    myLabels = {};
    for iGroup = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels{iGroup};
        if strcmp( myLabel, 'silence' ) || strcmp( myLabel, 'stayStill' )
            continue
        end
        myLabels = [myLabels; repmat( {myLabel}, numel( result.(myLabel).meanWindowActivity(:,iChan) ), 1 )];
        myRates = [myRates; result.(myLabel).meanWindowActivity(:,iChan)];
    end
    % Compare
    [p,tbl] = anova1( myRates, myLabels, 'off' );
    result.simpleAnovaNoSilence.p(iChan,1) = p;
    result.simpleAnovaNoSilence.F(iChan,1) = tbl{2,5};
end

significantNoSilence =  find( result.simpleAnovaNoSilence.p < simpleAnova.reportChannelsBelowPvalue );
reportTop = min( simpleAnova.reportTopN, numel( significantNoSilence ) );
Fvals = result.simpleAnovaNoSilence.F(significantNoSilence);
[~,rankF] = sort( Fvals, 'descend');
mostSignifChannels = significantNoSilence(rankF(1:reportTop));
mostSignifChannels_names = arrayfun( @(x) result.channelNames{x},  mostSignifChannels, 'UniformOutput', false ); % Convert these to strings
fprintf('NO SILENCE: %i/%i (%.1f%%) electrodes tuned (p<%g, anova1), highest F vals are: %s\n', ...
    numel(significantNoSilence), numChans, 100*numel(significantNoSilence)/numChans,...
    simpleAnova.reportChannelsBelowPvalue, CellsWithStringsToOneString( mostSignifChannels_names ) );

%% Save the results
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
resultsFilename = [saveResultsRoot datasetName structToFilename( params ) '.mat'];
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end
% saving the processed data (so they can be compared between datasets, for example, would
% happen here.
save( resultsFilename, 'result' )
fprintf('Saved results to \n%s\n', ...
    resultsFilename );



%% Bar Plots to compare each label to silence, for each channel

result.pValueVsSilent = nan( numChans, numel( uniqueLabels ) );

for iChan = 1 : numChans
    % silence/stayStill rates
    myLabel = uniqueLabels{1};
    silenceDat = result.(myLabel).meanWindowActivity(:,iChan);
    
    % loop through each of the other labels and compare them to the silent label
    for iLabel = 2 : numel( uniqueLabels )
        myLabel = uniqueLabels{iLabel};
        myDat = result.(myLabel).meanWindowActivity(:,iChan);
        result.pValueVsSilent(iChan,iLabel) = ranksum( myDat, silenceDat );
    end  
end

% p value cutoff 
testVal = (channelResponders.reportChannelsBelowPvalue ./ (numel( uniqueLabels )-1) ); % Bonefonni correction
% testVal = channelResponders.reportChannelsBelowPvalue;  % no Bonferonni correction

signifPvalueVsSilent = result.pValueVsSilent < testVal;
numEachTunedTo = sum( signifPvalueVsSilent, 2 );
% restrict to responders, meaning having significant tuning to at least one channel 
signifResponders = find( numEachTunedTo >= 1 );


fprintf('Significant responders are: %s\n', mat2str( ChannelNameToNumber( result.channelNames(signifResponders) ) ) );
nonResponders = setdiff( 1 : numel( R(1).(params.neuralFeature).channelName ), signifResponders );
if ~isempty( strfind( result.channelNames{1}, 'chan_')  ) % only makes sense for channels and not units
    fprintf('Non-responders are: %s\n', mat2str( ChannelNameToNumber( result.channelNames(nonResponders) ) ) );
end
% For channels that responded to just one label, identify how often each label appeared as
% that 'sparse label';
sparseChans = find( numEachTunedTo == 1 );
sparseLabels = sum( signifPvalueVsSilent(sparseChans,:), 1 );


% make histogram. First bar is stacked and colored bylabel. Rest are just counts of #
% channels of that bin.
barMat = [];
barMat = sparseLabels;
for count = 2 : max( numEachTunedTo )
    barMat(count,1) = nnz( numEachTunedTo == count);
end

figh = figure;
axh = axes;
barh = bar( barMat, 'stacked');

% color all other bars black.
barh(1).FaceColor = [0 0 0];
% color the spare ones by their label's color
for iLabel = 2 : numel( uniqueLabels ) % skip 1 because that's silence
   barh(iLabel).FaceColor = speechColors( uniqueLabels{iLabel});
end

barh(1).BarWidth = 0.9;
xlabel( '# Labels Responding To'); ylabel('# Channels');
titlestr = sprintf('Labels Tuned To Histogram %s', datasetName );
title( titlestr );
figh.Name = titlestr;
% draw median 
line( [median(  numEachTunedTo(signifResponders) ) median(  numEachTunedTo(signifResponders) )], axh.YLim, 'Color', [.5 .5 .5] );
fprintf('%i/%i channels/units have significant response to at least one label at p = %f (ranksum). Median = %.2f\n', ...
    numel( signifResponders ), size( result.pValueVsSilent,1 ),  testVal, median(  numEachTunedTo(signifResponders) ) );


%% Tuning plotted on the arrays
chanMap = channelAnatomyMap(arrayMaps, 'drawMap', false);




figh = figure;
figh.Renderer = 'painters';
figh.Position = [10 10 800 1200]; % if it starts too small, its auto-layout messes up with 6 rows
titlestr = sprintf('Array tuning %s', datasetName );
figh.Name = titlestr;

% grayscale colormap for the # tuned sum plot
N = numel( uniqueLabels  );
if exist( 'saturateMapOneBelow', 'var' ) && saturateMapOneBelow
    N = N - 1;
    fprintf(2, '\nNOTE: Units tuned to %i now changed to %i to saturate plot\n\n', N, N-1)
    numEachTunedTo(numEachTunedTo==N) = N-1;    
end
graymap = flipud( bone( N + 1) ); 
graymap = graymap(2:end,:); % so it doesn't start at pure white
% if exist( 'saturateMapOneBelow', 'var' ) && saturateMapOneBelow
%     graymap = [graymap; graymap(end,:)];
% end


NUM_ROWS = 6;
% will subplot as 2 columns of 6. Last one is for the # tuned plot (sum across all
% subplots)
for iLabel = 2 : numel( uniqueLabels )+1 % skips silence/stayStill
    drawnAlready = []; % will track which electrodes were drawn as having something on them
    % Create axis.
    axh = subplot( NUM_ROWS, 2, iLabel-1);
    hold on;
    axh.Position =  axh.OuterPosition;
    axh.XAxis.Visible = 'off';
    axh.YAxis.Visible = 'off';
    axh.XLim = chanMap.xlim;
    axh.YLim = chanMap.ylim;
    axis equal
    
    for iChan = 1 : numChans
          % Data to plot.
          if iLabel == numel( uniqueLabels )+1 
              % special bonus plot: sum across how many are tuned.
              myDat = numEachTunedTo(iChan);
              mySize = 36;
              myColor = graymap(myDat+1,:);
              
              % disabeld chans
              % here they look identical to 0, since I don't want ot imply that no-activity but not
              % disabled are somehow more biologically-empty than truly disabled channels.
              disabledSize = 4;
              disabledColor = graymap(1,:);

          else
              myLabel = uniqueLabels{iLabel};

              % one of the labels
              % Choose whether to plot binary tuned/not or different sizes:
%               myDat = result.pValueVsSilent(iChan,iLabel) < testVal; % binary sig nor not
              myDat = result.pValueVsSilent(iChan,iLabel); % p-value
              if myDat < testVal
                  mySize = 36;
                  myColor = speechColors( myLabel );
                  % do away with different sized circles for different p values, just uses same criterion
                  % as with the sum map. Keeps things more consistent.
%               if myDat < 0.001
%                   mySize = 36;
%                   myColor = speechColors( myLabel );
%               elseif myDat < 0.01
%                   mySize = 25;
%                   myColor = speechColors( myLabel );
%               elseif myDat < 0.05
%                   mySize = 16;
%                   myColor = speechColors( myLabel );
              else
                  mySize = 16; % distinct from disabled channels
                  myColor = [.8 .8 .8];
              end
              
              % disabeld chans
              disabledSize = 4;
              disabledColor = [.8 .8 .8];
          end
%       
        if ~isempty( params.thresholdRMS )
            myChanNum = ChannelNameToNumber( result.channelNames{iChan} );
        else
            myChanNum = sorted.unitElectrodeTo192(iChan);
        end
        drawnAlready(end+1) = myChanNum;
        x = chanMap.x(myChanNum);
        y = chanMap.y(myChanNum);
        
        % draw the point
        scatter( x, y, mySize, myColor, 'filled' )
    end
    % draw the remainder of electrodes so there aren't holes
    drawThese = setdiff( 1:192, drawnAlready );
    for iLeftover = 1 : numel( drawThese )
        x = chanMap.x(drawThese(iLeftover));
        y = chanMap.y(drawThese(iLeftover));
        % draw the point
        scatter( x, y, disabledSize, disabledColor, 'filled' )
    end
end

% This standardizes across participants so that the relationship between mm and pixels
% stays the same. Makes fiugre making a lot easier later.
STANDARD_MMperNormalizedUnits = 36.2076;
childs = figh.Children;
numAxes = numel( childs );

axes( childs(1 ) )
axis equal
c1Xlim = childs(1).XLim;
c1YLim = childs(1).YLim;

% standardize distance, so it's matched between participants
xRange = range( childs(1).XLim );
yRange = range( childs(1).YLim );
myPos = childs(1).Position;
MMperNormalizedUnits = yRange/myPos(4);
scaleFactor =  MMperNormalizedUnits / STANDARD_MMperNormalizedUnits;
childs(1).Position = [myPos(1) myPos(2), scaleFactor*myPos(3), scaleFactor*myPos(4)];
c1Width = scaleFactor*myPos(3);
c1Height = scaleFactor*myPos(4);
for iAxh = 1 : numAxes
    axes( childs(iAxh ) )
    axh = gca;
    axh.XLim = c1Xlim;
    axh.YLim = c1YLim;
    
    myPos = axh.Position;
    axh.Position = [myPos(1) myPos(2), c1Width, c1Height];
end




% plot colorbar for grayscale
figh = figure;
axh = axes;
colormap( graymap );
cbahr = colorbar;
cbahr.TickLabels = 10*cellfun(@str2num, cbahr.TickLabels);
figh.Name = 'Grayscale colormap';