% Takes the output of Plexon Offline Spike Sorter, and breaks it down into indivudal block
% spikeRasters files that match the RMS thresholding spikeRasters files used in
% WORKUP_breathTriggeredFiringRates.m
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory, 25 January
% 2019



%% point to where the rasters file is:

% Cell list, one cell for each array
ssTxtFiles = {...
    [CachedDatasetsRootNPTL '/NPTL/t5.2018.10.24_Breathing_Fitts/sorted/t5_2018_10_24_array1.txt'];
    [CachedDatasetsRootNPTL '/NPTL/t5.2018.10.24_Breathing_Fitts/sorted/t5_2018_10_24_array2.txt'];
};
ssSortQualityFiles = {...
    [CachedDatasetsRootNPTL '/NPTL/t5.2018.10.24_Breathing_Fitts/sorted/sortQuality_t5_2018_10_24_array1.txt'];
    [CachedDatasetsRootNPTL '/NPTL/t5.2018.10.24_Breathing_Fitts/sorted/sortQuality_t5_2018_10_24_array2.txt'];
};   
% I need these to chop up the glued-together sample indices from the plexon file back into
% individual blocks.
ssRolloversFiles = {...
    [CachedDatasetsRootNPTL '/NPTL/t5.2018.10.24_Breathing_Fitts/sorted/rollovers-t5_2018_10_24_array1.mat'];
    [CachedDatasetsRootNPTL '/NPTL/t5.2018.10.24_Breathing_Fitts/sorted/rollovers-t5_2018_10_24_array2.mat'];
};
saveToDir = [CachedDatasetsRoot, '/NPTL/t5.2018.10.24_Breathing_Fitts/'];


% it'll put the processed sortedSpikeRasters mat files into the same directory.
% number of block names has to match the number of blocks that are found in rollovers
% (this is clumsy I realize).
blockNames = {...
    'block_0';
    'block_1';
    'block_2';
    'block_3';
    'block_4';
    'block_5';
    'block_6';
    'block_passive';
    'block_9';
    'block_10';
    'block_11';
    'block_12';
    'block_13';
    'block_14';
    'block_15';
    'block_16';
    'block_17';
    'block_18';
    'block_19';
    'block_20';
    'block_21';
    'block_22';
    'block_23';
    };

FsSpikeBand = 1000; % the sampling rate I want things in (ms)


%% Load in the sort file, for each array
FsRaw = 30000; % original sampling ate
sortInfoEachArray = {};
Narrays = numel( ssTxtFiles );
for iArray = 1 : Narrays
    spikes = struct();
    plexonDat = readPlexonSortedTextFilesSimple( ssTxtFiles{iArray}, ...
              'sortQualityFile',  ssSortQualityFiles{iArray} );
   % copy some basic info
   spikes.unitNames = plexonDat.unitIDs;
   spikes.file = plexonDat.file;
   spikes.unitSortRating = plexonDat.unitSortRating;
   
   % Group by unit
   uniqueID  = unique( plexonDat.unit );
   fprintf('%s:\n', ssTxtFiles{iArray} );
   for iUnit = 1 : numel( uniqueID  )
       myID =  uniqueID(iUnit);
       myEventsInd = find( plexonDat.unit == myID );
       % convert from seconds in the file to a sample index
       spikes.samplesEachUnit{iUnit} = round( FsSpikeBand .* plexonDat.eventTimeSeconds(myEventsInd) );
       spikes.channelEachUnit(iUnit) = unique( plexonDat.electrode(myEventsInd) );
       spikes.ISIms{iUnit} = 1000*diff( spikes.samplesEachUnit{iUnit} )./FsSpikeBand ; % in milliseconds
       % Report how many spikes per unit
       fprintf('  Unit %i/%i (id ''%s'', rating %.1f): %i spikes on channel %i\n', ...
           iUnit, numel( uniqueID  ), spikes.unitNames{iUnit}, spikes.unitSortRating(iUnit), ...
           numel( spikes.samplesEachUnit{iUnit} ), spikes.channelEachUnit(iUnit)  );
   end
   in = load( ssRolloversFiles{iArray}, 'rollovers' );
   spikes.rollovers = in.rollovers;
   sortInfoEachArray{iArray} = spikes;  
end

