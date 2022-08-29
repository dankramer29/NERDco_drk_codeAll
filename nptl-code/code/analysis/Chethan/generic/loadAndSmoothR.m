function [R1 thresh]=loadAndSmoothR(participant,session,block, options)
% LOADANDSMOOTHR    
% 
% R1=loadAndSmoothR(participant,session,block, options)
% if options.thresh is scalar, treats it as an rms multiplier
%   gaussSD = options.gaussSD;
%   useHalfGauss = options.useHalfGauss;
%   useHLFP = options.useHLFP;

if ~isfield(options,'thresh')
    error('loadAndSmoothR: must specify option "thresh" as a single RMS multiplier or a vector of thresholds');
end
gaussSD = options.gaussSD;
useHalfGauss = options.useHalfGauss;
useHLFP = true;
if isfield(options,'useHLFP')
    useHLFP = options.useHLFP;
end

useLFPRaw = false;
if isfield(options,'useLFPRaw')
    useLFPRaw = options.useLFPRaw;
end


if ~isfield(options,'normalizeKernelPeak')
    disp('loadAndSmoothR: setting default value - no normalizing kernel peak');
    options.normalizeKernelPeak = false;
end
normalizeKernelPeak = options.normalizeKernelPeak;

% fields to drop from the rstruct
dropfields={'cerebusFrame','xpcScreenUpdateClock','minSpikeBand','minSpikeBandInd','maxSpikeBand','maxSpikeBandInd', ...
            'meanSquaredAcaus','meanSquaredAcausChannel','minAcausSpikeBand','minAcausSpikeBandInd','minAcausSpikeBandInd1','minAcausSpikeBandInd2','outputValid','packetChainSize','numDroppedUDPPackets','xpcTET'};

% fields to keep from the stream
streamfields={'minAcausSpikeBand','minAcausSpikeBand1','minAcausSpikeBand2','SBsmoothed','minSpikeBand'};
% if we need to remap the names
streamfieldsout={'minAcausSpikeBand','minAcausSpikeBand1','minAcausSpikeBand2','SBsmoothed', 'minAcausSpikeBand'};

if useHLFP
    streamfields(end+1) = {'HLFPsmoothed'};
    streamfieldsout(end+1) = {'HLFPsmoothed'};
end

if useLFPRaw
    streamfields(end+1) = {'lfp'};
    streamfieldsout(end+1) = {'lfp'};
