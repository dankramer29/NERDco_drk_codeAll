% Prepares speaking data into nice ssmall files of  PSTHs for subsequent use in
% WORKUP_wordsIntoDecoderPotent.m.
%
% Similar to WORKUP_speechPSTHs.m, but it doesn't exclude channels based on insufficient firiing 
% rate (since this is for a BCI application, not science)
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory, October 24 2018
%

clear
saveResultsRoot = [ResultsRootNPTL '/speech/psths/']; % I don't think there will be results file generated
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end

%% Analysis Parameters
% Spike-sorted
% params.neuralFeature = 'sortedspikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% params.thresholdRMS = [];
% params.minimumQuality = 3;
% sortQuality = speechSortQuality( datasetName ); % manual entry since I forgot to include this in R struct : (


% THRESHOLD CROSSINGS
% If thresholdRMS is NaN, use specific thresholds set in the dataset specification.
% These will be set based on the decoder used in the R8 task.
params.thresholdRMS = nan; % spikes happen below this RMS

% params.thresholdRMS = -4.5; % spikes happen below this RMS
% saveResultsRoot = [saveResultsRoot 'RMS4_5/'];

params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% params.neuralFeature = 'spikesBinnedRate_20ms'; % spikes rate with square 20 ms bin


% When audible speaking started (based on hand-annotated audio data)
params.alignEvent = 'handResponseEvent';
params.startEvent = 'handResponseEvent - 0.5';
params.endEvent = 'handResponseEvent + 0.5';


%% Dataset specification
% t5.2017.10.25 Words
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% % set thresholds from decoder file
% decoderFile = [CachedDatasetsRootNPTL '/NPTL/t5.2017.10.25/Data/Filters/002-blocks011-thresh-4.5-ch60-bin15ms-smooth25ms-delay0ms.mat'];
% decoder = load( decoderFile );
% thresholds = decoder.model.thresholds;
% fprintf('Set channel thresholds from %s\n', decoderFile );
% %  params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' ); % These were exclude rules used in initial speech paper
% params.excludeChannels = [];
% params.acceptWrongResponse = false;

% % t5.2018.12.12 Words
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12-words_noRaw.mat'; 
% set thresholds from decoder file
decoderFile = [CachedDatasetsRootNPTL '/NPTL/t5.2018.12.12/Data/Filters/002-blocks004-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat']; %ReFIT
decoder = load( decoderFile );
thresholds = decoder.model.thresholds;
fprintf('Set channel thresholds from %s\n', decoderFile );
params.excludeChannels = [];
params.acceptWrongResponse = false;

% t5.2018.12.17 Words
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-words_noRaw.mat'; 
% % set thresholds from decoder file
% decoderFile = [CachedDatasetsRootNPTL '/NPTL/t5.2018.12.17/Data/Filters/002-blocks004-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat']; %ReFIT
% 
% 
% decoder = load( decoderFile );
% thresholds = decoder.model.thresholds;
% params.excludeChannels = [];
% params.acceptWrongResponse = false;

% % t8.2017.10.18 Word
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% % set thresholds from decoder file (not actually a decoder in the T8 case, since they
% % store thresholds in block data file rather than decoder file)
% decoderFile = [CachedDatasetsRootNPTL '/NPTL/t8.2017.10.18/Data/SLC Data/PC1/SLCdata_2017_1018_155221(4).mat'];
% decoder = load( decoderFile );
% thresholds = decoder.sSLC.features.ncTX.min_threshold(1,:);
% thresholds = 4.* thresholds;
% fprintf( 2, 'MULTIPLYING THRESHOLDS by 4 TO ACCOUNT FOR PUTATIVE .NS5 West vs North Coast difference\n')
% % params.excludeChannels = participantChannelExcludeList( participant );
% params.excludeChannels = [];
% params.acceptWrongResponse = false;
% [params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );


%%
includeLabels = labelLists( Rfile ); % lookup;
numArrays = 2; % don't anticipate this changing

datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly

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
if strfind( params.neuralFeature, 'sorted' )
    % Quick and easy way to do it: replace rasters with the spike sorted one
    fprintf('Using spike sorted rasters \n');
    [ R, sorted ] = ReplaceRastersWithSorted( R, 'numArrays', numArrays, ...
        'minimumQuality', params.minimumQuality, 'sortQuality', sortQuality, ...
        'manualExcludeList', speechSortedUnitExclusions( datasetName ) );
    params.neuralFeature = regexprep( params.neuralFeature, 'sorted', '');
    R = AddFeature( R, params.neuralFeature, 'channelName', sorted.unitString );
    
elseif ~isempty( params.thresholdRMS )
    % Apply RMS thresholding
    if isnan( params.thresholdRMS )
        fprintf('Thresholding at specific values (from decoder %s)\n', decoderFile);
    else
        fprintf('Thresholding at %g RMS\n', params.thresholdRMS );
    end
    for iTrial = 1 : numel( R )
        for iArray = 1 : numArrays
            switch iArray
                case 1
                    rasterField = 'spikeRaster';
                    myThreshInds = 1:96; % if using externally specified thresholds
                otherwise
                    rasterField = sprintf( 'spikeRaster%i', iArray );
                    myThreshInds = [1:96] + 96*(iArray-1); % if using externally specified thresholds
            end
            ACBfield = sprintf( 'minAcausSpikeBand%i', iArray );
            myACB = R(iTrial).(ACBfield);
            if isnan( params.thresholdRMS )
                R(iTrial).(rasterField) = logical( myACB <  repmat( thresholds(myThreshInds)', 1, size( myACB, 2 ) ) );               
            else
                RMSfield = sprintf( 'RMSarray%i', iArray );
                R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( myACB, 2 ) ) );
            end
        end
    end
    R = AddFeature( R, params.neuralFeature  );
    
    if ~isempty( params.excludeChannels )
        fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
        R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
    end
else
    error('Feature not yet implemented')
end

%% Make PSTH
% I'm going to create a cell with each trial's trial-averaged mean/std/se,
% firing rate in the plot window.
% Here I also get a single average rate for each channel per trial.
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, myLabel );
    jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
    result.(myLabel).t = jenga.t;
    result.(myLabel).psthMean = squeeze( mean( jenga.dat, 1 ) );
    result.(myLabel).psthStd = squeeze( std( jenga.dat, 1 ) );
    for t = 1 : size( jenga.dat,2 )
        result.(myLabel).psthSem(t,:) =  sem( squeeze( jenga.dat(:,t,:) ) );
    end
    result.(myLabel).numTrials = jenga.numTrials;
    % channel names had best be the same across events/groups, so put them in one place
    result.channelNames = R(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
end

% sanity check
figure; plot( result.more.t, mean( result.silence.psthMean, 2 ) ); hold on;  plot( result.more.t, mean( result.bat.psthMean, 2 ) );
legend({'silence', 'more'})

%% Save the data
fileName = sprintf('%s_%s_%s_%s', datasetName, params.neuralFeature, params.startEvent, params.endEvent );
fileName = MakeValidFilename( fileName );
fprintf('Saving\n%s%s\n', saveResultsRoot, fileName )
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end
save( [saveResultsRoot fileName], 'result' );
fprintf('SAVED\n')