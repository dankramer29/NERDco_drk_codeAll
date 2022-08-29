% Stripped down version of WORKUP_speech_jPCA.m, with data processing matched to
% WORKUP_speechCIS_regularized.m. The goal is to save down the jPC dimensions so that they
% can be compared to the CIS1 dimension.
%
% Sergey Stavisky, August 15 2019
% Stanford Neural Prosthetics Translational Laboratory
function WORKUP_speech_jPCA_forCompareToCIS

clear
% add TME code to path
TMEstartup;
rng(1)


saveResultsRoot = [ResultsRootNPTL '/speech/jPCA/']; 


if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end


neuralVoiceOffsetRoot = [ResultsRootNPTL '/speech/neuralVoiceOffsets/']; % directory with acoustic onset offset lags previously calcualted by WORKUP_findNeuralOnsetOffsets.m
params.neuralVoiceOffset = false; % Whether to use PC1 neural alignment to adjust voice onset

%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted. The RESPONSE label ('ga' in above example) is used as the label for this trial.


% t5.2017.10.23 Phonemes
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-phonemes.mat';
% params.excludeChannels = datasetChannelExcludeList('t5.2017.10-23_-4.5RMSexclude');
% params.acceptWrongResponse = true;

% t5.2017.10.25 Words
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' ); % As of July 2018
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMS_respondersOnly' ); % trying keeping only speech-tuned chans, conssitent with Pandarinath 2015
params.acceptWrongResponse = false;


% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-phonemes.mat';
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = true;

