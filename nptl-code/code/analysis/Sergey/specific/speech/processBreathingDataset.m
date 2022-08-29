% Takes the raw data collected during breathing dataset, and
% processes them into more manageable data files:
% 1) *_audio.mat, containing the audio recording of the session (30ksps).
%    (will actually be used for breathing sensor)
% 2) *_spikes.mat, containing the minAcausalSpikeBand data at 1 ms
% resolution. This is obtained after common average referencing within each 
% array and the spikes_medium acasal filter. File also contains the RMS value 
% for the block.
% 3) *_HLFP.mat, containing the high frequency LFP at 1 ms resolution. CAR
% is NOT done before extracting HLFP, as per my 2018 EMBC proceeding and 
% the full length manuscript.
%
% Adapted from processContinuousSpeakingDataset.
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory,
% 9 Novemebr 2018

clear

%% Parameters of how to process data
% Spike band data 
params.spikeBand.getSpikeBand = true;
params.spikeBand.filterType = 'spikesmediumfiltfilt'; % these are names of NPTL codebase filters
params.spikeBand.commonAverageReference = true; % done within each array.

params.spikeBand.saveForSorting = true; % if true will save CAR  and filtered for downstream spike sorting

% HLFP band
params.hlfpBand.getHlfpBand = false;
params.hlfpBand.Fs = 1000; % what to downsample HLFP to
params.hlfpBand.featureName = 'lfpPow_125to5000_1ms'; % uses existing AddFeature code with this input


warnIfRecordingsXsecondsApart = 10; % different arrays' files shouldn't be more than this many s apart
CHANSPERARRAY = 96;
%% Point at raw data
datasetName = 't5.2018.10.24';
params.spikeBand.saveFilteredForSortingPath = [ResultsRootNPTL '/speech/rawForSorting/' datasetName '/']; 

params.audioChannel = 'c:99'; % has the breath sensor on it
params.arrayContainingAudio = 1; % which of the arrays actually has the audio channel
params.nsxChannel = 'c:01:96'; % use 'c' instead of 'e' because we don't use a .ccf that will map channels to electrodes

numArrays = 2;
% 
% These are the free breathing blocks
% will be used to name resulting files
% blockNames = {...
%     'block_0'; % OL
%     'block_1'; % OL
%     'block_2'; % CL R8
%     'block_3'; % CL R8
%     'block_4'; % CL Fitts
%     'block_5'; % CL R8
%     'block_6'; % CL Fitts
%     'block_passive'; % recoridng in the background
%     };
% rawFilesArray{1} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/0_cursorTask_Complete_t5_bld(000)001.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/1_cursorTask_Complete_t5_bld(001)002.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/2_cursorTask_Complete_t5_bld(002)003.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/3_cursorTask_Complete_t5_bld(003)004.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/4_fittsTask_Complete_t5_bld(004)005.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/5_cursorTask_Complete_t5_bld(005)006.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/6_fittsTask_Complete_t5_bld(006)007.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/breath001.ns5';
%     };
% rawFilesArray{2} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/0_cursorTask_Complete_t5_bld(000)001.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/1_cursorTask_Complete_t5_bld(001)002.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/2_cursorTask_Complete_t5_bld(002)003.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/3_cursorTask_Complete_t5_bld(003)004.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/4_fittsTask_Complete_t5_bld(004)005.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/5_cursorTask_Complete_t5_bld(005)006.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/6_fittsTask_Complete_t5_bld(006)007.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/breath001.ns5';
% };

% % Focus on where noise seems to start
% blockNames = {...
%     'block_3';
%     };
% rawFilesArray{1} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/3_cursorTask_Complete_t5_bld(003)004.ns5';
%     };
% rawFilesArray{2} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/3_cursorTask_Complete_t5_bld(003)004.ns5';
% };

