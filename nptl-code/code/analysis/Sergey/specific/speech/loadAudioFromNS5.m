% 
% For now just a dev script to get test audio data in.


% fname = '/Users/sstavisk/CachedDatasets/NPTL/devSpeech/tmpNSP/lateral.ns5';
% fname = '/Users/sstavisk/CachedDatasets/NPTL/devSpeech/tmpNSP/lateral2.ns5';
% fname = '/Users/sstavisk/CachedDatasets/NPTL/devSpeech/tmpNSP/regularGain.ns5';
% fname = '/Users/sstavisk/CachedDatasets/NPTL/devSpeech/tmpNSP/twentyGain.ns5';
% fname = '/Users/sstavisk/CachedDatasets/NPTL/devSpeech/tmpNSP/fullTestNSP1_001.ns5';
% fname2 = '/Users/sstavisk/CachedDatasets/NPTL/devSpeech/tmpNSP/fullTestNSP2001.ns5';

% Case test
fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.16/Data/NCS Data/NSP1/datafile003.ns5';
fname2 = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.16/Data/NCS Data/NSP2/datafile003.ns5';

playbackGain = 1;


sampleNeuralChannel = 'c:5';
sampleNeuralChannel_array2 = 'c:4';
audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% audioChannel = 'c:98'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2


% outputFname = '/Users/sstavisk/CachedDatasets/NPTL/devSpeech/tmpNSP/regularGain.wav';
outputFname = '/Users/sstavisk/CachedDatasets/NPTL/devSpeech/tmpNSP/datafile001.wav';



%% Open the NS5 file

ns5in1 = openNSx( fname, audioChannel, 'read' ); % audio

sampleNeuralRawIn = openNSx( fname, sampleNeuralChannel, 'read' ); % neural broadband
sampleNeuralRawIn_array2 = openNSx( fname2, sampleNeuralChannel_array2, 'read' ); % neural broadband array 2


audioRaw = playbackGain.*ns5in1.Data{2};

Fs = ns5in1.MetaTags.SamplingFreq;

playbackObj = audioplayer( audioRaw, Fs );

%% plot example raw neusampleNeuralRawInral 
figure; plot( sampleNeuralRawIn.Data{2} );
hold on;
plot( sampleNeuralRawIn_array2.Data{2}, 'r' );

%% Load the spikes data

nevIn = openNEV( regexprep( fname, '.ns5', '.nev' ) );
nevIn.Data.Spikes %.Electrode, .TimeStamp together can be used to make raster
figure; plot( nevIn.Data.Spikes.TimeStamp )


nevIn_array2 = openNEV( regexprep( fname2, '.ns5', '.nev' ) );
nevIn_array2.Data.Spikes %.Electrode, .TimeStamp together can be used to make raster
hold on; plot( nevIn_array2.Data.Spikes.TimeStamp, 'r' )
%% Play it back
playbackObj.play

%% Save it
audiowrite( outputFname, audioRaw, Fs );