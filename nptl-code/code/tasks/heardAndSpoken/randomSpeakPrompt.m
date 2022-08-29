% Plays the speak prompt at random intervals (parameters specified),
% and writes a log of when it played the cues.
%
% Audio files must have already been prepared into .mat format. For these experiments,
% this is done by prepareAudioMats.m.
% 
% Runs until the user ctrl-C's out or the elapsed time ends
%% 
% Sergey D. Stavisky, 11  December 2018, Stanford Neural Prosthetics Translational Laboratory.
% Updated
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
minimumInterval = 4; % can't start to play more frequently than this
meanInterval = 7; % how often, on average, the change occurs (drawn from Poisson distribution)
maximumInterval = 10; % can't wait longer than this to change.

maxTime = 5*60-10; % in seconds.

% Below is the list of sounds:
soundList = {...
    'metronomeShort'; % SPEAK CUE
    };



%% Load all the audio files and generate sequence list
for i = 1 : numel( soundList )
    mySound = soundList{i} ;
    in = load( [audioPath mySound '.mat'] );
    sobjs.(mySound) = audioplayer( in.y, in.Fs );
    fprintf('Loaded sound %s\n', mySound )
end

% Create the full order of 
possibleSounds = soundList;

logFile =  [logPath 'audioPromptLog_' datestr(now,1) '_' datestr(now, 13) '.txt'];
logFile = regexprep(logFile, ':', '-');
[fid, errmsg] = fopen( logFile, 'w' );
if fid < 1 
    error('Could not open file due to %s', errmsg )
else
    % write parameters
    fprintf( fid, 'minimumInterval, %i\n', minimumInterval );
    fprintf( fid, 'meanInterval, %i\n', meanInterval );
    fprintf( fid, 'maximumInterval, %i\n', maximumInterval );
    fprintf( fid, 'maxTime, %i\n', maxTime );
end

in = input('READY. Enter y to start, any other key to abort...\n', 's');

if ~strcmpi( in, 'y' )
    fprintf( fid, 'ABORTING\n' );
    fclose( fid );
    error(' ABORTED\n');
else
    fprintf('Starting in 3 seconds...\n')
    pause( 3 ) % gives time for experimenter to step away from keyboard % DEV uncomment
end

%% 
% If it gets this far, it's go-time.
tic;
timeRunning = 0;
iTrial = 0;

waitTime = exprnd( meanInterval );
waitTime = max( [minimumInterval, waitTime] );
waitTime = min( [maximumInterval, waitTime] );

while timeRunning + waitTime < maxTime
    % decide how long to wait until next change event
    iTrial = iTrial + 1;
    
    myString = sprintf('[%s] Trial %i: delay %.4f "%s"\n', datestr( now, 13 ), iTrial, waitTime, mySound );
    fprintf( 1, myString ); % print to console
    pause( waitTime )

    fprintf( fid, myString );
    
    %% ----------------------
    %        SPEAK
    %  ----------------------
    sobjs.metronomeShort.playblocking % commented out; just one speak cue
    sobjs.metronomeShort.playblocking
    
    waitTime = exprnd( meanInterval );
    waitTime = max( [minimumInterval, waitTime] );
    waitTime = min( [maximumInterval, waitTime] );
    timeRunning = toc;
end

%%
fprintf('Block complete, time = %.2f minutes\n', toc/60 )
fprintf( fid, 'FINISHED\n' );
fclose( fid );