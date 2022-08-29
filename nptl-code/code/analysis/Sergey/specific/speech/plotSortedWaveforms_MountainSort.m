% Script that takes output of MountainLab sorting and plots waveforms.
%
% Sergey D. Stavisky, 23 March 2018, Stanford Neural Prosthetics
% Translational Laboratory

% These were created by MountainSort.m 
mdaDir = '/net/derivative/user/sstavisk/Results/speech/rawForSorting/';
% These were created by trialifySpeechBlock.m after CAR, and are where the
% arrayFiles below live.
rawDir = '/net/derivative/user/sstavisk/Results/speech/rawForSorting/';

rng(1);

% t5.2017.10.23 (Phonemes and Facial Movements)
% Array 1
% mdaFile = 'firings_t5_2017_10_23_1to6_array1_c_curated.mda'; % sorted via MountainSort
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
% mdaFile = 'firings_t5_2017_10_23_1to6_array2_c_curated.mda'; % sorted via MountainSort
% rolloversFile = 'rollovers-t5_2017_10_23_1to6_array2.mat';
% arrayFiles = {...
%     't5.2017.10.23/datafile001_array2_forSorting.mat';
%     't5.2017.10.23/datafile002_array2_forSorting.mat';
%     't5.2017.10.23/datafile003_array2_forSorting.mat';
%     't5.2017.10.23/datafile004_array2_forSorting.mat';
%     't5.2017.10.23/datafile005_array2_forSorting.mat';
%     't5.2017.10.23/datafile006_array2_forSorting.mat';
%     };


% t8.2017.10.17 (Phonemes and Facial Movements)
% Array 1
% mdaFile = 'firings_t8_2017_10_17_1to6_array1_c.mda'; % sorted via MountainSort
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
mdaFile = 'firings_t8_2017_10_17_1to6_array2_c.mda'; % sorted via MountainSort
rolloversFile = 'rollovers-t8_2017_10_17_1to6_array2.mat';
arrayFiles = {...
    't8.2017.10.17/datafile001_array2_forSorting.mat';
    't8.2017.10.17/datafile002_array2_forSorting.mat';
    't8.2017.10.17/datafile003_array2_forSorting.mat';
    't8.2017.10.17/datafile004_array2_forSorting.mat';
    't8.2017.10.17/datafile005_array2_forSorting.mat';
    't8.2017.10.17/datafile006_array2_forSorting.mat';
    };


mlPath = '/net/home/sstavisk/mountainlab/matlab';
Fs = 30000; % sampling rate of data; just used for some display outputs, not critical.
addpath( genpath( mlPath ) );


% Note about how I deal with spieks that land during a rollover from .nsx
% files; I just grab the pre-rollover snippet and ignore the rest. Why
% these are sorted to begin with is an interesting question, so I keep
% count of how many there are.


%% Plotting choices
snippetsToPlot = 1000;
samplesEachSnippet = [16 32]; % dividied into before/after event
% numCols = 6; % how many columns to plot in
numCols = 8; % how many columns to plot in

colors = [1 0 0; % for multiple units per electrode
          0 1 0;
          0 0 1;
          1 1 0;
          0 1 0;
          1 0 1;
         .5 1 1];
      

