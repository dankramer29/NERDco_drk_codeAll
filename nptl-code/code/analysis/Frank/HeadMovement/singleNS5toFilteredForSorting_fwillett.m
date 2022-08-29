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
addpath(genpath('/net/home/fwillett/nptlBrainGateRig/code'))
addpath(genpath('/net/home/fwillett/nptlBrainGateRig/code/analysis/Sergey'))

% blockList = [4 6 8 9 10 11 12 13 14 15 16 17 18 19];
% experiment = 't7.2013.08.23';
% fileList = {...
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_165406(4)002.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_170048(6)004.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_170439(8)006.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_170905(9)007.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_171335(10)008.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_171729(11)009.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_172048(12)010.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_172743(13)011.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_173114(14)012.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_173425(15)013.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_173714(16)014.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_173943(17)015.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_174229(18)016.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Lateral/NSP Data/NSP_LATERAL_2013_0823_174522(19)017.ns5';
%             
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_165349(4)004.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_170032(6)006.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_170422(8)008.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_170849(9)009.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_171319(10)010.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_171713(11)011.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_172031(12)012.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_172726(13)013.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_173057(14)014.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_173409(15)015.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_173657(16)016.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_173927(17)017.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_174213(18)018.ns5';
%     '/net/home/fwillett/movementSweepDatasets/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/Data/_Medial/NSP Data/NSP_MEDIAL_2013_0823_174506(19)019.ns5';
%   };     
    
% blockList = [5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
% experiment = 't5.2018.10.22';
% fileList = {...
%   '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/5_movementCueTask_Complete_t5_bld(005)006.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/6_movementCueTask_Complete_t5_bld(006)007.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/7_movementCueTask_Complete_t5_bld(007)008.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/8_movementCueTask_Complete_t5_bld(008)009.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/9_movementCueTask_Complete_t5_bld(009)010.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/10_movementCueTask_Complete_t5_bld(010)011.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/11_movementCueTask_Complete_t5_bld(011)012.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/12_movementCueTask_Complete_t5_bld(012)013.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/13_movementCueTask_Complete_t5_bld(013)014.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/14_movementCueTask_Complete_t5_bld(014)015.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/15_movementCueTask_Complete_t5_bld(015)016.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/16_movementCueTask_Complete_t5_bld(016)017.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/17_movementCueTask_Complete_t5_bld(017)018.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/18_movementCueTask_Complete_t5_bld(018)019.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/19_movementCueTask_Complete_t5_bld(019)020.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Lateral/NSP Data/20_movementCueTask_Complete_t5_bld(020)021.ns5';
%            
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/5_movementCueTask_Complete_t5_bld(005)006.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/6_movementCueTask_Complete_t5_bld(006)007.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/7_movementCueTask_Complete_t5_bld(007)008.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/8_movementCueTask_Complete_t5_bld(008)009.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/9_movementCueTask_Complete_t5_bld(009)010.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/10_movementCueTask_Complete_t5_bld(010)011.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/11_movementCueTask_Complete_t5_bld(011)012.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/12_movementCueTask_Complete_t5_bld(012)013.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/13_movementCueTask_Complete_t5_bld(013)014.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/14_movementCueTask_Complete_t5_bld(014)015.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/15_movementCueTask_Complete_t5_bld(015)016.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/16_movementCueTask_Complete_t5_bld(016)017.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/17_movementCueTask_Complete_t5_bld(017)018.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/18_movementCueTask_Complete_t5_bld(018)019.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/19_movementCueTask_Complete_t5_bld(019)020.ns5';
%    '/net/experiments/t5/t5.2018.10.22/Data/_Medial/NSP Data/20_movementCueTask_Complete_t5_bld(020)021.ns5';
%  }; 

% blockList = [1 2 3 4 5 6 7 8 9 10];
experiment = 't5.2018.12.05';
fileList = {...
  '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/1_movementCueTask_Complete_t5_bld(001)002.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/2_movementCueTask_Complete_t5_bld(002)003.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/3_movementCueTask_Complete_t5_bld(003)004.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/4_movementCueTask_Complete_t5_bld(004)005.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/5_movementCueTask_Complete_t5_bld(005)006.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/6_movementCueTask_Complete_t5_bld(006)007.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/7_movementCueTask_Complete_t5_bld(007)008.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/8_movementCueTask_Complete_t5_bld(008)009.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/9_movementCueTask_Complete_t5_bld(009)010.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Lateral/NSP Data/10_movementCueTask_Complete_t5_bld(010)011.ns5';
           
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/1_movementCueTask_Complete_t5_bld(001)002.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/2_movementCueTask_Complete_t5_bld(002)003.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/3_movementCueTask_Complete_t5_bld(003)004.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/4_movementCueTask_Complete_t5_bld(004)005.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/5_movementCueTask_Complete_t5_bld(005)006.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/6_movementCueTask_Complete_t5_bld(006)007.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/7_movementCueTask_Complete_t5_bld(007)008.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/8_movementCueTask_Complete_t5_bld(008)009.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/9_movementCueTask_Complete_t5_bld(009)010.ns5';
   '/net/experiments/t5/t5.2018.12.05/Data/_Medial/NSP Data/10_movementCueTask_Complete_t5_bld(010)011.ns5';
 }; 

% T5 2017.10.25 BMI Task
% experiment = 't5.2017.10.25';
% fileList = {...
%     '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5';
%     '/net/experiments/t5/t5.2017.10.25/Data/_Lateral/NSP Data/14_cursorTask_Complete_t5_bld(014)015.ns5';
%     '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5';
%     '/net/experiments/t5/t5.2017.10.25/Data/_Medial/NSP Data/14_cursorTask_Complete_t5_bld(014)015.ns5';
%   }; 
    
    
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
params.spikeBand.saveFilteredForSortingPath = ['/net/home/fwillett/movementSweepSorting/' experiment '/']; 

params.CHANSPERARRAY = 96;



%% Main loop
for iFile = 1 : numel( fileList )
    fprintf('File %i/%i: %s\n', iFile, numel( fileList ), fileList{iFile} );
    % read the nsx file
    nsxIn = openNSx( 'read', fileList{iFile}, params.nsxChannel);
    nsxFs = double( nsxIn.MetaTags.SamplingFreq );
    if ~iscell( nsxIn.Data)
        nsxDat = single( nsxIn.Data' );
    elseif numel( nsxIn.Data ) > 2
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