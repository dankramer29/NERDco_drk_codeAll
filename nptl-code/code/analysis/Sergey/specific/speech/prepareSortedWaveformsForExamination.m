% Script that takes output of Plexon Offline Spike Sorter sorting and saves
% waveforms. It also saves the data so I can do other things with it like
% plot mean +- sem. The results can then be saved and plotted.
%
% Sergey D. Stavisky, 30 March 2018, Stanford Neural Prosthetics
% Translational Laboratory
clear

% These were created by Plexon Offline Sorter
sortedDir = '/net/derivative/user/sstavisk/Results/speech/rawForSorting/';
% These were created by trialifySpeechBlock.m after CAR, and are where the
% arrayFiles below live.
rawDir = '/net/derivative/user/sstavisk/Results/speech/rawForSorting/';

% t5.2017.10.23 (Phonemes and Facial Movements)
% Array 1
% plexonFile = 't5_2017_10_23_1to6_array1.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t5_2017_10_23_1to6_array1.txt';
% rolloversFile = 'rollovers-t5_2017_10_23_1to6_array1.mat';
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array1_forSorting.mat';
%     't5.2017.10.23/datafile002_array1_forSorting.mat';
%     't5.2017.10.23/datafile003_array1_forSorting.mat';
%     't5.2017.10.23/datafile004_array1_forSorting.mat';
%     't5.2017.10.23/datafile005_array1_forSorting.mat';
%     't5.2017.10.23/datafile006_array1_forSorting.mat';
%     };

% Array 2
% plexonFile = 't5_2017_10_23_1to6_array2.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t5_2017_10_23_1to6_array2.txt';
% rolloversFile = 'rollovers-t5_2017_10_23_1to6_array2.mat';
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array2_forSorting.mat';
%     't5.2017.10.23/datafile002_array2_forSorting.mat';
%     't5.2017.10.23/datafile003_array2_forSorting.mat';
%     't5.2017.10.23/datafile004_array2_forSorting.mat';
%     't5.2017.10.23/datafile005_array2_forSorting.mat';
%     't5.2017.10.23/datafile006_array2_forSorting.mat';
%     };


% t5.2017.10.25 (Words and R8)
% Array 1
% plexonFile = 't5_2017_10_25_13_15_1to3_array1.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t5_2017_10_25_13_15_1to3_array1.txt';
% rolloversFile = 'rollovers-t5_2017_10_25_13_15_1to3_array1.mat';
% arrayFiles = {...
%     't5.2017.10.25/12_cursorTask_Complete_t5_bld(012)013_array1_forSorting.mat';
%     't5.2017.10.25/14_cursorTask_Complete_t5_bld(014)015_array1_forSorting.mat';
%     't5.2017.10.25/datafile001_array1_forSorting.mat';
%     't5.2017.10.25/datafile002_array1_forSorting.mat';
%     't5.2017.10.25/datafile003_array1_forSorting.mat';
%     };
% Array 2
% plexonFile = 't5_2017_10_25_13_15_1to3_array2.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t5_2017_10_25_13_15_1to3_array2.txt';
% rolloversFile = 'rollovers-t5_2017_10_25_13_15_1to3_array2.mat';
% arrayFiles = {...
%     't5.2017.10.25/12_cursorTask_Complete_t5_bld(012)013_array2_forSorting.mat';
%     't5.2017.10.25/14_cursorTask_Complete_t5_bld(014)015_array2_forSorting.mat';
%     't5.2017.10.25/datafile001_array2_forSorting.mat';
%     't5.2017.10.25/datafile002_array2_forSorting.mat';
%     't5.2017.10.25/datafile003_array2_forSorting.mat';
%     };



% t8.2017.10.17 (Phonemes and Facial Movements)
% Array 1
% plexonFile = 't8_2017_10_17_1to6_array1.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t8_2017_10_17_1to6_array1.txt';
% rolloversFile = 'rollovers-t8_2017_10_17_1to6_array1.mat';
% arrayFiles = {...
%     't8.2017.10.17/datafile001_array1_forSorting.mat';
%     't8.2017.10.17/datafile002_array1_forSorting.mat';
%     't8.2017.10.17/datafile003_array1_forSorting.mat';
%     't8.2017.10.17/datafile004_array1_forSorting.mat';
%     't8.2017.10.17/datafile005_array1_forSorting.mat';
%     't8.2017.10.17/datafile006_array1_forSorting.mat';
%     };

