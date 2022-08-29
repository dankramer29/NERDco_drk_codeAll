% Speaks and writes a log of PHONEME cues.
%
% Five words only: Got , Beet, Seal, Bat, More
% 
% Part of code for running minimal viable experiment to survey for neural tuning in motor
% cortex when a participant hears or produces language-related sounds.
%
% Audio files must have already been prepared into .mat format. For these experiments,
% this is done by prepareAudioMats.m.
%
% Writes a log file of what it's doing.
% 
% Sergey D. Stavisky, August 2017, Stanford Neural Prosthetics Translational Laboratory.
% Updated Dec 11 2018
%
% NOTE: Runs in R2015b, not R2017b 


% Audio .mat files live here:
audioPath = [CodeRoot '/NPTL/code/tasks/heardAndSpoken/soundFiles/'];

% Log file gets written here:
logPath = [CachedDatasetsRoot '/NPTL/t5.' datestr(today,'yyyy.mm.dd') '/'];
if ~isdir( logPath )
    mkdir( logPath );
end

% EXPERIMENT PARAMETERS:
repetitionsEachSound = 17; % how many repetitions of each sound
pauseAfterReadyMS = 400; % ms how long to pause after the ready cue before playing the sound
pauseAfterSoundPrompt = 800; % ms how long to pause after the sound prompt was played
pauseAfterSpeakPrompt = 2200; % ms how long to pause after the speak prompt was played. 
                              % Note this should include inter-trial interval
% Below is the list of sounds:
soundList = {...
    'beep'; % LISTEN CUE
    'metronomeShort'; % SPEAK CUE
    'silence';
    'beet';
    'shot';
    'bat';
    'seal';
    'more';
    };





%% Load all the audio files and generate sequence list
for i = 1 : numel( soundList )
    mySound = soundList{i} ;
    in = load( [audioPath mySound '.mat'] );
    sobjs.(mySound) = audioplayer( in.y, in.Fs );
    fprintf('Loaded sound %s\n', mySound )
end

% Create the full order of 
possibleSounds = soundList(3:end); % first 2 are the cues

promptList = {};
for i = 1 : repetitionsEachSound
    thisSequenceOrder = randperm( numel(possibleSounds) );
    thisSequence = possibleSounds(thisSequenceOrder);
    promptList = [promptList; thisSequence];
end

fprintf('Generated pseudorandom sequence of %i reps x %i sounds = %i total hear & speak trials\n', ...
    repetitionsEachSound, numel( possibleSounds ), numel( promptList ) );
logFile =  [logPath 'audioCueLog_' datestr(now,1) '_' datestr(now, 13) '.txt'];
logFile = regexprep(logFile, ':', '-');
[fid, errmsg] = fopen( logFile, 'w' );
if fid < 1 
    error('Could not open file due to %s', errmsg )
else
    % write parameters
    fprintf( fid, 'repetitionsEachSound, %i\n', repetitionsEachSound );
    fprintf( fid, 'pauseAfterReadyMS, %i\n', pauseAfterReadyMS );
    fprintf( fid, 'pauseAfterSoundPrompt, %i\n', pauseAfterSoundPrompt );
    fprintf( fid, 'pauseAfterSpeakPrompt, %i\n', pauseAfterSpeakPrompt );
end

in = input('READY. Enter y to start, any other key to abort...\n', 's');

if ~strcmpi( in, 'y' )
    fprintf( fid, 'ABORTING\n' );
    fclose( fid );
    error(' ABORTED\n');
else
    fprintf('Starting in 3 seconds...\n')
    pause( 3 ) % gives time for experimenter to step away from keyboard
end

%% 
% If it gets this far, it's go-time.
tic;
for iTrial = 1 : numel( promptList )    
    % Opportunity for a break after each set
    if iTrial > 1 && mod( iTrial-1, numel(possibleSounds) ) == 0
        fprintf( '[%s] ',  datestr( now, 13 ) );
        fprintf( fid, '[%s] PAUSE\n',  datestr( now, 13 ) );
        in = input('PAUSED BETWEEN SETS. Enter any key to continue, k to end prematurely...\n', 's');        
        if strcmpi( in, 'k' )
            fprintf( fid, 'ABORTING\n' );
            fclose( fid );
            error('BLOCK STOPPED PREMATURELY')
        else
            pause(1) % pause after pressing the key to give operator time to step away and prevent keyboard sound from being problematic
        end
    end
        
   mySound = promptList{iTrial};
   myString = sprintf('[%s] Trial %i/%i: "%s"\n', datestr( now, 13 ), iTrial, numel( promptList ), mySound );
   fprintf( 1, myString ); % print to console
   fprintf( fid, myString );
    
   %% ----------------------
   %        LISTEN
   %  ----------------------
   % Play the ready tone twice in a row
   sobjs.beep.playblocking
   sobjs.beep.playblocking
   pause( pauseAfterReadyMS/1000 );
   
   % Play the prompt
   sobjs.(mySound).playblocking;
   pause( pauseAfterSoundPrompt/1000 );
   
   %% ----------------------
   %        SPEAK
   %  ----------------------
   sobjs.metronomeShort.playblocking % commented out; just one speak cue
   sobjs.metronomeShort.playblocking
   pause( pauseAfterSpeakPrompt/1000 );   
end

fprintf('Block complete, time = %.2f minutes\n', toc/60 )
fprintf( fid, 'FINISHED\n' );
fclose( fid );