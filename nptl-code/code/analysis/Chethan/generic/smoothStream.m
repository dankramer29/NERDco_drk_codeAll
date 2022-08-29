function [neural, smoothKernel] = smoothStream(neural, thresh, gaussSD, useHalfGauss, normalizeKernelPeak, ...
    neuralChannels, neuralChannelsHLFP)
% SMOOTHSTREAM
%
% function [neural, smoothKernel] = smoothStream(neural, thresh, gaussSD, useHalfGauss, normalizeKernelPeak, ...
%        neuralChannels, neuralChannelsHLFP)


spikefield = 'minSpikeBand';
if isfield(neural,'minAcausSpikeBand')
    spikefield = 'minAcausSpikeBand';
end


lfpfield = 'gamma';
if isfield(neural,'HLFP')
    lfpfield = 'HLFP';
end

%% should the kernel have a peak of 1 or a total mass of 1?
if ~exist('normalizeKernelPeak','var')
    normalizeKernelPeak = false;
end
%% what channels to smooth?
if ~exist('neuralChannels','var')
    neuralChannels = 1:numel(thresh);
end
if ~exist('neuralChannelsHLFP','var')
    neuralChannelsHLFP = 1:numel(thresh);
end

if isfield(neural,spikefield)
    %% threshold and gaussian smooth
    sf = squeeze(neural.(spikefield));
    
    if length(thresh) == 1
        error('smoothStream: threshold should be at least 96 channels');
    end
    %for nc=1:length(thresh)
    for nc=neuralChannels
        sb=sf(:,nc)'<thresh(nc);
        if gaussSD
            [sbtmp,k] = gaussianSmooth(sb(:),gaussSD,1,0,struct('useHalfGauss',useHalfGauss));
            % preallocate for speed
            if ~exist('sbgauss','var')
                sbgauss = zeros(length(thresh), length(sbtmp),'single');
            end
            sbgauss(nc,:)=single(sbtmp);
            if normalizeKernelPeak
                sbgauss(nc,:) = sbgauss(nc,:) / max(k);
            end
        else
            if ~exist('sbgauss','var')
                sbgauss = zeros(length(thresh), length(sb),'single');
            end
            sbgauss(nc,:) = sb;
        end
    end
    neural.SBsmoothed=sbgauss';
end

if isfield(neural, lfpfield)
    %% smooth hlfp
    hlfp = double(squeeze(neural.(lfpfield)).^2)';
    if size(hlfp, 1) ~= length(thresh)
        disp(...
            sprintf('smoothStream: warning - hlfp size and proposed number of channels dont match up, %g ~= %g', size(hlfp,1), length(thresh)));
    end
    % for nc=1:length(thresh)
    if  ~exist('hlfpgauss','var')
        if ~gaussSD
            hlfpgauss = zeros(length(thresh), length(hlfp),'single');
        else
            hlfpgauss = zeros(size(sbgauss));
        end
    end
    
    for nc=neuralChannelsHLFP %if this is an empty vector hlfpgauss needs to be pre initialized -SNF
        if gaussSD
            [hlfptmp,k] = gaussianSmooth(hlfp(nc,:)',gaussSD,1,0,struct('useHalfGauss',useHalfGauss));
            % preallocate for speed
            if ~exist('hlfpgauss','var')
                hlfpgauss = zeros(length(thresh), length(hlfptmp),'single');
            end
            hlfpgauss(nc,:)=single(sqrt(hlfptmp));
            if normalizeKernelPeak
                hlfpgauss(nc,:) = hlfpgauss(nc,:) / max(k);
            end
        else
            %                 if ~exist('hlfpgauss','var')
            %                     hlfpgauss = zeros(length(thresh), length(hlfp),'single');
            %                 end
            hlfpgauss(nc,:)=single(sqrt(hlfp(nc,:)));
        end
    end

        neural.HLFPsmoothed = hlfpgauss';

end

%% output the kernel used for smoothing
smoothKernel = k;
