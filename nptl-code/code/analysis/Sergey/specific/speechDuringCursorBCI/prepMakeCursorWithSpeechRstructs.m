% First generates the cursor task R structs, and then merges in the audio
% annotations that I made using WRKUP_labelSpeechWhileCursorExptData.m
% The end result is an R struct that has event markers for speaking.
%
% Sergey D Stavisky, 28 February 2019
clear

saveRstructsTo = [ResultsRootNPTL filesep 'speech' filesep 'Rstructs' filesep];

% List the blocks of interest.

%% t5.2018.12.12 Words during cursor BCI Day 1
% this is the day that had the NSP sync issue, so I'm a bit worried.
audioAnnotationRoot = [ResultsRootNPTL '/speech/audioAnnotation/'];
participant = 't5';
dataset = 't5.2018.12.12';
syncUsingWhichNSP = 1; % all audio was aligned to NSP1 (which also drove xPC).

blockNumbers = [...
    7; % A, beet
    9; % B
    10; % A bot
    12; % B
    ];

%% t5.2018.12.17 Words during cursor BCI Day 2
% audioAnnotationRoot = [ResultsRootNPTL '/speech/audioAnnotation/'];
% participant = 't5';
% dataset = 't5.2018.12.17';
% syncUsingWhichNSP = 1; % all audio was aligned to NSP1 (which also drove xPC).
% 
% blockNumbers = [...
%     8; % B, silent
%     9; % A seal
%     10; % A more
%     11; % B
%     12; % A bat
%     13; % B
%     16; % B
%     17; % A, shot
%     18; % A beet
%     19; % B
%     ];



%%
streamRoot = sprintf('%s/%s/%s/Data/FileLogger/', ...
    CachedDatasetsRoot, participant, dataset );
FsCerebus = 30000; % needed to know how to go from seconds to nspTime

% Load in one block at a time
for iBlock = 1 : numel( blockNumbers )
    % GET CURSOR TASK R STRUCT
    myStreamFile = sprintf('%s%i', streamRoot, blockNumbers(iBlock) );
    R = onlineR( parseDataDirectoryBlock( myStreamFile ) ); % includes minACausSpikeBand
    fprintf('Block %i: Loaded %i cursor task trials\n', blockNumbers(iBlock), numel( R ) );

    % GET ITS AUDIO ANNOTATION FILE
    myAudioAnnotationFile = sprintf('%s%s/manualLabels_%i_cursorTask_Complete_t5_bld(%03i)%03i.mat', ...
        audioAnnotationRoot, dataset, blockNumbers(iBlock), blockNumbers(iBlock), blockNumbers(iBlock)+1 );
    annotateIn = load( myAudioAnnotationFile );
    annotateIn = annotateIn.sAnnotation;
    fprintf('  loaded annotated audio with %i speech events.\n', numel( annotateIn.label ) );
    
    % Merge in sound events. Here, a trial refers to the cursor task trial.
    % The speaking prompts are merged in whenever they happen. Note that
    % the cueStartTime and speechStartTime for a given speech event could
    % occur for different cursor task trials.
    
    % I will keep track of whether all speech events were assigned to a
    % trial. This could reveal if the cursor task ended before the speaking task.
    speechEventHasAHome = zeros( numel( annotateIn.label ),1 ); % will become 1 when assigned
              % doesn't distinguish between cue and response
    for iTrial = 1 : numel( R )
        % create fields that may be filled if a speech event happened, otherwise will be empty
        R(iTrial).timeCue = nan;
        R(iTrial).labelCue = {};
        R(iTrial).timeSpeech = nan;
        R(iTrial).labelSpeech = {};
        R(iTrial).speechEventNumber = nan;
        % What is the first and last cerebus time for this trial? This will
        % determine whether any speech events happened during it.
        firstCerebusTime = R(iTrial).firstCerebusTime(syncUsingWhichNSP,1);
        lastCerebusTime = R(iTrial).lastCerebusTime(syncUsingWhichNSP,end);
        % Go through speech events, and determine if it belongs to a cursor
        % task trial. If so, add it in.
        for iSpeak = 1 : numel( annotateIn.cueStartTime )
            % repeat separately for cueStartTime and speechStartTime
            for iEvent = 1 : 2
               switch iEvent
                   case 1
                       myEvent = 'cueStartTime';
                       myFieldTime = 'timeCue';
                       myFieldLabel = 'labelCue';
                       myFieldNumber = 'eventNumberCue';
                   case 2
                       myEvent = 'speechStartTime';
                       myFieldTime = 'timeSpeech';
                       myFieldLabel = 'labelSpeech';
                       myFieldNumber = 'eventNumberSpeech';

               end
               myNSPtime = annotateIn.(myEvent){iSpeak}; % these are in NSP clock units (30k)
               if isempty( myNSPtime )
                   % occasionally there is a missing annotation event, so
                   % just skip it
                   continue
               end
               myNSPtime = round( myNSPtime ); % convert to integer NSP clock tick
               if myNSPtime >= firstCerebusTime && myNSPtime < lastCerebusTime
                   % yay, we belong in this cursor trial! Now, which
                   % millisecond do I belong to?
                   thisTrialMS = find( myNSPtime <=  R(iTrial).lastCerebusTime(syncUsingWhichNSP,:) & ...
                       myNSPtime >=  R(iTrial).firstCerebusTime(syncUsingWhichNSP,:), 1, 'first' ); % shouldn't be more than 1 but just in case
                   speechEventHasAHome(iSpeak) = 1; % this speech event was assigned
                   % add it to this trial
                   if isnan( R(iTrial).(myFieldTime) )
                       R(iTrial).(myFieldTime) = thisTrialMS;
                       R(iTrial).(myFieldLabel) = annotateIn.label(iSpeak);
                       R(iTrial).audioEventFromFile = annotateIn.filename;
                       R(iTrial).(myFieldNumber) = annotateIn.trialNumber(iSpeak);
                   else
                       % Ended up with 2 or more speech events in 1 trial.
                       % This is rare unless cursor trials are very long.
                       R(iTrial).(myFieldTime) = [R(iTrial).(myFieldTime), thisTrialMS];
                       R(iTrial).(myFieldLabel) = [R(iTrial).(myFieldLabel), annotateIn.label(iSpeak)];
                       R(iTrial).(myFieldNumber) = [R(iTrial).(myFieldNumber), annotateIn.trialNumber(iSpeak)];
                   end
                   if isempty( R(iTrial).(myFieldTime) ) % shouldn't happen anymore 
                       error('empty time, huh?')
                       keyboard
                   end
               end
            end
        end
    end
    
    
    % Save the R struct for this block.
    fprintf('  %i/%i speech events assigned to cursor task trials.\n', ...
        nnz( speechEventHasAHome ), numel( speechEventHasAHome ) );
    Rfilename = sprintf('%sR_%s_B%i.mat', ...
        saveRstructsTo, dataset,  blockNumbers(iBlock) );
    fprintf('Saving %s... ', Rfilename );
    save( Rfilename, 'R' )
    fprintf('OK\n');
end


