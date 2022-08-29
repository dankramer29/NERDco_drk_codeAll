% This script prepares speech experiment data for subsequent LFADS
% announcement. It breaks the datastream into a trials x neurons x time
% tensor in which threshold crossing firing rates are binned (typically 10
% ms).
%
%
% This version works on The Caterpillar passage. Since LFADS wants consistent length
% trials, here I'm breaking apart the Caterpillar passage into multiple trials
% which are the same length as the phonemes/words dataset 
% Thus, this script's parameters need to be 
% hand-aligned to give the same "trial" bin length as the corresponding
% phones/words dataset.
%
% Sergey Stavisky 11 December 2017
% Stanford Neural Prosthetics Translational Laboratory
%
%

clear
saveResultsRoot = [ResultsRootNPTL '/speech/dataForLFADS/'];



%% T5.2017.10.23 Phonemes
Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t5.2017.10.23-caterpillar.mat'];
participant = 't5';

params.binsEachFauxTrial = 250; % matched to /dataForLFADS/t5.2017.10.23-phonemes_5ae60c61a42dca423cd4ab54034528cc.mat
params.slideBinsForEachTrial = 50; % When chopping into trials, how many bins to slide by for each bin. Set this equal to params.binsEachFauxTrial to have non-overlapping bins

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

%% Loop through and assemble the neural data

% note on how the Caterpillar events were encoded when I annotated them:
% the start of the read-through is .timeCueStart, and the end is .timeSpeechStart
datTensor = []; % Trials x Neurons x Time
whichReadthrough = []; % will track which 
tMatrix = []; % trial x time
audioMatrix = [];
for iRunthrough = 1 : numel( R )
    mySampleInds = R(iRunthrough).timeCueStart + params.sampleEveryNms : ...
        params.sampleEveryNms :  R(iRunthrough).timeSpeechStart;
    myT = [mySampleInds - R(iRunthrough).timeCueStart] ./ (1000); % into seconds
    myDat = R(iRunthrough).(params.neuralFeature).dat(:,mySampleInds);
    % restrict to appropriate number of samples to fill trials
%     numFakeTrials = floor( size( myDat, 2 ) / params.binsEachFauxTrial );
    numFakeTrials = floor( ( size( myDat, 2 ) - params.binsEachFauxTrial) / params.slideBinsForEachTrial );
%     myDat = myDat(:,1:numFakeTrials*params.slideBinsForEachTrial);
%     myT = myT(1:1:numFakeTrials*params.slideBinsForEachTrial);
    ptr = 1; % where to look in the data stream
    % reshape into faux trials.
    for iTrial = 1 : numFakeTrials
        myTrialDat = myDat(:,ptr:ptr+params.binsEachFauxTrial-1);
        % reshape it into 1 x neurons x time
        myTrialDat = reshape( myTrialDat, 1, size( myTrialDat, 1 ), size( myTrialDat, 2 ) );
        datTensor = cat(1, datTensor, myTrialDat);
        tMatrix = [tMatrix; myT(ptr:ptr+params.binsEachFauxTrial-1)];
        whichReadthrough = [whichReadthrough; iRunthrough];
        
        % If specified, also grab the corresponding audio data.
        if params.saveAudio
            tStart =  myT(ptr) - params.sampleEveryNms/1000; % in seconds, note I subtract bin width because the binned rate timestamp is delayed this much, but audio isn't binned 
            tEnd = myT(ptr+params.binsEachFauxTrial-1);
            audioStartInd = round( tStart * R(iRunthrough).audio.rate ) +1;
            audioEndInd = round( tEnd * R(iRunthrough).audio.rate );
            audioMatrix = [audioMatrix; R(iRunthrough).audio.dat(audioStartInd:audioEndInd)];
        end
        
        ptr = ptr + params.slideBinsForEachTrial;
    end
end
datTensor = double( datTensor ); % matches what comes out of phonemes

% Prepare the supplementary informaiton to make this data tensor matrix
% interpretable.
datInfo.tWithinReadthrough = tMatrix; 
datInfo.channelName = forceCol( R(1).(params.neuralFeature).channelName );
datInfo.trialNumber = forceCol( 1 : size( datTensor, 1 ) );
datInfo.neuralFeature = params.neuralFeature;
datInfo.params = params;
datInfo.whichReadthrough = whichReadthrough;

%% Save the data
fprintf('Saving to %s\n', resultsFilename );
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot );
end
save( resultsFilename, 'datTensor', 'datInfo', 'audioMatrix' );