% Array 2
% plexonFile = 't8_2017_10_17_1to6_array2.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t8_2017_10_17_1to6_array2.txt';
% rolloversFile = 'rollovers-t8_2017_10_17_1to6_array2.mat';
% arrayFiles = {...
%     't8.2017.10.17/datafile001_array2_forSorting.mat';
%     't8.2017.10.17/datafile002_array2_forSorting.mat';
%     't8.2017.10.17/datafile003_array2_forSorting.mat';
%     't8.2017.10.17/datafile004_array2_forSorting.mat';
%     't8.2017.10.17/datafile005_array2_forSorting.mat';
%     't8.2017.10.17/datafile006_array2_forSorting.mat';
%     };


% t8.2017.10.18 (Words and BCI Blocks)
% Array 1
% plexonFile = 't8_2017_10_18_1to6_11to12_array1.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t8_2017_10_18_1to6_11to12_array1.txt';
% rolloversFile = 'rollovers-t8_2017_10_18_1to6_11to12_array1.mat';
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

% Array 2
% plexonFile = 't8_2017_10_18_1to6_11to12_array2.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t8_2017_10_18_1to6_11to12_array2.txt';
% rolloversFile = 'rollovers-t8_2017_10_18_1to6_11to12_array2.mat';
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
% 
% Fs = 30000; % sampling rate of data

% t5.2018.10.24 BREATHING
% Array 1
sortedDir = '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/sorted/';
rawDir = '/media/sstavisk/ExtraDrive1/Results/speech/rawForSorting/';
plexonFile = 't5_2018_10_24_array1.txt'; % sorted via Plexon Offline Sorter
plexonSortQualityFile = 'sortQuality_t5_2018_10_24_array1.txt';
rolloversFile = 'rollovers-t5_2018_10_24_array1.mat';
arrayFiles = {...
    't5.2018.10.24/block_0_array1_forSorting.mat';
    't5.2018.10.24/block_1_array1_forSorting.mat';
    't5.2018.10.24/block_2_array1_forSorting.mat';
    't5.2018.10.24/block_3_array1_forSorting.mat';
    't5.2018.10.24/block_4_array1_forSorting.mat';
    't5.2018.10.24/block_5_array1_forSorting.mat';
    't5.2018.10.24/block_6_array1_forSorting.mat';
    't5.2018.10.24/block_passive_array1_forSorting.mat';
    't5.2018.10.24/block_9_array1_forSorting.mat';
    't5.2018.10.24/block_10_array1_forSorting.mat';
    't5.2018.10.24/block_11_array1_forSorting.mat';
    't5.2018.10.24/block_12_array1_forSorting.mat';
    't5.2018.10.24/block_13_array1_forSorting.mat';
    't5.2018.10.24/block_14_array1_forSorting.mat';
    't5.2018.10.24/block_15_array1_forSorting.mat';
    't5.2018.10.24/block_16_array1_forSorting.mat';
    't5.2018.10.24/block_17_array1_forSorting.mat';
    't5.2018.10.24/block_18_array1_forSorting.mat';
    't5.2018.10.24/block_19_array1_forSorting.mat';
    't5.2018.10.24/block_20_array1_forSorting.mat';
    't5.2018.10.24/block_21_array1_forSorting.mat';
    't5.2018.10.24/block_22_array1_forSorting.mat';
    't5.2018.10.24/block_23_array1_forSorting.mat';
    };


% Array 2
% sortedDir = '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/sorted/';
% rawDir = '/media/sstavisk/ExtraDrive1/Results/speech/rawForSorting/';
% plexonFile = 't5_2018_10_24_array2.txt'; % sorted via Plexon Offline Sorter
% plexonSortQualityFile = 'sortQuality_t5_2018_10_24_array2.txt';
% rolloversFile = 'rollovers-t5_2018_10_24_array2.mat';
% arrayFiles = {...
%     't5.2018.10.24/block_0_array2_forSorting.mat';
%     't5.2018.10.24/block_1_array2_forSorting.mat';
%     't5.2018.10.24/block_2_array2_forSorting.mat';
%     't5.2018.10.24/block_3_array2_forSorting.mat';
%     't5.2018.10.24/block_4_array2_forSorting.mat';
%     't5.2018.10.24/block_5_array2_forSorting.mat';
%     't5.2018.10.24/block_6_array2_forSorting.mat';
%     't5.2018.10.24/block_passive_array2_forSorting.mat';
%     't5.2018.10.24/block_9_array2_forSorting.mat';
%     't5.2018.10.24/block_10_array2_forSorting.mat';
%     't5.2018.10.24/block_11_array2_forSorting.mat';
%     't5.2018.10.24/block_12_array2_forSorting.mat';
%     't5.2018.10.24/block_13_array2_forSorting.mat';
%     't5.2018.10.24/block_14_array2_forSorting.mat';
%     't5.2018.10.24/block_15_array2_forSorting.mat';
%     't5.2018.10.24/block_16_array2_forSorting.mat';
%     't5.2018.10.24/block_17_array2_forSorting.mat';
%     't5.2018.10.24/block_18_array2_forSorting.mat';
%     't5.2018.10.24/block_19_array2_forSorting.mat';
%     't5.2018.10.24/block_20_array2_forSorting.mat';
%     't5.2018.10.24/block_21_array2_forSorting.mat';
%     't5.2018.10.24/block_22_array2_forSorting.mat';
%     't5.2018.10.24/block_23_array2_forSorting.mat';
%     };

