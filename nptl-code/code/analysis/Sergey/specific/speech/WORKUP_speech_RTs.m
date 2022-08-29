% Makes histograms of reaction time (AO - Go)
%
% Sergey Stavisky, September 6 2019
% Stanford Neural Prosthetics Translational Laboratory

neuralVoiceOffsetRoot = [ResultsRootNPTL '/speech/neuralVoiceOffsets/']; % directory with acoustic onset offset lags previously calcualted by WORKUP_findNeuralOnsetOffsets.m
params.neuralVoiceOffset = false; % Whether to use PC1 neural alignment to adjust voice onset

%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted. The RESPONSE label ('ga' in above example) is used as the label for this trial.


% t5.2017.10.23 Phonemes
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-phonemes.mat';
params.excludeChannels = datasetChannelExcludeList('t5.2017.10-23_-4.5RMSexclude');
params.acceptWrongResponse = true;

% t5.2017.10.25 Words
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' ); % As of July 2018
% % params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMS_respondersOnly' ); % trying keeping only speech-tuned chans, conssitent with Pandarinath 2015
% params.acceptWrongResponse = false;


% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-phonemes.mat';
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = true;

% t8.2017.10.18 Words
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_20ms.mat'; % has sorted units
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
%%
includeLabels = labelLists( Rfile ); % lookup;



datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly
datasetName = regexprep( datasetName, '_lfpPow_125to5000_20ms', ''); %otherwise names get ugly



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


%% RTs for non-silence trials
myTrialIdx = ~ismember( allLabels, 'silence' );
R = R(myTrialIdx); 

%%
RTs = [R.handResponseEvent] - [R.handPreResponseBeep];
figh = figure;
titlestr = sprintf( 'RTs %s', datasetName );
figh.Name = titlestr;
axh = axes;


histh = histogram( RTs );
histh.BinWidth = 50;

title( titlestr )

ylim([0 max( histh.Values ) + 5] );
line( [median( RTs ) median( RTs )], [0 max( histh.Values ) + 5] ) ;
fprintf('Median RT is %.1fms\n', median( RTs ) )

%% For plotting trial timeline
 allFirstBeeps = arrayfun( @(x) x.timeCueStart(1), R );
 
 fprintf('Median time between handCueEvent (prompt) and first beep (trial start) and  is %fms\n', ...
     nanmedian( [R.handCueEvent]' - allFirstBeeps ) );
 
 fprintf('Median time between prompt (handCueEvent) and Go Cue (handPreResponseBeep) and is %fms\n', ...
     nanmedian( [R.handPreResponseBeep] - [R.handCueEvent] ) )
 
 minRT = min( [R.handResponseEvent] - [R.handPreResponseBeep] );
 medianRT = median( [R.handResponseEvent] - [R.handPreResponseBeep] );
 maxRT = max( [R.handResponseEvent] - [R.handPreResponseBeep] );
 fprintf('Min/median/max time between Go Cue (handPreResponseBeep) and AO (handResponseEvent) is %i/%i/%ims\n', ...
     minRT, medianRT, maxRT )
 
 figure; plot( R(1).audio.t, R(1).audio.dat )
 line( [R(1).handPreCueBeep R(1).handPreCueBeep]./1000, [-1e4 1e4], 'Color', 'b' )
 text( R(1).handPreCueBeep/1000, 6000, 'handPreCueBeep')
 
 line( [R(1).handCueEvent R(1).handCueEvent]./1000, [-1e4 1e4], 'Color', 'g' )
 text( R(1).handCueEvent/1000, 5000, 'handCueEvent')
 
 line( [R(1).handPreResponseBeep R(1).handPreResponseBeep]./1000, [-1e4 1e4], 'Color', [1 1 0] )
 text( R(1).handPreResponseBeep/1000, 6000, 'handPreResponseBeep')
 
 line( [R(1).handResponseEvent R(1).handResponseEvent]./1000, [-1e4 1e4], 'Color', 'r' )
 text( R(1).handResponseEvent/1000, 5000, 'handResponseEvent')
