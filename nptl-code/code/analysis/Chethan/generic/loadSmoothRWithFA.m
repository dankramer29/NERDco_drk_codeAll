function [Rs thresh taskDetails]=loadAndSmoothR(participant,session,blocks, options)
% LOADANDSMOOTHR    
% 
% R1=loadAndSmoothR(participant,session,block, options)
% if options.thresh is scalar, treats it as an rms multiplier
%   gaussSD = options.gaussSD;
%   useHalfGauss = options.useHalfGauss;
%   useHLFP = options.useHLFP;

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

if ~isfield(options,'faopts')
    error('loadSmoothRWithFA: need to pass in factor analysis options');
end
faopts = options.faopts;

if ~isfield(options,'normalizeKernelPeak')
    disp('loadAndSmoothR: setting default value - no normalizing kernel peak');
    options.normalizeKernelPeak = false;
end
normalizeKernelPeak = options.normalizeKernelPeak;

velSmoothingWindow = 0;
if isfield(options,'velSmoothingWindow')
    velSmoothingWindow = options.velSmoothingWindow;
end


% fields to drop from the rstruct
dropfields={'cerebusFrame','xpcScreenUpdateClock','minSpikeBand','minSpikeBandInd','maxSpikeBand','maxSpikeBandInd', ...
            'meanSquaredAcaus','meanSquaredAcausChannel','minAcausSpikeBandInd','minAcausSpikeBandInd1','minAcausSpikeBandInd2','outputValid','packetChainSize','numDroppedUDPPackets','xpcTET'};

% fields to keep from the stream
streamfields={'minAcausSpikeBand','minAcausSpikeBand1','minAcausSpikeBand2','SBsmoothed','minSpikeBand','xorth'};
% if we need to remap the names
streamfieldsout={'minAcausSpikeBand','minAcausSpikeBand1','minAcausSpikeBand2','SBsmoothed', 'minAcausSpikeBand','xorth'};

if useHLFP
    streamfields(end+1) = {'HLFPsmoothed'};
    streamfieldsout(end+1) = {'HLFPsmoothed'};
end

if useLFPRaw
    streamfields(end+1) = {'lfp'};
    streamfieldsout(end+1) = {'lfp'};
end


for nb = 1:numel(blocks)
    block=blocks(nb);

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
      case 't7'
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


    %% need thresholds to do smoothing
    if length(options.thresh) == 1
        % calculate rms-based thresholds
        rms = channelRMS(spikeband);
        thresh = rms * options.thresh;
    else
        thresh = options.thresh;
    end

    %% change fieldnames and rename as needed
    for nf = 1:numel(streamfields)
        if ~strcmp(streamfieldsout{nf},streamfields{nf})
            if isfield(spikeband,streamfields{nf})
                spikeband.(streamfieldsout{nf}) = spikeband.(streamfields{nf});
                spikeband = rmfield(spikeband,streamfields{nf});
            end
            if exist('lfpband','var')
                if isfield(lfpband,streamfields{nf})
                    lfpband.(streamfieldsout{nf}) = lfpband.(streamfields{nf});
                    lfpband = rmfield(lfpband,streamfields{nf});
                end
            end
        end
    end

    %% apply smoothing to the streamed spikeband data
    spikeband = smoothStream(spikeband, thresh, gaussSD, useHalfGauss, normalizeKernelPeak);

    if exist('lfpband','var')
        %% apply smoothing to the streamed lfpband data
        lfpband = smoothStream(lfpband, thresh, gaussSD, useHalfGauss, normalizeKernelPeak);
    end

    switch lower(participant)
      case 's3'
        disp('loadSmoothRWithFA: warning - this function isnt really vetted for S3 data.');
        %% load the R struct
        fnR=sprintf('/net/derivative/R/%s/%s/R_%g',...
                    participant, session, block);
        [R1] = loadvar(fnR, 'R');
      otherwise
        %% load the original stream
        fn=sprintf('/net/derivative/stream/%s/%s/%g.mat',participant,session,block);
        b(nb).stream = load(fn);

    end
    %% should now have the spikeband and lfpband for this block    
    b(nb).spikeband = spikeband;
    if exist('lfpband','var')
        b(nb).lfpband = lfpband;
    end

    %% save down minacausspikeband for use in FA
    if isfield(spikeband,'minAcausSpikeBand')
        f='minAcausSpikeBand';
    else
        f='minSpikeBand';
    end
    Rtmp(nb).minAcausSpikeBand = squeeze(spikeband.(f))';
end

%% run FA on the streams together
if ~isfield(faopts,'outputPref')
    faopts.outputPref = '/net/cache/chethan/fa/alignment/';
