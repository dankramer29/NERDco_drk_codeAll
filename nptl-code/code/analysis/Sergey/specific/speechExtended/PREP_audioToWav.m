% make the long .mat audio files into .wav files 
inLongMAT = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.06.13 penntree/block_1_audio.mat';
% inLongMAT = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.06.13 penntree/block_2_audio.mat';
% inLongMAT = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.06.13 penntree/block_3_audio.mat';
% inLongMAT = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.06.13 penntree/block_4_audio.mat';


in = load( inLongMAT );
fprintf('Loaded %s\n', inLongMAT);
Fs = in.FsRaw;
[wavPath, fname] = fileparts( inLongMAT );
myFilename = sprintf('%s/%s.wav',wavPath, fname );      
audiowrite(myFilename, in.audioDat, Fs);
fprintf(' wrote %s\n', myFilename )