% These are the instructed breathing files
% will be used to name resulting files
% blockNames = {...
%     'block_9'; % breathing movements cue
%     'block_10'; %
%     'block_11'; % 
%     'block_12'; % 
%     'block_13'; %
%     'block_14'; %
%     'block_15'; %
%     'block_16'; %
%     'block_17'; %
%     'block_18'; %
%     'block_19'; %
%     'block_20'; %
%     'block_21'; %
%     'block_22'; %
%     'block_23'; %
%     };
% rawFilesArray{1} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/9_movementCueTask_Complete_t5_bld(009)004.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/10_movementCueTask_Complete_t5_bld(010)005.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/11_movementCueTask_Complete_t5_bld(011)006.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/12_movementCueTask_Complete_t5_bld(012)007.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/13_movementCueTask_Complete_t5_bld(013)008.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/14_movementCueTask_Complete_t5_bld(014)009.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/15_movementCueTask_Complete_t5_bld(015)010.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/16_movementCueTask_Complete_t5_bld(016)011.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/17_movementCueTask_Complete_t5_bld(017)012.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/18_movementCueTask_Complete_t5_bld(018)013.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/19_movementCueTask_Complete_t5_bld(019)014.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/20_movementCueTask_Complete_t5_bld(020)015.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/21_movementCueTask_Complete_t5_bld(021)016.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/22_movementCueTask_Complete_t5_bld(022)017.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/23_movementCueTask_Complete_t5_bld(023)018.ns5';
%     };
% rawFilesArray{2} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/9_movementCueTask_Complete_t5_bld(009)004.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/10_movementCueTask_Complete_t5_bld(010)005.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/11_movementCueTask_Complete_t5_bld(011)006.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/12_movementCueTask_Complete_t5_bld(012)007.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/13_movementCueTask_Complete_t5_bld(013)008.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/14_movementCueTask_Complete_t5_bld(014)009.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/15_movementCueTask_Complete_t5_bld(015)010.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/16_movementCueTask_Complete_t5_bld(016)011.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/17_movementCueTask_Complete_t5_bld(017)012.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/18_movementCueTask_Complete_t5_bld(018)013.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/19_movementCueTask_Complete_t5_bld(019)014.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/20_movementCueTask_Complete_t5_bld(020)015.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/21_movementCueTask_Complete_t5_bld(021)016.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/22_movementCueTask_Complete_t5_bld(022)017.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/23_movementCueTask_Complete_t5_bld(023)018.ns5';
% };

