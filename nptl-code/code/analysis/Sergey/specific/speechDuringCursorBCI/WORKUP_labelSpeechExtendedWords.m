% Script used to guide the researcher in hand-labeling the audio stream. Based on 
% /speech/WORKUP_labelSPeechExptData.m, but for this new spin-off project.
% This one is for the extended word list collected on 2019.01.23.


autoplayEachSnippet = true;



%% t5.2018.12.19 Speech with exteded words
audioChannel = []; % not needed because it's already an audio file (different pre-processing than before).
saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t5.2019.01.23/';

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_1_audio.mat'; % 
% labelOptions = load('extendedWords1.mat'); 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_2_audio.mat'; % 
% labelOptions = load('extendedWords2.mat'); 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_3_audio.mat'; % 
% labelOptions = load('extendedWords3.mat'); 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_4_audio.mat'; % 
% labelOptions = load('extendedWords4.mat'); 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_5_audio.mat'; % 
% labelOptions = load('extendedWords1.mat'); 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_6_audio.mat'; % 
% labelOptions = load('extendedWords2.mat'); 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_7_audio.mat'; % 
% labelOptions = load('extendedWords3.mat'); 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_8_audio.mat'; % 
% labelOptions = load('extendedWords4.mat'); 

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_9_audio.mat'; % 
% labelOptions = load('extendedWords1.mat');

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_10_audio.mat'; % 
% labelOptions = load('extendedWords2.mat');

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_11_audio.mat'; % 
% labelOptions = load('extendedWords3.mat');

fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.01.23/audioOnly/block_12_audio.mat'; % 
labelOptions = load('extendedWords4.mat');

labelOptions = labelOptions.wordList; 
msShownEachTime = 5000;


%% Run the labeling tool
% Allow 1 event
% Labeling rule: Prompt event 1 is cue
%                Response event 1 is Acoustic Onset if there's a response. Otherwise, it's
%                ignored.
[matName, sAnnotation] = soundLabelTool( fname, audioChannel, saveAnnotationPath, 'possibleCues', labelOptions, 'msShownEachTime', msShownEachTime, ...
    'autoplayEachSnippet', autoplayEachSnippet, 'maxEventsPerTrial', 1, 'minEventsPerTrial', 1);