Fs = 30000; % sampling rate of data


% Note about how I deal with spieks that land during a rollover from .nsx
% files; I just grab the pre-rollover snippet and ignore the rest. Why
% these are sorted to begin with is an interesting question, so I keep
% count of how many there are.


%% How much data to grab choices
snippetsToPlot = 200;
samplesEachSnippet = [16 32]; % dividied into before/after event


%% Load the text file
plexonDat = readPlexonSortedTextFilesSimple( [sortedDir plexonFile], ...
              'sortQualityFile', [sortedDir plexonSortQualityFile] );
% copy some basic info         
spikes.unitNames = plexonDat.unitIDs;
spikes.file = plexonDat.file;
spikes.unitSortRating = plexonDat.unitSortRating;

% Group by unit
uniqueID  = unique( plexonDat.unit );
fprintf('%s:\n', plexonFile );
for iUnit = 1 : numel( uniqueID  )
   myID =  uniqueID(iUnit);
   myEventsInd = find( plexonDat.unit == myID );
   % convert from seconds in the file to a sample index
   spikes.samplesEachUnit{iUnit} = round( Fs .* plexonDat.eventTimeSeconds(myEventsInd) );
   spikes.channelEachUnit(iUnit) = unique( plexonDat.electrode(myEventsInd) );
   spikes.ISIms{iUnit} = 1000*diff( spikes.samplesEachUnit{iUnit} )./Fs ; % in milliseconds
   % Report how many spikes per unit
   fprintf('  Unit %i/%i (id ''%s'', rating %.1f): %i spikes on channel %i\n', ...
      iUnit, numel( uniqueID  ), spikes.unitNames{iUnit}, spikes.unitSortRating(iUnit), ...
      numel( spikes.samplesEachUnit{iUnit} ), spikes.channelEachUnit(iUnit)  );
end
fprintf('\n');


%% Load in (CAR, filtered) raw data and get snippets.
numRolloverSpikes = zeros( numel( uniqueID  ),1 ); % where the spike was cut off either at start or end of a file
in = load( [rawDir rolloversFile] );
rollovers = in.rollovers;
numArrayFiles = numel( arrayFiles );

waveforms = nan( numel( uniqueID  ), snippetsToPlot, sum( samplesEachSnippet ) );  % unit x spike x sample
waveformsPointers = ones( numel( uniqueID  ), 1 ); % tracks which waveform to fill next
cumRawSamples = 0; % will track overall neural data duration; used to compute Hz rate of each neuron.

% determine how many waveforms of each unit to plot from each array file.
plotEachFile = {};
for iUnit = 1 : numel( uniqueID  )
    plotTotal = min( snippetsToPlot, numel( spikes.samplesEachUnit{iUnit} ) );
    plotEachFile{iUnit} = [ 0 repmat( floor( plotTotal / numArrayFiles ) , 1, numArrayFiles-1 ) ];
    plotEachFile{iUnit}(1,1) = plotTotal - sum( plotEachFile{iUnit} ); % first file gets most
    
    % initialize vectors for cumulative caulcation of mean and std of the
    % waveforms
    cumCount(iUnit) = 0;
    cumMean{iUnit} = zeros( sum( samplesEachSnippet ), 1 );
    cumM2{iUnit} = zeros( sum( samplesEachSnippet ), 1 );
end



