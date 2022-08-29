function discretemodel = calculateSmoothedLowDProjection(continuous, options)    
    % calc threshold crossings & bin the tx data
    if options.useTx
        numTxChannels = size(continuous.SBsmoothed,1);
        sumRaster = cumsum(single(continuous.SBsmoothed'));
        txBinned = diff(sumRaster(1:options.binSize:end,:))';
        clear sumRaster
        % eliminate unused channels
        channels = false([size(txBinned,1) 1]);
        channels(options.neuralChannels) = true;
        txBinned(~channels,:)=0;
    else
        numTxChannels = 0;
        txBinned = [];
    end
    % bin the HLFP data
    if options.useHLFP
        numHLFPChannels = size(continuous.HLFP,1);
        sumSquaresHLFP = cumsum(continuous.HLFP'.^2);
        % be sure to apply the HLFP_DIVISOR to scale the HLFP data appropriately
        HLFPBinned = diff(sumSquaresHLFP(1:options.binSize:end,:))'...
            ./single(options.HLFPDivisor);
        clear sumSquaresHLFP
        
        % eliminate unused channels
        channels = false([size(HLFPBinned,1) 1]);
        channels(options.neuralChannelsHLFP) = true;
        HLFPBinned(~channels,:)=0;
        dm.hLFPDivisor = options.HLFPDivisor;
    else
        numHLFPChannels = 0;
        HLFPBinned = [];
    end

    discretemodel.invSoftNormVals = zeros([numTxChannels+numHLFPChannels 1],'single');

    %  calculate normalization factors if desired
    if options.useTx && options.normalizeTx
        normFactorsTx = calcNormFactors(txBinned',options.txNormFactor)';
        % normalize and save over the original binned tx data
        txBinned = bsxfun(@times, txBinned, normFactorsTx(:));
        discretemodel.invSoftNormVals(1:numTxChannels) = normFactorsTx;
    end
    if options.useHLFP && options.normalizeHLFP
        normFactorsHLFP = calcNormFactors(HLFPBinned',options.HLFPNormFactor)';
        % normalize and save over the original binned LFP data
        HLFPBinned = bsxfun(@times, HLFPBinned, normFactorsHLFP(:));
        discretemodel.invSoftNormVals(numTxChannels+(1:numHLFPChannels)) = normFactorsHLFP;
    end
    %  create low dimensional projector matrices (if desired)
    % default is just a unitary projection
    discretemodel.projector = zeros([numTxChannels + numHLFPChannels, options.numOutputDims],'double');
    discretemodel.pcaMeans = zeros([numTxChannels + numHLFPChannels,1],'double');
    if options.usePCA
        numPCsToKeep = options.numPCsToKeep;
        assert(numPCsToKeep <= options.numOutputDims, ...
               ['onlineDfromR: too many PCs for number of possible output dimensions']);
        Z = [txBinned;HLFPBinned];
        
        if ~options.useTx
            Z(1:numTxChannels,:) = 0;
        end
        if ~options.useHLFP
            Z(numTxChannels+(1:numHLFPChannels),:) = 0;
        end
        
        % princomp expects data to be [Nobs x Ndims]
        discretemodel.pcaMeans = mean(Z',1)';
        [PCs,scores,eVals] = princomp(Z', 'econ');
        % save only the number of PCs we actually want...
        discretemodel.projector(:,1:numPCsToKeep) = PCs(:,1:numPCsToKeep);
    else
        if options.numOutputDims ~= numTxChannels+numHLFPChannels
            error('dont understand requested output dimensionality without PCA...?')
        end
        % discretemodel.projector = eye(size(discretemodel.projector));
        for nn = 1:length(options.neuralChannels)
            cn = options.neuralChannels(nn);
            discretemodel.projector(cn,cn) = 1;
        end
        for nn = 1:length(options.neuralChannelsHLFP)
            cn = options.neuralChannelsHLFP(nn)+numTxChannels;
            discretemodel.projector(cn,cn) = 1;
        end
    end
    
    discretemodel.options = options;
    