end
% update thresholds if they were set above
faopts.thresholds = thresh;
faopts.outputPref = sprintf('%s%s/',faopts.outputPref,session);
bstr = sprintf('%g_',blocks);
bstr = bstr(1:end-1);
faopts.outputDir = sprintf('%s%s/', faopts.outputPref, bstr);
if ~isfield(faopts,'useChannels')
    faopts.useChannels = faopts.channels;
end
processed=runFAonRstruct(Rtmp, faopts);
clear Rtmp;

%% add FA-processed data to the original streams
for nb = 1:numel(b)
    %% allocate space for the FA data
    b(nb).spikeband.xorth = zeros(size(b(nb).spikeband.(f),1), faopts.keepfs);

    for nf = 1:faopts.keepfs
        tmpa=resample(processed.seqTrain(nb).xorth(nf,:),processed.binWidth,1);
        tmpt = length(tmpa);
        b(nb).spikeband.xorth(1:tmpt,nf) = tmpa;
    end

b(nb).stream.neural = b(nb).spikeband;
if defined('lfpband')
    b(nb).stream.neural.HLFPsmoothed = lfpband.HLFPsmoothed;
end


if b(nb).stream.neural.clock(end) < b(nb).stream.continuous.clock(end)
    lastInd = find(b(nb).stream.continuous.clock == b(nb).stream.neural.clock(end));
    fprintf('loadSmoothRWithFA: fyi: trimming %i continuous samples.\n', numel(b(nb).stream.continuous.clock)-lastInd);
    fs = fields(b(nb).stream.continuous);
    for nf = 1:numel(fs)
        b(nb).stream.continuous.(fs{nf}) = b(nb).stream.continuous.(fs{nf})(1:lastInd,:,:);
    end

end

% do cursor position/velocity smoothing
if velSmoothingWindow
    for ndim = 1:size(b(nb).stream.continuous.cursorPosition,2)
        xtr = b(nb).stream.continuous.cursorPosition(:,ndim);
        b(nb).stream.continuous.cursorVelocity(:,ndim) = smooth(diff(xtr),velSmoothingWindow,'loess');
    end
end

R1 = parseStream(b(nb).stream);


%% drop some fields from the Rstr
for nf = 1:length(dropfields)
    if isfield(R1, dropfields{nf})
        R1 = rmfield(R1, dropfields{nf});
    end
end


Rs{nb}=R1;

%% i don't think the rest of this is needed, but commenting out just in case.

% %now use those block-specific variables
% spikeband = b(nb).spikeband;
% if exist('lfpband','var')
%     %% apply smoothing to the streamed lfpband data
%     lfpband = b(nb).lfpband;
% end

% %% add the stream data to the Rstr
% for nt = 1:length(R1)
%     switch participant
%       case {'t6','t7'}
%         sc = R1(nt).startcounter;
%         ec = R1(nt).endcounter;
        
%         startind = find(spikeband.clock==sc);
%         endind = find(spikeband.clock==ec);

%       case 's3'
%         sc = R1(nt).timeCerebusStart*30000;
%         ec = R1(nt).timeCerebusEnd*30000;
        
%         [~,startind] = min(abs(spikeband.cerebusTime-sc));
%         [~,endind] = min(abs(spikeband.cerebusTime-ec));

%     end

%     for nf = 1:length(streamfields)
%         if isfield(spikeband,streamfields{nf})
%             R1(nt).(streamfieldsout{nf}) = ...
%                 spikeband.(streamfields{nf})(startind:endind,:)';
%             if ~isempty(R1(nt).preTrial)
%                 R1(nt).preTrial.(streamfieldsout{nf}) = ...
%                     spikeband.(streamfields{nf})(startind+(-500:-1),:)';
%             end
%             if ~isempty(R1(nt).postTrial)
%                 R1(nt).postTrial.(streamfieldsout{nf}) = ...
%                     spikeband.(streamfields{nf})(endind+(1:500),:)';
%             end
%         end
%         if exist('lfpband','var') & isfield(lfpband,streamfields{nf})
%             R1(nt).(streamfieldsout{nf}) = ...
%                 lfpband.(streamfields{nf})(startind:endind,:)';
%             if ~isempty(R1(nt).preTrial)
%                 R1(nt).preTrial.(streamfieldsout{nf}) = ...
%                     lfpband.(streamfields{nf})(startind+(-500:-1),:)';
%             end
%             if ~isempty(R1(nt).postTrial)
%                 R1(nt).postTrial.(streamfieldsout{nf}) = ...
%                     lfpband.(streamfields{nf})(endind+(1:500),:)';
%             end
%         end
%     end

% end
end
