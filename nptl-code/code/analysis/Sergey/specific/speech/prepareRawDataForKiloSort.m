% Script that points bunchOfMATfilesToDAT to the right files.
% The .dat files can be fed into KiloSort or Plexon Offline Sorter.
%
% Sergey D. Stavisky, 18 March 2018, Stanford Neural Prosthetics
% Translational Laboratory

% These were created by trialifySpeechBlock.m after CAR
% OR by singleNS5toFilteredForSorting.m
% rawDir = '/net/derivative/user/sstavisk/Results/speech/rawForSorting/';
% rawDir = '/net/derivative/user/sstavisk/Results/speech/rawForSorting/';
rawDir = [ResultsRootNPTL '/speech/rawForSorting/'];
% rawDir = [ResultsRootNPTL '/speech/rawForSorting/noCAR/'];

excludeZeroChans = false;
% t5.2017.10.23 (Phonemes and Facial Movements)
% Array 1
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array1_forSorting.mat';
%     't5.2017.10.23/datafile002_array1_forSorting.mat';
%     't5.2017.10.23/datafile003_array1_forSorting.mat';
%     't5.2017.10.23/datafile004_array1_forSorting.mat';
%     't5.2017.10.23/datafile005_array1_forSorting.mat';
%     't5.2017.10.23/datafile006_array1_forSorting.mat';
%     };
% outname = 't5_2017_10_23_1to6_array1.dat';


% Array 2
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array2_forSorting.mat';
%     't5.2017.10.23/datafile002_array2_forSorting.mat';
%     't5.2017.10.23/datafile003_array2_forSorting.mat';
%     't5.2017.10.23/datafile004_array2_forSorting.mat';
%     't5.2017.10.23/datafile005_array2_forSorting.mat';
%     't5.2017.10.23/datafile006_array2_forSorting.mat';
%     };
% outname = 't5_2017_10_23_1to6_array2.dat';

% t5.2017.10.23 (Phonemes and Facial Movements)
% Array 1
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array1_forSorting.mat';
%     't5.2017.10.23/datafile002_array1_forSorting.mat';
%     't5.2017.10.23/datafile003_array1_forSorting.mat';
%     't5.2017.10.23/datafile004_array1_forSorting.mat';
%     't5.2017.10.23/datafile005_array1_forSorting.mat';
%     't5.2017.10.23/datafile006_array1_forSorting.mat';
%     };
% outname = 't5_2017_10_23_1to6_array1.dat';


% Array 2
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array2_forSorting.mat';
%     't5.2017.10.23/datafile002_array2_forSorting.mat';
%     't5.2017.10.23/datafile003_array2_forSorting.mat';
%     't5.2017.10.23/datafile004_array2_forSorting.mat';
%     't5.2017.10.23/datafile005_array2_forSorting.mat';
%     't5.2017.10.23/datafile006_array2_forSorting.mat';
%     };
% outname = 't5_2017_10_23_1to6_array2.dat';

% t5.2017.10.25 (Words)
% Array 1
% arrayFiles = {...
%     't5.2017.10.25/12_cursorTask_Complete_t5_bld(012)013_array1_forSorting.mat';
%     't5.2017.10.25/14_cursorTask_Complete_t5_bld(014)015_array1_forSorting.mat';
%     't5.2017.10.25/datafile001_array1_forSorting.mat';
%     't5.2017.10.25/datafile002_array1_forSorting.mat';
%     't5.2017.10.25/datafile003_array1_forSorting.mat';
%     };
% outname = 't5_2017_10_25_13_15_1to3_array1.dat';

% Array 2
% arrayFiles = {...
%     't5.2017.10.25/12_cursorTask_Complete_t5_bld(012)013_array2_forSorting.mat';
%     't5.2017.10.25/14_cursorTask_Complete_t5_bld(014)015_array2_forSorting.mat';
%     't5.2017.10.25/datafile001_array2_forSorting.mat';
%     't5.2017.10.25/datafile002_array2_forSorting.mat';
%     't5.2017.10.25/datafile003_array2_forSorting.mat';
%     };
% outname = 't5_2017_10_25_13_15_1to3_array2.dat';

% t8.2017.10.17 (Phonemes and Facial Movements)
% % Array 1
% arrayFiles = {...
%     't8.2017.10.17/datafile001_array1_forSorting.mat';
%     't8.2017.10.17/datafile002_array1_forSorting.mat';
%     't8.2017.10.17/datafile003_array1_forSorting.mat';
%     't8.2017.10.17/datafile004_array1_forSorting.mat';
%     't8.2017.10.17/datafile005_array1_forSorting.mat';
%     't8.2017.10.17/datafile006_array1_forSorting.mat';
%     };
% outname = 't8_2017_10_17_1to6_array1.dat';

