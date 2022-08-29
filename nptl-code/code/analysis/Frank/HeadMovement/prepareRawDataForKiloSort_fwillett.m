% Script that points bunchOfMATfilesToDAT to the right files.
% The .dat files can be fed into KiloSort or Plexon Offline Sorter.
%
% Sergey D. Stavisky, 18 March 2018, Stanford Neural Prosthetics
% Translational Laboratory

% These were created by trialifySpeechBlock.m after CAR
% OR by singleNS5toFilteredForSorting.m
clear
rawDir = '/net/home/fwillett/movementSweepSorting/';
addpath(genpath('/net/home/fwillett/nptlBrainGateRig/code'))
addpath(genpath('/net/home/fwillett/nptlBrainGateRig/code/analysis/Sergey'))
    
excludeZeroChans = false;

% t5.2018.12.05
% Array 1
% arrayFiles = {...
% 't5.2018.12.05/1_movementCueTask_Complete_t5_bld(001)002_array1_forSorting.mat';
% 't5.2018.12.05/2_movementCueTask_Complete_t5_bld(002)003_array1_forSorting.mat';
% 't5.2018.12.05/3_movementCueTask_Complete_t5_bld(003)004_array1_forSorting.mat';
% 't5.2018.12.05/4_movementCueTask_Complete_t5_bld(004)005_array1_forSorting.mat';
% 't5.2018.12.05/5_movementCueTask_Complete_t5_bld(005)006_array1_forSorting.mat';
% 't5.2018.12.05/6_movementCueTask_Complete_t5_bld(006)007_array1_forSorting.mat';
% 't5.2018.12.05/7_movementCueTask_Complete_t5_bld(007)008_array1_forSorting.mat';
% 't5.2018.12.05/8_movementCueTask_Complete_t5_bld(008)009_array1_forSorting.mat';
% 't5.2018.12.05/9_movementCueTask_Complete_t5_bld(009)010_array1_forSorting.mat';
% 't5.2018.12.05/10_movementCueTask_Complete_t5_bld(010)011_array1_forSorting.mat';
%      };
% outname = 't5_2018_12_05_1to10_array1.dat';

% Array 2
arrayFiles = {...
't5.2018.12.05/1_movementCueTask_Complete_t5_bld(001)002_array2_forSorting.mat';
't5.2018.12.05/2_movementCueTask_Complete_t5_bld(002)003_array2_forSorting.mat';
't5.2018.12.05/3_movementCueTask_Complete_t5_bld(003)004_array2_forSorting.mat';
't5.2018.12.05/4_movementCueTask_Complete_t5_bld(004)005_array2_forSorting.mat';
't5.2018.12.05/5_movementCueTask_Complete_t5_bld(005)006_array2_forSorting.mat';
't5.2018.12.05/6_movementCueTask_Complete_t5_bld(006)007_array2_forSorting.mat';
't5.2018.12.05/7_movementCueTask_Complete_t5_bld(007)008_array2_forSorting.mat';
't5.2018.12.05/8_movementCueTask_Complete_t5_bld(008)009_array2_forSorting.mat';
't5.2018.12.05/9_movementCueTask_Complete_t5_bld(009)010_array2_forSorting.mat';
't5.2018.12.05/10_movementCueTask_Complete_t5_bld(010)011_array2_forSorting.mat';
     };
outname = 't5_2018_12_05_1to10_array2.dat';

% t5.2018.10.22
% Array 1
% arrayFiles = {...
% 't5.2018.10.22/5_movementCueTask_Complete_t5_bld(005)006_array1_forSorting.mat';
% 't5.2018.10.22/6_movementCueTask_Complete_t5_bld(006)007_array1_forSorting.mat';
% 't5.2018.10.22/7_movementCueTask_Complete_t5_bld(007)008_array1_forSorting.mat';
% 't5.2018.10.22/8_movementCueTask_Complete_t5_bld(008)009_array1_forSorting.mat';
% 't5.2018.10.22/9_movementCueTask_Complete_t5_bld(009)010_array1_forSorting.mat';
% 't5.2018.10.22/10_movementCueTask_Complete_t5_bld(010)011_array1_forSorting.mat';
% 't5.2018.10.22/11_movementCueTask_Complete_t5_bld(011)012_array1_forSorting.mat';
% 't5.2018.10.22/12_movementCueTask_Complete_t5_bld(012)013_array1_forSorting.mat';
% 't5.2018.10.22/13_movementCueTask_Complete_t5_bld(013)014_array1_forSorting.mat';  
% 't5.2018.10.22/14_movementCueTask_Complete_t5_bld(014)015_array1_forSorting.mat';  
% 't5.2018.10.22/15_movementCueTask_Complete_t5_bld(015)016_array1_forSorting.mat';  
% 't5.2018.10.22/16_movementCueTask_Complete_t5_bld(016)017_array1_forSorting.mat';  
% 't5.2018.10.22/17_movementCueTask_Complete_t5_bld(017)018_array1_forSorting.mat';  
% 't5.2018.10.22/18_movementCueTask_Complete_t5_bld(018)019_array1_forSorting.mat';
% 't5.2018.10.22/19_movementCueTask_Complete_t5_bld(019)020_array1_forSorting.mat';
% 't5.2018.10.22/20_movementCueTask_Complete_t5_bld(020)021_array1_forSorting.mat';
%     };
% outname = 't5_2018_10_22_4to19_array1.dat';

