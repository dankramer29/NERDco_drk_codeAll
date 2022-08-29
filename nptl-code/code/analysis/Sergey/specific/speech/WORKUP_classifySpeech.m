% Performs a leave-one-trial-out classification on the data.
%
% This is one of the key analyses of the speech decoding project
%
% Sergey Stavisky, September 23 2017
% Updated December 6 2017
clear
rng(1); % consistent random seed


%% Analysis results saving
% Since some of these analysis runs take a long time, I save the results in
% a mat file whose name is based on the R file and a hash of the params
% (which isn't interpretable just by reading). Thus, if an analysis has
% already been run (based on having a shared params), it'll warn the user that 
% this results file already exists and that therefore this run is probably
% unnecessary (it'll run anyway and then overwrite at the end if it
% finished -- user can cancel midway to avoid this). The idea is that
% downstream figure making / metananalysis scripts can just point to a
% bunch of these results files, load them, and plot them.
saveResultsRoot = [ResultsRootNPTL '/speech/classification/withOffsets/'];
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end

neuralVoiceOffsetRoot = [ResultsRootNPTL '/speech/neuralVoiceOffsets/']; % directory with acoustic onset offset lags previously calcualted by WORKUP_findNeuralOnsetOffsets.m
params.neuralVoiceOffset = false; % Whether to use PC1 neural alignment to adjust voice onset

% R struct has already been prepared by WORKUP_prepareSpeechBlocks.m, which built off of
% WORKUP_labelSpeechExptData.m

% T5.2017.09.20
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/R_T5_2017_09_20-words.mat';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/R_T5_2017_09_20-phonemes.mat';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/R_T5_2017_09_20-thoughtSpeak.mat';




%% T8.2017.10.17 Phonemes
% % Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t8.2017.10.17-phonemes.mat'];
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% % Rfile = [ResultsRootNPTL '/speech/Rstructs/withRaw/R_t8.2017.10.17-phonemes.mat']; % if using ultrahigh frequency LFP. Otherwise avoid becuase it's a huge file
% participant = 't8';
%  % if so, then labels like 'da-ga' (he was cued 'da' but said 'ga') are accepted
% % The RESPONSE label ('ga' in above example) is used as the label for this trial.
% params.acceptWrongResponse = true;
% % params.excludeChannels = participantChannelExcludeList( participant );
% % params.excludeChannels = datasetChannelExcludeList('t8.2017.10-17_-4.5RMSexclude');
% % params.excludeChannels = datasetChannelExcludeList('t8.2017.10-17_-3.5RMSexclude');
% params.excludeChannels = [];
% 
% params.divideIntoNtimeBins = 10;
% % 
% % % -500 to 500 ms around start of response speech
% params.alignEvent = 'handResponseEvent';
% params.startEvent = 'handResponseEvent - 0.500';
% params.endEvent = 'handResponseEvent + 0.500';
% 
% % params.alignEvent = 'votResponseEvent';
% % params.startEvent = 'votResponseEvent - 0.500';
% % params.endEvent = 'votResponseEvent + 0.500';

%% t8 2017.10.17 Instructed Movements
% Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t8.2017.10.17-movements.mat'];
% participant = 't8';
% params.acceptWrongResponse = 'false';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.divideIntoNtimeBins = 10;
% 
% % 0 to 1000 ms after go cue
% % params.alignEvent = 'handResponseEvent';
% % params.startEvent = 'handResponseEvent ';
% % params.endEvent = 'handResponseEvent + 1.0';
% 
% params.alignEvent = 'votResponseEvent';
% params.startEvent = 'votResponseEvent ';
% params.endEvent = 'votResponseEvent + 1.0';


%% T8.2017.10.18 Words
% % Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t8.2017.10.18-words.mat'];
% % Rfile = [ResultsRootNPTL '/speech/Rstructs/withRaw/R_t8.2017.10.18-words.mat']; % if using ultrahigh frequency LFP. Otherwise avoid becuase it's a huge file
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% participant = 't8';
% params.acceptWrongResponse = false;
% % params.excludeChannels = participantChannelExcludeList( participant );
% params.excludeChannels = datasetChannelExcludeList('t8.2017.10-18_-4.5RMSexclude');
% % params.excludeChannels = datasetChannelExcludeList('t8.2017.10-18_-3.5RMSexclude');
% % params.excludeChannels = [];
% [params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );
% 
% params.divideIntoNtimeBins = 10;
% 
% % % -500 to 500 ms around start of response speech
% params.alignEvent = 'handResponseEvent';
% params.startEvent = 'handResponseEvent - 0.500';
% params.endEvent = 'handResponseEvent + 0.500';
% 
% % params.alignEvent = 'votResponseEvent';
% % params.startEvent = 'votResponseEvent - 0.500';
% % params.endEvent = 'votResponseEvent + 0.500';

%% t8 2017.10.18 Instructed Movements
% Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t8.2017.10.18-movements.mat'];
% participant = 't8';
% params.acceptWrongResponse = 'false';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.divideIntoNtimeBins = 10;
% 
% % 0 to 1000 ms after go cue
% % params.alignEvent = 'handResponseEvent';
% % params.startEvent = 'handResponseEvent ';
% % params.endEvent = 'handResponseEvent + 1.0';
% 
% params.alignEvent = 'votResponseEvent';
% params.startEvent = 'votResponseEvent ';
% params.endEvent = 'votResponseEvent + 1.0';

%% T5.2017.10.23 Phonemes
% Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t5.2017.10.23-phonemes.mat'];
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units

% Rfile = [ResultsRootNPTL '/speech/Rstructs/withRaw/R_t5.2017.10.23-phonemes.mat']; % if using ultrahigh frequency LFP. Otherwise avoid becuase it's a huge file
participant = 't5';
params.acceptWrongResponse = 'true';
params.excludeChannels = datasetChannelExcludeList('t5.2017.10-23_-4.5RMSexclude');
% params.excludeChannels = datasetChannelExcludeList('t5.2017.10-23_-3.5RMSexclude');
% params.excludeChannels = participantChannelExcludeList( participant );
% params.excludeChannels = [];
params.divideIntoNtimeBins = 10;

% -500 to 500 ms around start of response speech
params.alignEvent = 'handResponseEvent';
params.startEvent = 'handResponseEvent - 0.500';
params.endEvent = 'handResponseEvent + 0.500';

% params.alignEvent = 'votResponseEvent';
% params.startEvent = 'votResponseEvent - 0.500';
% params.endEvent = 'votResponseEvent + 0.500';

%% T5.2017.10.23 Instructed Movements
% Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t5.2017.10.23-movements.mat'];
% participant = 't5';
% params.acceptWrongResponse = 'false'; % irrelevnat for instructed movements
% params.excludeChannels = participantChannelExcludeList( participant );
% params.divideIntoNtimeBins = 10;
% 
% % 0 to 1000 ms after go cue
% % params.alignEvent = 'handResponseEvent';
% % params.startEvent = 'handResponseEvent ';
% % params.endEvent = 'handResponseEvent + 1.0';
% 
% params.alignEvent = 'votResponseEvent';
% params.startEvent = 'votResponseEvent ';
% params.endEvent = 'votResponseEvent + 1.0';

%% T5.2017.10.25 Words
% % Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t5.2017.10.25-words.mat'];
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% participant = 't5';
% params.acceptWrongResponse = 'false';
% % params.excludeChannels = participantChannelExcludeList( participant );
% params.excludeChannels = datasetChannelExcludeList('t5.2017.10-25_-4.5RMSexclude');
% % params.excludeChannels = datasetChannelExcludeList('t5.2017.10-25_-3.5RMSexclude');
% params.divideIntoNtimeBins = 10;
% 
% 
% 
% % 
% % % -500 to 500 ms around start of response speech
% params.alignEvent = 'handResponseEvent';
% params.startEvent = 'handResponseEvent - 0.500';
% params.endEvent = 'handResponseEvent + 0.500';
% % 
% % % params.alignEvent = 'votResponseEvent';
% % % params.startEvent = 'votResponseEvent - 0.500';
% % % params.endEvent = 'votResponseEvent + 0.500';



% params.excludeChannels = union( params.excludeChannels, [1:96] ); % array 2 only
% params.excludeChannels = union( params.excludeChannels, [97:192] ); % array 1 only


%% Analysis Parameters
% params.thresholdRMS = -4.5; % spikes happen below this RMS
params.thresholdRMS = -3.5; % spikes happen below this RMS
% for spike-sorted
params.minimumQuality = 3; % this is a 'neuron science' result so exclude ambiguous units.
% params.minimumQuality = 0; % this is a 'neuron science' result so exclude ambiguous units.


% Note: put even singular features in a cell array to simplify code reuse
% for combinations of features.

% Spike-sorted
% params.neuralFeature = {'sortedspikesBinnedRate_1ms'};
% params.neuralFeature = {'spikesBinned_1ms'}; % spike counts binned every 1ms. Makes for easier dividing into features later
% params.neuralFeature = {'lfpFilt_boxcar_50ms'};
% params.neuralFeature = {'lfpPow_65to125_50ms'};
% params.neuralFeature = {'lfpPow_125to500_50ms'};
% params.neuralFeature = {'lfpPow_125to5000_50ms'}; params.CARlfp = {false};
% params.neuralFeature = {'lfpPow_250to5000_50ms'}; params.CARlfp = {false}; % note, I use 125to5000

% bunch of lower frequency powers
% params.neuralFeature = {'lfpPow_10to25_200ms'};
% params.neuralFeature = {'lfpPow_25to40_100ms'};
% params.neuralFeature = {'lfpPow_40to65_50ms'};
    
% Combinations of features yay!
% params.neuralFeature = {'sortedspikesBinnedRate_1ms', 'spikesBinned_1ms'}; 
% params.neuralFeature = {'spikesBinned_1ms', 'lfpFilt_boxcar_50ms'}; params.CARlfp = {false, true}; % if true, will do CAR on raw data. Ignored for spikesBinned
% params.neuralFeature = {'spikesBinned_1ms', 'lfpPow_65to125_50ms'};
params.neuralFeature = {'spikesBinned_1ms', 'lfpPow_125to5000_50ms'}; params.CARlfp = {false, false}; 
% params.CARlfp = {true, false}; % if true, will do CAR on raw data. Ignored for spikesBinned


% Triple and Quadruple features. Doesn't help?
% params.neuralFeature = {'sortedspikesBinnedRate_1ms', 'spikesBinned_1ms', 'lfpPow_125to5000_50ms'};  params.CARlfp = {false, false, false}; 
% params.neuralFeature = {'spikesBinned_1ms', 'lfpFilt_boxcar_50ms', 'lfpPow_125to5000_50ms'};
% params.neuralFeature = {'spikesBinned_1ms', 'lfpPow_65to125_100ms', 'lfpPow_125to500_50ms'};
% params.neuralFeature = {'spikesBinned_1ms', 'lfpFilt_boxcar_50ms', 'lfpPow_125to500_50ms'};
% params.neuralFeature = {'spikesBinned_1ms', 'lfpFilt_boxcar_50ms', 'lfpPow_65to125_100ms', 'lfpPow_125to500_50ms'};
% params.CARlfp = {false, true, false}; % if true, will do CAR on raw data. Ignored for spikesBinned

params.CARafterChannelRemoval = true; % if true, will remove channels BEFORE doing CAR

% SVM parameters
params.outlierFraction = 0.05; 

% Random selection folds
% Picks a random subset of trials as test trials and the rest as train
% trials. This is repeated a specified number of times. This provides a
% distribution of performance results and gives some sense of the
% how consistent a given performance is across variations in training and
% testing data.
% note: it never does pick-with-replacement, as otherwise a duplicate of the
% test trial could appear in the training trial, which could unduly inflate
% performance.
% params
params.trialsEachClassEachFold = 0; % if 0, does leave-one-out testing. Otherwise, has this many 
                                    % test trials from each class per fold.
                                    % DO THIS FOR MAIN PERFORMANCE AND
                                    % STATS VS CHANCE
% params.trialsEachClassEachFold = 1; % if 0, does leave-one-out testing. Otherwise, has this many 
%                                     % test trials from each class per
%                                     fold. DO THIS FOR FEATURE COMPARISON
params.numResamples = 1001; % irrelevant if above is empty, as it then just goes through every trial (this is the standard mode)


% Shuffle labels (to compute chance levels)
% params.numShuffles = 101; % for paper
% params.numShuffles = 2; % dev
params.numShuffles = 0;

% PCA across electrodes, on trial-averaged data
params.numPCs = [];


includeLabels = labelLists( Rfile ); % lookup;




%% Prepare filename from these parameters and warn if it already exists.
params.Rfile = Rfile;
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly

resultsFilename = [saveResultsRoot datasetName structToFilename( params ) '.mat'];
try 
    in = load( resultsFilename );
    classifyResult = in.classifyResult;
    beep;
    fprintf( 'This analysis appears to have already been run and was loaded from %s\n', resultsFilename )
    fprintf( 'You can abort now, or let it run and overwrite\n');
    keyboard
catch
    % (empty)
end
    


%% Load the data
in = load( Rfile );
R = in.R;
clear('in'); % save memory
numArrays = 2;
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
        if strfind( myLabel, '-' ) 
            myResponse = myLabel(strfind( myLabel , '-' )+1:end);
            if ismember( myResponse, includeLabels )
                R(iTrial).label = myResponse;
                numCorrected = numCorrected + 1;
            end
        end
    end
    fprintf('%i trials with wrong response included based on their RESPONSE\n', numCorrected )
end

allLabels = {R.label};
uniqueLabels = includeLabels( ismember( includeLabels, unique( allLabels ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [R.blockNumber] );
% Restrict to trials of the labels we care about
R = R(ismember( allLabels, uniqueLabels ));
fprintf('Classifying %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.label, uniqueLabels{iLabel} ), R ) ) )
end
results.uniqueLabels = uniqueLabels;
results.blocksPresent = blocksPresent;
results.params = params;


% Determine the critical alignment points
% note I choose to do this for each block, since this will better address ambient
% noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
% silence speech time estimation)
if params.neuralVoiceOffset
    offsetFile = sprintf('%soffsets-%s.mat', neuralVoiceOffsetRoot, datasetName );
    load( offsetFile, 'sOffsets' );
else
    sOffsets = [];
end

if strfind( params.alignEvent, 'vot' )
    fprintf('VOT alignment required, will add those now...\n')
    alignMode = 'VOTdetection';
else
    alignMode = 'handLabels';
end
uniqueBlocks = unique( [R.blockNumber] );
Rnew = [];
for blockNum = uniqueBlocks
    myTrials = [R.blockNumber] == blockNum; 
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode, 'sOffsets', sOffsets )];
end
R = Rnew; 
clear( 'Rnew' );


%% Add Neural Features  

for iFeature = 1 : numel( params.neuralFeature )
    didExcludeChannels = false;
    
    if strfind( params.neuralFeature{iFeature}, 'sortedspikes' )
        % I don't want to actually replace rasters since I'll use these for RMS crossings, 
        % so duplicate R struct and then move the desired feature over. Ugly but gets the job
        % done.
        sortQuality = speechSortQuality( datasetName ); % manual entry since I forgot to include this in R struct : (
        [ R2, sorted ] = ReplaceRastersWithSorted( R, 'numArrays', numArrays, ...
            'minimumQuality', params.minimumQuality, 'sortQuality', sortQuality, ...
            'manualExcludeList', speechSortedUnitExclusions( datasetName ) );
        tmpFeatureName = regexprep( params.neuralFeature{iFeature}, 'sorted', ''); % will be renamed
        R2 = AddFeature( R2, tmpFeatureName, 'channelName', sorted.unitString );
        for i = 1 : numel( R )
            R(i).(params.neuralFeature{iFeature}) = R2(i).(tmpFeatureName);
        end
        didExcludeChannels = true; % units are on a different exclusion system altogther.
    
    elseif strfind( params.neuralFeature{iFeature}, 'spikes' )
        % apply RMS thresholding if needed
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
                
%                 % Hack until I fix this in the data loading
%                 if size( myACB, 2 ) > size( R(iTrial).(rasterField),2 )
%                     myACB(:,end) = [];
%                 elseif size( myACB, 2 ) < size( R(iTrial).(rasterField),2 )
%                     myACB(:,end+1)=inf;
%                 end
                
                R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( R(iTrial).(rasterField), 2 ) ) );
            end
        end
        R = AddFeature( R, params.neuralFeature{iFeature} );

    elseif strfind( params.neuralFeature{iFeature}, 'lfp' ) 
        if isfield( R, params.neuralFeature{iFeature} )
            % this logic here because I have R structs with HLFP already in it
            fprintf('Field %s already exists (pre-generated?), will use that and just remove channels\n', params.neuralFeature{iFeature} )
            if ~isempty( params.excludeChannels ) && ~didExcludeChannels
                fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
                R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature{iFeature} );
            end
            continue
        end
        bandInfo = bandNameParse( params.neuralFeature{iFeature} );

        
        % if using very high frequency, need to use the 'raw' different source
        if bandInfo.hi >= 500 || params.CARlfp{iFeature}    
            if params.CARlfp{iFeature}
                keyboard % TODO: Should happen on a temporary raw so that I can have other features that DONT do this
                for iArray = 1 : numArrays
                    myfield = sprintf('raw%i', iArray );
                    if params.CARafterChannelRemoval
                        myExcludeChannels = params.excludeChannels([params.excludeChannels >= ((iArray-1)*96 +1)] & [params.excludeChannels < ((iArray)*96 +1)]);
                        myExcludeChannels = myExcludeChannels - 96*(iArray-1); % since operating within this one array
                        R = RemoveChannelsFromR( R, myExcludeChannels, 'sourceFeature', myfield ); % will be redundant if CARlfp and params.CARafterChannelRemoval happened
                        didExcludeChannels = true;
                        fprintf('Performing CAR array %i after removing channels %s\n', iArray, mat2str( myExcludeChannels ) )

                    else
                        fprintf('Performing CAR array %i ...\n', iArray)
                    end
                    
                    for iTrial = 1 : numel( R )
                        R(iTrial).(myfield).dat = R(iTrial).(myfield).dat - int16( repmat( mean( R(iTrial).(myfield).dat, 1 ), size( R(iTrial).(myfield).dat, 1 ), 1 ) );
                    end                    
                end
            end
            
            if ~isfield( R, 'raw')
                R  = AddCombinedFeature( R, {'raw1', 'raw2'}, 'raw', 'deleteSources', true );
            end
            R = AddFeature( R, params.neuralFeature{iFeature}, 'sourceSignal', 'raw' );                             
        else            
            if ~isfield( R, 'lfp')
                R  = AddCombinedFeature( R, {'lfp1', 'lfp2'}, 'lfp', 'deleteSources', true );
            end
            R = AddFeature( R, params.neuralFeature{iFeature}, 'sourceSignal', 'lfp' );
        end
    end
    
    if ~isempty( params.excludeChannels ) && ~didExcludeChannels
        fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
        R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature{iFeature} );
    end
    