% % Array 2
% arrayFiles = {...
%     't8.2017.10.17/datafile001_array2_forSorting.mat';
%     't8.2017.10.17/datafile002_array2_forSorting.mat';
%     't8.2017.10.17/datafile003_array2_forSorting.mat';
%     't8.2017.10.17/datafile004_array2_forSorting.mat';
%     't8.2017.10.17/datafile005_array2_forSorting.mat';
%     't8.2017.10.17/datafile006_array2_forSorting.mat';
%     };
% outname = 't8_2017_10_17_1to6_array2.dat';

% t8.2017.10.18 Words and Movements
% Array 1
% arrayFiles = {...
%     't8.2017.10.18/datafile001_array1_forSorting.mat';
%     't8.2017.10.18/datafile002_array1_forSorting.mat';
%     't8.2017.10.18/datafile003_array1_forSorting.mat';
%     't8.2017.10.18/datafile004_array1_forSorting.mat';
%     't8.2017.10.18/datafile005_array1_forSorting.mat';
%     't8.2017.10.18/datafile006_array1_forSorting.mat';
%     't8.2017.10.18/NSP_ANTERIOR_2017_1018_155221(4)011_array1_forSorting.mat'; % block 11 CL R8
%     't8.2017.10.18/NSP_ANTERIOR_2017_1018_155650(5)012_array1_forSorting.mat'; % block 12 CL R8
%     };
% outname = 't8_2017_10_18_1to6_11to12_array1.dat';

% Array 2
% arrayFiles = {...
%     't8.2017.10.18/datafile001_array2_forSorting.mat';
%     't8.2017.10.18/datafile002_array2_forSorting.mat';
%     't8.2017.10.18/datafile003_array2_forSorting.mat';
%     't8.2017.10.18/datafile004_array2_forSorting.mat';
%     't8.2017.10.18/datafile005_array2_forSorting.mat';
%     't8.2017.10.18/datafile006_array2_forSorting.mat';
%     't8.2017.10.18/NSP_POSTERIOR_2017_1018_155221(4)011_array2_forSorting.mat'; % block 11 CL R8
%     't8.2017.10.18/NSP_POSTERIOR_2017_1018_155650(5)012_array2_forSorting.mat'; % block 12 CL R8
%     };
% outname = 't8_2017_10_18_1to6_11to12_array2.dat';


% t5.2018.10.24 (Breathing)

% Array 1
% arrayFiles = {...
%     't5.2018.10.24/block_0_array1_forSorting.mat';
%     't5.2018.10.24/block_1_array1_forSorting.mat';
%     't5.2018.10.24/block_2_array1_forSorting.mat';
% };
% outname = 't5_2018_10_24_B0_1_2_array1.dat';

% Array 1
% arrayFiles = {...
%     't5.2018.10.24/block_0_array1_forSorting.mat';
%     't5.2018.10.24/block_1_array1_forSorting.mat';
%     't5.2018.10.24/block_2_array1_forSorting.mat';
%     't5.2018.10.24/block_3_array1_forSorting.mat';
%     't5.2018.10.24/block_4_array1_forSorting.mat';
%     't5.2018.10.24/block_5_array1_forSorting.mat';
%     't5.2018.10.24/block_6_array1_forSorting.mat';
%     't5.2018.10.24/block_passive_array1_forSorting.mat';
%     't5.2018.10.24/block_9_array1_forSorting.mat';
%     't5.2018.10.24/block_10_array1_forSorting.mat';
%     't5.2018.10.24/block_11_array1_forSorting.mat';
%     't5.2018.10.24/block_12_array1_forSorting.mat';
%     't5.2018.10.24/block_13_array1_forSorting.mat';
%     't5.2018.10.24/block_14_array1_forSorting.mat';
%     't5.2018.10.24/block_15_array1_forSorting.mat';
%     't5.2018.10.24/block_16_array1_forSorting.mat';
%     't5.2018.10.24/block_17_array1_forSorting.mat';
%     't5.2018.10.24/block_18_array1_forSorting.mat';
%     't5.2018.10.24/block_19_array1_forSorting.mat';
%     't5.2018.10.24/block_20_array1_forSorting.mat';
%     't5.2018.10.24/block_21_array1_forSorting.mat';
%     't5.2018.10.24/block_22_array1_forSorting.mat';
%     't5.2018.10.24/block_23_array1_forSorting.mat';
%     };
% outname = 't5_2018_10_24_array1.dat';

