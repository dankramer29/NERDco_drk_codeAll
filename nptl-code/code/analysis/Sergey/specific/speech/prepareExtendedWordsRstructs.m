% The purpose of this script is to generate R structs with  behavioral task
% (instructed delay) events, neural data, audio annotation, and audio data
% itself.
% Generates R struct from instructed movement task stream files, and
% then merges in the audio data AND the hand annotation of audio events.
%      So there's a lot of pieces going on, which is a legacy of doing various processing
% in stages and reusing a lot of existing code from the original t5-words dataset
% labeling tool.
%
% Workflow:
% The raw .ns5 files were already processed into audio files (amongst
% others) by processContinuousSpeakingDataset.m. Those audio files were
% annotated using  WORKUP_labelSpeechExtendedWords.m
%
%
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory,
% 12 March 2019,

saveRstructsTo = [ResultsRootNPTL filesep 'speech' filesep 'Rstructs' filesep];


%% t5.2019.01.23 Slutzky Extended Words List
dataset = 't5.2019.01.23';
blocks = [...
    1; % Set 1 rep1
    2; % Set 2 rep1
    3; % Set 3 rep1
    4; % Set 4 rep1
    5; % Set 1 rep2
    6; % Set 2 rep2
    7; % Set 3 rep2
    8; % Set 4 rep2
    9; % Set 1 rep3
    10; % Set 2 rep 3
    11; % Set 3 rep 3
    12; % Set 4 rep 3
    ];


    

%% Get paths to all the relevant files for this block
syncUsingWhichNSP = 1; % all audio was aligned to NSP1 (which also drove xPC).
participant = dataset(1:strfind(dataset, '.')-1);

params.hlfpBand.getHlfpBand = true;
params.hlfpBand.Fs = 1000; % what to downsample HLFP to
params.hlfpBand.featureName = 'lfpPow_125to5000_1ms'; % uses existing AddFeature code with this input

for iBlock = 1 : numel( blocks )
    blockNum = blocks(iBlock);
    fprintf('\n\n\n%s Block %i (#%i/%i)\n', dataset, blockNum, iBlock, numel( blocks ) )
        
    % how to find its task stream directory:
    streamDir = sprintf('%s/%s/%s/Data/FileLogger/%i/', ...
        CachedDatasetsRoot, participant, dataset, blockNum );
    
    if params.hlfpBand.getHlfpBand
        hlfpFile = sprintf(  '/media/sstavisk/ExtraDrive1/Results/speech/manyWords/%s/block_%i_HLFP.mat', ...
        dataset, blockNum );
        inHLFP = load( hlfpFile );
        fprintf('  loaded %s\n', hlfpFile)
    end
    
    % how to find its audio file:
    audioFile = sprintf(  '/media/sstavisk/ExtraDrive1/Results/speech/manyWords/%s/block_%i_audio.mat', ...
        dataset, blockNum );
    inAudio = load( audioFile );
    fprintf('  loaded %s\n', audioFile)
    
    
    % how to find its audio annotation file
    annotationFile = sprintf('/media/sstavisk/ExtraDrive1/Results/speech/audioAnnotation/%s/manualLabels_block_%i_audio.mat', ...
        dataset, blockNum );
    inAnnotate = load( annotationFile );
    inAnnotate = inAnnotate.sAnnotation;
    % verify that there's just one cue and one speech annotation per trial
    allCueStartTimes = arrayfun(@(x) numel(x), inAnnotate.cueStartTime );
    if any( allCueStartTimes ~= 1 )
        error('why is there not just 1 cueStartTime per trial?')
    end
    allCueStartTimes = cell2mat( inAnnotate.cueStartTime );

    allSpeechStartTimes = arrayfun(@(x) numel(x), inAnnotate.speechStartTime );
    if any( allSpeechStartTimes ~= 1 )
        error('why is there not just 1 speechStartTime per trial?')
    end
    allSpeechStartTimes = cell2mat( inAnnotate.speechStartTime );
    
    
    fprintf('  loaded %s\n', annotationFile)

    
    %% Load the task R struct
    R = onlineR( parseDataDirectoryBlock( streamDir ) );
    fprintf('  Block %i: Loaded %i movement task trials\n', blockNum, numel( R ) );
    
    
    for iTrial = 1 : numel( R )
        %% Add the 30ksps audio data corresponding to each trial.
        % grab from the first to the last cerebus timestamp that went into
        % this trial.
        firstCerebusTime = R(iTrial).firstCerebusTime(syncUsingWhichNSP,1);
        lastCerebusTime = R(iTrial).lastCerebusTime(syncUsingWhichNSP,end);
        myAudioFs = inAudio.FsRaw;
        myAudioSnippet = inAudio.audioDat(firstCerebusTime:lastCerebusTime);
        % add it to R struct trial
        R(iTrial).audioFs = myAudioFs;
        R(iTrial).audio = myAudioSnippet';
        R(iTrial).block = saveRstructsTo;

        
        %% Add the HLFP corresponding to each trial
        if params.hlfpBand.getHlfpBand
            % its timestamps are in seconds and start ~1 s after the audio,
            % since HLFP had a fitler warm up. So use the time from the
            % audio to figure out which samples
            startT = inAudio.audioTimeStamps_secs(firstCerebusTime);
