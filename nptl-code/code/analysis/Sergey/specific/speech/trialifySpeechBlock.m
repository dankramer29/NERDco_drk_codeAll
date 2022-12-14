% trialifySpeechBlock.m
%
% Takes audio event labels and raw .nsx and .nev files from the speech experiment, and
% organizes the data in a way that is similar to a NPTL R struct. This function operates
% on a single block, meaning a single start to stop of Cerebus File Recorder, which will
% generate one .ns5 and .nev file per array.
%
%
% NOTE: Requires filtfilthd and spikesMediumFilter, so make sure these NPTL utilities are
% on the paht
%
% USAGE: [ R ] = trialifySpeechBlock( broadbandFiles, nevFiles, sAnnotation, params, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     broadbandFiles            cell list of N arrays' broadband files
%     nevFiles                  cell list of N arrays' nevFiles
%     sAnnotation               structure generated by soundLabelTool which has trial
%                               time markers/labels.
%     params                    
%           .neural             Alignment specifications
%           .arrayContainingAudio  Which array to look into to get the audio file
%           .audioChannel       Which channel in above array to look for the raw audio
%                               file.                        
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%      ssort                    Spike sorting structure, if spike sorted
%                               data should be merged in.
%           .spikes                   one cell for each array. Each
%                                     contains a .channels (which channel
%                                     each spike is on), .sample (what raw
%                                     Cerebus timestamp this happened on
%                                     (BUT DON'T FORGET TO SUBTRACT
%                                     sampleStartThisFile), and additional 
%                                     info from the spike sorter .unitCode (e.g.
%                                     mountainSortID). 
%           .sampleStartThisFile      first sample for this raw data, one
%                                     per array
%           .sampleEndThisFile        last sample for this raw data, one
%                           	      per array
%           .syncUsingTimestamp  If the NSPs didn't sync, it can use the 
%                                   nsxIn.MetaTags.DateTime to try to
%                                   syncronize the data. IMPORTANT: I
%                                   assume that the audio data (used to
%                                   determine when the trials are through
%                                   the audio annotation file) come from
%                                   Array 1. If this isn't the case, all
%                                   alignments to behavior will be off (but
%                                   the neural will still be aligned to
%                                   itself across arrays).
%
% OUTPUTS:
%     R                         Roughly structured like a standard NPTL R struct
%
% Created by Sergey Stavisky on 19 Sep 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ R ] = trialifySpeechBlock( broadbandFiles, nevFiles, sAnnotation, params, varargin )
    def.blockNumber = nan; % unless specified, do not assign it a blocknum.
    def.warnIfRecordingsXsecondsApart = 10; % different arrays' files shouldn't be more than this many s apart
    def.CHANSPERARRAY = 96; % assume 96 electrodes, even though some could be turned off.
    def.ssort = struct([]); % spike sorting structure    
    assignargs( def, varargin );
   
    numArrays = numel( broadbandFiles );

    %% Load the various files
    audioin = openNSx( 'read', broadbandFiles{params.arrayContainingAudio}, params.audioChannel ); % audio
    if ~iscell( audioin.Data )
        fprintf('Heads up, audioin.Data is not a cell. I dont know if this means sync failed or not.\n')
        audioin.Data = {audioin.Data}; % put it in a cell so handling is consistent with most data.
    end
    bigAudioData = audioin.Data{sAnnotation.streamNumber};
    audioFs = audioin.MetaTags.SamplingFreq;
    
    recordTimeEachArray = []; % will fill in for each array if using timestamp sync
    for iArray = 1 : numArrays   
        %% RAW NSX DATA 
        if params.spikeBand.getSpikeBand || params.lfpBand.getLfpBand || params.raw.getRaw
            nsxIn = openNSx( 'read', broadbandFiles{iArray}, params.nsxChannel);
            nsxFs = double( nsxIn.MetaTags.SamplingFreq );

            if ~iscell( nsxIn.Data )
                fprintf('Heads up, nsxIn.Data is not a cell. I dont know if this means sync failed or not.\n')
                nsxIn.Data = {nsxIn.Data}; % put it in a cell so handling is consistent with most data.
            end
            if isfield( params, 'syncUsingTimestamp' ) && params.syncUsingTimestamp
                % Get the time (for this day) in seconds
                recordTimeEachArray(iArray) = nsxIn.MetaTags.DateTimeRaw(5)*(60*60) + nsxIn.MetaTags.DateTimeRaw(6)*60 + ...
                    nsxIn.MetaTags.DateTimeRaw(7) + nsxIn.MetaTags.DateTimeRaw(8)/1000;
                fprintf('Array %i started at %s\n', iArray, nsxIn.MetaTags.DateTime )
                
                if iArray > 1
                    diffT = recordTimeEachArray(iArray) - recordTimeEachArray(1);
                    if diffT < 0
                    % if array N started before array 1, cut out its
                    % earlier data so it effectively starts at same time
                    samplesToDelete = round( nsxFs * -diffT);
                    fprintf('Array %i started %.4g seconds before array 1, so %i samples will be trimmed off\n', ...
                        iArray, -diffT, samplesToDelete)
                     nsxIn.Data{1}(:,1:samplesToDelete) = [];
                    else                       
                        % if array N started AFTER array 1, pad it with zeros
                        % data so it effectively starts at same time
                        keyboard
                    end
                end
            end
            
            if numel( nsxIn.Data ) > 2
                % it's going to be the last file
                nsxDatEachArray{iArray} = nsxIn.Data{end}';                               
            elseif numel( nsxIn.Data ) == 2
                nsxDatEachArray{iArray} = nsxIn.Data{2}';
            else
                warning('Only one .nsx data detected in %s, should be 2. Did Cerebus sync fail?', broadbandFiles{iArray})
                nsxDatEachArray{iArray}  = nsxIn.Data{1}'; %
            end
            clear( 'nsxIn' ) % reduce memory load
            
            % ---------------------------------------------------------------------------
            %                           RAW BAND
            % ---------------------------------------------------------------------------
            % Do nothing, it's already loaded, I just need to trialify later
            
            
            % ---------------------------------------------------------------------------
            %                           LFP BAND
            % ---------------------------------------------------------------------------
            if params.lfpBand.getLfpBand
                nsxDat = single( nsxDatEachArray{iArray} ); 
                
                % 1. Filter
                LPF = params.lfpBand.filterType; % hd filter object
                
                % plot a bit of data to verify it's doing what I want.
%                 testt = 1:30000*5;
%                 testt = testt./30;
%                 testx = nsxDat(1:30000*5,60);
%                 testy = LPF.filter(testx);
%                 testyy = filtfilthd( LPF, testx);
%                 figure; plot( testt,testx, 'k'); hold on; plot( testt,testy, 'r'); plot( testt,testyy, 'b'); xlabel('ms'); ylabel('uV');
                if params.lfpBand.useFiltfilt
                    lfpDat{iArray} = filtfilthd( LPF, nsxDat );
                else
                    lfpDat{iArray} = nsxDat;
                    % whoel matrix is too big for filter, so do it one channel at a time
                    for iChan = 1 : size( lfpDat, 2 )
                        lfpDat{iArray}(:,iChan) = LPF.filter( nsxDat(:,iChan) );
                    end
                end
            end
            
            % ---------------------------------------------------------------------------
            %                           SPIKE BAND
            % ---------------------------------------------------------------------------
            % convert to single before proceeding with filtering
            if params.spikeBand.getSpikeBand
                if ~exist( 'nsxDat', 'var' ) % may already exist from above
                    nsxDat = single( nsxDatEachArray{iArray} ); 
                end
                % 1. Common Average Reference
                if params.spikeBand.commonAverageReference
                    nsxDat =  nsxDat - repmat( mean( nsxDat, 2 ), 1, size( nsxDat, 2 ) );
                end
                
                
                if ~isempty( params.spikeBand.saveCARForSortingPath )
                    % Can save data at this point for spike sorting before filtering.
                    if ~isdir( params.spikeBand.saveCARForSortingPath )
                        mkdir( params.spikeBand.saveCARForSortingPath );
                    end
                    filenameForSorting = [params.spikeBand.saveCARForSortingPath, ...
                        regexprep( pathToLastFilesep( broadbandFiles{iArray},1 ), '.ns5', ''), ...
                        sprintf('_array%i', iArray ) '_forSortingPostCAR.mat'];
                    sourceFile = broadbandFiles{iArray};
                    fprintf('Filtering complete, saving for spike sorting... %s', ...
                        filenameForSorting );
                    save( filenameForSorting, 'nsxDat', 'params', 'sourceFile', '-v7.3')
                    fprintf(' SAVED\n')
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
                    if useFiltfilt
                        nsxDat = filtfilthd( filt, nsxDat );
                    else
                        % Filter for spike band
                        nsxDat = filt.filter( filt, nsxDat );
                    end
                else
                    nsxDat = nsxDat;
                end
                
                
                % NOTE: This is where CAR high pass filtered data is saved for later spike-sorting.
                if ~isempty( params.spikeBand.saveFilteredForSortingPath )
                    if ~isdir( params.spikeBand.saveFilteredForSortingPath )
                        mkdir( params.spikeBand.saveFilteredForSortingPath );
                    end
                    filenameForSorting = [params.spikeBand.saveFilteredForSortingPath, ...
                        regexprep( pathToLastFilesep( broadbandFiles{iArray},1 ), '.ns5', ''), ...
                        sprintf('_array%i', iArray ) '_forSorting.mat'];
                    sourceFile = broadbandFiles{iArray};
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
                cbSamplesEachMS = (nsxFs/1000); % should be 30
                SBtoKeep = cbSamplesEachMS*floor(size( nsxDat,1 )/cbSamplesEachMS ); % so only complete ms
                minValues{iArray} = zeros(floor(size(nsxDat)./ [cbSamplesEachMS 1]), 'single');
                
                
                for iChan = 1 : size( nsxDat, 2 )
                    % taken from lines 159-177 of broadband2streamMinMax.m
                    cspikeband = reshape( nsxDat(1:SBtoKeep,iChan), cbSamplesEachMS, []);
                    minValues{iArray}(:,iChan) = min( cspikeband );
                end
            end
            clear( 'nsxDat' ); % save memory
        end

        %% NEV PARSING
        nevIn = openNEV( nevFiles{iArray}, 'nosave' ); % no save or else won't work on original data directories since they are read only  
        arrayFs = double( nevIn.MetaTags.SampleRes );

        
        % Deal with timestamp reset when sync happens.
        ts = double( nevIn.Data.Spikes.TimeStamp );
        dts = diff(ts);
        indDrop = find( dts < 0 );
        if numel( indDrop ) > 1 
            error('More than one nev timestamp decrease detected. Examine data to figure out why!')
        elseif isempty( indDrop )
            fprintf(2, '[%s] No spike time reset detected for %s, did Cerebus sync not happen?\n', ...
                mfilename, broadbandFiles{iArray} )
        else
            % chopity chop. Delete everything up to sample indDrop 
            fprintf('[%s] NSP sync reset detected at %.1fms of %s\n', ...
                mfilename, 1000*indDrop/arrayFs, nevFiles{iArray}  );
            nevIn.Data.Spikes.TimeStamp(1:indDrop) = [];
            nevIn.Data.Spikes.Electrode(1:indDrop) = [];
            nevIn.Data.Spikes.Unit(1:indDrop) = [];
            if ~isempty( nevIn.Data.Spikes.Waveform )
                % it looks like in t8.2017.10.17, waveforms weren't saved for some reason.
                % Hence this check, otherwise function break.s
                nevIn.Data.Spikes.Waveform(:,1:indDrop) = [];
            end
        end
        arrayRecordTime{iArray} =  datenum( nevIn.MetaTags.DateTimeRaw(1), nevIn.MetaTags.DateTimeRaw(2), nevIn.MetaTags.DateTimeRaw(3), ...
            nevIn.MetaTags.DateTimeRaw(4), nevIn.MetaTags.DateTimeRaw(5), nevIn.MetaTags.DateTimeRaw(6) ); % Y, M D, H, Mn, S 
        bigNev{iArray} = nevIn.Data.Spikes; % makes life easier to not burrow into struct.
        bigNev{iArray}.TimeStamp = double( bigNev{iArray}.TimeStamp ); % convert to double will save trouble later
       
        clear('nevIn');
        
    end
    % Throw a warning if the array recording start times 
    if numArrays > 1
        if any( diff( cell2mat( arrayRecordTime ) ) ) > warnIfRecordingsXsecondsApart
            fprintf(2, '[%s] Warning, different NEV files within same block appear have been started many seconds apart. Check %s data?\n', ...
                mfilename, nevFiles{1} )
        end
    end
    
    %% Go through trial by trial and build the things I care about.   
    R = [];
    for iTrial = 1 : numel( sAnnotation.trialNumber )
        fprintf( 'Trial %i\n', iTrial )
        % build up trial r (little R), then at end add it to R struct array iff it's a valid
        % trial.
        % identification
        r.trialNumber = sAnnotation.trialNumber(iTrial);
        r.label = sAnnotation.label{iTrial};
        r.blockNumber = blockNumber;
        r.experimentDate = datestr( arrayRecordTime{1},1 );
        r.experimentStartTime = datestr( arrayRecordTime{1},1 );
        
        % ------------------------
        %      Audio stimulus
        % ------------------------
        audioStartInd = sAnnotation.cueStartTime{iTrial}(1) - params.neural.msBeforeCue*(audioFs/1000);
        % Check if we have this data. If not, warn and discard this trial. 
        if audioStartInd < 1
            fprintf(2, '[%s] Insufficient data in trial %i of %s to look back from cue start by %.0f ms. Discarding this trial.\n', ...
                mfilename, iTrial, broadbandFiles{1}, params.neural.msBeforeCue );
            continue
        end          
        audioEndInd = sAnnotation.speechStartTime{iTrial}(end) + params.neural.msAfterSpeech*(audioFs/1000);
        % Check whether there is sufficient data at the end of things
        if audioEndInd > numel( bigAudioData )
            fprintf(2, '[%s] Insufficient data in trial %i of %s to look forward from speech start by %.0f ms. Discarding this trial.\n', ...
                mfilename, iTrial, broadbandFiles{1}, params.neural.msAfterSpeech );
            continue
        end
        
        
        mySnippet = bigAudioData(floor( audioStartInd ): floor( audioEndInd ));   
        myT = 0 : numel(mySnippet)-1;
        myT = myT ./ audioFs; % in seconds
        r.audio = contDatObject( 'dat', mySnippet, 'rate', audioFs, 't', myT, ...
            'channelName', {params.audioChannel} );        
      
        % Add cue and speech times in MS aligned to this trial's start time.
        r.timeCueStart = round( params.neural.msBeforeCue  + (1000/audioFs).*[sAnnotation.cueStartTime{iTrial} - sAnnotation.cueStartTime{iTrial}(1) ] );
        r.timeSpeechStart = round( params.neural.msBeforeCue + (1000/audioFs).*[sAnnotation.speechStartTime{iTrial} - sAnnotation.cueStartTime{iTrial}(1)] );
        
        % ------------------------
        %   Continuous Broadband
        % ------------------------
        % start and stop times in NSX time.
        thisTrialNSXfirstInd = round( sAnnotation.cueStartTime{iTrial}(1) - params.neural.msBeforeCue*(arrayFs/1000) );
        thisTrialNSXlastInd = round( -1 + sAnnotation.speechStartTime{iTrial}(end) + params.neural.msAfterSpeech*(arrayFs/1000) );
        % sAnnotation times are in cerebus samples. I want these
        % in milliseconds because that's what 'minValues' (which is already binned to ms) uses
        thisTrialNSXfirstIndMS = round( sAnnotation.cueStartTime{iTrial}(1) / (nsxFs/1000) ) - params.neural.msBeforeCue; % in ms
        thisTrialNSXlastIndMS = -1 + round( sAnnotation.speechStartTime{iTrial}(end) / (nsxFs/1000) ) + params.neural.msAfterSpeech;
            
        % Create faux-clock (it comes from Cerebus timestamps instead of from xPC), since some
        % downstream analysis functions expect this. It's designed to always given same samples as
        % array spike raster field generation below. 
        r.clock = uint32( thisTrialNSXfirstIndMS : 1 : thisTrialNSXlastIndMS );
        
        % ---------------
        % SPIKE BAND
        % ---------------
        if params.spikeBand.getSpikeBand
            for iArray = 1 : numArrays
                % Record RMS value for each channel. These will be the same across trials within a block
                % but still easier to carry these around.
                fieldName = sprintf('RMSarray%i', iArray);
                r.(fieldName) = RMSarray{iArray}';
                
                % Record most negative voltage values recorded in each millisecond
                fieldName = sprintf('minAcausSpikeBand%i', iArray);
                
                r.(fieldName) = minValues{iArray}(thisTrialNSXfirstIndMS:thisTrialNSXlastIndMS,:)';
            end
        end
        
        % ---------------
        % RAW BAND
        % ---------------
        if params.raw.getRaw
            for iArray = 1 : numArrays                
                fieldName = sprintf('raw%i', iArray);
            
                mySnippet = nsxDatEachArray{iArray}(thisTrialNSXfirstInd:thisTrialNSXlastInd , :);
                myT = 0 : size( mySnippet, 1 )-1;
                myT = myT ./ arrayFs; % in seconds
                myChanNames = {};
                % create proper channel names
                for i = 1 : size( mySnippet, 2 )
                    myChanNames{i} = sprintf('chan_%i.%i', iArray, i );
                end
                r.(fieldName) = contDatObject( 'dat', mySnippet', 'rate', arrayFs, 't', myT, ...
                    'channelName', myChanNames );                  
            end
        end
        
        % ---------------
        % LFP BAND
        % ---------------
        if params.lfpBand.getLfpBand
            for iArray = 1 : numArrays
                fieldName = sprintf( 'lfp%i', iArray );
                mySnippet = lfpDat{iArray}(thisTrialNSXfirstInd:thisTrialNSXlastInd , :);
                myT = 0 : size( mySnippet, 1 )-1;
                myT = myT ./ arrayFs; % in seconds
                
                % Downsample
                mySnippet = downsample( mySnippet, arrayFs/params.lfpBand.Fs );
                myT = downsample( myT, arrayFs/params.lfpBand.Fs ); 
                
                % ensure it's same length as the spike band
                if numel( myT ) > numel( r.clock )
                    % trim by 1
                    mySnippet(end,:) = [];
                    myT(end) = [];                    
                elseif numel( myT ) < numel( r.clock )
                    % trim other fields by one
                    r.clock(end) = [];
                    r.minAcausSpikeBand1(:,end) = [];
                    r.minAcausSpikeBand2(:,end) = [];                    
                end
                
                myChanNames = {};
                % create proper channel names
                for i = 1 : size( mySnippet, 2 )
                    myChanNames{i} = sprintf('chan_%i.%i', iArray, i );
                end
                r.(fieldName) = contDatObject( 'dat', mySnippet', 'rate', params.lfpBand.Fs, 't', myT, ...
                    'channelName', myChanNames );                   
            end
        end
        
        % ------------------------
        %      NEV spikes
        % ------------------------ 
        nevStartT = sAnnotation.cueStartTime{iTrial}(1) - params.neural.msBeforeCue*(arrayFs/1000); % in nev samples
        nevEndT = sAnnotation.speechStartTime{iTrial}(end) + params.neural.msAfterSpeech*(arrayFs/1000); % in nev samples
        for iArray = 1 : numArrays
            spikesThisTrialInds = find( bigNev{iArray}.TimeStamp >= nevStartT & bigNev{iArray}.TimeStamp < nevEndT );            
            % Create the sparse MS-resolution array. How long will it be?
            myFieldName = 'spikeRaster';
            if iArray > 1
                myFieldName = sprintf('%s%i', myFieldName, iArray);
            end
            
            % Note that nev spikes are considered secondary to data coming in from raw data, and thus
            % I ensure it has same # samples as minAcausSpikeBand. There could be a 1 ms shift in how
            % this works out but I'm OK w/ that. No spikes are lost.
            r.(myFieldName) = sparse(  false( CHANSPERARRAY, numel( r.clock ) ) );
            % place the spikes in their 1ms bins
            for i = 1 : numel( spikesThisTrialInds )
                myChan = bigNev{iArray}.Electrode(spikesThisTrialInds(i));
                myMS = ceil( (bigNev{iArray}.TimeStamp(spikesThisTrialInds(i)) - nevStartT ) * (1000 / arrayFs) );
                if myMS > size( r.(myFieldName), 2 )  % put it in previous bin
                    myMS = myMS - 1;
                end
                r.(myFieldName)(myChan,myMS) = true;
            end
        end                
        if isfield(r, 'minAcausSpikeBand1' ) && ( size( r.minAcausSpikeBand1, 2 ) ~= numel( r.clock ) )
            % Should never happen, keeping this check to be sure.
            warning('Trial %i has mismatched nev and nsx raster number of samples', iTrial )
        end
        
        
        % ------------------------
        %      Sorted Spikes
        % ------------------------         
        
        % DEV
%         if blockNumber > 2 
%             keyboard
%         end
        
        
        if params.ss.mergeSpikeSorted
            thisTrialMS = numel( r.clock );
            for iArray = 1 : numArrays
                unitCodeEachUnit = unique( ssort.spikes{iArray}.unitCode ); % lookup from the mountainsort ID 
                % reverse lookup
                for i = 1 : numel( unitCodeEachUnit )
                    unitCodeToIndLookup(unitCodeEachUnit(i)) = find( unitCodeEachUnit == unitCodeEachUnit(i) );
                    % lookup of what electrode each unit comes from
                    electrodeEachUnit(i) = mode( ssort.spikes{iArray}.channels( ssort.spikes{iArray}.unitCode == unitCodeEachUnit(i) ) );
                end
                
                
                
                numUnits = numel( unitCodeEachUnit );                
                % preallocate spike raster for this array
                mySortedRaster = sparse(  false( numUnits, thisTrialMS ) );
                
                ssort.spikes{iArray}.sampleInThisFile = ssort.spikes{iArray}.sample - ssort.sampleStartThisFile(iArray);
                % from which event to which event should I look at so
                % they're within this file?
                startAtEventInd = find( ssort.spikes{iArray}.sampleInThisFile >= thisTrialNSXfirstInd, 1, 'first');
                endAtEventInd = find( ssort.spikes{iArray}.sampleInThisFile > thisTrialNSXlastInd, 1, 'first')-1;
                
                
                      
                % DEV: Sanity check that spike-aligned minAcausalSpikeBand
                % looks like a spike.
%                 figh = figure;
%                 clear('axh');
%                 for iUnit = 1 : numUnits
%                     axh(iUnit) = subplot(10,6,iUnit);
%                     hold on;
%                     xlim([-3 4]);
%                 end
%                 acausField = sprintf('minAcausSpikeBand%i', iArray );
                % /DEV
                
                % go through spike by spike and write them in
                
                for spikeInd = startAtEventInd:endAtEventInd
                    myUnit = unitCodeToIndLookup(ssort.spikes{iArray}.unitCode(spikeInd));
                    myMS = ceil( (ssort.spikes{iArray}.sampleInThisFile(spikeInd) - thisTrialNSXfirstInd ) * (1000 / arrayFs) );
                    if myMS > thisTrialMS  % put it in previous bin
                        myMS = myMS - 1;
                    elseif myMS == 0
                        myMS = 1;
                    end
                    mySortedRaster(myUnit,myMS) = true;
                    
                    %DEV: plot around the time of the spike the minAcaus                   
%                     myChannel = electrodeEachUnit(myUnit);                 
%                     if myMS > 3 && myMS <= thisTrialMS-4
%                         t = -3:4;
%                         y = r.(acausField)(myChannel,myMS-3:myMS+4);
%                         plot( axh(myUnit ), t, y );
%                     end
%                     /DEV
                end
                
                
                % add these to the R struct
                fieldname = sprintf('unitCodeOfEachUnitArray%i', iArray);
                r.(fieldname) = unitCodeEachUnit;
                fieldname = sprintf('sortedRasters%i', iArray );
                r.(fieldname) = mySortedRaster;
                fieldname = sprintf('electrodeEachUnitArray%i', iArray);
                r.(fieldname) = electrodeEachUnit;
            end
            
            % TODO: Add sort quality (I forgot to do this before, would have to regenerate all these
            % files).
            keyboard
        end
        

        
        % add this trial to the growing R struct
        R = [R; r];
    end
 end

 