% t5.2018.10.22
% Array 1
% arrayFiles = {...
% 't5.2018.10.22/5_movementCueTask_Complete_t5_bld(005)006_array2_forSorting.mat';
% 't5.2018.10.22/6_movementCueTask_Complete_t5_bld(006)007_array2_forSorting.mat';
% 't5.2018.10.22/7_movementCueTask_Complete_t5_bld(007)008_array2_forSorting.mat';
% 't5.2018.10.22/8_movementCueTask_Complete_t5_bld(008)009_array2_forSorting.mat';
% 't5.2018.10.22/9_movementCueTask_Complete_t5_bld(009)010_array2_forSorting.mat';
% 't5.2018.10.22/10_movementCueTask_Complete_t5_bld(010)011_array2_forSorting.mat';
% 't5.2018.10.22/11_movementCueTask_Complete_t5_bld(011)012_array2_forSorting.mat';
% 't5.2018.10.22/12_movementCueTask_Complete_t5_bld(012)013_array2_forSorting.mat';
% 't5.2018.10.22/13_movementCueTask_Complete_t5_bld(013)014_array2_forSorting.mat';
% 't5.2018.10.22/14_movementCueTask_Complete_t5_bld(014)015_array2_forSorting.mat';
% 't5.2018.10.22/15_movementCueTask_Complete_t5_bld(015)016_array2_forSorting.mat';
% 't5.2018.10.22/16_movementCueTask_Complete_t5_bld(016)017_array2_forSorting.mat';
% 't5.2018.10.22/17_movementCueTask_Complete_t5_bld(017)018_array2_forSorting.mat';
% 't5.2018.10.22/18_movementCueTask_Complete_t5_bld(018)019_array2_forSorting.mat';
% 't5.2018.10.22/19_movementCueTask_Complete_t5_bld(019)020_array2_forSorting.mat';
% 't5.2018.10.22/20_movementCueTask_Complete_t5_bld(020)021_array2_forSorting.mat';
%      };
% outname = 't5_2018_10_22_4to19_array2.dat';

% t7.2013.08.23
% Array 1
% arrayFiles = {...
%    't7.2013.08.23/NSP_LATERAL_2013_0823_165406(4)002_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_170048(6)004_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_170439(8)006_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_170905(9)007_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_171335(10)008_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_171729(11)009_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_172048(12)010_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_172743(13)011_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_173114(14)012_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_173425(15)013_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_173714(16)014_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_173943(17)015_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_174229(18)016_array1_forSorting.mat';
%    't7.2013.08.23/NSP_LATERAL_2013_0823_174522(19)017_array1_forSorting.mat';
%     };
% outname = 't7_2013_08_23_4to19_array1.dat';

% t7.2013.08.23
% Array 1
% arrayFiles = {...
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_165349(4)004_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_170032(6)006_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_170422(8)008_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_170849(9)009_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_171319(10)010_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_171713(11)011_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_172031(12)012_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_172726(13)013_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_173057(14)014_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_173409(15)015_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_173657(16)016_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_173927(17)017_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_174213(18)018_array2_forSorting.mat';
%    't7.2013.08.23/NSP_MEDIAL_2013_0823_174506(19)019_array2_forSorting.mat';
%     };
% outname = 't7_2013_08_23_4to19_array2.dat';

% t7.2013.08.23 (Phonemes and Facial Movements)
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
%    't5.2017.10.25/12_cursorTask_Complete_t5_bld(012)013_array1_forSorting.mat';
%    't5.2017.10.25/14_cursorTask_Complete_t5_bld(014)015_array1_forSorting.mat';
%    't5.2017.10.25/datafile001_array1_forSorting.mat';
%    't5.2017.10.25/datafile002_array1_forSorting.mat';
%    't5.2017.10.25/datafile003_array1_forSorting.mat';
%    };
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


