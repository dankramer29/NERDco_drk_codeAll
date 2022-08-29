% wholeSessionFRplot.m
%
% Used to sanity check whether there are gross neural recording shifts
% during a session. Point it to a neural data directory and it'll load the
% .nsx data, apply our spikes filtering, and record binned firing rates (at
% a specified RMS) and also the RMS voltage in each bin. 
%
% Note: I had to decide whether to just load both arrays separately and
% likely have slightly different numbers of samples in each, or whether to
% load both in a coordinated way and trim so the samples lined up. I opted
% to go with synchronized so that, if there are recording
% non-stationarities, we can diagnose if they happen simlultaneously across
% arrays or not. 
%
% USAGE: [ tBin, FRmat, RMSmat, rollovers, figh, metadata, rms ] = wholeSessionFRplot( sessionDir, varargin )
%
% EXAMPLE: [t, fr, rms, rollovers, figh] = wholeSessionFRplot(
% '/net/experiments/t5/t5.2019.05.29/Data/' )
%
% INPUTS:
%     sessionDir                The 'Data' directory in a session, which
%                               should contain subdirectories with .ns5 files
%                               (e.g., '_Lateral/' and '_Medial').
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     tBin                      time (in seconds) of each bin
%     FRmat                     Time (bin) x Electrodes firing rate
%     RMSmat                    Time (bin) x Electrodes RMS voltage
%     rollovers                 vector of indices into tBin that correspond
%                               to the start of a new .ns5 file.
%     figh                      figure handles of resulting plots. It's a
%                               structure, one field per plot.
%     metaData                  One metadata from each array (from last file
%                               loaded)
%     RMSarray                  numArrays x numBlocks of RMS for the whole
%                               block
% Created by Sergey Stavisky on 31 May 2019 using MATLAB version 9.5.0.944444 (R2018b)

 function [ tBin, FRmat, RMSmat, rollovers, figh, metaData, RMSarray ] = wholeSessionFRplot( sessionDir, varargin )
    
    if ~strcmp( sessionDir(end), filesep )
        sessionDir(end+1) = filesep; % enforce tailing filesep
    end
    def.binMS = 20; % what size to bin neural data at.
    def.thresholdRMS = -4.5; % at what RMS to threshold
    def.arrayPath{1} = '_Lateral/NSP Data/';
    def.arrayPath{2} = '_Medial/NSP Data/';
    def.nsxChannel = 'c:01:96'; % use 'c' instead of 'e' because we don't use a .ccf that will map channels to electrodes
    def.CAR = true; % whether or not to do common average referencing within an arrya (generally should be true)
    def.filterType = 'spikesmediumfiltfilt'; % these are names of NPTL codebase filters
    
    def.warnIfRecordingsXsecondsApart = 10; % different arrays' files shouldn't be more than this many s apart
    def.CHANSPERARRAY = 96;
    assignargs( def, varargin );

    %% Get list of .ns5 files
    for iArray = 1 : numel( arrayPath )
        myPath = [sessionDir, arrayPath{iArray}];
        dInfo = dir( [myPath '*.ns5'] );
        % I want them in chronological order
        fileTimes = [dInfo.datenum];
        [~, sortOrder] = sort( fileTimes, 'ascend');
        filesEachArray{iArray} = {};
        for iFile = 1 : numel( sortOrder )
            myInd = sortOrder(iFile);
            filesEachArray{iArray}{iFile} = [dInfo(myInd).folder filesep dInfo(myInd).name];
        end
        fprintf('Found %i .ns5 files in %s\n', numel( filesEachArray{iArray} ), myPath )
        % warn if # files doesn't match
        if iArray > 1
            if numel( filesEachArray{iArray} ) ~= numel( filesEachArray{1} )
                error( 'Different numbers of .ns5 files across arrays. Add rules to handle this!')
            end
        end            
    end
    
    %% Loop across files, and for each, load both arrays and generate the features of interest.
    % Add these to growing matrices of data.
    tBin = [];
    FRmat = [];
    RMSmat = [];
    rollovers = [];
    arrayRecordTime = []; % numArrays x numBlocks mat
    for iBlock = 1 : numel( filesEachArray{1} )
        fprintf('  block %i/%i\n', iBlock, numel( filesEachArray{1} ) )
        for iArray = 1 : numel( filesEachArray )        
            nsxIn = openNSx( 'read', filesEachArray{iArray}{iBlock}, nsxChannel);
            metaData{iArray} = nsxIn.MetaTags;
            % there can be multiple subfiles due to sync between NSPs. We
            % always want the longest one (usually this one is minuts long
            % and others are a few seconds)
            [val, subfileInd] = max(  cellfun( @numel, nsxIn.Data ) );
            arrayRecordTime(iArray,iBlock) =  datenum( nsxIn.MetaTags.DateTimeRaw(1), nsxIn.MetaTags.DateTimeRaw(2), nsxIn.MetaTags.DateTimeRaw(3), ...
                nsxIn.MetaTags.DateTimeRaw(4), nsxIn.MetaTags.DateTimeRaw(5), nsxIn.MetaTags.DateTimeRaw(6) ); % Y, M D, H, Mn, S
            nsxDat = double( nsxIn.Data{subfileInd} )'; % time x channels
            nsxGain = double( nsxIn.ElectrodesInfo(1).MaxDigiValue / nsxIn.ElectrodesInfo(1).MaxAnalogValue );
