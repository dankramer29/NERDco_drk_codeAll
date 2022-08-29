% Script that points my mountainlab preparation script to the right files.
%
% Sergey D. Stavisky, 18 March 2018, Stanford Neural Prosthetics
% Translational Laboratory

% These were created by trialifySpeechBlock.m after CAR
rawDir = '/net/derivative/user/sstavisk/Results/speech/rawForSorting/';


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
% outname = 't5_2017_10_23_1to6_array1.mda';


% Array 2
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array2_forSorting.mat';
%     't5.2017.10.23/datafile002_array2_forSorting.mat';
%     't5.2017.10.23/datafile003_array2_forSorting.mat';
%     't5.2017.10.23/datafile004_array2_forSorting.mat';
%     't5.2017.10.23/datafile005_array2_forSorting.mat';
%     't5.2017.10.23/datafile006_array2_forSorting.mat';
%     };
% outname = 't5_2017_10_23_1to6_array2.mda';

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
% outname = 't5_2017_10_23_1to6_array1.mda';


% Array 2
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array2_forSorting.mat';
%     't5.2017.10.23/datafile002_array2_forSorting.mat';
%     't5.2017.10.23/datafile003_array2_forSorting.mat';
%     't5.2017.10.23/datafile004_array2_forSorting.mat';
%     't5.2017.10.23/datafile005_array2_forSorting.mat';
%     't5.2017.10.23/datafile006_array2_forSorting.mat';
%     };
% outname = 't5_2017_10_23_1to6_array2.mda';

% t5.2017.10.25 (Words)
% Array 1
% arrayFiles = {...
%     't5.2017.10.25/datafile001_array1_forSorting.mat';
%     't5.2017.10.25/datafile002_array1_forSorting.mat';
%     't5.2017.10.25/datafile003_array1_forSorting.mat';
%     };
% outname = 't5_2017_10_25_1to3_array1.mda';

% % Array 2
% arrayFiles = {...
%     't5.2017.10.25/datafile001_array2_forSorting.mat';
%     't5.2017.10.25/datafile002_array2_forSorting.mat';
%     't5.2017.10.25/datafile003_array2_forSorting.mat';
%     };
% outname = 't5_2017_10_25_1to3_array2.mda';

% t8.2017.10.17 (Phonemes and Facial Movements)
% Array 1
arrayFiles = {...
    't8.2017.10.17/datafile001_array1_forSorting.mat';
    't8.2017.10.17/datafile002_array1_forSorting.mat';
    't8.2017.10.17/datafile003_array1_forSorting.mat';
    't8.2017.10.17/datafile004_array1_forSorting.mat';
    't8.2017.10.17/datafile005_array1_forSorting.mat';
    't8.2017.10.17/datafile006_array1_forSorting.mat';
    };
outname = 't8_2017_10_17_1to6_array1.mda';

% % Array 2
% arrayFiles = {...
%     't8.2017.10.17/datafile001_array2_forSorting.mat';
%     't8.2017.10.17/datafile002_array2_forSorting.mat';
%     't8.2017.10.17/datafile003_array2_forSorting.mat';
%     't8.2017.10.17/datafile004_array2_forSorting.mat';
%     't8.2017.10.17/datafile005_array2_forSorting.mat';
%     't8.2017.10.17/datafile006_array2_forSorting.mat';
%     };
% outname = 't8_2017_10_17_1to6_array2.mda';

% t8.2017.10.18 Words and Movements
% % Array 1
% arrayFiles = {...
%     't8.2017.10.18/datafile001_array1_forSorting.mat';
%     't8.2017.10.18/datafile002_array1_forSorting.mat';
%     't8.2017.10.18/datafile003_array1_forSorting.mat';
%     't8.2017.10.18/datafile004_array1_forSorting.mat';
%     't8.2017.10.18/datafile005_array1_forSorting.mat';
%     't8.2017.10.18/datafile006_array1_forSorting.mat';
%     };
% outname = 't8_2017_10_18_1to6_array1.mda';

% Array 2
% arrayFiles = {...
%     't8.2017.10.18/datafile001_array2_forSorting.mat';
%     't8.2017.10.18/datafile002_array2_forSorting.mat';
%     't8.2017.10.18/datafile003_array2_forSorting.mat';
%     't8.2017.10.18/datafile004_array2_forSorting.mat';
%     't8.2017.10.18/datafile005_array2_forSorting.mat';
%     't8.2017.10.18/datafile006_array2_forSorting.mat';
%     };
% outname = 't8_2017_10_18_1to6_array2.mda';




%%
outList = {};
for i = 1 : numel( arrayFiles )
    outList{i,1} = [rawDir arrayFiles{i}];    
end


%%
fprintf('Will call bunchOfMATfilesToMDA on %i files to generate %s\n', ...
    numel( outList ), outname );
[fname, rollovers] = bunchOfMATfilesToMDA( outList, [rawDir outname], 'excludeZeroChans', excludeZeroChans );
rolloverFilename = regexprep( [rawDir 'rollovers-' outname], '.mda', '.mat');
save( rolloverFilename, 'rollovers' );
fprintf('Saved rollovers to %s\n', rolloverFilename);






%% electrode geometry file
% It's the same for all four arrays in T5 and T8, so just one is needed
% emap = arrayMapHumans( 'T5_lateral' );
% geometryFile = utahChannelMapToMSgeometryCSV( emap, '/Users/sstavisk/Documents/Virtual Machines.localized/sharedWithVMandMac/humanGeom.csv');