%% All combined
% 
% blockNames = {...
%     'block_0'; % OL
%     'block_1'; % OL
%     'block_2'; % CL R8
%     'block_3'; % CL R8
%     'block_4'; % CL Fitts
%     'block_5'; % CL R8
%     'block_6'; % CL Fitts
%     'block_passive'; % recoridng in the background. Up through this block is background breathing
%     'block_9'; % breathing movements cue
%     'block_10'; %
%     'block_11'; % 
%     'block_12'; % 
%     'block_13'; %
%     'block_14'; %
%     'block_15'; %
%     'block_16'; %
%     'block_17'; %
%     'block_18'; %
%     'block_19'; %
%     'block_20'; %
%     'block_21'; %
%     'block_22'; %
%     'block_23'; %
%     };
% rawFilesArray{1} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/0_cursorTask_Complete_t5_bld(000)001.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/1_cursorTask_Complete_t5_bld(001)002.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/2_cursorTask_Complete_t5_bld(002)003.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/3_cursorTask_Complete_t5_bld(003)004.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/4_fittsTask_Complete_t5_bld(004)005.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/5_cursorTask_Complete_t5_bld(005)006.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/6_fittsTask_Complete_t5_bld(006)007.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/breath001.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/9_movementCueTask_Complete_t5_bld(009)004.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/10_movementCueTask_Complete_t5_bld(010)005.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/11_movementCueTask_Complete_t5_bld(011)006.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/12_movementCueTask_Complete_t5_bld(012)007.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/13_movementCueTask_Complete_t5_bld(013)008.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/14_movementCueTask_Complete_t5_bld(014)009.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/15_movementCueTask_Complete_t5_bld(015)010.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/16_movementCueTask_Complete_t5_bld(016)011.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/17_movementCueTask_Complete_t5_bld(017)012.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/18_movementCueTask_Complete_t5_bld(018)013.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/19_movementCueTask_Complete_t5_bld(019)014.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/20_movementCueTask_Complete_t5_bld(020)015.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/21_movementCueTask_Complete_t5_bld(021)016.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/22_movementCueTask_Complete_t5_bld(022)017.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Lateral/NSP Data/23_movementCueTask_Complete_t5_bld(023)018.ns5';
%     };
% rawFilesArray{2} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/0_cursorTask_Complete_t5_bld(000)001.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/1_cursorTask_Complete_t5_bld(001)002.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/2_cursorTask_Complete_t5_bld(002)003.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/3_cursorTask_Complete_t5_bld(003)004.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/4_fittsTask_Complete_t5_bld(004)005.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/5_cursorTask_Complete_t5_bld(005)006.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/6_fittsTask_Complete_t5_bld(006)007.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/breath001.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/9_movementCueTask_Complete_t5_bld(009)004.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/10_movementCueTask_Complete_t5_bld(010)005.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/11_movementCueTask_Complete_t5_bld(011)006.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/12_movementCueTask_Complete_t5_bld(012)007.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/13_movementCueTask_Complete_t5_bld(013)008.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/14_movementCueTask_Complete_t5_bld(014)009.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/15_movementCueTask_Complete_t5_bld(015)010.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/16_movementCueTask_Complete_t5_bld(016)011.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/17_movementCueTask_Complete_t5_bld(017)012.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/18_movementCueTask_Complete_t5_bld(018)013.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/19_movementCueTask_Complete_t5_bld(019)014.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/20_movementCueTask_Complete_t5_bld(020)015.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/21_movementCueTask_Complete_t5_bld(021)016.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/22_movementCueTask_Complete_t5_bld(022)017.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.10.24/Data/_Medial/NSP Data/23_movementCueTask_Complete_t5_bld(023)018.ns5';
% };



%% Where to put the resulting files
% processedDir = [ResultsRootNPTL '/speech/breathing/' datasetName];

mkdir( processedDir )


%%
numBlocks = numel( rawFilesArray{1} );

