% Script used to guide the researcher in hand-labeling the audio stream. 



% audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2

% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/';


% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech001.ns5'; % t5.2017.09.20 Speech Block 1/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech002.ns5'; % t5.2017.09.20 Speech Block 2/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech003.ns5'; % t5.2017.09.20 Speech Block 3/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech007.ns5'; % t5.2017.09.20 Internal Speech Block 1/1

% labelOptions = {...
%     'arm';
%     'beach';
%     'pull';
%     'push';
%     'tree';
%     'silence';
%     };


% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech004.ns5'; % t5.2017.09.20 Phoneme Block 1/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech005.ns5'; % t5.2017.09.20 Phoneme Block 2/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech006.ns5'; % t5.2017.09.20 Phoneme Block 3/3
% labelOptions = {...
%     'ba';
%     'da';
%     'ga';
%     'oo';
%     'sh';
%     'mm'; % this one was erroneous but he said it enough times I might as well label it, in case we want to compare 'oo' to 'mm' errors.
%     'silence';
%     };


%% T8.2017.10.17 PHONES AND MOVEMENTS
% audioChannel = 'c:98'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2

% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t8.2017.10.17/';
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.17/Data/_Lateral/datafile001.ns5'; % t8.2017.10.17 Phoneme Block 1/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.17/Data/_Lateral/datafile002.ns5'; % t8.2017.10.17 Phoneme Block 2/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.17/Data/_Lateral/datafile003.ns5'; % t8.2017.10.17 Phoneme Block 3/3
% labelOptions = {}; % leave empty so I can enter mistakes where cue and response differed
% msShownEachTime = 7000;

% fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.17/Data/_Lateral/datafile004.ns5'; % t8.2017.10.17 Movement Block 1/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.17/Data/_Lateral/datafile005.ns5'; % t8.2017.10.17 Movement Block 2/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.17/Data/_Lateral/datafile006.ns5'; % t8.2017.10.17 Movement Block 3/3


% labelOptions = {'tongueLeft', 'tongueRight', 'tongueDown', 'tongueUp', 'mouthOpen', 'lipsForward', 'lipsBack', 'stayStill'};
% msShownEachTime = 9000; % for cued movements

%% T8.2017.10.18  WORDS AND MOVEMENTS
% audioChannel = 'c:98'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% 
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t8.2017.10.18/';
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.18/Data/NSP Data/_Lateral/datafile001.ns5'; % t8.2017.10.8 Words Block 1/3
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.18/Data/NSP Data/_Lateral/datafile002.ns5'; % t8.2017.10.18 Words Block 2/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.18/Data/NSP Data/_Lateral/datafile003.ns5'; % t8.2017.10.18 Words Block 3/3
% labelOptions = { 'got', 'dot', 'bot', 'shot', 'boot', 'bat' 'keep', 'beet', 'more', 'seal', 'silence'}; 
% msShownEachTime = 7500;
% 
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.18/Data/NSP Data/_Lateral/datafile004.ns5'; % t8.2017.10.18 Movement Block 1/3
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.18/Data/NSP Data/_Lateral/datafile005.ns5'; % t8.2017.10.18 Movement Block 2/3
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.18/Data/NSP Data/_Lateral/datafile006.ns5'; % t8.2017.10.18 Movement Block 3/3
% 
% 
% % labelOptions = {'tongueLeft', 'tongueRight', 'tongueDown', 'tongueUp', 'mouthOpen', 'lipsForward', 'lipsBack', 'stayStill'};
% % msShownEachTime = 9000; % for cued movements


%% t5.2017.10.23 PHONEMES
% audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% 
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t5.2017.10.23/';
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.23/Data/_Lateral/datafile001.ns5'; % t5.2017.10.23 Phoneme Block 1/3
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.23/Data/_Lateral/datafile002.ns5'; % t5.2017.10.23 Phoneme Block 2/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.23/Data/_Lateral/datafile003.ns5'; % t5.2017.10.23 Phoneme Block 3/3
% labelOptions = {}; % leave empty so I can enter mistakes where cue and response differed - use for phonemes
% msShownEachTime = 7500;
% 
% %% t5.2017.10.23 INSTRUCTED MOVEMENTS
% audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% 
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t5.2017.10.23/';
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.23/Data/_Lateral/datafile004.ns5'; % t5.2017.10.23 Instrcuted Movements Block 1/3
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.23/Data/_Lateral/datafile005.ns5'; % t5.2017.10.3 Instrcuted Movements 2/3
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.23/Data/_Lateral/datafile006.ns5'; % t5.2017.10.23 nstrcuted Movements 3/3
% labelOptions = {'tongueLeft', 'tongueRight', 'tongueDown', 'tongueUp', 'mouthOpen', 'lipsForward', 'lipsBack', 'stayStill'};
% msShownEachTime = 9000; % for cued movements

%% t5.2017.10.25 WORDS
% audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% 
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t5.2017.10.25/';
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.25/Data/_Lateral/datafile001.ns5'; % t5.2017.10.25 Words Block 1/3
% % fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.25/Data/_Lateral/datafile002.ns5'; % t5.2017.10.25 Words Block 2/3
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.25/Data/_Lateral/datafile003.ns5'; % t5.2017.10.25 Words Block 3/3
% labelOptions = { 'got', 'dot', 'bot', 'shot', 'boot', 'bat' 'keep', 'beet', 'more', 'seal', 'silence'}; 
% msShownEachTime = 7500;


autoplayEachSnippet = true; % for everythign except Caterpillar

%% t5.2017.10.23 Caterpillar
% audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% % 
% saveAnnotationPath = [ResultsRootNPTL '/speech/audioAnnotation/t5.2017.10.23/'];
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.10.23/datafile007.ns5'; % t5.2017.10.23 Caterpillar all run throughts
% labelOptions = {'caterpillar'};
% msShownEachTime = 90*1000;
% autoplayEachSnippet = false;

% %% t8.2017.10.18 Caterpillar
% audioChannel = 'c:98'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% % 
% saveAnnotationPath = [ResultsRootNPTL '/speech/audioAnnotation/t8.2017.10.18/'];
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t8.2017.10.18/datafile007.ns5'; % t8.2017.10.18 Caterpillar all run throughts
% labelOptions = {'caterpillar'};
% msShownEachTime = 90*1000;
% autoplayEachSnippet = false;

%% t5.2018.12.12 Speech while BCI cursor task
audioChannel = 'c:97'; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
% 
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t5.2018.12.12/';
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.12/Lateral/speech_1014.ns5'; % t5.2018.12.12 Words Block 1/2
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.12/Lateral/speech_1015.ns5'; % t5.2018.12.12 Words Block 2/2
saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/audioAnnotation/t5.2018.12.17/';
% fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/cuedSpeaking001.ns5'; % t5.2018.12.17 Words Block 1/2
fname = '/Users/sstavisk/CachedDatasets/NPTL/t5.2018.12.17/Lateral/cuedSpeaking002.ns5'; % t5.2018.12.17 Words Block 2/2

labelOptions = { 'bat', 'beet', 'seal', 'shot', 'more', 'silence'}; 
msShownEachTime = 7500;


%%
[matName, sAnnotation] = soundLabelTool( fname, audioChannel, saveAnnotationPath, 'possibleCues', labelOptions, 'msShownEachTime', msShownEachTime, ...
    'autoplayEachSnippet', autoplayEachSnippet);

% Verify the file
checkResults = consistencyChecksSoundLabeling( sAnnotation, 'audioChannel', audioChannel);