% Load each file in turn
for iFile = 1 : numArrayFiles
    fprintf('Loading %s...\n', [rawDir arrayFiles{iFile}] );    
    in = load( [rawDir arrayFiles{iFile}] );    
    numSamplesThisFile = size( in.nsxDat, 1 );
    cumRawSamples = cumRawSamples + numSamplesThisFile;
    % what samples are contained within this file?
    if iFile == 1
        startSampleThisFile = 1;
    else
        startSampleThisFile = rollovers(iFile-1);
    end
    if iFile == numArrayFiles
        endSampleThisFile = rollovers(end) + size( in.nsxDat, 1 );
    else
        endSampleThisFile = rollovers(iFile)-1;
    end
    fprintf('From %i to %i\n',  startSampleThisFile, endSampleThisFile ); % DEV
    
    % go through unit by unit getting the snippets I want
    fprintf('Unit ')
    for iUnit = 1 : numel( uniqueID  )
        myChan = spikes.channelEachUnit(iUnit);
        fprintf('%i ', iUnit)
        % what are my spike events that are within this file?
        myEvents = spikes.samplesEachUnit{iUnit}(spikes.samplesEachUnit{iUnit}>=startSampleThisFile & ...
            spikes.samplesEachUnit{iUnit}<= endSampleThisFile);
        
        % -----------------------------------------------------
        % Running mean and standard deviation of every waveform
        % -----------------------------------------------------
        myMATinds = myEvents - startSampleThisFile - 1;
%         figh = figure; hold on; %  DEV
        for i = 1 : numel( myMATinds )
            snippetStart = myMATinds(i)-samplesEachSnippet(1);
            snippetEnd = myMATinds(i)+samplesEachSnippet(2)-1;
            % ignore rollover waveforms                
            if snippetStart < 1
                continue
            end
            if snippetEnd >= numSamplesThisFile
                continue
            end
            mySnippet = double( in.nsxDat(snippetStart:snippetEnd,myChan) );
            cumCount(iUnit) = cumCount(iUnit) + 1;
            delta = mySnippet - cumMean{iUnit};
            cumMean{iUnit} = cumMean{iUnit} + delta ./ cumCount(iUnit);
            delta2 = mySnippet - cumMean{iUnit};
            cumM2{iUnit} =  cumM2{iUnit} + (delta .* delta2);
        end
        
        % -----------------------------------------------------
        % Store example waveforms for potential later plotting.
        % -----------------------------------------------------
        if ~isempty( myEvents )
            % choose evenly within these spike events
            mySubsampledMATinds = myMATinds(indexEvenSpaced( numel( myMATinds ), plotEachFile{iUnit}(iFile) ));
           
            % now write each of these into our snippets file
            for iSpike = 1 : numel( mySubsampledMATinds )
                snippetStart = mySubsampledMATinds(iSpike)-samplesEachSnippet(1);
                if snippetStart < 1
                    startClipAt = max( -snippetStart, 1 ); % avoids 0
                    snippetStart =  1; % protects against start of file
                else
                    startClipAt = 1;
                end
                snippetEnd = min( mySubsampledMATinds(iSpike)+samplesEachSnippet(2)-1, numSamplesThisFile); % protects against rollover
                
                mySnippet = in.nsxDat(snippetStart:snippetEnd,myChan);
                if numel( mySnippet ) < sum( samplesEachSnippet )
                    numRolloverSpikes(iUnit) = numRolloverSpikes(iUnit) + 1;
                end
                waveforms(iUnit,waveformsPointers(iUnit),startClipAt:startClipAt-1+numel(mySnippet)) = mySnippet;
                waveformsPointers(iUnit) = waveformsPointers(iUnit)+1;
            end
        end
    end
    fprintf('\n')
end

% Finalize running std
for iUnit = 1 :  numel( uniqueID  )
    spikes.meanWaveform{iUnit} = cumMean{iUnit};
    spikes.numSpikes(iUnit) = cumCount(iUnit);
    spikes.stdWaveform{iUnit} = sqrt( cumM2{iUnit} ./ (cumCount(iUnit)-1) );   
end


%% Save output
spikes = rmfield( spikes, 'samplesEachUnit' );
spikes.Fs = Fs;
spikes.snippetsToPlot = snippetsToPlot;
spikes.samplesEachSnippet = samplesEachSnippet;
spikes.totalDataDurationSeconds = cumRawSamples/Fs;

outfile = [sortedDir 'waveforms_' regexprep( plexonFile, '.txt', '.mat')];
save( outfile, 'spikes', 'waveforms' );
fprintf('Saved waveform data to %s\n', outfile )

