% Assembles raw neural data (specified here) and labeled event times file (prepared
% earlier using soundLabelTool) into a .mat file that has an R-struct like format, which
% will facilitate subsequent analysis. 
%
% Sergey Stavisky, September 18 2017
clear

% Where generated R structs will live:
RstructPathRoot = [ResultsRootNPTL '/speech/Rstructs/sortedPlexon/'];
mkdir( RstructPathRoot );
%
audioAnnotationPathRoot = [ResultsRootNPTL '/speech/audioAnnotation/'];
annotationPrepend = 'manualLabels_'; 


% Specify list of the raw neural .ns5 files for each block. They should be coordinated
% across the two arrays, by which I mean element 1, 2, 3, ... of each list shoudl correspond to
% blocks 1, 2, 3, ... .


%%
% Will save R struct here
% outputFile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/withRaw/R_T5_2017_09_20-words.mat';
% outputFile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/R_T5_2017_09_20-words.mat';
% 
% 
% % Where do audio event labels live and what is their filename start?
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/'; 
% annotationPrepend = 'manualLabels_'; 
% audioChannel = 'c:97'; 
% 
% numArrays = 2;
% 
% rawFilesArray{1} = { ...
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech001.ns5';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech002.ns5';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech003.ns5';
% };
% 
% rawFilesArray{2} = { ...
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Medial/speech001.ns5';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Medial/speech002.ns5';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Medial/speech003.ns5';
% };
% 
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     1;
%     2;
%     3;
%     ];

%%
% Will save R struct here
% outputFile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/R_T5_2017_09_20-phonemes.mat';
% outputFile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/R_T5_2017_09_20-phonemes.mat';
% 
% 
% % Where do audio event labels live and what is their filename start?
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/'; 
% annotationPrepend = 'manualLabels_'; 
% audioChannel = 'c:97'; 
% 
% numArrays = 2;
% 
% rawFilesArray{1} = { ...
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech004.ns5';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech005.ns5';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech006.ns5';
% };
% 
% rawFilesArray{2} = { ...
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Medial/speech004.ns5';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Medial/speech005.ns5';
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Medial/speech006.ns5';
% };
% 
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     4;
%     5;
%     6;
%     ];


%%  T8.2017.10.17 Phonemes
% experiment = 't8.2017.10.17';
% outputFile = [RstructPathRoot 'R_' experiment '-phonemes.mat'];
% audioChannel = 'c:98'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/net/experiments/t8/t8.2017.10.17/Data/_Lateral/datafile001.ns5';
%     '/net/experiments/t8/t8.2017.10.17/Data/_Lateral/datafile002.ns5';
%     '/net/experiments/t8/t8.2017.10.17/Data/_Lateral/datafile003.ns5';
% };
% rawFilesArray{2} = { ...
%     '/net/experiments/t8/t8.2017.10.17/Data/_Medial/datafile001.ns5';
%     '/net/experiments/t8/t8.2017.10.17/Data/_Medial/datafile002.ns5';
%     '/net/experiments/t8/t8.2017.10.17/Data/_Medial/datafile003.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     1
%     2
%     3
%     ];
% %  rollovers files - for spike sorting
% rollovers = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t8_2017_10_17_1to6_array1.mat';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t8_2017_10_17_1to6_array2.mat';
%     };
% % txt files - from Plexon Offline Sorter sorting
% plexonFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t8_2017_10_17_1to6_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t8_2017_10_17_1to6_array2.txt';
%     };
% plexonSortQualityFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t8_2017_10_17_1to6_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t8_2017_10_17_1to6_array2.txt';
%     };


