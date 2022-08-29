function getBinnedFeaturesFromSession( opts )
    
    %get CAR chans and RMS from first block
    nArrays = size(opts.fileNames,2);
    stdVal = cell(nArrays,1);
    carChans = cell(nArrays,1);
    for a=1:nArrays
        if isempty(opts.fileNames{1,a})
            continue
        end
        [ stdVal{a}, carChans{a} ] = getCarChansAndRMS( opts.fileNames{1,a}, opts.nCarChans );
    end
    
    for b=1:length(opts.fileNames)
        disp(opts.fileNames{b});

        if isempty(opts.fileNames{b})
            continue
        end
        
        %Binned LFP
        if opts.doLFP
            bandPowAllArrays = cell(nArrays,1);
            timeAxes = cell(nArrays,1);
            for a=1:nArrays
                if isempty(opts.fileNames{b,a})
                    continue
                end
        
                if ~isempty(opts.bands_lo)
                    [bp1, timeAxes{a}, metaTags] = getBandPowerFromNS5( opts.fileNames{b,a}, carChans{a}, opts.bands_lo, opts.binMS, [5 6] );
                else
                    bp1 = [];
                end
                if ~isempty(opts.bands_hi)
                    [bp2, timeAxes{a}, metaTags] = getBandPowerFromNS5( opts.fileNames{b,a}, carChans{a}, opts.bands_hi, opts.binMS, 2 );
                else
                    bp2 = [];
                end
                bandPowAllArrays{a} = [bp1; bp2];
            end

            save([opts.resultDir filesep num2str(opts.blockList(b)) ' LFP.mat'],'bandPowAllArrays','timeAxes','opts','carChans','metaTags');
        end
        
        %Binned TX
        if opts.doTX
            binnedTX = cell(nArrays, length(opts.txThresh));
            binTimes = cell(nArrays, length(opts.txThresh));
            for a=1:nArrays
                if isempty(opts.fileNames{b,a})
                    continue
                end
                
                threshVectors = cell(length(opts.txThresh),1);
                for t=1:length(opts.txThresh)
                    threshVectors{t} = stdVal{a}*opts.txThresh(t);
                end
                
                [txEvents, timeAxis, tOffset, metaTags] = getTXFromNS5_rawThresh( opts.fileNames{b,a}, threshVectors, carChans{a} );
                for t=1:length(opts.txThresh)    
                    nBins = ceil((timeAxis(end)+tOffset)*(1000/opts.binMS));
                    binEdges = (0:nBins)*(opts.binMS/1000);
                    binnedTX{a,t} = zeros(nBins,96);
                    binTimes{a,t} = (0:(nBins-1))*opts.binMS;

                    for c=1:length(txEvents)
                        binnedTX{a,t}(:,c) = histcounts(txEvents{c,t}, binEdges);
                    end
                end
            end
            
            save([opts.resultDir filesep num2str(opts.blockList(b)) ' TX.mat'],'binnedTX','binTimes','opts','carChans','metaTags');
        end 
        
        %try to get BNC sync
        ns3File = [opts.fileNames{b,1}(1:(end-4)) '.ns3'];
        if ~exist(ns3File,'file') || strcmp(opts.syncType,'none')
            continue;
        end
        
        siTot = cell(nArrays,1);
        pulse = cell(nArrays,1);
        pulseTime = cell(nArrays,1);
        for a=1:nArrays
            ns3File = [opts.fileNames{b,a}(1:(end-4)) '.ns3'];
            if strcmp(opts.syncType,'west')
                %run west clock extraction
                siTot{a}=extractNS3BNCTimeStamps(ns3File(1:(end-4)));
            elseif strcmp(opts.syncType,'east')
                %run east binned routine
                syncData = openNSx_v620(ns3File, 'read', 'c:1');
                if ~isstruct(syncData)
                    continue;
                end
                if iscell(syncData.Data)
                    sd = syncData.Data{end};
                else
                    sd = syncData.Data;
                end
                tmpPulse = double(sd>0);
                SR = syncData.MetaTags.SamplingFreq;
                binSep = opts.binMS*(SR/1000);
                pulse{a} = tmpPulse(1:binSep:end);
                pulseTime{a}= ((1:length(pulse{a}))-1)*opts.binMS/1000;
            end
        end
        save([opts.resultDir filesep num2str(opts.blockList(b)) ' SyncPulse.mat'],'pulse','pulseTime','siTot');
        
    end %blocks
end %function

