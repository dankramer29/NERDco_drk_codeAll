% Assembles raw neural data (specified here) and labeled event times file (prepared
% earlier using soundLabelTool) into a .mat file that has an R-struct like format, which
% will facilitate subsequent analysis. This is used for the fully NSP-saved
% blocks (no xPC), i.e., the cued words speaking task.
% Based on WORKUP_prepareSpeechBlocks.m in the speech project.
%
% Sergey Stavisky, September 18 2017
% Updated February 14, 2019
clear

% Where generated R structs will live:
RstructPathRoot = [ResultsRootNPTL '/speech/Rstructs/'];
mkdir( RstructPathRoot );
%
audioAnnotationPathRoot = [ResultsRootNPTL '/speech/audioAnnotation/'];
annotationPrepend = 'manualLabels_'; 


% Specify list of the raw neural .ns5 files for each block. They should be coordinated
% across the two arrays, by which I mean element 1, 2, 3, ... of each list shoudl correspond to
% blocks 1, 2, 3, ... .



%% T5.2018.12.17 Words and BCI Cursor Control Day 2
% params.syncUsingTimestamp = false; % Sync was fine on this day.

% experiment = 't5.2018.12.17';
% outputFile = [RstructPathRoot 'R_' experiment '-words.mat'];
% audioChannel = 'c:97'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/cuedSpeaking001.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/cuedSpeaking002.ns5';
% };
% rawFilesArray{2} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/cuedSpeaking001.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/cuedSpeaking002.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     1;
%     2;
%     ];


% params.syncUsingTimestamp = false; % Sync was fine on this day.

%% T5.2018.12.17 Words and BCI Cursor Control Day 2
% These are the DURING BCI blocks. I'm generating them from raw .ns5
% (aligned to speech events) in addition to as a cursor task R struct (
% which is done in prepMakeCursorWithSpeechRstructs.m) as a sanit check.
%
experiment = 't5.2018.12.17';
outputFile = [RstructPathRoot 'R_' experiment '-wordsDuringBCI.mat'];
audioChannel = 'c:97'; 
numArrays = 2;
rawFilesArray{1} = { ...
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/8_cursorTask_Complete_t5_bld(008)009.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/9_cursorTask_Complete_t5_bld(009)010.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/10_cursorTask_Complete_t5_bld(010)011.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/11_cursorTask_Complete_t5_bld(011)012.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/13_cursorTask_Complete_t5_bld(013)014.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/16_cursorTask_Complete_t5_bld(016)017.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/17_cursorTask_Complete_t5_bld(017)018.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/18_cursorTask_Complete_t5_bld(018)019.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Lateral/NSP Data/19_cursorTask_Complete_t5_bld(019)020.ns5';
    };

rawFilesArray{2} = { ...
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/8_cursorTask_Complete_t5_bld(008)009.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/9_cursorTask_Complete_t5_bld(009)010.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/10_cursorTask_Complete_t5_bld(010)011.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/11_cursorTask_Complete_t5_bld(011)012.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/13_cursorTask_Complete_t5_bld(013)014.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/16_cursorTask_Complete_t5_bld(016)017.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/17_cursorTask_Complete_t5_bld(017)018.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/18_cursorTask_Complete_t5_bld(018)019.ns5';
    '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.17/Data/_Medial/NSP Data/19_cursorTask_Complete_t5_bld(019)020.ns5';
};
% Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
absoluteBlockNum = [...
    8;
    9;
    10;
    11;
    12;
    13;
    16;
    17;
    18;
    19;
    ];

%% T5.2018.12.12 Words and BCI Cursor Control Day 1
% % NOTE: The sync between NSPs appears to not have worked here. Will try to
% % align by PC1 timestamp
% params.syncUsingTimestamp = true; %
% experiment = 't5.2018.12.12';
% outputFile = [RstructPathRoot 'R_' experiment '-words.mat'];
% audioChannel = 'c:97'; 
% numArrays = 2;
% rawFilesArray{1} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.12/Data/_Lateral/NSP Data/speech_1014.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.12/Data/_Lateral/NSP Data/speech_1015.ns5';
% };
% rawFilesArray{2} = { ...
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.12/Data/_Medial/NSP Data/speech_1014.ns5';
%     '/media/sstavisk/ExtraDrive1/CachedDatasets/t5/t5.2018.12.12/Data/_Medial/NSP Data/speech_1015.ns5';
% };
% % Gives an absolute block number. Useful for ordering based on whether this was phonemes or words.
% absoluteBlockNum = [...
%     13;
%     14;
%     ];



%% Parameters
params.neural.msBeforeCue = 1000; % how many ms back to go before very first cue event
params.neural.msAfterSpeech = 2500; % how many ms after last speech event .
params.neural.msAfterSpeech = 3500; % how many ms after last speech event . % longer for sanity check TMP

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
params.spikeBand.saveFilteredForSortingPath = []; % dont save
% params.spikeBand.saveFilteredForSortingPath = [ResultsRootNPTL '/speech/rawForSorting/' experiment '/']; 


% If true, will get and save 30sps raw into R struct
params.raw.getRaw = false;

% .nev data. Might as well get it though really I'm not likely to ever use this. It might
% be useful for aligning to closed-loop BMI data. 
params.nev.getNevSpikes = true; 

% lfp band
params.lfpBand.getLfpBand = false;
params.lfpBand.Fs = 1000; % what to downsample LFP to
params.lfpBand.filterType = lfpLPF; % < 250 Hz
params.lfpBand.useFiltfilt = true; % slightly more filtering,  no phase delay

% SPIKE SORTING?
params.ss.mergeSpikeSorted = false; 
params.ss.mountainSort = false;
params.ss.plexon = true;
params.ss.rawFs = 30000; % sampling rate used for sorting data.


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
else
    ssort = [];
end


% Trial-ify each block's raw neural stream.
R = [];
for iBlock = 1 : numBlocks
    for iArray = 1 : numArrays
        myNS5files{iArray} = rawFilesArray{iArray}{iBlock};
        myNEVfiles{iArray} = regexprep( rawFilesArray{iArray}{iBlock}, '.ns5', '.nev' );        
        
        if params.ss.mergeSpikeSorted
            myRawBlockNum = rolloverOrder(iBlock);

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

%% save it without raw or NEV-derived spikeRaster
% Rraw = R;
% R = rmfield(R, 'spikeRaster');
% R = rmfield(R, 'spikeRaster2');
% R = rmfield(R, 'raw1');
% R = rmfield(R, 'raw2');
% outputFileNoRaw = strrep( outputFile, '.mat', '_noRaw.mat');
% save( outputFileNoRaw, 'R', 'Rparams', '-v7.3' );
% fprintf('Saved %s with %i trials\n', outputFileNoRaw, numel( R ) );
    