end

% Create combo feature if so specified.
if numel( params.neuralFeature ) > 1
     R  = AddCombinedFeature( R, params.neuralFeature, 'comboFeature', 'deleteSources', false );
     params.componentNeuralFeatures = params.neuralFeature;
     fprintf('Created combination feature from {%s}\n', CellsWithStringsToOneString( params.componentNeuralFeatures  ) );
     params.neuralFeature = 'comboFeature'; % rename so downstream code still operates on this
else
    % unpack it so feature name isn't in a cell array
    params.neuralFeature =  params.neuralFeature{1};
end


%% Do the leave-one-out SVM classification
tic
fprintf('Starting classification...\n')
classifyResult = classifySpeech( R, params, 'verbose', false );
toc

%% Report results
% Two different ways to do it depending on whether I did leave-one-out
% (with chance performance due to shuffles) or or a fold-pased with
% multiple samples, which allows for error bars on decode performance.
if params.trialsEachClassEachFold > 0
    % HELD OUT FOLDS ANALYSIS
    meanAccuracy = 100*mean( classifyResult.classificationSuccessRate );
    stdAccuracy = 100*std( classifyResult.classificationSuccessRate  );
    fprintf('Classification Accuracy %s = %.1f%% (+-%.1f%% s.d.)\n', datasetName, ...
        meanAccuracy, stdAccuracy );
    
