% Used dPCA to plot how much of the speech neural data is condition-independent versus
% condition-dependent.
%
% Includes single-trial firing rates (soft-normed though) to regularize 
%
% based off of WORKUP_speechCIS.m
%
% Sergey Stavisky, August 14 2019
clear


saveFiguresDir = [FiguresRootNPTL '/speech/CIS/regularized/'];
% saveFiguresDir = [FiguresRootNPTL '/speech/CIS/regularized/jPCAepoch/']; % special side-analysis: run on jPCA peri-speak epoch
% saveFiguresDir = [FiguresRootNPTL '/speech/CIS/regularized/onearray/']; % special side-analysis: run on jPCA peri-speak epoch
% saveFiguresDir = [FiguresRootNPTL '/speech/CIS/regularized/varyDims/later/']; % special side-analysis: run on  different number of dPCs
% saveFiguresDir = [FiguresRootNPTL '/speech/CIS/regularized/prompt/']; % special side-analysis: run on prompt epoch
% saveFiguresDir = [FiguresRootNPTL '/speech/CIS/regularized/later/']; % 0 to 600 ms for T8

if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end

% Cumulative variance values are saved so they can be aggregated and plotted later.
% So are dPCs for comparison to other dimensions (e.g, jPCA)
saveResultsRoot = [ResultsRootNPTL '/speech/dPCA/regularized/']; 
% saveResultsRoot = [ResultsRootNPTL '/speech/dPCA/regularized/jPCAepoch/'];   % special side-analysis: run on jPCA peri-speak epoch
% saveResultsRoot = [ResultsRootNPTL '/speech/dPCA/regularized/onearray/'];   % special side-analysis: run on just one array
% saveResultsRoot = [ResultsRootNPTL '/speech/dPCA/regularized/varyDims/later/'];   %  special side-analysis: run on  different number of dPCs
% saveResultsRoot = [ResultsRootNPTL '/speech/dPCA/regularized/prompt/'];   %  special side-analysis: run on prompt epoch
% saveResultsRoot = [ResultsRootNPTL '/speech/dPCA/regularized/later/'];   % 0 to 600 ms for T8

if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end




% params.crossValidate = true; % as a santiy check; do dPCA on half the trials, then visualize the other half.
params.crossValidate = false; % main results 

params.neuralVoiceOffset = false; % Whether to use PC1 neural alignment to adjust voice onset (only matters for jPCA epoch)
% params.neuralVoiceOffset = true; % Whether to use PC1 neural alignment to adjust voice onset

neuralVoiceOffsetRoot = [ResultsRootNPTL '/speech/neuralVoiceOffsets/']; % directory with acoustic onset offset lags previously calcualted by WORKUP_findNeuralOnsetOffsets.m



%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted.3 The RESPONSE label ('ga' in above example) is used as the label for this trial.


% t5.2017.10.23 Phonemes
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-phonemes.mat';
% params.excludeChannels = datasetChannelExcludeList('t5.2017.10-23_-4.5RMSexclude');
% params.acceptWrongResponse = true;

% t5.2017.10.25 Words
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' );
params.acceptWrongResponse = false;

% t5.2017.10.23 Movements
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-movements.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = false;


% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-phonemes.mat';
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = true;

% t8.2017.10.18 Words
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList('t8.2017.10-18_-4.5RMSexclude');
% params.acceptWrongResponse = false;
% [params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );


% t8.2017.10.17 Movements
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-movements.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = false;

% use this to specifically look at exclude channels (are any of them amazing and maybe
% shouldn't be excluded?
% params.excludeChannels = setdiff( [1:192], participantChannelExcludeList( participant ) );

% NEW DATASETS
% t5.2018.12.12 Standalone
% participant = 't5';
% params.excludeChannels = datasetChannelExcludeList( 't5.2018.12.12-words_-4.5RMSexclude' );
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12-words_noRaw.mat'; 
% params.acceptWrongResponse = false;

%  t5.2018.12.17 Standalone 
% participant = 't5';
% params.excludeChannels = datasetChannelExcludeList( 't5.2018.12.17-words_-4.5RMSexclude' );
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-words_noRaw.mat';
% params.acceptWrongResponse = false;
%%
% Get labels, ignore silence/no movement conditions.
includeLabels = labelLists( Rfile ); % lookup;
includeLabels(strcmp(includeLabels, 'silence')) = [];
includeLabels(strcmp(includeLabels, 'stayStill')) = [];


numArrays = 2; % don't anticipate this changing

%% Analysis Parameters

% params.excludeChannels = union( params.excludeChannels, [1:96] ); % array 2 only
% params.excludeChannels = union( params.excludeChannels, [97:192] ); % array 1 only


% RMS Thresholds
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_28ms'; % spike counts binned smoothed with 28 ms SD Gaussian as in Kaufman 2016

% Spike-sorted
% params.neuralFeature = 'sortedspikesBinnedRateGaussian_28ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% params.thresholdRMS = [];
% params.minimumQuality = 3;



% Note: soft-norm currently works only on the data range analyzed. The range does capture
% most of the peak but it's worth being aware of this.
% params.softenNorm = []; % leave empty to not do this
params.softenNorm = 5; % if not empty, how many Hz to add to range denominator

% NOTE: Kaufman 2016 does soft-norm. 

% new in Aug 2018
% Matches the unit rejection criterion in Kaufman 2016
% Keeping this to false doesn't apply this test (which is how I first did all these
% analyses). NOTE: Doesn't matter, all units meet this criterion.
% params.unitSNRcheck = true;
params.unitSNRcheck = false;