%%  T8.2017.10.17 Instructed Movements
% experiment = 't8.2017.10.17';
% outputFile = [RstructPathRoot 'R_' experiment '-movements.mat'];
% audioChannel = 'c:98'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/net/experiments/t8/t8.2017.10.17/Data/_Lateral/datafile004.ns5';
%     '/net/experiments/t8/t8.2017.10.17/Data/_Lateral/datafile005.ns5';
%     '/net/experiments/t8/t8.2017.10.17/Data/_Lateral/datafile006.ns5';
% };
% rawFilesArray{2} = { ...
%     '/net/experiments/t8/t8.2017.10.17/Data/_Medial/datafile004.ns5';
%     '/net/experiments/t8/t8.2017.10.17/Data/_Medial/datafile005.ns5';
%     '/net/experiments/t8/t8.2017.10.17/Data/_Medial/datafile006.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     4
%     5
%     6
%     ];
% %  rollovers files - for spike sorting
% rollovers = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t8_2017_10_17_1to6_array1.mat';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t8_2017_10_17_1to6_array2.mat';
%     };
% % txt files - from Plexon Offline Sorter sorting
% plexonFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t8_2017_10_17_1to6_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t8_2017_10_17_1to6_array2.txt';
%     };
% plexonSortQualityFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t8_2017_10_17_1to6_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t8_2017_10_17_1to6_array2.txt';
%     };

%%  T8.2017.10.18 Words
% experiment = 't8.2017.10.18';
% outputFile = [RstructPathRoot 'R_' experiment '-words.mat'];
% audioChannel = 'c:98'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/datafile001.ns5';
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/datafile002.ns5';
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/datafile003.ns5';
% };
% rawFilesArray{2} = { ...
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/datafile001.ns5';
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/datafile002.ns5';
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/datafile003.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     1
%     2
%     3
%     ];
% % how these raw files are ordered in the big continous neural data variable
% % that is created for spike sorting; i.e, in what order is the raw data
% % concatenated, which trialifySpeechBlock will need to know to understand
% % what files the rollovers refer to.
% rolloverOrder= [...
%     1;
%     2;
%     3];
% 
% % rollovers files - for spike sorting
% rollovers = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t8_2017_10_18_1to6_11to12_array1.mat';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t8_2017_10_18_1to6_11to12_array2.mat';
%     };
% plexonFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t8_2017_10_18_1to6_11to12_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t8_2017_10_18_1to6_11to12_array2.txt';
%     };
% plexonSortQualityFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t8_2017_10_18_1to6_11to12_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t8_2017_10_18_1to6_11to12_array2.txt';
%     };



%%  T8.2017.10.18 Instructed Movements
experiment = 't8.2017.10.18';
outputFile = [RstructPathRoot 'R_' experiment '-movements.mat'];
audioChannel = 'c:98'; 
numArrays = 2;
rawFilesArray{1} = { ...
    '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/datafile004.ns5';
    '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/datafile005.ns5';
    '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/datafile006.ns5';
};
rawFilesArray{2} = { ...
    '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/datafile004.ns5';
    '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/datafile005.ns5';
    '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/datafile006.ns5';
};
% Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
absoluteBlockNum = [...
    4
    5
    6
    ];
% how these raw files are ordered in the big continous neural data variable
% that is created for spike sorting; i.e, in what order is the raw data
% concatenated, which trialifySpeechBlock will need to know to understand
% what files the rollovers refer to.
rolloverOrder= [...
    4;
    5;
    6];

% rollovers files - for spike sorting
rollovers = {...
    '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t8_2017_10_18_1to6_11to12_array1.mat';
    '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t8_2017_10_18_1to6_11to12_array2.mat';
    };
plexonFiles = {...
    '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t8_2017_10_18_1to6_11to12_array1.txt';
    '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t8_2017_10_18_1to6_11to12_array2.txt';
    };
plexonSortQualityFiles = {...
    '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t8_2017_10_18_1to6_11to12_array1.txt';
    '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t8_2017_10_18_1to6_11to12_array2.txt';
    };