%% Load the mda
mda = readmda( [mdaDir mdaFile] );
% row 1 is channel
% row 2 is sample index
% row 3 unit ID (note these don't go 1 to x because of how MountainSort numbers units)
spikes.channels = mda(1,:)';
spikes.sample = mda(2,:)';
spikes.MSid = mda(3,:)';

% Group by unit
uniqueMSid = unique( spikes.MSid );
fprintf('%s:\n', mdaFile );
for iUnit = 1 : numel( uniqueMSid )
   myMSid =  uniqueMSid(iUnit);
   myEventsInd = find( spikes.MSid == myMSid );
   myChannel = spikes.channels(myEventsInd);
   spikes.samplesEachUnit{iUnit} = spikes.sample(myEventsInd);
   spikes.channelEachUnit{iUnit} = unique( myChannel );
   % Report how many spikes per unit
   fprintf('  Unit %i/%i (MS id %i): %i spikes on channels %s\n', ...
      iUnit, numel( uniqueMSid ), myMSid, numel( spikes.samplesEachUnit{iUnit} ), ...
      mat2str( spikes.channelEachUnit{iUnit} ) );
end
fprintf('\n');


%% Load in (CAR, filtered) raw data and get snippets.
numRolloverSpikes = zeros( numel( uniqueMSid ),1 ); % where the spike was cut off either at start or end of a file
in = load( [rawDir rolloversFile] );
rollovers = in.rollovers;
numArrayFiles = numel( arrayFiles );

waveforms = nan( numel( uniqueMSid ), snippetsToPlot, sum( samplesEachSnippet ) );  % unit x spike x sample
waveformsPointers = ones( numel( uniqueMSid ), 1 ); % tracks which waveform to fill next

% determine how many waveforms of each unit to plot from each array file.
plotEachFile = {};
for iUnit = 1 : numel( uniqueMSid )
    plotTotal = min( snippetsToPlot, numel( spikes.samplesEachUnit{iUnit} ) );
    plotEachFile{iUnit} = [ 0 repmat( floor( plotTotal / numArrayFiles ) , 1, numArrayFiles-1 ) ];
    plotEachFile{iUnit}(1,1) = plotTotal - sum( plotEachFile{iUnit} ); % first file gets most
end

% Load each file in turn
for iFile = 1 : numArrayFiles
    fprintf('Loading %s...\n', [rawDir arrayFiles{iFile}] );    
    in = load( [rawDir arrayFiles{iFile}] );    
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
    for iUnit = 1 : numel( uniqueMSid )
        myChan = spikes.channelEachUnit{iUnit};
        fprintf('%i ', iUnit)
        % what are my spike events that are within this file?
        myEvents = spikes.samplesEachUnit{iUnit}(spikes.samplesEachUnit{iUnit}>=startSampleThisFile & ...
            spikes.samplesEachUnit{iUnit}<= endSampleThisFile);
        if ~isempty( myEvents )
            % choose evenly within these spike events
            myMSinds = myEvents(indexEvenSpaced( numel( myEvents ), plotEachFile{iUnit}(iFile) ));
            % now convert them to indices within THIS FILE
            myMATinds = myMSinds - startSampleThisFile - 1;
            
            % now write each of these into our snippets file
            for iSpike = 1 : numel( myMATinds )
                snippetStart = myMATinds(iSpike)-samplesEachSnippet(1);
                if snippetStart < startSampleThisFile
                    startClipAt = startSampleThisFile - snippetStart;
                    snippetStart =  startSampleThisFile; % protects against start of file
                else
                    startClipAt = 1;
                end
                snippetEnd = min( myMATinds(iSpike)+samplesEachSnippet(2)-1, endSampleThisFile); % protects against rollover
                
                mySnippet = in.nsxDat(snippetStart:snippetEnd,myChan);
                if numel( mySnippet ) < sum( samplesEachSnippet );
                    numRolloverSpikes(iUnit) = numRolloverSpikes(iUnit) + 1;
                end
                waveforms(iUnit,waveformsPointers(iUnit),startClipAt:startClipAt-1+numel(mySnippet)) = mySnippet;
                waveformsPointers(iUnit) = waveformsPointers(iUnit)+1;
            end
        end
    end
    fprintf('\n')
end

%% Plot each unit
% Note that I plot units on the same electrode on the same plot

figh = figure;
uniqueElectrodes = unique( spikes.channels );
axh = nan( numel( uniqueElectrodes ), 1  );
unitsEachAxis = repmat(cell(1),  numel( uniqueMSid ), 1);
titleEachAxis = repmat(cell(1),  numel( uniqueMSid ), 1);
numRows = ceil( numel( uniqueElectrodes ) / numCols );

t = -samplesEachSnippet(1):1:samplesEachSnippet(2)-1;
t = t./Fs; % ms
for iUnit = 1 : numel( uniqueMSid )
    myChan = spikes.channelEachUnit{iUnit};
    myAxisInd = find( uniqueElectrodes == myChan );
    
    
    if isnan( axh( myAxisInd ) )
        axh(myAxisInd) = subplot( numRows, numCols, myAxisInd );
        set( axh(myAxisInd), 'TickDir', 'out' )
        box off;
        hold on;
        xlim( [t(1) t(end)] );
    end
    
    unitsEachAxis{myAxisInd}(end+1) = iUnit; % in 1 : N, NOT mountainsort ID
    % some information about this unit
    myRate = numel( spikes.samplesEachUnit{iUnit} ) / (rollovers(end)/Fs);
    titleEachAxis{myAxisInd}{end+1} = sprintf('e%iu%i %.2fHz', myChan, iUnit, myRate );
    
    
    % plot my traces     
    myy = squeeze( waveforms(iUnit,1:waveformsPointers(iUnit)-1,:) );
    myt = repmat( t, size( myy, 1 ), 1 );
    ph = plot( myt', myy', 'LineWidth', 0.5, ...
        'Color', colors( numel(  unitsEachAxis{myAxisInd} ), : ) );
    meanTrace = nanmean( myy );
    plot( t, meanTrace, 'LineWidth', 2, ...
        'Color', 0.8.*colors( numel(  unitsEachAxis{myAxisInd} ), : ) )
    
    title( titleEachAxis{myAxisInd} )
end
% save figure
titlestr = sprintf('Sorted Waveforms %s', mdaFile );
figh.Name = titlestr;
ExportFig( figh, [mdaDir titlestr] );