params.maxDims = 8; % main analysis
% params.maxDims = 5;  % try sweeping range
% params.maxDims = 12;  % try sweeping range
params.highDims = 30; % for scree plot; not used for actual analyses

params.subspaceaDims = 2; % report subspace angle between CIS1 and these many condition-dependent DIMS


% Align to speak go cue. (matched to Kaufman 2016 Go Cue alignment)
if isempty( strfind( Rfile, 'movements') ) %#ok<STREMP>
    % Speaking
    params.alignEvent = 'handPreResponseBeep';
    params.startEvent = 'handPreResponseBeep - 0.200';
    params.endEvent= 'handPreResponseBeep + 0.400';
else
    % Align to MOVEMENT go cue, which is 'handResponseEvent'
    % ONLY use this for movement data
    params.alignEvent = 'handResponseEvent';
    params.startEvent = 'handResponseEvent - 0.200';
    params.endEvent= 'handResponseEvent + 0.400';
end

% special side-analysis: run on jPCA peri-speak epoch
% fprintf(2, 'USING PERI-SPEECH EPOCH USED FOR jPCA ANALYSES!! This is not main figure usage\n')
% if params.neuralVoiceOffset
%     params.alignEvent = 'handResponseEvent';
%     params.startEvent = 'handResponseEvent - 0.250'; % 1 ms buffer to make sure exact ms is available
%     params.endEvent = 'handResponseEvent';
% else
%     params.alignEvent = 'handResponseEvent';
%     params.startEvent = 'handResponseEvent - 0.150';
%     params.endEvent = 'handResponseEvent + 0.101';
% end


% Speaking T8: bit later
% params.alignEvent = 'handPreResponseBeep';
% params.startEvent = 'handPreResponseBeep + 0.100 ';
% params.endEvent= 'handPreResponseBeep + 0.700';
% special side-analysis: run on prompt epoch
% % fprintf(2, 'USING PROMPT EPOCH! This is not main figure usage\n')
% params.alignEvent = 'handCueEvent';
% params.startEvent = 'handCueEvent';
% params.endEvent = 'handCueEvent + 0.600';


% Alignments for single-trial VOT finding 
% these are taken from Matt's methods which look at 60 ms before to 
% 500 ms after.
params.singleTrial.startEvent = 'handPreResponseBeep - 0.100'; 
params.singleTrial.alignEvent = 'handPreResponseBeep';  % Go Cue
params.singleTrial.endEvent = 'handPreResponseBeep + 0.600';
params.singleTrial.neuralFeature = 'spikesBinnedRate_10ms';
params.singleTrial.gaussianSmoothMS = 30; % how many milliseconds standard deviation Gaussian smoothing to apply to the binned rates
params.singleTrial.crossingThreshold = 0.5; % at what fraction of max( z~(t) ) - min ( z~(t) ) to determine the "crossover" and use this as predictor of RT
params.sigleTrial.normalizeRTwithinWord = true; % if true, then will z-score single trial RTs within a word.
result.params = params;
result.params.Rfile = Rfile;



%% Load the data
in = load( Rfile );
R = in.R;
clear('in')
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly
try
    sortQuality = speechSortQuality( datasetName ); % manual entry since I forgot to include this in R struct : (
catch
    sortQuality = [];
end
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
if params.neuralVoiceOffset
    offsetFile = sprintf('%soffsets-%s.mat', neuralVoiceOffsetRoot, datasetName );
    load( offsetFile, 'sOffsets' );
else
    sOffsets = [];
end

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
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode, 'sOffsets', sOffsets )];
end
R = Rnew; 
clear( 'Rnew' );


%% Generate neural feature
% Apply RMS thresholding
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
else
    error('Feature not yet implemented')
end