%% T5.2017.10.23 Phonemes
% experiment = 't5.2017.10.23';
% outputFile = [RstructPathRoot 'R_' experiment '-phonemes.mat'];
% audioChannel = 'c:97'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/net/experiments/t5/t5.2017.10.23/Data/_Lateral/NSP Data/datafile001.ns5';
%     '/net/experiments/t5/t5.2017.10.23/Data/_Lateral/NSP Data/datafile002.ns5';
%     '/net/experiments/t5/t5.2017.10.23/Data/_Lateral/NSP Data/datafile003.ns5';
% };
% rawFilesArray{2} = { ...
%     '/net/experiments/t5/t5.2017.10.23/Data/_Medial/NSP Data/datafile001.ns5';
%     '/net/experiments/t5/t5.2017.10.23/Data/_Medial/NSP Data/datafile002.ns5';
%     '/net/experiments/t5/t5.2017.10.23/Data/_Medial/NSP Data/datafile003.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     1;
%     2;
%     3;
%     ];
% 
% % rollovers files - for spike sorting
% rollovers = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t5_2017_10_23_1to6_array1.mat';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t5_2017_10_23_1to6_array2.mat';
%     };
% % txt files - from Plexon Offline Sorter sorting
% plexonFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t5_2017_10_23_1to6_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t5_2017_10_23_1to6_array2.txt';
%     };
% plexonSortQualityFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t5_2017_10_23_1to6_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t5_2017_10_23_1to6_array2.txt';
%     };
%% T5.2017.10.23 Instructed Movements
% experiment = 't5.2017.10.23';
% outputFile = [RstructPathRoot 'R_' experiment '-movements.mat'];
% audioChannel = 'c:97'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/net/experiments/t5/t5.2017.10.23/Data/_Lateral/NSP Data/datafile004.ns5';
%     '/net/experiments/t5/t5.2017.10.23/Data/_Lateral/NSP Data/datafile005.ns5';
%     '/net/experiments/t5/t5.2017.10.23/Data/_Lateral/NSP Data/datafile006.ns5';
% };
% rawFilesArray{2} = { ...
%     '/net/experiments/t5/t5.2017.10.23/Data/_Medial/NSP Data/datafile004.ns5';
%     '/net/experiments/t5/t5.2017.10.23/Data/_Medial/NSP Data/datafile005.ns5';
%     '/net/experiments/t5/t5.2017.10.23/Data/_Medial/NSP Data/datafile006.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     4;
%     5;
%     6;
%     ];
% % rollovers files - for spike sorting
% rollovers = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t5_2017_10_23_1to6_array1.mat';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t5_2017_10_23_1to6_array2.mat';
%     };
% plexonFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t5_2017_10_23_1to6_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t5_2017_10_23_1to6_array2.txt';
%     };
% plexonSortQualityFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t5_2017_10_23_1to6_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t5_2017_10_23_1to6_array2.txt';
%     };


%% T5.2017.10.25 Words
% experiment = 't5.2017.10.25';
% outputFile = [RstructPathRoot 'R_' experiment '-words.mat'];
% audioChannel = 'c:97'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/datafile001.ns5';
%     '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/datafile002.ns5';
%     '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/datafile003.ns5';
% };
% rawFilesArray{2} = { ...
%     '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/datafile001.ns5';
%     '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/datafile002.ns5';
%     '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/datafile003.ns5';
% };
% 
% % Commented out files below went into the raw data .dat used for spike
% % sorting. They're not speech task so they don't get constructed into the
% % R, but this is a reminder to myself for why rolloverOrder doesn't start
% % at 1.
% %     '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5';
% %     '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/14_cursorTask_Complete_t5_bld(014)015.ns5';
% %     '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5';
% %     '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/14_cursorTask_Complete_t5_bld(014)015.ns5';
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     1;
%     2;
%     3;
%     ];
% 
% % how these raw files are ordered in the big continous neural data variable
% % that is created for spike sorting; i.e, in what order is the raw data
% % concatenated, which trialifySpeechBlock will need to know to understand
% % what files the rollovers refer to.
% rolloverOrder= [...
%     3;
%     4;
%     5];
% 
% % rollovers files - for spike sorting
% rollovers = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t5_2017_10_25_13_15_1to3_array1.mat';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/rollovers-t5_2017_10_25_13_15_1to3_array2.mat';
%     };
% plexonFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t5_2017_10_25_13_15_1to3_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/t5_2017_10_25_13_15_1to3_array2.txt';
%     };
% plexonSortQualityFiles = {...
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t5_2017_10_25_13_15_1to3_array1.txt';
%     '/net/derivative/user/sstavisk/Results/speech/rawForSorting/sortQuality_t5_2017_10_25_13_15_1to3_array2.txt';
%     };

%%
% Will save R struct here
% outputFile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/R_T5_2017_09_20-thoughtSpeak.mat';
% 
% % Where do audio event labels live and what is their filename start?
% saveAnnotationPath = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/'; 
% annotationPrepend = 'manualLabels_'; 
% audioChannel = 'c:97'; 
% 
% numArrays = 2;
% 
% rawFilesArray{1} = { ...
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Lateral/speech007.ns5';
% };
% 
% rawFilesArray{2} = { ...
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/Medial/speech007.ns5';
% };
% 
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     7;
%     ];
% 