% Array 2
arrayFiles = {...
    't5.2018.10.24/block_0_array2_forSorting.mat';
    't5.2018.10.24/block_1_array2_forSorting.mat';
    't5.2018.10.24/block_2_array2_forSorting.mat';
    't5.2018.10.24/block_3_array2_forSorting.mat';
    't5.2018.10.24/block_4_array2_forSorting.mat';
    't5.2018.10.24/block_5_array2_forSorting.mat';
    't5.2018.10.24/block_6_array2_forSorting.mat';
    't5.2018.10.24/block_passive_array2_forSorting.mat';
    't5.2018.10.24/block_9_array2_forSorting.mat';
    't5.2018.10.24/block_10_array2_forSorting.mat';
    't5.2018.10.24/block_11_array2_forSorting.mat';
    't5.2018.10.24/block_12_array2_forSorting.mat';
    't5.2018.10.24/block_13_array2_forSorting.mat';
    't5.2018.10.24/block_14_array2_forSorting.mat';
    't5.2018.10.24/block_15_array2_forSorting.mat';
    't5.2018.10.24/block_16_array2_forSorting.mat';
    't5.2018.10.24/block_17_array2_forSorting.mat';
    't5.2018.10.24/block_18_array2_forSorting.mat';
    't5.2018.10.24/block_19_array2_forSorting.mat';
    't5.2018.10.24/block_20_array2_forSorting.mat';
    't5.2018.10.24/block_21_array2_forSorting.mat';
    't5.2018.10.24/block_22_array2_forSorting.mat';
    't5.2018.10.24/block_23_array2_forSorting.mat';
    };
outname = 't5_2018_10_24_array2.dat';

% Array 2
% arrayFiles = {...
%     't5.2018.10.24/block_0_array2_forSorting.mat';
%     't5.2018.10.24/block_1_array2_forSorting.mat';
%     't5.2018.10.24/block_2_array2_forSorting.mat';
% };
% outname = 't5_2018_10_24_B0_1_2_array2.dat';

% % isolate where I think noise is
% arrayFiles = {...
%     't5.2018.10.24/block_3_array2_forSorting.mat';
% };
% outname = 't5_2018_10_24_B3_array2.dat';

% arrayFiles = {...
%     't5.2018.10.24/block_0_array2_forSorting.mat';
%     't5.2018.10.24/block_1_array2_forSorting.mat';
%     't5.2018.10.24/block_2_array2_forSorting.mat';
%     't5.2018.10.24/block_3_array2_forSorting.mat';
%     't5.2018.10.24/block_4_array2_forSorting.mat';
%     't5.2018.10.24/block_5_array2_forSorting.mat';
%     't5.2018.10.24/block_6_array2_forSorting.mat';
%     't5.2018.10.24/block_passive_array2_forSorting.mat';
%     };
% outname = 't5_2018_10_24_array2_noCAR.dat';


% arrayFiles = {...
%     't5.2018.10.24/block_0_array1_forSorting.mat';
%     't5.2018.10.24/block_1_array1_forSorting.mat';
%     't5.2018.10.24/block_2_array1_forSorting.mat';
%     't5.2018.10.24/block_3_array1_forSorting.mat';
%     't5.2018.10.24/block_4_array1_forSorting.mat';
%     't5.2018.10.24/block_5_array1_forSorting.mat';
%     't5.2018.10.24/block_6_array1_forSorting.mat';
%     't5.2018.10.24/block_passive_array1_forSorting.mat';
%     };
% outname = 't5_2018_10_24_array1_noCAR.dat';


%%
outList = {};
for i = 1 : numel( arrayFiles )
    outList{i,1} = [rawDir arrayFiles{i}];    
end


%%
fprintf('Will call bunchOfMATfilesToMDA on %i files to generate %s\n', ...
    numel( outList ), outname );
[fname, rollovers] = bunchOfMATfilesToDAT( outList, [rawDir outname]);
rolloverFilename = regexprep( [rawDir 'rollovers-' outname], '.dat', '.mat');
save( rolloverFilename, 'rollovers' );
fprintf('Saved rollovers to %s\n', rolloverFilename);






%% electrode geometry file
% It's the same for all four arrays in T5 and T8, so just one is needed
% emap = arrayMapHumans( 'T5_lateral' );
% geometryFile = utahChannelMapToKSgeometryMAT( emap, [rawDir/'humanGeom.mat']);


