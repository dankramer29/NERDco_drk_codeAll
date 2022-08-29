% This script prepares speech experiment data for subsequent LFADS
% announcement. It breaks the datastream into a trials x neurons x time
% tensor in which threshold crossing firing rates are binned (typically 10
% ms).
%
% This variant works on cued sound datasets, i.e. phonemes or words, which were the
% main tasks for this project. 
% (it would also work for the tongue/face/mouth movement datasets)
%
% There's a separate script that packages up The Caterpillar reading
% pcakages with the same
%
% Sergey Stavisky 11 December 2017
% Stanford Neural Prosthetics Translational Laboratory
%
%

clear
saveResultsRoot = [ResultsRootNPTL '/speech/dataForLFADS/'];



%% T5.2017.10.23 Phonemes
% Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t5.2017.10.25-phonemes.mat'];
% participant = 't5';
% params.acceptWrongResponse = true;

%% T5.2017.10.25 Words
% Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t5.2017.10.25-words.mat'];
% participant = 't5';
% params.acceptWrongResponse = false;


%% t8.2017.10.18 Words
participant = 't8';
Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t8.2017.10.18-words.mat'];
params.excludeChannels = participantChannelExcludeList( participant );
params.acceptWrongResponse = false;
[params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );


% 2500 ms following the speech go cue
% params.alignEvent = 'handPreResponseBeep';
% params.startEvent = 'handPreResponseBeep';
% params.endEvent = 'handPreResponseBeep + 2.500';

% Align to audible start of response speech (VOT)
params.alignEvent = 'handResponseEvent';
params.startEvent = 'handResponseEvent - 1.000';
params.endEvent = 'handResponseEvent + 1.000';

%% Data inclusion parameters 
params.includeSilence = false; % whether to include 'silence' trials. 

%% Neural feature parameters
params.excludeChannels = participantChannelExcludeList( participant );
params.thresholdRMS = -3.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRate_10ms';
params.sampleEveryNms = 10; % the above feature will be sampled every X ms to get the tensor (should be same as binning in NeuralFeature)

% Get audio too?
params.saveAudio = true;


%% Prepare filename from these parameters and warn if it already exists.
params.Rfile = Rfile;
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
resultsFilename = [saveResultsRoot datasetName structToFilename( params ) '.mat'];
try 
    in = load( resultsFilename );
    beep;
    fprintf( 'This data appears to have already been generated and was loaded from %s\n', resultsFilename )
    fprintf( 'You can abort now, or let it run and overwrite\n');
catch
    % (empty)
end

%% Load the data
in = load( Rfile );
R = in.R;
clear('in'); % save memory
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
% exclude some trials?
if isfield( params, 'excludeTrials' ) && ~isempty( params.excludeTrials )
    excludeInds =  find( ismember( [R.trialNumber], params.excludeTrials ) .* ismember( [R.blockNumber], params.excludeTrialsBlocknum ) );
    fprintf('Excluding trials %s from blocks %s (%i trials)\n', ...
        mat2str( params.excludeTrials ), mat2str( params.excludeTrialsBlocknum ), numel( excludeInds ) );
    R(excludeInds) = [];
end

%% Restrict to trials of interest
includeLabels = labelLists( Rfile ); % lookup;
if ~params.includeSilence
    includeLabels(strcmp( includeLabels, 'silence' )) = [];
end

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
fprintf('Will prepare %i trials across %i blocks with %i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );

%% Annotate the data labels and trial event times

% Determine the critical alignment points
% note I choose to do this for each block, since this will better address ambient
% noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
% silence speech time estimation)
if strfind( params.alignEvent, 'vot' )
    error('Need to implement this...')
    % Would need to keep silence trials this far.
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



%% Sanity check, what does the sound envelope look like when aligned to response go cue.
% hpfObj = load( 'hpf30Hz_R2016a.mat', 'hpf' );
% audioFs = R(1).audio.rate;
% filterName = 'boxcar_5ms';
% filterFunctionHandle = @filtfilt;
% filterStruct = filterNameLookup( filterName, audioFs);
% filterStruct.filterFunction = filterFunctionHandle;    
% parfor iTrial = 1 : numel( R )
%     R(iTrial).audioAbs = R(iTrial).audio;   
%     R(iTrial).audioAbs.dat = filtfilt( hpfObj.hpf, double( R(iTrial).audioAbs.dat ) );
%     R(iTrial).audioAbs.dat = single( abs( R(iTrial).audioAbs.dat ) ); %keep reasonable memory usage
% end
% R = AddFilteredFeature( R, 'audioFiltered', 'sourceSignal', 'audioAbs', ...
%     'filterStruct', filterStruct, 'outputRate', audioFs );
% 
% audioJenga = AlignedMultitrialDataMatrix( R, 'featureField', 'audioFiltered', ...
%     'startEvent', 'handPreResponseBeep', 'alignEvent', 'handPreResponseBeep', 'endEvent', 'handPreResponseBeep + 3.5');
% absAudio = abs( audioJenga.dat );
% figh = figure;
% imagesc( audioJenga.t, 1:audioJenga.numTrials, absAudio );
% xlabel('Seconds Since handPreResonseBeep');
% ylabel(sprintf('Trial %s', pathToLastFilesep( params.Rfile,1 ) ) )


%% Prepare the neural data

% Need to do RMS thresholding
fprintf('Thresholding at %g RMS\n', params.thresholdRMS );
for iTrial = 1 : numel( R )
    for iArray = 1 : 2
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

R = AddFeature( R, params.neuralFeature );
R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
jenga = AlignedMultitrialDataMatrix( R, 'featureField', params.neuralFeature, ...
    'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent);
subsampleInds = params.sampleEveryNms : params.sampleEveryNms : size( jenga.dat, 2 );

datTensor = jenga.dat(:,subsampleInds,:);
datTensor = permute( datTensor, [ 1, 3, 2 ] ); % makes it Trials x Neurons x Time


audioMatrix = [];
if params.saveAudio
    jengaAudio = TrimToSolidJenga( AlignedMultitrialDataMatrix( R, 'featureField', 'audio', ...
    'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent) );
    audioMatrix = jengaAudio.dat;
end

% Prepare the supplementary informaiton to make this data tensor matrix
% interpretable.
datInfo.t = forceCol( jenga.t(subsampleInds) ); 
datInfo.channelName = forceCol( R(1).(params.neuralFeature).channelName );
datInfo.trialNumber = forceCol( 1 : jenga.numTrials );
datInfo.label = forceCol( {R.label} );
datInfo.neuralFeature = params.neuralFeature;
datInfo.params = params;
% Record reaction time for each trial - might be interesting to look at
% this compared to the factors.
datInfo.reactionTime = forceCol( [R.handResponseEvent] - [R.handPreResponseBeep] );

%% Save the data
fprintf('Saving to %s\n', resultsFilename );
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot );
end
save( resultsFilename, 'datTensor', 'datInfo', 'audioMatrix' );