%% Make PSTH
% I'm going to create a cell with each trial's trial-averaged mean/std/se,
% firing rate in the plot window.
% Here I also get a single average rate for each channel per trial.
% I also keep track of each unit's range and max SEM across each condition, which is
% useful
N = R(1).(params.neuralFeature).numChans;
minPSTHeachCondition = nan( N, numel( uniqueLabels ) );
maxPSTHeachCondition = minPSTHeachCondition;
maxSEMeachCondition = minPSTHeachCondition;
maxTrialNum = 0; % will keep track of maximum number of trials.
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, myLabel );
    jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
    result.(myLabel).t = jenga.t;
    result.(myLabel).psthMean = squeeze( mean( jenga.dat, 1 ) );
    result.(myLabel).psthStd = squeeze( std( jenga.dat, 1 ) );
    tPlot = jenga.t(1:end-1); % will be used for plotting time using dpca_plot later
    
    % save single trials 
    result.(myLabel).allTrials = jenga.dat; % trials x time x electrode
    
    for t = 1 : size( jenga.dat,2 ) 
        result.(myLabel).psthSem(t,:) =  sem( squeeze( jenga.dat(:,t,:) ) );
    end
    result.(myLabel).numTrials = jenga.numTrials;
    maxTrialNum = max( [maxTrialNum, result.(myLabel).numTrials]);
    % channel names had best be the same across events/groups, so put them in one place
    result.channelNames = R(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
    
    minPSTHeachCondition(:,iLabel) = min( result.(myLabel).psthMean, [], 1 )';
    maxPSTHeachCondition(:,iLabel) = max( result.(myLabel).psthMean, [], 1 )';
    maxSEMeachCondition(:,iLabel) = max( result.(myLabel).psthSem, [], 1)';
    
    % SANITY CHECK: Divide trials into two folds, make sure things look 
    if params.crossValidate 
        minPSTHeachCondition_folds = nan( N, numel( uniqueLabels ),2 );
        maxPSTHeachCondition_folds = minPSTHeachCondition_folds;
        
        fprintf(2, 'ALERT: Doing two folds cross-validated analysis. Not intended for final analyis!\n')
        myTrialInds = find( myTrialInds );
        for iFold = 1 : 2
            thisFoldInds = myTrialInds(iFold:2:end);
            jenga = AlignedMultitrialDataMatrix( R(thisFoldInds), 'featureField', params.neuralFeature, ...
                'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
            myMeanField = sprintf( 'psthMean%i', iFold );
            result.(myLabel).(myMeanField) = squeeze( mean( jenga.dat, 1 ) );
            minPSTHeachCondition_folds(:,iLabel,iFold) = min( result.(myLabel).(myMeanField), [], 1 )';
            maxPSTHeachCondition_folds(:,iLabel,iFold) = max( result.(myLabel).psthMean, [], 1 )';
            
            result.(myLabel).allTrialsEachFold{iFold} = jenga.dat;
            result.(myLabel).numTrialsEachFold(iFold) = numel( thisFoldInds );
        end        
    end
end




%% Remove units that don't meet SNR inclusion crieria
if params.unitSNRcheck 
    % what is the max range of each channel?
    rangeEachChan = max( maxPSTHeachCondition - minPSTHeachCondition, [], 2 );
    maxSEMeachChan = max( maxSEMeachCondition, [], 2 );
    SNRexcludedInds = find( maxSEMeachChan >= rangeEachChan );
    figure; scatter( maxSEMeachChan, rangeEachChan )
    xlabel( 'Max SEM (Hz)'); ylabel('Range (Hz)');
    line([0 100], [0 100], 'Color', [.5 .5 .5])
    title( sprintf('SNR exclusion %s', datasetName ) );
    
    if numel( SNRexcludedInds ) > 0
        keyboard
        % TODO: actually remove the channels. No units have met this rejection rule yet so
        % irrelevant for now.
        % TODO: make sure single-trial analysis also excludes these
    end
end
fprintf('Using %i units in analysis\n', numel( result.channelNames ) );





%% Format for dPCA


% firingRatesAverage: N x S x D x T
%
% N is the number of neurons
% S is the number of conditions for factor 1
% T is the number of time-points (note that all the trials/conditions should have the
% same length in time!)
%
N = size( result.(uniqueLabels{1}).psthMean, 2 );
S = numel( uniqueLabels );
T = numel( result.(uniqueLabels{1}).t )-1; % drop last sample so its even 100s of ms



combinedParams = {{1, [1 2]}, {2}}; %so marginalization 1 is condition and condition/time, and marg. 2 is just time
margNames = {'Condition-dependent', 'Condition-independent'};
margColours = [0 0 250; 250 0 0]./255;

trialNum = nan( N, S );
featureAverages = nan(N, S, T);
featureIndividual = nan(N, S, T, maxTrialNum); % individual trial data
if params.crossValidate 
    trialNum1 = nan( N, S );
    trialNum2 = nan( N, S );

    featureAverages1 = featureAverages;
    featureAverages2 = featureAverages;
    featureIndividual1 = featureIndividual;
    featureIndividual2 = featureIndividual;
end

for iLabel = 1 : numel( uniqueLabels )
    featureAverages(:,iLabel,:) = result.(uniqueLabels{iLabel}).psthMean(1:end-1,:)';
    myDat = result.(uniqueLabels{iLabel}).allTrials(:,1:end-1,:);    
    myNumTrials = size( myDat, 1 );
    featureIndividual(:,iLabel,:,1:myNumTrials) = permute( myDat, [3, 2, 1] );    
    trialNum(:,iLabel) = myNumTrials;
    if params.crossValidate         
        featureAverages1(:,iLabel,:) = result.(uniqueLabels{iLabel}).psthMean1(1:end-1,:)';
        featureAverages2(:,iLabel,:) = result.(uniqueLabels{iLabel}).psthMean2(1:end-1,:)';
           
        myDat1 = result.(uniqueLabels{iLabel}).allTrialsEachFold{1}(:,1:end-1,:);    
        trialNum1(:,iLabel) = size( myDat1, 1 );
        featureIndividual1(:,iLabel,:,1:size( myDat1, 1 )) = permute( myDat1, [3, 2, 1] );
        myDat2 = result.(uniqueLabels{iLabel}).allTrialsEachFold{2}(:,1:end-1,:);    
        trialNum2(:,iLabel) = size( myDat2, 1 );
        featureIndividual2(:,iLabel,:,1:size( myDat2, 1 )) = permute( myDat2, [3, 2, 1] );
    end
end

if ~isempty( params.softenNorm )
    fprintf('Doing Soften-norm %g Hz\n', params.softenNorm )
    % range for each channel
    allChannelRange =  max( max( featureAverages, [], 3 ), [], 2 ) - min( min( featureAverages, [], 3 ), [], 2 );
    allChannelRange = allChannelRange + params.softenNorm;
    % softnorm
    featureAverages = featureAverages .* repmat( 1./allChannelRange, 1, size( featureAverages, 2 ), size( featureAverages, 3 ) );
    featureIndividual = bsxfun( @times, featureIndividual, 1./allChannelRange );
    
    if params.crossValidate
        allChannelRange1 =  max( max( featureAverages1, [], 3 ), [], 2 ) - min( min( featureAverages1, [], 3 ), [], 2 );
        allChannelRange1 = allChannelRange1 + params.softenNorm;
        featureAverages1 = featureAverages1 .* repmat( 1./allChannelRange1, 1, size( featureAverages1, 2 ), size( featureAverages1, 3 ) );
        featureIndividual1 = bsxfun( @times, featureIndividual1, 1./allChannelRange1 );
        
        allChannelRange2 =  max( max( featureAverages2, [], 3 ), [], 2 ) - min( min( featureAverages2, [], 3 ), [], 2 );
        allChannelRange2 = allChannelRange2 + params.softenNorm;
        featureAverages2 = featureAverages2 .* repmat( 1./allChannelRange2, 1, size( featureAverages2, 2 ), size( featureAverages2, 3 ) );   
        featureIndividual2 = bsxfun( @times, featureIndividual2, 1./allChannelRange2 );
    end
end

% % Sanity check that individual trials work:
% figh_sanityIndividual = figure;
% % plot mean FR for one condition
% ax1= subplot(1,2,1);
% exChan = 6;
% plot( squeeze( featureAverages(exChan,1,:) ));
% ax2 = subplot(1,2,2);
% individualTraces = squeeze( featureIndividual(exChan,1,:,:) );
% plot( individualTraces );
% hold on;
% plot( nanmean( individualTraces,2 ), 'Color', 'k', 'LineWidth', 3 )
% linkaxes( [ax1, ax2] )



%% do DPCA


params.maxDims = 8; %  Can override here to quickly iterate across dimensionalities (for supp fig)


isSimultaneous = true; % array data

optimalLambda = dpca_optimizeLambda(featureAverages, featureIndividual, trialNum, ...
    'combinedParams', combinedParams, ...
    'simultaneous', isSimultaneous, ...
    'numRep', 10, ...  % increase this number to ~10 for better accuracy
    'filename', 'tmp_optimalLambdas.mat');

Cnoise = dpca_getNoiseCovariance(featureAverages, ...
    featureIndividual, trialNum, 'simultaneous', isSimultaneous);
% optimalLambda = 0; % try just using Cnoise to regularize
% first do dpca using a lot of dimensions to get what the scree plots look like (and save
% them)

[W,V,whichMarg] = dpca(featureAverages, params.highDims, ...
    'combinedParams', combinedParams, ...
    'lambda', optimalLambda, ...
    'Cnoise', Cnoise);

explVar = dpca_explainedVariance(featureAverages, W, V, ...
    'combinedParams', combinedParams, ...
        'Cnoise', Cnoise, 'numOfTrials', trialNum); % estimate signal variance


% save the cumulative vars explained
saveFilepath = sprintf('%scumvars-%s.mat', saveResultsRoot, datasetName );
save( saveFilepath, 'explVar' )
fprintf('Saved %s\n', saveFilepath )


% now do it for real
if ~params.crossValidate
    % normal usage
    [W,V,whichMarg] = dpca(featureAverages, params.maxDims, ...
        'combinedParams', combinedParams, ...
        'lambda', optimalLambda, ...
        'Cnoise', Cnoise);
    explVar = dpca_explainedVariance(featureAverages, W, V, ...
        'combinedParams', combinedParams, ...
        'Cnoise', Cnoise, 'numOfTrials', trialNum); % estimate signal variance
    
else
   % CROSS VALIDATED 
   optimalLambda = dpca_optimizeLambda(featureAverages1, featureIndividual1, trialNum1, ...
       'combinedParams', combinedParams, ...
       'simultaneous', isSimultaneous, ...
       'numRep', 10, ...  % increase this number to ~10 for better accuracy
       'filename', 'tmp_optimalLambdas.mat');

    Cnoise = dpca_getNoiseCovariance(featureAverages1, ...
        featureIndividual1, trialNum1, 'simultaneous', isSimultaneous);
   
    [W,V,whichMarg] = dpca(featureAverages1, params.maxDims, ...
        'combinedParams', combinedParams, ...
        'lambda', optimalLambda, ...
        'Cnoise', Cnoise);
    
    explVar = dpca_explainedVariance(featureAverages2, W, V, ...
        'combinedParams', combinedParams, ...
        'Cnoise', Cnoise, 'numOfTrials', trialNum2); % estimate signal variance
end



% I can plot using the built-in dPCA plotting tools. 

% Time events of interest (e.g. stimulus onset/offset, cues etc.)
% They are marked on the plots with vertical lines
timeEvents = 0; 
if ~params.crossValidate
    % normal usage
    dpca_plot(featureAverages, W, V, @dpca_plot_default, ...
        'explainedVar', explVar, ...
        'marginalizationNames', margNames, ...
        'marginalizationColours', margColours, ...
        'whichMarg', whichMarg,                 ...
        'time', tPlot,                        ...
        'timeEvents', timeEvents,               ...
        'timeMarginalization', 3,           ...
        'legendSubplot', 16);
else
    % CROSS VALIDATE
    dpca_plot(featureAverages2, W, V, @dpca_plot_default, ...
        'explainedVar', explVar, ...
        'marginalizationNames', margNames, ...
        'marginalizationColours', margColours, ...
        'whichMarg', whichMarg,                 ...
        'time', tPlot,                        ...
        'timeEvents', timeEvents,               ...
        'timeMarginalization', 3,           ...
        'legendSubplot', 16);
end
numCDdims = nnz( whichMarg == 1 );
numCIdims = nnz( whichMarg == 2 );
fprintf('%i condition-dependent dimensions and %i condition-INDEPENDENT dims together explain %.2f%% overall variance\n', ...
    numCDdims, numCIdims, explVar.cumulativeDPCA(end) );


% ----------------------------------------------------------------  
% re-sort based on how much condition-independent activity there is
CIdims = whichMarg==2;
CIdimsInds = find( CIdims );
[~, sortIndsByCI] = sort( explVar.margVar(2,CIdims), 'descend');
% start with the CI dimensions
eachVarExplained = explVar.margVar(:,CIdimsInds(sortIndsByCI));
eachVarExplained = [eachVarExplained, explVar.margVar(:,~CIdims)];
% also grab all the W and V vectors with this order
Wreordered = [W(:,CIdimsInds(sortIndsByCI)), W(:,~CIdims)];
Vreordered = [V(:,CIdimsInds(sortIndsByCI)), V(:,~CIdims)];

% Flip CIS1 if necessary to show it as upwards-going (it's AU and thus arbtirary direction anyway, but
% this keeps it from flip-flopping for different number dimensionalities and looking very different for an arbtirary sign flip).
acrossCondsMean = squeeze( mean( featureAverages,2 ) )'; % T x E
GM = acrossCondsMean * Wreordered(:,1);
if GM(end) < GM(1)
    fprintf( 2, 'FLIPPING SIGN CI1 to maintain upward-going\n')
    Wreordered(:,1) = -Wreordered(:,1);    
    Vreordered(:,1) = -Vreordered(:,1);    
end


fprintf('CD: %s\n', mat2str( eachVarExplained(1,:), 5 ) )
fprintf('CI: %s\n', mat2str( eachVarExplained(2,:), 5 ) )

% What fraction of variance does CIS 1 explain? Note I'm including both its CI and CD
% marginalization (latter is tiny though)
totVarDPCA = explVar.cumulativeDPCA(end);
varCIS1 = sum( eachVarExplained(:,1) );
fprintf('CIS1 (which includes a tiny bit of CD marganization) explains %.1f%% of top %i dPCs and %.1f%% of full-D variance\n', ...
    100*varCIS1/totVarDPCA, numCDdims+numCIdims, varCIS1 );

% save the components in a file. I'll use this later to compare the CIS and jPC plane
saveFilepath_dPCs = sprintf('%sdPCs-%s-%idim.mat', saveResultsRoot, datasetName, params.maxDims );
save( saveFilepath_dPCs, 'Wreordered', 'Vreordered' )
fprintf('Saved %s\n', saveFilepath_dPCs )


% ----------------------------------------------------
% How orthogonal is CIS_1 to the movement dims?
% W versioin
% CIS1_W = Wreordered(:,1);
% CDdims_W = Wreordered(:,numel(CIdimsInds)+1:end);
% 
% for i = 1: size( CDdims_W, 2 )
%     angleBetween = angleBetweenVectors(CIS1_W,CDdims_W(:,i));
%     if angleBetween > 90
%         angleBetween = 180- angleBetween;
%     end
%     fprintf('Angle between CIS1 and CD%i is %.3fdeg\n', i,  angleBetween)
% end
% suba = rad2deg( subspacea( CIS1_W, CDdims_W(:,1:params.subspaceaDims) ) );
% fprintf('Subspace angle between CIS1 and first %i condition-dependent dims is %.2f deg\n', ...
%     params.subspaceaDims, suba );
% subaAll = rad2deg( subspacea( CIS1_W, CDdims_W ) );
% fprintf('Subspace angle between CIS1 and ALL %i condition-dependent dims is %.2f deg\n', ...
%     size( CDdims_W, 2 ), subaAll );

% ----------------------------------------------------------------  
% How orthogonal is CIS_1 to the movement dims?
% V version
CIS1_V = Vreordered(:,1);
CDdims_V = Vreordered(:,numel(CIdimsInds)+1:end);

for i = 1: size( CDdims_V, 2 )
    angleBetween = angleBetweenVectors(CIS1_V,CDdims_V(:,i));
    if angleBetween > 90
        angleBetween = 180- angleBetween;
    end
    fprintf('Angle between CIS1 and CD%i is %.3fdeg\n', i,  angleBetween)
end
if ~isempty( CDdims_V ) % if very few dims specified, may not be dPCs
    suba = rad2deg( subspacea( CIS1_V, CDdims_V(:,1:min( params.subspaceaDims, size( CDdims_V, 2))) ) );
    fprintf('Subspace angle between CIS1 and first %i condition-dependent dims is %.2f deg\n', ...
        min( params.subspaceaDims, size( CDdims_V, 2)), suba );
    subaAll = rad2deg( subspacea( CIS1_V, CDdims_V ) );
    fprintf('Subspace angle between CIS1 and ALL %i condition-dependent dims is %.2f deg\n', ...
        size( CDdims_V, 2 ), subaAll );
end
% ----------------------------------------------------------------  
% make rod-and-disk figure showing how orthogonal CIS1 is to the first N CD-dims

figh = figure;
figh.Color = 'w';
circle( [0,0],1,[.5 .5 .5],1)
axh = gca;
ch = axh.Children;
axh.Visible = 'off';
axis equal
rayx = cos( deg2rad( suba ) );
rayy = sin( deg2rad( suba ) );
lh = line( [0 0], [0 rayx], [0 rayy], 'LineWidth', 2', 'Color', 'k');
view(3)
titlestr = sprintf('disk and rot dPCA %s', datasetName);
figh.Name = titlestr;
ExportFig( figh, [saveFiguresDir titlestr] );

% ----------------------------------------------------------------  
% Correlations between axes and components 
% p value is fourth argument
if ~params.crossValidate
    % regular usage
    [a, b, dimCorr_p, figh_dimCorr] = dpca_dimCorrelations( featureAverages, Wreordered, Vreordered, 0.01 );
else
    [a, b, dimCorr_p, figh_dimCorr] = dpca_dimCorrelations( featureAverages2, Wreordered, Vreordered, 0.01 );
end
titlestr = sprintf('dPC correlations %s %idims', datasetName, params.maxDims);
figh_dimCorr.Name = titlestr;
ExportFig( figh_dimCorr, [saveFiguresDir titlestr] );

% [a, b, dimCorr_p, figh_dimCorr] = dpca_dimCorrelations( featureAverages, Wreordered, Vreordered, 0.001 );

% ----------------------------------------------------------------  
% Plot how much each component explains    
% (Presented as in Kaufman et al. 2016)
figh = figure;
figh.Color = 'w';
titlestr = sprintf('CIS dPCA %s %idims', datasetName, params.maxDims);
figh.Name = titlestr;
axh_var = subplot( 2, 1, 1 );
axh_var.TickDir = 'out';
hbar = barh( eachVarExplained', 'stacked' );
axh_var.YDir = 'reverse';
hbar(1).BarWidth = 1;
hbar(2).BarWidth = 1;
hbar(2).FaceColor = margColours(2,:);
hbar(1).FaceColor = margColours(1,:);

ylabel('dPCA Component');
xlabel('% Overall Variance Explained')

% ----------------------------------------------------------------  
% Prep for plotting
% Define the specific colormap
colors = [];
legendLabels = {};
for iLabel = 1 : numel( uniqueLabels )
   colors(iLabel,1:3) = speechColors( uniqueLabels{iLabel} ); 
   legendLabels{iLabel} = sprintf('%s (n=%i)', uniqueLabels{iLabel}, result.(uniqueLabels{iLabel}).numTrials );
end


% ----------------------------------------------------------------  
% Plot each condition's CIS_1
axh_CIS = subplot( 2, 1, 2 ); hold on;



CIS1dim = Wreordered(:,1);
for iLabel = 1 : numel( uniqueLabels )
    if ~params.crossValidate
        % regular usage
        myCIS1 = squeeze( featureAverages(:,iLabel,:) )' * CIS1dim; % T x 1
    else
        myCIS1 = squeeze( featureAverages2(:,iLabel,:) )' * CIS1dim; % T x 1
    end
    plot( tPlot, myCIS1, 'Color', colors(iLabel,:), ...
        'LineWidth', 1 );
end

axh_CIS.TickDir = 'out';
xlim( [tPlot(1) tPlot(end) ] );
xlabel( sprintf( 'Time wrt %s (s)', params.alignEvent ) );

ExportFig( figh, [saveFiguresDir titlestr] );


% ----------------------------------------------------------------  
% Plot activity in all the dPCs
    
figh = figure;
figh.Color = 'w';
titlestr = sprintf('All dPCs %s', datasetName);
figh.Name = titlestr;
Ncols = ceil( params.maxDims/2 );
for iDPC = 1 : params.maxDims
   axh = subplot( 2,  Ncols, iDPC );
   myDim = Wreordered(:,iDPC);
   title( sprintf('CI: %.2f, CD: %.2f', ... 
       eachVarExplained(2,iDPC), eachVarExplained(1,iDPC) ) );
   hold on;
   for iLabel = 1 : numel( uniqueLabels )
       if ~params.crossValidate
           % regular usage
           myComponents = squeeze( featureAverages(:,iLabel,:) )' * myDim; % T x 1
       else
           % cross-validated
           myComponents = squeeze( featureAverages2(:,iLabel,:) )' * myDim; % T x 1
       end
       plot( tPlot, myComponents, 'Color', colors(iLabel,:), ...
           'LineWidth', 1 );
   end
   xlim( [tPlot(1) tPlot(end) ] );   
end



%% Sanity check: plot grand mean FR
meanFR = squeeze( mean( featureAverages, 1 ) );
figh_meanFR = figure;
figh_meanFR.Color = 'w';
titlestr = sprintf('Mean FR %s', datasetName);
figh_meanFR.Name = titlestr;
axes; 
hold on;
for iLabel = 1 : numel( uniqueLabels )
    myFR = meanFR(iLabel,:);
    plot( tPlot, myFR, 'Color', colors(iLabel,:), ...
        'LineWidth', 1 );
end
xlim( [tPlot(1) tPlot(end) ] );







%% Look for single-trial VOT timing correlates
% add an end event to each trial
for i = 1 : numel( R )
    R(i).endOfTrial = numel( R(i).clock );
end

% Add the binned spike rate to all trials
R = AddFeature( R, params.singleTrial.neuralFeature );
if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.singleTrial.neuralFeature );
end
% apply Gaussian smoothing to this
fprintf( 'Smoothing %s with %i ms s.d. Gaussian kernel\n', params.singleTrial.neuralFeature, params.singleTrial.gaussianSmoothMS )
stdMS = params.singleTrial.gaussianSmoothMS;
numSTD = 3; % will make the kernel out to this many standard deviations
% now make the Gaussian kernel out to 3 standard deviations
x = -numSTD*stdMS:1:numSTD*stdMS;
gkern = normpdf( x, 0, stdMS );
% normalize to area 1
gkern = gkern ./ sum( gkern );
for iTrial = 1 : numel( R ) 
    R(iTrial).(params.singleTrial.neuralFeature).dat = filter( gkern, 1, double( R(iTrial).(params.singleTrial.neuralFeature).dat' ) )';
    % trim to only valid parts of filtered data
    R(iTrial).(params.singleTrial.neuralFeature).t(1:numSTD*stdMS) = [];
    R(iTrial).(params.singleTrial.neuralFeature).t(end-numSTD*stdMS+1:end)=[];
    R(iTrial).(params.singleTrial.neuralFeature).dat(:,1:2*numSTD*stdMS)=[]; % 2 x because only taking from front, to shift everything back
end

% Soft-normalize all the trials
for iTrial = 1 : numel( R ) % can probably be parfor to speed things up
    NF = repmat( 1./allChannelRange, 1, size( R(iTrial).(params.singleTrial.neuralFeature).dat,2 ));
    R(iTrial).(params.singleTrial.neuralFeature).dat = R(iTrial).(params.singleTrial.neuralFeature).dat .* NF;
end

% Calculate CIS Dim 1 for all trials
jenga = AlignedMultitrialDataMatrix( R, 'featureField', params.singleTrial.neuralFeature, ...
    'startEvent', params.singleTrial.startEvent, 'alignEvent', params.singleTrial.alignEvent, 'endEvent', params.singleTrial.endEvent );
singleTrialCIS1t = jenga.t;
singleTrialCIS1 = nan( jenga.numTrials, jenga.numSamples );   % trials x time
for iTrial = 1 : numel( R )
    singleTrialCIS1(iTrial,:) = squeeze( jenga.dat(iTrial,:,:) ) * CIS1dim;
end
medianCIS1 = median( singleTrialCIS1 );


% Calculate the midpoint using the Kaufman 2016 method:
% "To find that criterion value, we took the median of z(t,r) across trials, producing z~(t). We set the criterion value 
% to be the midpoint of z?(t): [max( z~(t) ) + min( z~(t) ]/2.
midpointCIS1 = min( medianCIS1 ) + params.singleTrial.crossingThreshold * (max( medianCIS1 ) - min( medianCIS1 ));
% crossing times
allCrossingTimes = []; % will be in MS after go cue
% will note trials that violate rule from Kaufman 2016:
% Trials that never exceeded the criterion value, or that exceeded it before the go cue, were
% discarded from the analysis. Such trials were uncommon,
% especially for the better prediction methods (0?9%, de-pending on dataset and method). "
invalidTrials = zeros( numel( R ), 1 ); 
for iTrial = 1 : numel( R )
    myCrossing = find( singleTrialCIS1(iTrial,:) > midpointCIS1, 1, 'first' );
    % is this a valid trial?
    if singleTrialCIS1t(myCrossing) <= 0 
        % exceeds before go cue
        invalidTrials(iTrial) = true;
    end
    if isempty( myCrossing )
        % never exceeds
        invalidTrials(iTrial) = true;
    end
     
    if invalidTrials(iTrial)
        allCrossingTimes(iTrial) = nan;
    else
        allCrossingTimes(iTrial) = round( 1000.* singleTrialCIS1t(myCrossing) ); % MS
    end
end
fprintf('%i/%i (%.1f%%) trials discarded to to no CIS1 midpoint crossing or crossing is before go cue\n', ...
    nnz( invalidTrials ), numel( invalidTrials ), 100* nnz( invalidTrials ) / numel( invalidTrials ) )

% NORMALIZED RT WITHIN EACH LABEL
figh = figure;
figh.Color = 'w';
axh = axes; hold on;
titlestr = sprintf('RT vs CIS1 %s', datasetName);
figh.Name = titlestr;

% Do it separately within each label since the relationship between muscle start and VOT
% can differ between sounds
allValidCrossingTimes = [];
allValidNormRTs = []; % will get filled in with accepted trials


for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, myLabel );    
    myRTs = [R(myTrialInds).handResponseEvent] - [R(myTrialInds).handPreResponseBeep];
    if params.sigleTrial.normalizeRTwithinWord
        myNormRTs = (myRTs - mean( myRTs )) ./ std( myRTs );
    else
        % don't normalize
        myNormRTs = myRTs;
    end

    myCrossingTimes = allCrossingTimes(myTrialInds);
    myValids = ~isnan( myCrossingTimes );
    myValidCrossingTimes =  myCrossingTimes(myValids);
    myValidNormRTs = myNormRTs(myValids);

    % uncomment to plot each label separately
%     myColor = speechColors( myLabel );
%     sh = scatter( myValidCrossingTimes, myValidNormRTs, 16, 'filled', 'Marker', 'o' );
    
    allValidCrossingTimes = [allValidCrossingTimes ; myValidCrossingTimes'];
    allValidNormRTs = [allValidNormRTs ; myValidNormRTs'];    
end

% Linear fit
lm = fitlm( allValidCrossingTimes, allValidNormRTs );
yint = lm.Coefficients.Estimate(1);
slope = lm.Coefficients.Estimate(2);
RTpval = lm.coefTest;

sh = scatter( allValidCrossingTimes, allValidNormRTs, 16, 'filled', 'Marker', 'o' );
% draw the fit line
x1 = min( allValidCrossingTimes );
x2 = max( allValidCrossingTimes );
y1 = yint + slope*x1;
y2 = yint + slope*x2;
lh = line( [x1 x2], [y1 y2], 'Color', 'k', 'LineWidth', 1.5);
xlabel( 'Crossing time (ms) ' );
ylabel( 'RT (z-score)' );
r = corr( allValidCrossingTimes, allValidNormRTs );
fprintf('Correlation between crossing time and z-scored RT = %f (p=%f)\n', ...
    r, RTpval )



%% Plot all trials' CIS1. Color based on whether it was accepted or not.
figh = figure;
figh.Color = 'w';
axh = axes; hold on;
titlestr = sprintf('All Trials CIS1 %s', datasetName);
figh.Name = titlestr;
% not valid
plot( singleTrialCIS1t, singleTrialCIS1(logical(invalidTrials),:)', 'Color', [.6 .6 .6]  );
% valid:
plot( singleTrialCIS1t, singleTrialCIS1(~logical(invalidTrials),:)', 'Color', [1 0 0]  );

xlabel( sprintf( 'Time after %s (s)', params.singleTrial.alignEvent ) )
ylabel('CIS1');
hold on;
% Plot valid mean CIS1
plot( singleTrialCIS1t, medianCIS1', 'Color', 'k', 'LineWidth', 2);
% show midpoint
% show the midpoint
lh = line( [singleTrialCIS1t(1) singleTrialCIS1t(end)], [midpointCIS1, midpointCIS1], 'Color', [.4 .4 .4], 'LineWidth', 3 );
xlim( [singleTrialCIS1t(1) singleTrialCIS1t(end)] );