else
    % LEAVE-ONE-OUT ANALYSIS
    fprintf('Classification Accuracy %s = %.1f%%\n', datasetName, 100*classifyResult.classificationSuccessRate );
    if params.numShuffles > 0
        betterThanShuffles = nnz( classifyResult.classificationSuccessRate > classifyResult.classificationSuccessRate_shuffled );
        classifyResult.minShuffle = 100 * min( classifyResult.classificationSuccessRate_shuffled );
        classifyResult.maxShuffle = 100 * max( classifyResult.classificationSuccessRate_shuffled );
        classifyResult.meanShuffle = 100 * mean( classifyResult.classificationSuccessRate_shuffled );
        fprintf('This is better than %i/%i shuffles (min=%.1f, mean=%.1f, max=%.1f%%)\n', ...
            betterThanShuffles, numel( classifyResult.classificationSuccessRate_shuffled ), classifyResult.minShuffle, ...
            classifyResult.meanShuffle, classifyResult.maxShuffle );
        for iLabel = 1 : numel( classifyResult.confuseMatLabels )
            fprintf('  %s: p=%g\n', ...
                classifyResult.confuseMatLabels{iLabel}, classifyResult.conufeMat_pValueVersusShuffle(iLabel,iLabel) )
        end
    end
end


%% Plot Confusion Matrix