%% T5.2017.10.23 Caterpillar
% experiment = 't5.2017.10.23';
% outputFile = [RstructPathRoot 'R_' experiment '-caterpillar.mat'];
% audioChannel = 'c:97'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/net/experiments/t5/t5.2017.10.23/Data/_Lateral/NSP Data/datafile007.ns5';
% };
% rawFilesArray{2} = { ...
%     '/net/experiments/t5/t5.2017.10.23/Data/_Medial/NSP Data/datafile007.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     7;
%     ];

%%  T8.2017.10.18 Caterpillar
% experiment = 't8.2017.10.18';
% outputFile = [RstructPathRoot 'R_' experiment '-caterpillar.mat'];
% audioChannel = 'c:98'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/datafile007.ns5';
% };
% rawFilesArray{2} = { ...
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/datafile007.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     7
%     ];


%% Parameters
params.neural.msBeforeCue = 1000; % how many ms back to go before very first cue event
params.neural.msAfterSpeech = 2500; % how many ms after last speech event .

params.audioChannel = audioChannel; % which analog input channel has audio. Formatted as a openNSx arguemnt. This corresponds to analog 2
params.arrayContainingAudio = 1; % which of the arrays actually has the audio channel
params.nsxChannel = 'c:01:96'; % use 'c' instead of 'e' because we don't use a .ccf that will map channels to electrodes



% .nsx data 
params.spikeBand.getSpikeBand = true;
params.spikeBand.filterType = 'spikesmediumfiltfilt'; % these are names of NPTL codebase filters
params.spikeBand.commonAverageReference = true; % done within each array.
% Will save the CAR, high-pass spikeBand neural (not trialified) if below is not empty, 
% This is used for spike sorting later, and thus needs to be done.
params.spikeBand.saveCARForSortingPath = []; % will save before the filtering but after CAR
params.spikeBand.saveFilteredForSortingPath = [];
% params.spikeBand.saveFilteredForSortingPath = [ResultsRootNPTL '/speech/rawForSorting/' experiment '/']; 


% If true, will get and save 30sps raw into R struct
params.raw.getRaw = true;

% .nev data. Might as well get it though really I'm not likely to ever use this. It might
% be useful for aligning to closed-loop BMI data. 
params.nev.getNevSpikes = true; 

% lfp band
params.lfpBand.getLfpBand = true;
params.lfpBand.Fs = 1000; % what to downsample LFP to
params.lfpBand.filterType = lfpLPF; % < 250 Hz
params.lfpBand.useFiltfilt = true; % slightly more filtering,  no phase delay

% SPIKE SORTING?
params.ss.mergeSpikeSorted = false; 
params.ss.mountainSort = false;
params.ss.plexon = true;
params.ss.rawFs = 30000; % sampling rate used for sorting data.
% mountainsort path:
% mlPath = '/net/home/sstavisk/mountainlab/matlab';
% addpath( genpath( mlPath ) );

%%
audioAnnotationPath = [audioAnnotationPathRoot experiment '/'];
numBlocks = numel( rawFilesArray{1} );

% Scan for whether event labels files exist for each block. 
for iBlock = 1 : numBlocks
    inLabels = [];
    
    putativeFile = [audioAnnotationPath annotationPrepend regexprep( pathToLastFilesep( rawFilesArray{params.arrayContainingAudio}{iBlock}, 1 ), '.ns5', '.mat' )];
    inLabels = load( putativeFile );
    
    if isempty( inLabels )
        error('No labeled event file exists for block %i', iBlock)
    else
        sAnnotation{iBlock} = inLabels.sAnnotation;
        fprintf('Block %i has labels %s, %i trials\n', ...
            iBlock, mat2str( cell2mat( cellfun( @(x) [x ', '], sAnnotation{iBlock}.label, 'UniformOutput', false ) )), ...
            numel( sAnnotation{iBlock}.trialNumber ) );
    end
end