% t8.2017.10.18 Words
% participant = 't8';
% % Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_20ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-18_-4.5RMSexclude' );
% % params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-18_-4.5RMS_respondersOnly' ); % trying keeping only speech-tuned chans, conssitent with Pandarinath 2015
% params.acceptWrongResponse = false;
% [params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( 't8.2017.10.18-words' );


% NEW DATASETS


% t5.2018.12.12 Standalone
% participant = 't5';
% params.excludeChannels = datasetChannelExcludeList( 't5.2018.12.12-words_-4.5RMSexclude' );
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12-words_noRaw.mat'; 
% params.acceptWrongResponse = false;

% t5.2018.12.17 Standalone 
% participant = 't5';
% params.excludeChannels = datasetChannelExcludeList( 't5.2018.12.17-words_-4.5RMSexclude' );
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-words_noRaw.mat';
% params.acceptWrongResponse = false;
% ~~~~~~~~~~~
% Movements jPCA
% ~~~~~~~~~~

% % t5.2017.10.23 Movements
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-movements_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
% params.acceptWrongResponse = false;

% t8.2017.10.17 Movements
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-movements_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = false;



%%
includeLabels = labelLists( Rfile ); % lookup;

% TMP: test on half of words
% fprintf( 2, 'ARTIFICALLY RESTRICTING TO FOLLOW-UP WORDS\n')
% includeLabels = {'silence', 'seal', 'shot', 'more', 'bat', 'beet' };
% Don't analyze silence / stayStill 
includeLabels(strcmp( includeLabels,{'silence'})) = [];
includeLabels(strcmp( includeLabels,{'stayStill'})) = [];

numArrays = 2; % don't anticipate this changing

datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly
datasetName = regexprep( datasetName, '_lfpPow_125to5000_20ms', ''); %otherwise names get ugly


% Analysis parameters
% Spike-sorted
% params.neuralFeature = 'sortedspikesBinnedRateGaussian_30ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% params.thresholdRMS = [];
% params.minimumQuality = 3;
% sortQuality = speechSortQuality( datasetName ); % manual entry since I forgot to include this in R struct : (


% THRESHOLD CROSSINGS
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_28ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% try longer smoothing
% params.neuralFeature = 'spikesBinnedRateGaussian_35ms'; % spike counts binned smoothed with 25 ms SD Gaussian 


% HIGH GAMMA POWER
% Interesting to see if we still see rotations with high gamma?
% params.neuralFeature = 'lfpPow_65to150_35ms';

% params.neuralFeature = 'lfpPow_125to5000_20ms';
% params.lfpPowGaussianMS = 20; % how many milliseconds standard deviation Gaussian smoothing to apply to the the LFP
% params.thresholdRMS = [];

% It's nice to see some PSTHs, with the same color scheme as jPCA 
% These are chosen based on which channels were interesting from earlier PSTH analysis
% Should be an even number for a nicer plot

switch datasetName
    case 't5.2017.10.25-words' % T5 Example channels (high ANOVA scores):
        if strfind( params.neuralFeature, 'sorted' )
           plotTheseElecs = {'unit12(1)_array2_elec2(98)', 'unit13(2)_array2_elec4(100)', ...
                   'unit24(13)_array2_elec85(181)', 'unit5(5)_array1_elec20(20)'};      
        else
            plotTheseElecs = {'chan_2.2', 'chan_2.95', 'chan_1.53', 'chan_2.91', 'chan_2.4', 'chan_2.66', 'chan_2.71', ...
                'chan_2.93', 'chan_1.11', 'chan_2.37', 'chan_1.17', 'chan_2.7', 'chan_1.10', 'chan_1.19', 'chan_2.88', 'chan_1.66', 'chan_2.30', 'chan_1.37'};               
        end
        
    case 't5.2017.10.23-phonemes' % copied directly from t5-words, may not be reasonable
        if strfind( params.neuralFeature, 'sorted' )
            plotTheseElecs = {'unit12(1)_array2_elec2(98)', 'unit13(2)_array2_elec4(100)', ...
                'unit24(13)_array2_elec85(181)', 'unit5(5)_array1_elec20(20)'};
        else
            plotTheseElecs = {'chan_2.2', 'chan_2.95', 'chan_1.53', 'chan_2.91', 'chan_2.4', 'chan_2.66', 'chan_2.71', ...
                'chan_2.93', 'chan_1.11', 'chan_2.37', 'chan_1.17', 'chan_2.7', 'chan_1.10', 'chan_1.19', 'chan_2.88', 'chan_1.66', 'chan_2.30', 'chan_1.37'};
        end
        
    case 't5.2017.10.23-movements' % T5 Example channels (high ANOVA scores):
        if strfind( params.neuralFeature, 'sorted' )
            plotTheseElecs =  {'unit20(8)_array2_elec36(132)', 'unit11(11)_array1_elec40(40)', 'unit28(16)_array2_elec76(172)', 'unit30(18)_array2_elec81(177)', ...
                'unit22(10)_array2_elec39(135)', 'unit32(20)_array2_elec87(183)', 'unit31(19)_array2_elec85(181)', 'unit16(4)_array2_elec11(107)', ...
                'unit4(4)_array1_elec13(13)', 'unit15(3)_array2_elec4(100)'}; 
        else
            plotTheseElecs = {'chan_1.9', 'chan_2.34', 'chan_1.17', 'chan_2.3', 'chan_1.6', 'chan_2.4', 'chan_2.13', 'chan_2.63', 'chan_2.7', 'chan_2.94'};
        end        
        
        
    case 't8.2017.10.18-words'        % T8 Example channels (high ANOVA scores)
        if strfind( params.neuralFeature, 'sorted' )
           plotTheseElecs = {'unit5(5)_array1_elec45(45)', 'unit13(3)_array2_elec9(105)', 'unit40(30)_array2_elec72(168)', 'unit6(6)_array1_elec65(65)',...
               'unit12(2)_array2_elec8(104)', 'unit37(27)_array2_elec66(162)', 'unit47(37)_array2_elec84(180)', 'unit5(5)_array1_elec45(45)'};    
        else
            plotTheseElecs = {'chan_1.65', 'chan_1.79', 'chan_2.70', 'chan_2.35', 'chan_1.54', 'chan_1.6', 'chan_1.9', 'chan_2.72', 'chan_2.39', 'chan_1.45'};
        end
        
    case 't8.2017.10.17-phonemes'        % copied directly from t8-words, may not be reasonabvle
        if strfind( params.neuralFeature, 'sorted' )
           plotTheseElecs = {'unit5(5)_array1_elec45(45)', 'unit13(3)_array2_elec9(105)', 'unit40(30)_array2_elec72(168)', 'unit6(6)_array1_elec65(65)',...
               'unit12(2)_array2_elec8(104)', 'unit37(27)_array2_elec66(162)', 'unit47(37)_array2_elec84(180)', 'unit5(5)_array1_elec45(45)'};    
        else
            plotTheseElecs = {'chan_1.65', 'chan_1.79', 'chan_2.70', 'chan_2.35', 'chan_1.54', 'chan_1.6', 'chan_1.9', 'chan_2.72', 'chan_2.39', 'chan_1.45'};
        end    
        
        
        
    case 't8.2017.10.17-movements'
        if strfind( params.neuralFeature, 'sorted' )
            plotTheseElecs = {'unit44(38)_array2_elec84(180)', 'unit35(29)_array2_elec68(164)', 'unit11(5)_array2_elec10(106)', 'unit36(30)_array2_elec71(167)', 'unit32(26)_array2_elec63(159)', 'unit21(15)_array2_elec41(137)', 'unit22(16)_array2_elec43(139)', ...
                'unit41(35)_array2_elec79(175)', 'unit40(34)_array2_elec78(174)', 'unit48(42)_array2_elec93(189)'};
        else
            plotTheseElecs = {'chan_2.84', 'chan_2.83', 'chan_2.65', 'chan_2.47', 'chan_2.35', 'chan_1.65', 'chan_1.83', 'chan_2.67', 'chan_1.81', 'chan_1.33'};
        end
        
    otherwise
        fprintf('ALERT: No electrodes specified to plot\n')
        plotTheseElecs = {};
end




% Note: these windows grab more data than is actualy used in the analysis.

% Align to audible start of response speech (VOT) 
% More consistent with Churchland et al. 2012
% longer epoch is better if making a video from this. 
% params.alignEvent = 'handResponseEvent';
% params.startEvent = 'handResponseEvent - 1.000';
% params.endEvent = 'handResponseEvent + 1.000';

% restricted to just final analysis epoch so that covariance oval will match
params.alignEvent = 'handResponseEvent';
if params.neuralVoiceOffset
    params.startEvent = 'handResponseEvent - 0.251'; % 1 ms buffer to make sure exact ms is available
    params.endEvent = 'handResponseEvent + 0.001';
else
    params.startEvent = 'handResponseEvent - 0.151'; % 1 ms buffer to make sure exact ms is available
    params.endEvent = 'handResponseEvent + 0.101';
end
% % Align to go cue
% % params.alignEvent = 'handPreResponseBeep';
% % params.startEvent = 'handPreResponseBeep - 0.500';
% % params.endEvent = 'handPreResponseBeep + 2.500';

% The exact JPCA epoch used is defined below for now to make it faster for me to try different
% windows.


params.downSampleEveryNms = 10; % will downsample firing rates this often. Needed for JPCA

% jPCA specific parameters
params.jPCA_params.softenNorm = 5;
params.jPCA_params.suppressBWrosettes = true;
params.jPCA_params.suppressHistograms = true;
params.jPCA_params.meanSubtract = true;
params.jPCA_params.numPCs = 6;

% what timestamps (from the Data structure) to use.
switch params.alignEvent
    case 'handResponseEvent' % SPEECH ALIGNMENT
         if params.neuralVoiceOffset
             params.dataTimestamps =  -250:params.downSampleEveryNms : 0;    % if doing neural speech onset offset
         else
             params.dataTimestamps =  -150:params.downSampleEveryNms :100;
         end
    case 'handPreResponseBeep'  % GO CUE ALIGNMENT
        params.dataTimestamps = 900:params.downSampleEveryNms :1400; % T5 from before
%         params.dataTimestamps = 1200:params.downSampleEveryNms :1450; % T8
end

% Add jPCA code (from Churchland et al 2012, obtained from Chuchland lab website)
addpath( genpath( [CodeRootNPTL '/code/analysis/Sergey/generic/jPCA/'] ) );





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
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode, 'sOffsets', sOffsets  )];
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
elseif strfind( params.neuralFeature, 'lfpPow' )
    if strcmp( params.neuralFeature, 'lfpPow_125to5000_50ms' )
        % should already exist
        if ~isfield( R, 'lfpPow_125to5000_50ms' )
            % gamma power already exists from pre-generation, so I'm good.
            error( 'Field lfpPow_125to5000_50ms does not exist in this R struct loaded' )
        end

    else
        R  = AddCombinedFeature( R, {'lfp1', 'lfp2'}, 'lfp', 'deleteSources', true );
        R = AddFeature( R, params.neuralFeature, 'sourceSignal', 'lfp' );
    end
    if ~isempty( params.excludeChannels )
        fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
        R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
    end
    % GAUSSIAN SMOOTHING
    fprintf( 'Smoothing %s with %i ms s.d. Gaussian kernel\n', params.neuralFeature, params.lfpPowGaussianMS )
    stdMS = params.lfpPowGaussianMS;
    numSTD = 3; % will make the kernel out to this many standard deviations
    % now make the Gaussian kernel out to 3 standard deviations
    x = -numSTD*stdMS:1:numSTD*stdMS;
    gkern = normpdf( x, 0, stdMS );
    % normalize to area 1
    gkern = gkern ./ sum( gkern );
    for iTrial = 1 : numel( R ) % can probably be parfor to speed things up
        R(iTrial).(params.neuralFeature).dat = filter( gkern, 1, double( R(iTrial).(params.neuralFeature).dat' ) )';
        % trim to only valid parts of filtered data
        R(iTrial).(params.neuralFeature).t(1:numSTD*stdMS) = [];
        R(iTrial).(params.neuralFeature).t(end-numSTD*stdMS+1:end)=[];
        R(iTrial).(params.neuralFeature).dat(:,1:2*numSTD*stdMS)=[]; % 2 x because only taking from front, to shift everything back
    end
else
    error('Feature not yet implemented')
end

%% Format the data for jPCA

%rapid iterate across windows

%         params.dataTimestamps =  -350:params.downSampleEveryNms :-100;        
%         params.dataTimestamps =  -300:params.downSampleEveryNms :-50;        
%         params.dataTimestamps =  -250:params.downSampleEveryNms :-100;        
%         params.dataTimestamps =  -250:params.downSampleEveryNms :-50;        
%         params.dataTimestamps =  -250:params.downSampleEveryNms :0;        

%         params.dataTimestamps =  -200:params.downSampleEveryNms :-50;  
%         params.dataTimestamps =  -200:params.downSampleEveryNms :0;        
%             params.dataTimestamps =  -200:params.downSampleEveryNms :50;        
%         params.dataTimestamps =  -200:params.downSampleEveryNms :100;           

%         params.dataTimestamps =  -150:params.downSampleEveryNms :100;        
%         params.dataTimestamps =  -100:params.downSampleEveryNms :150;        
%         params.dataTimestamps =  -150:params.downSampleEveryNms :150;        
%     params.dataTimestamps =  -150:params.downSampleEveryNms :200;      
%     params.dataTimestamps =  -150:params.downSampleEveryNms :250;      


fprintf('Data: %s, epoch: %s %g to %g\n', params.neuralFeature, params.alignEvent, params.dataTimestamps(1), params.dataTimestamps(end))
jenga = AlignedMultitrialDataMatrix( R, 'featureField', params.neuralFeature, ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
% align exactly ( avoids unpredictabl;e 1 ms roundoff issues )
startInd = find( round( 1000.*jenga.t ) == params.dataTimestamps(1), 1, 'first' );
endInd = find( round( 1000.*jenga.t ) == params.dataTimestamps(end), 1, 'first' );
% Subsample every X ms (Mark's code won't subsample itself)

jenga.t = jenga.t(startInd:params.downSampleEveryNms:endInd);
jenga.dat = jenga.dat(:,startInd:params.downSampleEveryNms:endInd,:);
jenga.numSamples = size( jenga.t, 2 );
jenga = TrimToSolidJenga( jenga );
    
    
% This involves the key trial-averaging operation.
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrials = strcmp( allLabels, myLabel );
    
    % trial-average within this condition    
    Data(iLabel).A = squeeze( mean( jenga.dat(myTrials,:,:), 1 ) );
    Data(iLabel).times = round( 1000.*jenga.t)'; % converted to ms 
end

% Make jPCA Plots
fprintf('Analysis proceeding with %i units\n', size( Data(1).A,2 ) )
[Projection, Summary] = jPCA( Data, params.dataTimestamps, params.jPCA_params );
fprintf('%i PCs used capture %.4f overall variance (%s)\n', ...
    params.jPCA_params.numPCs, sum(Summary.varCaptEachPC(1:end)), mat2str( Summary.varCaptEachPC , 4 ) )

% Make the jPCA plot
plotParams.planes2plot = [1]; % PLOT
[figh, cmap] = makeJPCAplot(  Projection, Summary, plotParams, uniqueLabels );
titlestr = sprintf('jPCA trajectories %s', datasetName );
figh.Name = titlestr;

%% Also plot PCs for context
figh = figure;
titlestr = sprintf('PCs %s', datasetName );
figh.Name = titlestr;
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


%% Verify that I can plot PSTHs into jPC1
% Summary.preprocessing.normFactors
% Summary.jPCs_highD(:,2);



% Code snippet for across-conditions mean at each time point
sumA = 0;
numConds = numel( uniqueLabels );
normFactors = Summary.preprocessing.normFactors;
for c = 1: numConds
    sumA = sumA + bsxfun(@times, Data(c).A, 1./normFactors);  % using the same normalization as above
%         sumA = sumA + Data(c).A;  % if I want to softnorm after across-conditions mean subtraction
end
meanA = sumA/numConds;
% if meanSubtract  % subtract off the across-condition mean from each neurons response
%     bigA = bigA-repmat(meanA,numConds,1);
% end

figh = figure;
titlestr = sprintf('manual plot jPC %s', datasetName );
figh.Name = titlestr;
figh.Color = 'w';
axh = axes;
hold on;

for iLabel = 1 : numel( uniqueLabels )
    myDat = Data(iLabel).A; 
    
    % softnorm
    myDat = bsxfun( @times, myDat, 1./normFactors );
    
    % subtract across-conditions mean
    myDat = myDat - meanA;
    
    % mean subtract
    myDat = bsxfun( @minus, myDat, Summary.preprocessing.meanFReachNeuron );
    
    x = myDat * Summary.jPCs_highD(:,1);
    y = myDat * Summary.jPCs_highD(:,2);
    plot( x, y, 'Color', speechColors( uniqueLabels{iLabel} ) );     
end

%% Save the jPCs
% save the components in a file. I'll use this later to compare the CIS and jPC plane
saveFilepath_jPCs = sprintf('%sjPCs-%s.mat', saveResultsRoot, datasetName );
save( saveFilepath_jPCs, 'Summary', 'Projection' )
fprintf('Saved %s\n', saveFilepath_jPCs )
end


%% Support functions
function DataOut = dataTensorToDataStruct( dataTensor, timestamps )
    % takes a dataTensor (format of data used and generated by Gamal & John's TME code)
    % and converts it into the data structure expected by Mark's jPCA code
    % Preserves ordering of conditions in dataTensor and in the data structure
    for iC = 1 : size( dataTensor, 3 )
        DataOut(iC).A = dataTensor(:,:,iC); % time x neuron
        DataOut(iC).times = forceCol( timestamps );
    end
end


function [figh, cmap] = makeJPCAplot( Projection, Summary, plotParams, uniqueLabels )
    % Makes the jPCA plot using Mark's code.

    [colorStruct, haxP, vaxP] = phaseSpace( Projection, Summary, plotParams );

    % identify the groups
    [ indsLeftToRight, cmap ] = whichGroupIsWhichJpca( Projection );
    
    % Label the end points of each condition with its label. Note this won't work if more than
    % one plane was plotted (because it'll try to plot on the last plane using data from first
    % plane. So make plotParams.planes2plot = 1 to use this .
    figh = gcf;
    for iLabel = 1 : numel( uniqueLabels )
        myH = Projection(iLabel).proj(end,1);
        myV = Projection(iLabel).proj(end,2);
        th(iLabel) = text( myH, myV, uniqueLabels{iLabel} );
    end

end