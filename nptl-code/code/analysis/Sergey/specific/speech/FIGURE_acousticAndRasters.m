% Loads an example trial and plots both the acoustic timeseries and spike rasters for this
% trial. Used as part of Figure 1 to illustrate the task. 
%
% TODO: Doesn't do rasters yet, just acoustic for IEEE EMBS : )
%
% Sergey Stavisky, Jan 12 2018
% Stanford Neural Prosthetic Systems Laboratory
%
% Scoops a bunch of code from WORKUP_speechPSTHs.m to make sure I get the same real
% trials.

clear
saveFiguresDir = [FiguresRootNPTL '/speech/examples/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end


%% Dataset
% t5.2017.10.23 Phonemes
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-phonemes.mat';

exampleTrial = 153; % ba
% exampleTrial = 150; % ga


params.excludeChannels = participantChannelExcludeList( participant );
params.acceptWrongResponse = true;

params.alignEvent = 'handPreResponseBeep';
params.startEvent = 'handPreResponseBeep - 0.2';
params.endEvent = 'handPreResponseBeep + 0.5';



%% Neural Parameters
params.thresholdRMS = -4.5; % spikes happen below this RMS


%% Load the data

includeLabels = labelLists( Rfile ); % lookup;
numArrays = 2; % don't anticipate this changing

in = load( Rfile );
R = in.R;
clear('in')
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
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


%% Play the trial so I can confirm it's not weird in some way
Fs = R(exampleTrial).audio.rate;
audioDat = R(exampleTrial).audio.dat;
speechPlaybackObj = audioplayer( audioDat, Fs );
speechPlaybackObj.play;


%% Report some details about block's timing statistics
RnotSilence = R(~strcmp({R.label}, 'silence'));
intervalBeep2ToCue = [RnotSilence.handCueEvent] - [RnotSilence.handPreCueBeep];
intervalClick2ToVOT = [RnotSilence.handResponseEvent] - [RnotSilence.handPreResponseBeep];
timeFirstClick = arrayfun( @(x) x.timeSpeechStart(1), RnotSilence); % starting the go cue (first of 2 clicks)
intervalBeep2ToFirstClick = timeFirstClick - [RnotSilence.handPreCueBeep]'; % basically how long the whole cue epoch is


fprintf('Time from second cue-beep to cue VOT is %.1fms (mean)\n', mean( intervalBeep2ToCue ) );
fprintf('Time from second cue-beep to first go beep is %.1fms (mean)\n', mean( intervalBeep2ToFirstClick ) );
fprintf('Time from second go-beep to response VOT (RT) is %.1fms (mean)\n', mean( intervalClick2ToVOT ) );
fprintf('Example trial has RT %.1f\n', R(exampleTrial).handResponseEvent - R(exampleTrial).handPreResponseBeep );


%% Make the acoustic figure
figh = figure;
axh = axes;
plot( R(exampleTrial).audio.t, R(exampleTrial).audio.dat)
titlestr = sprintf('%s Trial %i (''%s'')', pathToLastFilesep(Rfile, 1), exampleTrial, R(exampleTrial).label );
title( titlestr );
ExportFig( figh, [saveFiguresDir titlestr])