for iBlock = 1 : numBlocks
    %% AUDIO
    audioin = openNSx( 'read', rawFilesArray{params.arrayContainingAudio}{iBlock}, params.audioChannel ); % audio
    FsRaw = audioin.MetaTags.SamplingFreq;
    % if mulitple subfiles exist, I want the longest one
    [val, subfileInd] = max(  cellfun( @numel, audioin.Data ) );
    fprintf( 'Block %i is %.1fs long, data at Fs = %i.\n', iBlock, val/FsRaw, FsRaw );
    audioDat = audioin.Data{subfileInd}';
    audioTimeStamps_secs = [0 : numel(audioDat)-1] ./ FsRaw;
    % Save the audio file
    audioFilename = sprintf('%s/%s_audio.mat', processedDir, blockNames{iBlock} );
    fprintf('Saving %s...\n', audioFilename )
    save( audioFilename, 'audioDat', 'FsRaw', 'audioTimeStamps_secs' )
    fprintf('DONE\n');
    clear( 'audioIn', 'audioDat', 'audioTimeStamps_secs'  ); % save memory
    
    %% HLFP Data
    if params.hlfpBand.getHlfpBand
        R = struct(); % spoof it as a giant R struct so I can use existing feature adding code.
        % ends up a bit cloodgey but reuse will be good for consistency
        % with previous analyses.
        for iArray = 1 : numArrays
            nsxIn = openNSx( 'read', rawFilesArray{iArray}{iBlock}, params.nsxChannel);
            arrayRecordTime{iArray} =  datenum( nsxIn.MetaTags.DateTimeRaw(1), nsxIn.MetaTags.DateTimeRaw(2), nsxIn.MetaTags.DateTimeRaw(3), ...
                nsxIn.MetaTags.DateTimeRaw(4), nsxIn.MetaTags.DateTimeRaw(5), nsxIn.MetaTags.DateTimeRaw(6) ); % Y, M D, H, Mn, S

            R(1).raw = single( nsxIn.Data{subfileInd} );
            clear('nsxIn');
            % give it a clock
            R(1).counter = 0 : size( R(1).raw, 2 ) - 1;
            R = ConvertToContDat( R, 'raw', 'rate', FsRaw, 'datatype', 'single' );
            % filter 1 channel at a time or else it runs out of memory
            R = rmfield( R, 'raw');
            fprintf('Chan')
            for iChan = 1 : CHANSPERARRAY
                fprintf('%i', iChan );
                R(1).tmpRaw = R(1).rawCont;
                R(1).tmpRaw.channelName = iChan;
                R(1).tmpRaw.dat = R(1).tmpRaw.dat(iChan,:);
                R = AddFeature( R, params.hlfpBand.featureName, ...
                    'sourceSignal', 'tmpRaw', 'outputRate', params.hlfpBand.Fs );
                myHLFP = R(1).(params.hlfpBand.featureName);
                R = rmfield( R, params.hlfpBand.featureName ); % to avoid annoying overwrite warning
                % write this to the filtered data variable
                if iChan == 1
                    HLFPeachArray{iArray} = nan( myHLFP.numSamples, CHANSPERARRAY );
                    HLFPeachArray_t{iArray} = myHLFP.t;
                end
                HLFPeachArray{iArray}(:,iChan) = myHLFP.dat;
            end
            fprintf('\n');
        end
        
        
        % combine the two arrays by trimming down the longer one (which is
        % presumably whichever was shut off last)
        if any( diff( cell2mat( arrayRecordTime ) ) ) > warnIfRecordingsXsecondsApart
            fprintf(2, '[%s] Warning, different NEV files within same block appear have been started many seconds apart. Check %s data?\n', ...
                mfilename, rawFilesArray{iArray}{iBlock} )
        end
        minSamples = min( cellfun( @length, HLFPeachArray_t ) );
        if numArrays == 1
            HLFP_timeStamps_secs = HLFPeachArray_t{1};
            HLFP_dat = HLFPeachArray{1}(1:minSamples,:);
        elseif numArrays == 2
            HLFP_timeStamps_secs = HLFPeachArray_t{1}(1:minSamples);
            HLFP_dat = [HLFPeachArray{1}(1:minSamples,:), HLFPeachArray{2}(1:minSamples,:)];
        else
            keyboard
        end
        FsHLFP = params.hlfpBand.Fs;
        HLFP_feature = params.hlfpBand.featureName;
        
        % Save the HLFP file
        HLFPfilename = sprintf('%s/%s_HLFP.mat', processedDir, blockNames{iBlock} );
        fprintf('Saving %s...\n', HLFPfilename )
        save( HLFPfilename, 'HLFP_dat', 'FsHLFP', 'HLFP_timeStamps_secs', 'HLFP_feature', '-v7.3' )
        fprintf('DONE\n');
        
         % save memory
         clear( 'HLFP_dat', 'HLFPeachArray_t', 'HLFPeachArray', 'R' );    
    end
   
    %% SPIKE BAND
    if params.spikeBand.getSpikeBand
        for iArray = 1 : numArrays
            nsxIn = openNSx( 'read', rawFilesArray{iArray}{iBlock}, params.nsxChannel);
            [val, subfileInd] = max(  cellfun( @numel, nsxIn.Data ) );

            nsxDat = single( nsxIn.Data{subfileInd} )'; % time x channels
            nsxGain = double( nsxIn.ElectrodesInfo(1).MaxDigiValue / nsxIn.ElectrodesInfo(1).MaxAnalogValue );
            clear('nsxIn');
            
            % 1. Common Average Reference
            if params.spikeBand.commonAverageReference