%             clear('nsxIn'); % UNCOMMENT LATER, save space
            Fs = metaData{iArray}.SamplingFreq;


             % 1. Common Average Reference
            if CAR
                nsxDat =  nsxDat - repmat( mean( nsxDat, 2 ), 1, size( nsxDat, 2 ) );
            end
            
             % 2. Filter
            switch lower( filterType )
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
            
            % already convert to uV, which typically means divide by 4. Do
            % it here or it'll be easy to forget this later.
            nsxDat = nsxDat ./ nsxGain;
            spikeBandUnits = 'uV';
            
            % 3. Binned RMS          
            binEnds = round( binMS*Fs/1000 ) : round( binMS*Fs/1000 ) : size( nsxDat, 1 ); % ensures full bins
            binStarts = binEnds-round( binMS*Fs/1000 )+1;
            
            myRMSmat{iArray} = nan( numel(binStarts), size( nsxDat, 2 ) ); % bin x chans
            for iBin = 1 : numel( binStarts )
                 myRMSmat{iArray}(iBin,:) = sqrt( mean( nsxDat(binStarts(iBin):binEnds(iBin),:).^2, 1) );
            end

            % 4. Estimate RMS (of this whole block's filtered signal!)
            % this is used for threshold crossing
            for iChan = 1 : size( nsxDat, 2 )
                RMSarray{iArray,iBlock}(iChan) = sqrt( mean( nsxDat(:,iChan).^2  ) );
            end
            mytBin{iArray} = binStarts ./ Fs;
            
            % 5. Bin firing rates
            % need to convert to 1 ms (so can't get multiple spieks in a
            % ms, then apply thresholding, then bin 
            % Convert to 1 ms min voltages
            cbSamplesEachMS = (Fs/1000); % should be 30
            SBtoKeep = cbSamplesEachMS*floor(size( nsxDat,1 )/cbSamplesEachMS ); % so only complete ms
            minValues = zeros(floor(size(nsxDat)./ [cbSamplesEachMS 1]), 'single');
            for iChan = 1 : size( nsxDat, 2 )
                % taken from lines 159-177 of broadband2streamMinMax.m
                cspikeband = reshape( nsxDat(1:SBtoKeep,iChan), cbSamplesEachMS, []);
                minValues(:,iChan) = min( cspikeband );
            end
            % do thresholding
            rasters1ms = minValues < thresholdRMS.*repmat( RMSarray{iArray,iBlock}, size( minValues, 1 ), 1 );
            
            % do longer binning
            binEnds1ms = binMS :  binMS  : size( rasters1ms, 1 ); % ensures full bins
            binStarts1ms = binEnds1ms-binMS +1;
            
            myFRmat{iArray} = nan( numel(binStarts1ms), size( nsxDat, 2 ) ); % bin x chans
            for iBin = 1 : numel( binStarts1ms )
                myFRmat{iArray}(iBin,:) = sum( rasters1ms(binStarts1ms(iBin):binEnds1ms(iBin),:), 1  ) .* ...
                  (1000/binMS) ; % note convert to hz at end
            end
        end 
        
        % Warn if array record start times appear mis-aligned (culd be
        % we're matching the wrong .ns5 files, for instance if one NSP
        % didn't record one block.
        if abs( diff( arrayRecordTime(:,iBlock) ) ) > warnIfRecordingsXsecondsApart
            fprintf(2, '[%s] Warning, %s and %s within same block appear have been started many seconds apart. Check data?\n', ...
                mfilename, filesEachArray{1}{iBlock}, filesEachArray{2}{iBlock} )            
        end
        
        % standardize to the same number of bins across arrays, and add
        % these to the bin matrix        
        if iBlock > 1
            % keeps track of the bin that is the start of a new block
            rollovers(end+1) = numel( tBin )+1;
        end
        minBins = min( cellfun( @(x) size( x, 1 ), myFRmat ) );
        % tBin is cmulative, 
        if isempty( tBin )
            addme = 0;
        else
            addme = tBin(end);
        end
        tBin = [tBin; addme+mytBin{1}(1:minBins)'];
        % concatenate across arrays
        thisBlockFR = [];
        thisBlockRMS = [];
        for iArray = 1 :  numel( filesEachArray )        
            thisBlockFR = [thisBlockFR, myFRmat{iArray}(1:minBins,:)];
            thisBlockRMS = [thisBlockRMS, myRMSmat{iArray}(1:minBins,:)];
        end
        FRmat = [FRmat; thisBlockFR];       
        RMSmat = [RMSmat; thisBlockRMS];
    end
    
    %% MAKE PLOTS
    seps = strfind( sessionDir, filesep );
    sessionName = sessionDir(seps(end-2)+1:seps(end-1)-1);
   
    
    % TODO: matrix plot is wrong (transpose)
    % RMS
    figh.rms = figure;
    % z score
    rmsZ = (RMSmat - repmat( mean( RMSmat, 1 ), size( RMSmat, 1 ), 1 ) ) ./ ...
        repmat( std( RMSmat, 0, 1 ), size( RMSmat, 1 ), 1 ) ;
    % clip above 5 std
    rmsZ(rmsZ>5) = 5;
    rmsZ(rmsZ<-5) = -5;
 
    imh = imagesc([tBin(1)./60, tBin(end)./60 ], [1, size( rmsZ, 2 )], rmsZ');
    hold on
    xlabel('Time (min)')
    ylabel('Electrode')
    % mark rollovers on this timeline
    for i = 1 : numel( rollovers )
        lh = line( [tBin(rollovers(i))./60 tBin(rollovers(i))./60], [0 size( rmsZ, 2 )+1], ...
            'Color', 'k' );
    end
    colorbar;
 
    titlestr = sprintf('%s RMS z-score', sessionName );
    title( titlestr );
    figh.rms.Name = titlestr;
    
     % FR
    figh.fr = figure;
    % z score
    frZ = (FRmat - repmat( mean( FRmat, 1 ), size( FRmat, 1 ), 1 ) ) ./ ...
        repmat( std( FRmat, 0, 1 ), size( FRmat, 1 ), 1 ) ;
    % clip above 5 std
    frZ(frZ>5) = 5;
    frZ(frZ<-5) = -5;
 
    imh = imagesc( [tBin(1)./60, tBin(end)./60 ], [1, size( rmsZ, 2 )], frZ');
    hold on
    xlabel('Time (min)')
    ylabel('Electrode')
    % mark rollovers on this timeline
    for i = 1 : numel( rollovers )
        lh = line( [tBin(rollovers(i))./60 tBin(rollovers(i))./60], [0 size( frZ, 2 )+1], ...
            'Color', 'k' );
    end
    colorbar
    titlestr = sprintf('%s firing rate z-score', sessionName );
    title( titlestr );
    figh.rms.Name = titlestr;

    
   
end