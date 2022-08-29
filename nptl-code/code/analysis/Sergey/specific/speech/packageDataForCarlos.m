% Takes the t5-syllables dataset and packages it up for Dr. Carlos Vargas-Irwin (Brown
% University).,
%
% Sergey Stavisky, Neural Prosthetics Translational Laboratory, February 2019
clear
% t5.2017.10.23 Phonemes
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
params.acceptWrongResponse = true;

%%
includeLabels = labelLists( Rfile ); % lookup;
numArrays = 2; % don't anticipate this changing

datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly

% THRESHOLD CROSSINGS
params.thresholdRMS = -4.5; % spikes happen below this RMS

% Spike-sorted
params.minimumQuality = 3;
sortQuality = speechSortQuality( datasetName ); % manual entry since I forgot to include this in R struct : (


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

uniqueBlocks = unique( [R.blockNumber] );
Rnew = [];
for blockNum = uniqueBlocks
    myTrials = [R.blockNumber] == blockNum; 
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', 'handLabels' )];
end
R = Rnew; 
clear( 'Rnew' );

%% Sorted Units
fprintf('Making spike sorted rasters \n');
[ R, sorted ] = ReplaceRastersWithSorted( R, 'numArrays', numArrays, ...
    'minimumQuality', params.minimumQuality, 'sortQuality', sortQuality, ...
    'manualExcludeList', speechSortedUnitExclusions( datasetName ) );
% rename these 
for i = 1 : numel( R )
   R(i).sortedRasters1 = R(i).spikeRaster;
   R(i).sortedRasters2 = R(i).spikeRaster2;
end

%% Do RMS thresholding
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
    
    R(iTrial).RMSthresholdMulitplier = params.thresholdRMS;
end
% rename these
for i = 1 : numel( R )
    R(i).RMSrasters1 = R(i).spikeRaster;
    R(i).RMSrasters2 = R(i).spikeRaster;
end

%% Add key event times 

for i = 1 : numel( R )
    R(i).timeAudioPrompt = R(i).handCueEvent;
    R(i).timeGoCue = R(i).handPreResponseBeep;
    R(i).timeAcousticOn = R(i).handResponseEvent;
end


%% Remove all the extra fields
R = rmfield( R, {'timeCueStart', 'timeSpeechStart', 'clock', 'minAcausSpikeBand1', 'minAcausSpikeBand2', ...
    'lfp1', 'lfp2', 'audio', 'spikeRaster', 'spikeRaster2', 'unitCodeOfEachUnitArray1', 'electrodeEachUnitArray1', ...
    'unitCodeOfEachUnitArray2', 'electrodeEachUnitArray2', 'lfpPow_125to5000_50ms', 'handCueEvent', 'handResponseEvent', ...
    'handPreCueBeep', 'handPreResponseBeep', 'experimentDate', 'experimentStartTime' } );


%% Save
% save('t5-2017-10-23-syllables', 'R')