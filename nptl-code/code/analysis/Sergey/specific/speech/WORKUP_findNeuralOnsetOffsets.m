
% Plots the PCs of the speech datasets, to facilitate selecting offsets to align
% to neural onset rather than voice onset. The idea being, different phonemes will be
% audible at different times relative to the articulator movements (and presumed
% corresponding neural activity), and we'd like to align all the words/phonemes to the
% same 'speech start (neural)' time point.
%
%
% Sergey Stavisky, August 4 2018
% Stanford Neural Prosthetics Translational Laboratory

clear


saveOffsetsRoot = [ResultsRootNPTL '/speech/neuralVoiceOffsets/'];
if ~isdir( saveOffsetsRoot )
    mkdir( saveOffsetsRoot )
end
    
%% t5.2017.10.23 Phonemes
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
% params.acceptWrongResponse = true;


%% t5.2017.10.25 Words
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' );
% params.acceptWrongResponse = false;

%% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = true;

%% t8.2017.10.18 Words
participant = 't8';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = participantChannelExcludeList( participant );
params.acceptWrongResponse = false;



%%
includeLabels = labelLists( Rfile ); % lookup;
numArrays = 2; % don't anticipate this changing

datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly


%% Analysis Parameters

% THRESHOLD CROSSINGS
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 


%---------------------------------------------------

% When audible speaking started (based on hand-annotated audio data)
params.alignEvent = 'handResponseEvent';
params.startEvent = 'handResponseEvent - 1';
params.endEvent = 'handResponseEvent + 1';


result.params = params;
result.params.Rfile = Rfile;

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
alignMode = 'handLabels';

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
        R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( R(iTrial).(rasterField), 2 ) ) );
    end
end
R = AddFeature( R, params.neuralFeature  );

if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
end




%% Make PSTH
% I'm going to create a cell with each trial's trial-averaged mean/std/se,
% firing rate in the plot window.
% Also prepare for PCA by concatenating across conditions
bigDat = [];


for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, myLabel );
    jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
    result.(myLabel).t = jenga.t;
    result.(myLabel).psthMean = squeeze( mean( jenga.dat, 1 ) );
    result.(myLabel).psthStd = squeeze( std( jenga.dat, [], 1 ) );
    for t = 1 : size( jenga.dat,2 )
        result.(myLabel).psthSem(t,:) =  sem( squeeze( jenga.dat(:,t,:) ) );
    end
    result.(myLabel).numTrials = jenga.numTrials;
    % channel names had best be the same across events/groups, so put them in one place
    result.channelNames = R(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
    
    bigDat = [bigDat; result.(myLabel).psthMean];
end

%% Do PCA on all conditions
[coeff, ~, ~, ~, explained] = pca( bigDat );
% figure; plot( cumsum( explained ) )
PC1 = coeff(:,1);

% Plot the non-silence conditions' PC1
figh = figure;
titlestr = sprintf( 'PC1 alignment %s', datasetName );
figh.Name = titlestr;
axh = subplot(1,2,1);
hold on;
for iLabel = 2 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myPC1 = result.(myLabel).psthMean * PC1;
    plot( result.(myLabel).t, myPC1, 'Color', speechColors( myLabel ) );
end
ylabel('PC1')
xlabel('sec after Voice Onset')

%% Sweep cross correlation to align these
% note: aligning to the first of the spoken labels
sOffsets = struct(); % will save offsets to this. Units are secs
labelAlign = uniqueLabels{2};
sOffsets.(labelAlign) = 0; 
vectorAlignTarget = result.(labelAlign).psthMean * PC1; % will try to align other vectors to this one
vectorAlignTarget(1) = []; % gets rid of nan
plot( result.(labelAlign).t(2:end), vectorAlignTarget, 'Color', speechColors( labelAlign ) );

vectorAlignTarget = vectorAlignTarget - mean( vectorAlignTarget ); % zero mean
axh2 = subplot( 1, 2, 2); hold on;

figh_corrs = figure; % working figure; will plot all acor onto this
axh_corrs = axes;
xlabel('Lag index');
ylabel('Correlation')
hold on;
for iLabel = 3 :  numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myPC1 = result.(myLabel).psthMean * PC1;
    myPC1(1) = [];
    myPC1_zerod = myPC1 - mean( myPC1 );
 
    [acor,lag] = xcorr( vectorAlignTarget', myPC1_zerod' );
    axes( axh_corrs );
    plot( acor, 'Color', speechColors( myLabel ) )
    
    [~,I] = max(abs(acor));
    lagDiff = lag(I);
    fprintf('Aligning %s to %s: optimal lag is to shift it by %ims\n', ...
        myLabel, labelAlign, lagDiff )
    sOffsets.(myLabel) = lagDiff/1000; % in secs
    
    % draw this offset on the original plot
    axes( axh )
    line( [0  sOffsets.(myLabel)], [5*iLabel 5*iLabel], 'Color', speechColors( myLabel ), ...
        'LineWidth', 3)
    
    
    % Plot the updated PC plot
    axes( axh2 );
    plot( result.(labelAlign).t(2:end) + sOffsets.(myLabel), myPC1, 'Color', speechColors( myLabel ) );

end
xlabel('S relative to neural-adjusted onset')

%% Save the offsets file
saveFilename = sprintf('%soffsets-%s.mat', saveOffsetsRoot, datasetName );
save( saveFilename, 'sOffsets' );
fprintf('Saved offsets to %s\n', saveFilename );