% Prepare the spikesorted data if we'll be using it
if params.ss.mergeSpikeSorted 
   % Load the rollovers
   for iArray = 1 : numArrays
       in = load( rollovers{iArray} );
       fprintf('Loaded %s\n', rollovers{iArray} );
       allRollovers{iArray} = in.rollovers;
   end
   
   if params.ss.mountainSort
      % Load the mountainsort data
      for iArray = 1 : numArrays
          tic
          fprintf('Loading %s', MDAfiles{iArray} );
          mda{iArray} = readmda( MDAfiles{iArray} );
          fprintf(' DONE in %.1fs\n', toc )          
      
      
          % Convert to unit-wise spike times; this will be standardized across
          % MountainSort or KiloSort so the merge can be the same.
          ssort.spikes{iArray}.channels = mda{iArray}(1,:)';
          ssort.spikes{iArray}.sample = mda{iArray}(2,:)';
          ssort.spikes{iArray}.unitCode = mda{iArray}(3,:)'; % id number that the spike sorter assigns to each unit
      end      
   end
   
   if params.ss.plexon
      for iArray = 1 : numArrays
          tic
          plexonDat{iArray} = readPlexonSortedTextFilesSimple( plexonFiles{iArray}, ...
              'sortQualityFile', plexonSortQualityFiles{iArray} );
          

          % Convert to same format as with other sorting methods. Note that
          % this requires converting from seconds to 30ksps sample and
          % sorting events by their timestamp (the plexon files are ordered
          % by units, not time.
          
          spikeSamples = round( params.ss.rawFs .* plexonDat{iArray}.eventTimeSeconds );
          [spikeSamples, chronOrder] = sort( spikeSamples, 'ascend' );
          if spikeSamples(1) < 1
              spikeSamples(1) = 1; % these are indices so they cannot be 0
          end
          ssort.spikes{iArray}.sample = spikeSamples;
          ssort.spikes{iArray}.channels = plexonDat{iArray}.electrode(chronOrder);        
          ssort.spikes{iArray}.unitCode = plexonDat{iArray}.unit(chronOrder); 
          % since these are already ordered 1, 2, ... N they'll just be maintained when I do the merge into .sortedRasters1 .sortedRasters2

          % some additional stuff
          ssort.unitNames{iArray} = plexonDat{iArray}.unitIDs;
          ssort.unitQuality{iArray} = plexonDat{iArray}.unitSortRating;
      end
   end
end


% Trial-ify each block's raw neural stream.
R = [];
for iBlock = 1 : numBlocks
    myRawBlockNum = rolloverOrder(iBlock); 
    for iArray = 1 : numArrays
        myNS5files{iArray} = rawFilesArray{iArray}{iBlock};
        myNEVfiles{iArray} = regexprep( rawFilesArray{iArray}{iBlock}, '.ns5', '.nev' );        
        
        if params.ss.mergeSpikeSorted
            % prepare the key info needed for this block's spike-sort merge
            % note that it's critical to use actual block number relative
            % to how the raw data used for sorting was made, rather 
            if myRawBlockNum > 6
                keyboard
                % NOTE TO SELF: I bet you're merging in the BCI data
                % (blocks 7, etc). these might need some finesse because
                % their raw data will be in a new raw file with different
                % rollovers that probably start from file number 1 again.
            end
            if myRawBlockNum == 1
                ssort.sampleStartThisFile(iArray) = 1;
            else
                ssort.sampleStartThisFile(iArray) = allRollovers{iArray}(myRawBlockNum-1);
            end
            if myRawBlockNum == numel( allRollovers{iArray} ) + 1
                ssort.sampleEndThisFile(iArray) = inf;
            else
                ssort.sampleEndThisFile(iArray) = allRollovers{iArray}(myRawBlockNum)-1;
            end
        end        
    end
    
    tic
    myR = trialifySpeechBlock( myNS5files, myNEVfiles, sAnnotation{iBlock}, params, ...
        'blockNumber', absoluteBlockNum(iBlock), 'ssort', ssort );
    fprintf('Block %i, created R struct with %i trials. Took %gm\n', iBlock, numel( myR ), toc/60 )
    R = [R; myR];
end

Rparams = params;
if ~isdir( pathToLastFilesep( outputFile ) )
    mkdir( pathToLastFilesep( outputFile ) )
end
% save the block
save( outputFile, 'R', 'Rparams', '-v7.3' );
fprintf('Saved %s with %i trials\n', outputFile, numel( R ) );
