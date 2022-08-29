function [neural] = calcRollingMeans(neural, thresh, timeConstantMS, neuralChannels, neuralChannelsHLFP)
% CALCROLLINGMEANS    
% 
% [neural] = calcRollingMeans(neural, thresh, timeConstantMS, neuralChannels, neuralChannelsHLFP)


    spikefield = 'minSpikeBand';
    if isfield(neural,'minAcausSpikeBand')
        spikefield = 'minAcausSpikeBand';
    end
    if isfield(neural,'SBsmoothed')
        spikefield = 'SBsmoothed';
    end
    
    lfpfield = 'gamma';
    if isfield(neural,'HLFP')
        lfpfield = 'HLFP';
    end
    if isfield(neural,'HLFPsmoothed')
        lfpfield = 'HLFPsmoothed';
    end
    %% what channels to use?
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
        for nc=neuralChannels
            % if we're not using smoothed, we need to threshold
            if ~strcmp(spikefield,'SBsmoothed')
                sb=sf(:,nc)'<thresh(nc);
            else
                sb = sf(:,nc)';
            end
            
            [sbtmp] = smoothts(sb(:)','e',timeConstantMS);
            % preallocate for speed
            if ~exist('sbmean','var')
                sbmean = zeros(length(thresh), length(sbtmp),'single');
            end
            sbmean(nc,:)=single(sbtmp);
        end
        neural.SBmeans=sbmean';

    end
    
    if isfield(neural, lfpfield)
        %% smooth hlfp
        hlfp = double(squeeze(neural.(lfpfield)).^2)';
        if size(hlfp, 1) ~= length(thresh)
            disp(...
                sprintf('smoothStream: warning - hlfp size and proposed number of channels dont match up, %g ~= %g', size(hlfp,1), length(thresh)));
        end
        % for nc=1:length(thresh)
        for nc=neuralChannelsHLFP
            sb = hlfp(nc,:);
            [hlfptmp] = smoothts(sb(:)','e',timeConstantMS);
            % preallocate for speed
            if ~exist('hlfpgauss','var')
                hlfpgauss = zeros(length(thresh), length(hlfptmp),'single');
            end
            hlfpgauss(nc,:)=single(sqrt(hlfptmp));
        end
        neural.HLFPmeans=hlfpgauss';
    end

    %% output the kernel used for smoothing
