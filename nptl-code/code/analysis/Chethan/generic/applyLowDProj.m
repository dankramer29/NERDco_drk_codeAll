function D=applyLowDProj(R,ld,options)
% APPLYLOWDPROJ    
% 
% D=applyLowDProj(R,ld,options)

    nD = 0;

    nR=1;
    if isfield(R(nR),'SBsmoothed')
        numTxChannels = size(R(nR).SBsmoothed,1);
    else
        numTxChannels = size(R(nR).minAcausSpikeBand,1);
    end
    if isfield(R(nR),'HLFPsmoothed')
        numHLFPChannels = size(R(nR).HLFPsmoothed,1);
    else
        numHLFPChannels = size(R(nR).HLFP,1);
    end

    for nR = 1:length(R)
        nD =nD+1;
        
        if options.useTx
            if ~isfield(R,'SBsmoothed')
                raster = zeros(size(R(nR).minAcausSpikeBand),'uint8');
                for ch = 1:numTxChannels
                    raster(ch,:) = R(nR).minAcausSpikeBand(ch,:) < options.thresh(ch);
                end
            else
                numTxChannels = size(R(nR).SBsmoothed,1);
                raster = R(nR).SBsmoothed;
            end
            sumRaster = cumsum(single(raster'));
            txBinned = diff(sumRaster(1:options.binSize:end,:))';
            numBins = size(txBinned,2);
            if options.normalizeTx
                %  normalize the data for each trial
                txBinned = bsxfun(@times, txBinned, ld.invSoftNormVals(1:numTxChannels));
            end
        end
        

        if options.useHLFP
            if ~isfield(R,'HLFPsmoothed')
                sumSquaresHLFP = cumsum(R(nR).HLFP'.^2);
            else
                numHLFPChannels = size(R(nR).HLFPsmoothed,1);
                sumSquaresHLFP = cumsum(R(nR).HLFPsmoothed'.^2);
            end
            % be sure to apply the HLFP_DIVISOR to scale the HLFP data appropriately
            HLFPBinned = diff(sumSquaresHLFP(1:options.binSize:end,:))'...
                ./single(options.HLFPDivisor);
            numBins = size(txBinned,2);
            if options.normalizeHLFP
                HLFPBinned = bsxfun(@times, HLFPBinned, ld.invSoftNormVals(numTxChannels+ ...
                                                                  (1:numHLFPChannels)));
            end
        end
        
        Z1 = zeros(numTxChannels+numHLFPChannels,numBins);
        if options.useTx
            Z1(1:numTxChannels,:) = txBinned;
        else
            Z1(1:numTxChannels,:) = 0;
        end
        if options.useHLFP
            Z1(numTxChannels+(1:numHLFPChannels),:) = HLFPBinned;
        else
            Z1(numTxChannels+(1:numHLFPChannels),:) = 0;
        end
        

        D(nD).Z = zeros(options.numOutputDims,numBins);
        % subtract off PCA means and project each trial
        D(nD).Z = ld.projector'*(bsxfun(@minus,Z1,ld.pcaMeans));
        
        if isfield(R(nR),'trialNum')
            % save the trial num
            D(nD).trialNum = R(nR).trialNum;
        end
    end
