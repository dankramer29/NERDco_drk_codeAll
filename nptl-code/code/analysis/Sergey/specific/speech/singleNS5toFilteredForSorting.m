% There are .ns5 files from the speech experiment days that aren't read,
% CAR, and spike band filtered by WORKUP_prepareSpeechBlocks.m because
% they come from other non-cued-speech tasks run on those days.
%
% The kinds of blocks that could be processed this way are:
% Caterpillar blocks
% T5 BMI blocks (Stanford code)
% T8 BMI blocks (Case code)
%
% This script gets pointed to one of those blocks, and it processes it and
% generates a .mat with the filtered data, similar to what
% WORKUP_prepareSpeechBlocks.m does. The resulting .mat file can then be
% pointed to in prepareRawDataForKiloSort.m
%
% Sergey Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 1 April 2018
clear

% T5 2017.10.25 BMI Task
experiment = 't5.2017.10.25';
fileList = {...
    '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5';
    '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/14_cursorTask_Complete_t5_bld(014)015.ns5';
    '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5';
    '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/14_cursorTask_Complete_t5_bld(014)015.ns5';
   }; 
    
    
% T8 2018.10.18 BMI Task 
% experiment = 't8.2017.10.18';
% fileList = {...
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/NSP_ANTERIOR_2017_1018_155221(4)011.ns5';
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Lateral/NSP_ANTERIOR_2017_1018_155650(5)012.ns5';
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/NSP_POSTERIOR_2017_1018_155221(4)011.ns5';
%     '/net/experiments/t8/t8.2017.10.18/Data/NSP Data/_Medial/NSP_POSTERIOR_2017_1018_155650(5)012.ns5';
%    }; 


%%
params.nsxChannel = 'c:01:96'; % use 'c' instead of 'e' because we don't use a .ccf that will map channels to electrodes
params.spikeBand.getSpikeBand = true;
params.spikeBand.filterType = 'spikesmediumfiltfilt'; % these are names of NPTL codebase filters
params.spikeBand.commonAverageReference = true; % done within each array.
params.spikeBand.saveFilteredForSortingPath = [ResultsRootNPTL '/speech/rawForSorting/' experiment '/']; 

params.CHANSPERARRAY = 96;



%% Main loop
for iFile = 1 : numel( fileList )
    fprintf('File %i/%i: %s\n', iFile, numel( fileList ), fileList{iFile} );
    % read the nsx file
    nsxIn = openNSx( 'read', fileList{iFile}, params.nsxChannel);
    nsxFs = double( nsxIn.MetaTags.SamplingFreq );
    if numel( nsxIn.Data ) > 2
        warning('%i .nsx data detected in %s, using last one. This OK?', ...
            numel( nsxIn.Data ), fileList{iFile} )
        nsxDat = single( nsxIn.Data{end}' );
    elseif numel( nsxIn.Data ) == 2
        nsxDat = single( nsxIn.Data{2}' );
    else
        warning('Only one .nsx data detected in %s, should be 2. Did Cerebus sync fail?', fileList{iFile})
        nsxDat = single( nsxIn.Data{1}' );
    end
    fprintf('%.2f minutes of data\n', ...
        size( nsxDat, 1 )/nsxFs/60 );
    clear( 'nsxIn' ) % reduce memory load
    
    if params.spikeBand.getSpikeBand        
        % 1. Common Average Reference
        if params.spikeBand.commonAverageReference
            nsxDat =  nsxDat - repmat( mean( nsxDat, 2 ), 1, size( nsxDat, 2 ) );
        end
        
        
        % 2. Filter
        switch lower( params.spikeBand.filterType )
            case 'spikesmedium'
                filt = spikesMediumFilter();
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
            fprintf('Filtering...\n')
            if useFiltfilt
                nsxDat = filtfilthd( filt, nsxDat );
            else
                % Filter for spike band
                nsxDat = filt.filter( filt, nsxDat );
            end
        end
        
        
        % Save this mat file for later use in preparing spike sorting
        % I want to know what array this was; easy hack is to use full path
        % and look for Lateral or Medial
        myArray = 0;
        if strfind( fileList{iFile}, 'Lateral' )
            myArray = 1;
        elseif strfind( fileList{iFile}, 'Medial' )
            myArray = 2;
        end
        if ~myArray
            keyboard
            % huh? Why didn't this work
        end
        
        
        % NOTE: This is where CAR high pass filtered data is saved for later spike-sorting.
        if ~isempty( params.spikeBand.saveFilteredForSortingPath )
            if ~isdir( params.spikeBand.saveFilteredForSortingPath )
                mkdir( params.spikeBand.saveFilteredForSortingPath );
            end
            filenameForSorting = [params.spikeBand.saveFilteredForSortingPath, ...
                regexprep( pathToLastFilesep( fileList{iFile},1 ), '.ns5', ''), ...
                sprintf('_array%i', myArray ) '_forSorting.mat'];
            sourceFile = fileList{iFile};
            fprintf('Filtering complete, saving for spike sorting... %s', ...
                filenameForSorting );
            save( filenameForSorting, 'nsxDat', 'params', 'sourceFile', '-v7.3')
            fprintf(' SAVED\n')
        end
    end


end