% for now just for leave-one-out mode
if params.trialsEachClassEachFold == 0
    % re-order based on specified at top order
    uniqueLabels = classifyResult.uniqueLabelsStr;
    newOrder = cellfun( @(x) find( strcmp( classifyResult.confuseMatLabels, x) ), includeLabels );
    for row = 1 : numel( uniqueLabels )
        for col = 1 : numel( uniqueLabels )
            orderedConfuseMat(row,col) = classifyResult.confuseMat(newOrder(row), newOrder(col));
        end
    end
    % Normalize to 100% is number of true labels
    orderedConfuseMat = 100*(orderedConfuseMat./ repmat( sum( orderedConfuseMat, 2 ), 1, numel( uniqueLabels ) ));
    
    figh = figure;
    figh.Color = 'w';
    titlestr = sprintf( '%s confusion matrix', datasetName );
    figh.Name = titlestr;
    axh = axes;
    imagesc( orderedConfuseMat, [0 100] );
    
    axh.TickLength = [0 0];
    axh.XTickLabel = classifyResult.confuseMatLabels(newOrder);
    axh.YTickLabel = classifyResult.confuseMatLabels(newOrder);
    xlabel('Predicted Sound');
    ylabel('True Sound');
    title( sprintf('%s to %s', params.startEvent, params.endEvent ) )
    cbarh = colorbar;
    cbarh.TickDirection = 'out';
    ylabel(cbarh, '% of true labels');
    colormap('bone')
    axis square
end

%% Save the results
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end
save( resultsFilename, 'classifyResult', 'params' )
fprintf('Saved results to %s\n%s\n', ...
    pathToLastFilesep( resultsFilename ), pathToLastFilesep( resultsFilename, 1 ) );

if isfield( params, 'componentNeuralFeatures' )
        fprintf('%s\n', CellsWithStringsToOneString( params.componentNeuralFeatures ) )
else
    fprintf('%s\n', params.neuralFeature)
end