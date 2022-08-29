% Generates a video of the cursor task block where T5 was freely speaking and telling a story much of the time. 
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 13 March 2019
%
clear


% Point to the audio data:
audioNS5file = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/20_cursorTask_Complete_t5_bld(020)021.ns5';
% Point to the cursor task
taskFileloggerDir = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Data/FileLogger/20/';


% What to compare performance to
comparisonFile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B19.mat';


params.audioChannel = 'c:97'; 


% some task data that isn't in the R struct
params.cursorDiameter = 45;



%% Load in the audio file
audioIn = openNSx( 'read', audioNS5file, params.audioChannel ); % audio
audioStream.Fs = audioIn.MetaTags.SamplingFreq;
audioStream.dat = audioIn.Data{end}';
clear('audioIn');






%% Load in the cursor task and create R struct
R = onlineR( parseDataDirectoryBlock( taskFileloggerDir ) );
fprintf('Loaded %i movement task trials\n', numel( R ) );
% first trial is not legit;
R(1) = [];

%% Measure performance compared to last no-speech block
Rcompare = load( comparisonFile );
Rcompare = Rcompare.R;
statCompare = CursorTaskSimplePerformanceMetrics( Rcompare );

R = AddDialInTime( R );
R = AddCursorPathEfficiency( R, 'radiusCounts', false ); 
stat = CursorTaskSimplePerformanceMetrics( R );



% Time to target
[p,h] = ranksum( stat.TTT, statCompare.TTT );
fprintf('TTT speech: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmedian( stat.TTT ), nanmedian( statCompare.TTT ), p );

% Path efficiency
[p,h] = ranksum( stat.pathEfficiency, statCompare.pathEfficiency );
fprintf('PE speech: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmedian( stat.pathEfficiency ), nanmedian( statCompare.pathEfficiency ), p );
    
% Dial-in 
[p,h] = ranksum( stat.dialIn, statCompare.dialIn );
fprintf('Dial-in haptic: %.2f, null: %.2f, (p=%g, ranksum)\n', ...
    nanmedian( stat.dialIn ), nanmedian( statCompare.dialIn ), p );







%% Play video
% Restrict to the audio from the start of the first trial.
startAudioInd = R(1).firstCerebusTime(1,1);
audioStream.dat = audioStream.dat(startAudioInd:end);



CursorTaskVid2D( R, 't5.2018.12.17_B20.avi', ...
    'cursorRadius', params.cursorDiameter/2, 'audioStream', audioStream, ...
    'heightPixels', 720, 'FontSize', 30 )
beep; pause(0.1); beep