%                 CAR = mean( nsxDat, 2 );
                nsxDat =  nsxDat - repmat( mean( nsxDat, 2 ), 1, size( nsxDat, 2 ) );
            end
            
            % 2. Filter
            switch lower( params.spikeBand.filterType )
                case 'spikesmedium'
                    filt =MediumFilter();
                case 'spikeswide'
                    filt = spikesWideFilter();
                case 'spikesnarrow'
                    filt = spikesNarrowFilter();
                case 'spikesmediumfiltfilt'
                    filt = spikesMediumFilter();
                    useFiltfilt = true;
                case 'none'
                    filt =[];
            end
            if ~isempty(filt)
                if useFiltfilt
                    nsxDat = filtfilthd( filt, nsxDat );
                else
                    % Filter for spike band
                    nsxDat = filt.filter( filt, nsxDat );
                end
            else
                nsxDat = nsxDat;
            end
            
            % already convert to uV, which typically means divide by 4. Do
            % it here or it'll be easy to forget this later.
            nsxDat = nsxDat ./ nsxGain;
            spikeBandUnits = 'uV';
            
            if params.spikeBand.saveForSorting 
                if ~isdir( params.spikeBand.saveFilteredForSortingPath )
                    mkdir( params.spikeBand.saveFilteredForSortingPath );
                end
                filenameForSorting = [params.spikeBand.saveFilteredForSortingPath, ...
                    blockNames{iBlock}, sprintf('_array%i', iArray ) '_forSorting.mat'];
                sourceFile = rawFilesArray{iArray}{iBlock};
                fprintf('Filtering complete, saving for spike sorting... %s', ...
                    filenameForSorting );
                save( filenameForSorting, 'nsxDat', 'params', 'sourceFile', '-v7.3')
                fprintf(' SAVED\n')
            end

            
            % 3. Estimate RMS (of the filtered signal!)
            for iChan = 1 : size( nsxDat, 2 )
                RMSarray{iArray}(iChan) = sqrt( mean( double( nsxDat(:,iChan) ).^2  ) );
            end
            
            % 4. Record just the minimum voltage in each millisecond (dramatic reduction in data size)
            cbSamplesEachMS = (FsRaw/1000); % should be 30
            SBtoKeep = cbSamplesEachMS*floor(size( nsxDat,1 )/cbSamplesEachMS ); % so only complete ms
            minValues{iArray} = zeros(floor(size(nsxDat)./ [cbSamplesEachMS 1]), 'single');
            
            for iChan = 1 : size( nsxDat, 2 )
                % taken from lines 159-177 of broadband2streamMinMax.m
                cspikeband = reshape( nsxDat(1:SBtoKeep,iChan), cbSamplesEachMS, []);
                minValues{iArray}(:,iChan) = min( cspikeband );
            end
            clear( 'nsxDat', 'cspikeband' ); % save memory
        end
        % Combine the two arrays
        minSamples = min( cellfun( @(x) size(x,1), minValues ) );
        FsSpikeBand = 1000;
        spikeBand_timeStamps_secs = [0 : (minSamples -1)] ./ FsSpikeBand;
        if numArrays == 1
            spikeBand_dat = minValues{1}(1:minSamples,:);
            spikeBand_RMS = RMSarray{1};
        elseif numArrays == 2
            spikeBand_dat = [minValues{1}(1:minSamples,:), minValues{2}(1:minSamples,:)];
            spikeBand_RMS = [RMSarray{1}, RMSarray{2}];
        else
            keyboard
        end
        
        % Save the spike band file
        spikeBandFilename = sprintf('%s/%s_spikeBand.mat', processedDir, blockNames{iBlock} );
        fprintf('Saving %s...\n', spikeBandFilename )
        save( spikeBandFilename, 'spikeBand_dat', 'FsSpikeBand', 'spikeBand_timeStamps_secs', 'spikeBand_RMS', '-v7.3' )
        fprintf('DONE\n');
        clear( 'spikeBand_dat' )        % save memory
    end
    
end