%% Go through block by block, making the spike rasters file
numBlocks = numel( in.rollovers ) + 1;
if numBlocks ~= numel( blockNames )
    error('Number of blocks implicit by rollovers does not match manually entered blockNames list. Please fix' );
end

% how many total units are there? This will determine ms raster matrix size
unitArray = [];
unitChannel = [];
unitSortRating = [];
for iArray = 1 : Narrays    
    unitArray = [unitArray; repmat( iArray, numel( sortInfoEachArray{iArray}.channelEachUnit ), 1 )];
    unitChannel = [unitChannel; sortInfoEachArray{iArray}.channelEachUnit']; 
    unitSortRating = [unitSortRating; sortInfoEachArray{iArray}.unitSortRating];
end
    
    
% Go through block by block and grap its data
for iBlock = 1 : numBlocks
    spikeRasters = struct;
    spikeRasters.FsSpikeBand = FsSpikeBand;
    % what is my starting index?
    if iBlock == 1
        startIndEachBlock = ones(1, Narrays); % recall they don't get shut off at exact same time
    else 
        startIndEachBlock = cellfun( @(x) x.rollovers(iBlock-1), sortInfoEachArray );
    end    
    
    % what is my ending index?    
    % note that it's based on array 1; I'm trimming all array 2 data to match array 1 data.
    if iBlock == 1
        endIndEachBlock = startIndEachBlock + sortInfoEachArray{1}.rollovers(iBlock) - 1;
    elseif iBlock == numBlocks
        % this is a pain, since there's no end to rollovers. Let's build it to max of where data
        % goes plus 10 seconds
        for iArray = 1 : Narrays
            maxSampleMS =  max( cell2mat( reshape( sortInfoEachArray{iArray}.samplesEachUnit, [], 1 ) ) );
            % convert to broadband, subtract rollovers,  add 10 second buffer
            maxSampleMS = (maxSampleMS + 10*FsSpikeBand) * (FsRaw/FsSpikeBand);
            endIndEachBlock(iArray) = maxSampleMS;
        end
    else
        endIndEachBlock = startIndEachBlock + sortInfoEachArray{1}.rollovers(iBlock) - sortInfoEachArray{1}.rollovers(iBlock-1) - 1;
    end
    numSamplesRaw = endIndEachBlock - startIndEachBlock; 
    
    % convert start/end ind into ms (they are in 30k)
    startIndEachBlock = round( startIndEachBlock / (FsRaw/FsSpikeBand) );
    numSamples1k = ceil( numSamplesRaw(1) / (FsRaw/FsSpikeBand) );
    endIndEachBlock = startIndEachBlock + numSamples1k; % this avoids mismatch in lengths due to rounding into different directions on each array
        
    spikeRasters = []; % will be saved

    % Go through each array and build the rasters
    for iArray = 1 : Narrays   
        Nsamples = endIndEachBlock(iArray) - startIndEachBlock(iArray) + 1;
        Nunits = numel( sortInfoEachArray{iArray}.samplesEachUnit ); % this array
        myRasters = false(Nsamples,Nunits);
        
        for iUnit = 1 : Nunits            
            myEvents = sortInfoEachArray{iArray}.samplesEachUnit{iUnit};
            myEvents = myEvents(myEvents >= startIndEachBlock(iArray) & myEvents <= endIndEachBlock(iArray));
            % now convert these indices to start at sample 1
            myEvents = myEvents - startIndEachBlock(iArray);
            % avoid indexing into element 1
            myEvents(myEvents==0)=1; % moves a spike max of 1 ms; tolerable
            
            myRasters(myEvents,iUnit) = true;
        end
        spikeRasters = [spikeRasters, myRasters];
    end
    
    % get the rest of the stuff for this array
    spikeBand_time = [1: size( spikeRasters)] ./ FsSpikeBand; % in seconds
    spikeBand_RMS = nan( numel(unitArray), 1 );
    
    % Save this file
    filename = sprintf('%s%s_sortedSpikeRasters.mat', saveToDir, blockNames{iBlock});
    fprintf('Saving %s...', filename );
    save( filename, 'spikeRasters', 'spikeBand_time', 'spikeBand_RMS', 'unitArray', 'unitChannel', 'unitSortRating',  ...
        'ssTxtFiles', 'ssSortQualityFiles', 'ssRolloversFiles', 'FsSpikeBand' )
    fprintf('OK\n');
end