%             endT = inAudio.audioTimeStamps_secs(lastCerebusTime);
            [~, startInd] = FindClosest( inHLFP.HLFP_timeStamps_secs, startT );
            % match length to spike rasters
            endInd = startInd + numel( R(iTrial).clock ) - 1; 
%             [~, endInd] = FindClosest( inHLFP.HLFP_timeStamps_secs, endT );
            % grab the 
            R(iTrial).HLFP = single( inHLFP.HLFP_dat(startInd:endInd,:)' ); % save as single            
        end
        
        
        
        %% Merge in the manual annotation
        % repeat separately for cueStartTime and speechStartTime
        for iEvent = 1 : 2
            switch iEvent
                case 1
                    annotatedTimes = allCueStartTimes;
                    myEvent = 'cueStartTime';
                    myFieldTime = 'timeCue'; % should be very close to R struct goCue, after audio playback and annotation delay
                case 2
                    annotatedTimes = allSpeechStartTimes;
                    myEvent = 'speechStartTime';
                    myFieldTime = 'timeSpeech';
            end
            % look through annotation events and find those that matches this
            % time interval (there should only be one!)
            eventsThisTrial = find( annotatedTimes >= firstCerebusTime & annotatedTimes < lastCerebusTime );
            if numel( eventsThisTrial ) > 1
                keyboard % huh? Right now I'm expecting one event per R trial
            end
            if isempty( eventsThisTrial )
                keyboard % hmm, why is there a missed event?
            end
            myEventTime = annotatedTimes(eventsThisTrial); % in samples since start of .ns5 files, but a continuous value because it came from annotation click
            myLabel = inAnnotate.label{eventsThisTrial};
            % write this label in
            R(iTrial).speechLabel = myLabel;
            
            % I want to convert this event time to ms after the start of
            % this trial:
            myMS = round( (myEventTime - double(firstCerebusTime))/(myAudioFs/1000) );
            % don't let it be 0 since this will screw up using MS-events as
            % indices
            myMS = max( myMS, 1 );
            
            % write this event into the trial
            R(iTrial).(myFieldTime) = myMS;
        end        
    end
    
    % TMP: verify that HLFP is aligned right
%     neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
%  
%     RMS = channelRMS( R ); % compute rms of the block
%     R = RastersFromMinAcausSpikeBand( R, -4.5 .*RMS );  
%     R = AddFeature( R, neuralFeature  );
%     jengaSP =   AlignedMultitrialDataMatrix( R, 'featureField', neuralFeature, ...
%             'startEvent','timeSpeech-0.5', 'alignEvent', 'timeSpeech', 'endEvent', 'timeSpeech+0.5' );
%     meanFR = squeeze( mean( mean( jengaSP.dat,1), 3 ) );
%     figh = figure;
%     plot( jengaSP.t, meanFR, 'Color', 'k')
%     
%     jengaHLFP =   AlignedMultitrialDataMatrix( R, 'featureField', 'HLFP', ...
%             'startEvent','timeSpeech-0.5', 'alignEvent', 'timeSpeech', 'endEvent', 'timeSpeech+0.5' );
%    meanHLFP = squeeze( mean( mean( jengaHLFP.dat,1), 3 ) );
%    hold on;
%    plot( jengaSP.t, meanHLFP./200, 'Color', 'r')
    
    
    blockFilename = sprintf('%sR_%s_B%i.mat', ...
        saveRstructsTo, dataset, blockNum );
    % Save the R struct
    fprintf('  saving %s...', blockFilename )
    save( blockFilename, 'R', '-v7.3' ) %files are < 2GB
    fprintf(' OK\n')
end