end

    %% set the stream directories for each participant, load the spike and lfp data
    switch participant
      case {'t6','s3'}
        fnsb=sprintf('/net/derivative/stream/%s/%s/spikeband/%g',...
                     participant,session,block);
        spikeband=loadvar(fnsb,'spikeband');
        fnlfp=sprintf('/net/derivative/stream/%s/%s/lfpband/%g',...
                      participant,session,block);
        if useHLFP || useLFPRaw
            try
                lfpband=loadvar(fnlfp,'lfpband');
            catch
                disp('couldnt load lfpband data');
            end
        end
      case {'t7','t5'}
        %% t7 has 2 arrays - merge the two together
        fnsb1=sprintf('/net/derivative/stream/%s/%s/spikeband/_Lateral/%g',...
                      participant,session,block);
        fnsb2=sprintf('/net/derivative/stream/%s/%s/spikeband/_Medial/%g',...
                      participant,session,block);

        try
            spikeband1=loadvar(fnsb1,'spikeband');
        catch
            disp('couldnt load array 1');
            spikeband1=[];
        end
        try
            spikeband2=loadvar(fnsb2,'spikeband');
        catch
            disp('couldnt load array 2');
            spikeband2 = [];
        end
        
        %% fill with nans if data didn't exist
        if isempty(spikeband1)
            spikeband1 = spikeband2;
            fs = fields(spikeband1);
            for nf = 1:length(fs)
                if ~strcmp(fs{nf},'clock')
                    spikeband1.(fs{nf})(1:end) = nan;
                end
            end
        elseif isempty(spikeband2)
            spikeband2 = spikeband1;
            fs = fields(spikeband2);
            for nf = 1:length(fs)
                if ~strcmp(fs{nf},'clock')
                    spikeband2.(fs{nf})(1:end) = nan;
                end
            end
        end

            

        %% find the alignment points for data from the two arrays
        min1 = min(spikeband1.clock);
        min2 = min(spikeband2.clock);
        minBoth = max(min1,min2);

        max1 = max(spikeband1.clock);
        max2 = max(spikeband2.clock);
        maxBoth = min(max1,max2);

        keepInds1 = find(spikeband1.clock >= minBoth & spikeband1.clock <= maxBoth);
        keepInds2 = find(spikeband2.clock >= minBoth & spikeband2.clock <= maxBoth);
        fs = fields(spikeband1);
        for nf = 1:length(fs)
            spikeband.(fs{nf}) = spikeband1.(fs{nf})(keepInds1,:);
            if ~strcmp(fs{nf},'clock')
                spikeband.(fs{nf}) = [spikeband.(fs{nf}) spikeband2.(fs{nf})(keepInds2,:)];
            end
        end
        spikeband.meanSquaredChannel(:,2) = spikeband.meanSquaredChannel(:,2) + 96;

        if useHLFP || useLFPRaw
            fnlfp1=sprintf('/net/derivative/stream/%s/%s/lfpband/_Lateral/%g',...
                           participant,session,block);
            fnlfp2=sprintf('/net/derivative/stream/%s/%s/lfpband/_Medial/%g',...
                           participant,session,block);
            
            lfpband1=loadvar(fnlfp1,'lfpband');
            lfpband2=loadvar(fnlfp2,'lfpband');
            
            fs = fields(lfpband1);
            for nf = 1:length(fs)
                lfpband.(fs{nf}) = lfpband1.(fs{nf})(keepInds1,:);
                if ~strcmp(fs{nf},'clock')
                    lfpband.(fs{nf}) = [lfpband.(fs{nf}) lfpband2.(fs{nf})(keepInds2,:)];
                end
            end
        end
    end

    switch lower(participant)
      case 's3'
        %% load the R struct
        fnR=sprintf('/net/derivative/R/%s/%s/R_%g',...
                    participant, session, block);
        [R1] = loadvar(fnR, 'R');
      otherwise
        R1=loadRWithAddons(participant, session, block, {'spikeband'}, ...
                           {'minSpikeBand','maxSpikeBand','minSpikeBandInd','maxSpikeBandInd'});
    end

    %% drop some fields from the Rstr
    for nf = 1:length(dropfields)
        if isfield(R1, dropfields{nf})
            R1 = rmfield(R1, dropfields{nf});
        end
    end
    
    %% calculate rms-based thresholds
    if length(options.thresh) == 1
        rms = channelRMS(spikeband);
        thresh = rms * options.thresh;
    else
        thresh = options.thresh;
    end

    %% apply smoothing to the streamed data
    spikeband = smoothStream(spikeband, thresh, gaussSD, useHalfGauss, normalizeKernelPeak);
    if exist('lfpband','var')
        %% apply smoothing to the streamed data
        lfpband = smoothStream(lfpband, thresh, gaussSD, useHalfGauss, normalizeKernelPeak);
    end


    %% add the stream data to the Rstr
    for nt = 1:length(R1)
        switch participant
          case {'t6','t7','t5'}
            sc = R1(nt).startcounter;
            ec = R1(nt).endcounter;
            
            startind = find(spikeband.clock==sc);
            endind = find(spikeband.clock==ec);

          case 's3'
            sc = R1(nt).timeCerebusStart*30000;
            ec = R1(nt).timeCerebusEnd*30000;
            
            [~,startind] = min(abs(spikeband.cerebusTime-sc));
            [~,endind] = min(abs(spikeband.cerebusTime-ec));

        end

        for nf = 1:length(streamfields)
            if isfield(spikeband,streamfields{nf})
                R1(nt).(streamfieldsout{nf}) = ...
                    spikeband.(streamfields{nf})(startind:endind,:)';
            end
            if exist('lfpband','var') & isfield(lfpband,streamfields{nf})
                R1(nt).(streamfieldsout{nf}) = ...
                    lfpband.(streamfields{nf})(startind:endind,:)';
            end
        end

    end
