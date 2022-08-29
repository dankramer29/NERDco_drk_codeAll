function [R,k]=smoothR(R,thresholds,gausswidth,useHalfGauss)
% SMOOTHR    
% 
% [R,k]=smoothR(R,thresholds,gausswidth,useHalfGauss)

%% apply gaussian smoothing to minAcausSpikeBand data in Rstruct. 
%% output is the same Rstruct with an 'SBsmoothed' field

    if ~exist('useHalfGauss','var')
        useHalfGauss = false;
    end
    smoothOptions.useHalfGauss = useHalfGauss;
    if isfield(R,'HLFP');
        smoothLFP = true;
    else
        smoothLFP = false;
    end
    for nR = 1:length(R)
        numTxChannels = length(thresholds);
        masb = R(nR).minAcausSpikeBand;
        if smoothLFP
            hlfp = R(nR).HLFP;
            hlfp = double(hlfp.^2);
        end

        %% to alleviate edge effects, use pre- and post- trial data if available
        if isfield(R(nR),'preTrial') & ~isempty(R(nR).preTrial)
            masbPre = [R(nR).preTrial.minAcausSpikeBand];
            masb = [masbPre masb];
            if smoothLFP && isfield(R(nR).preTrial,'HLFP')
                hlfpPre = R(nR).preTrial.HLFP;
                hlfp = [hlfpPre hlfp];
            else
                hlfpPre = [];
            end
        else
            masbPre = [];
            hlfpPre = [];
        end
        if isfield(R(nR),'postTrial') & ~isempty(R(nR).postTrial)
            masbPost = [R(nR).postTrial.minAcausSpikeBand];
            masb = [masb masbPost];
            if smoothLFP && isfield(R(nR).postTrial,'HLFP')
                hlfpPost = R(nR).postTrial.HLFP;
                hlfp = [hlfp hlfpPost];
            else
                hlfpPost = [];
                hlfpPost = [];
            end
        else
            masbPost = [];
            hlfpPost = [];
        end

        raster = zeros(size(masb),'uint8');
        for ch = 1:numTxChannels
            raster(ch,:) = masb(ch,:) < thresholds(ch);
        end


        %% smooth spikeband data
        if size(raster,2)
            [smoothedtmp,k] = gaussianSmooth(double(raster)',gausswidth,1,1,smoothOptions);
            smoothed = smoothedtmp';
        else
            smoothed = [];
        end
        if size(masbPre,2)
            smoothed = smoothed(:,size(masbPre,2)+1:end);
        end
        if size(masbPost,2)
            smoothed = smoothed(:,1:end-size(masbPost,2));
        end
        R(nR).SBsmoothed = smoothed;
        
        %% smooth lfp data
        if smoothLFP
            if size(hlfp,2)
                [smoothedtmp,k] = gaussianSmooth(double(hlfp)',gausswidth,1,1,smoothOptions);
                smoothed = sqrt(smoothedtmp');
            else
                smoothed = [];
            end
            if size(hlfpPre,2)
                smoothed = smoothed(:,size(hlfpPre,2)+1:end);
            end
            if size(hlfpPost,2)
                smoothed = smoothed(:,1:end-size(hlfpPost,2));
            end
            R(nR).HLFPsmoothed = smoothed;
        end
    end
        
