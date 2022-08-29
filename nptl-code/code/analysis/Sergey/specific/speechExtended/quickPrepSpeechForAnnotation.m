% Quickly put together a sentence and a paragraph for testing the speech annotation tools
% that Navdeep will send me.
%
% These are from t5.2018.06.13
%
% May 2019
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Lab

clear

saveDir = '/Users/sstavisk/Results/speech/contSpeech/annotate';

audioFile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.06.13 penntree/block_1_audio.mat';
textFile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.06.13 penntree/treebankTaskLog_13-Jun-2018_15-33-24.mat';


in = load( audioFile );
Fs = in.FsRaw;

inText = load( textFile );
% Note: formattedForScreenText is for all the blocks, it's just the 100 passages.

%%
% how many seconds to grab
% Sentence 0001
% startS = 9 * in.FsRaw + 1;
% endS = 20 * in.FsRaw;

% Paragraph 006
startS = 180 * in.FsRaw + 1;
endS = 250 * in.FsRaw;

showSnippet = in.audioDat(startS:endS);
figh = figure;
plot( showSnippet )
title('showSnippet')

% play the long snippet
playbackObj = audioplayer( showSnippet, in.FsRaw  );
playbackObj.play;


% possibleText = inText.formattedForScreenText{1}; % sentence 1
possibleText = inText.formattedForScreenText{6}; % paragraph 6
TrimScreenText( possibleText )

% Save this manually to a text file for now. Will need to figure out what kind of
% preprocessing their scripts need before automating.


%% Put finalized snippet here
% Sentence 1
% snippetName = 'sentence0001.dat'
% startSample = 2.641e4;
% endSample = 2.596e5;

% Paragraph 6
snippetNameDat = 'paragraph006.dat';
startSample = 2.05e5;
endSample = 1.845e6;


saveSnippet = showSnippet(startSample:endSample);
figh = figure; figh.Name = 'saveSnippet';
plot( saveSnippet )



% play the curstom snippet
playbackObj = audioplayer( saveSnippet, in.FsRaw  );
playbackObj.play;
cd( saveDir );


% save it as .wav
audiowrite( regexprep( snippetNameDat, '.dat', '.wav' ), saveSnippet, Fs)



%%
% make the long .mat into .wav so 
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


