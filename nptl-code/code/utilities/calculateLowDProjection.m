function discretemodel = calculateLowDProjection(continuous, options)

%% if using FA, then keep everything at 1ms bins until after FA is run
    binsizeHighD = options.binSize;
    if ~isfield(options,'useFA')
        options.useFA = false;
    end
    if options.useFA
        binsizeHighD = 1;
    end

    % calc threshold crossings & bin the tx data
    if isfield(continuous,'SBsmoothed')
%        numTxChannels = size(continuous.SBsmoothed,1);
        numTxChannels = double(DecoderConstants.NUM_SPIKE_CHANNELS);
%	numHLFPChannels = size(continuous.HLFPsmoothed,1);
    numHLFPChannels = double(DecoderConstants.NUM_HLFP_CHANNELS);
    else
%        numTxChannels = size(continuous.minAcausSpikeBand,1);
        numTxChannels = double(DecoderConstants.NUM_SPIKE_CHANNELS);
%	numHLFPChannels = size(continuous.HLFP,1);
    numHLFPChannels = double(DecoderConstants.NUM_HLFP_CHANNELS);
    end
    if options.useTx
        if ~options.gaussSmoothHalfWidth || options.useFA
            if length(options.thresh) ~= size(continuous.minAcausSpikeBand,1)
                error('onlineDfromR: need to pass in a threshold for all spiking channels');
            end
            raster = zeros(size(continuous.minAcausSpikeBand),'uint8');
            for ch = 1:size(continuous.minAcausSpikeBand,1)
                raster(ch,:) = continuous.minAcausSpikeBand(ch,:) < options.thresh(ch);
            end
            discretemodel.thresholds = options.thresh;
        else
            raster = continuous.SBsmoothed;
        end
        sumRaster = cumsum(single(raster'));
        txBinned = diff(sumRaster(1:binsizeHighD:end,:))';
        clear sumRaster
        % eliminate unused channels
        channels = false([size(txBinned,1) 1]);
        channels(options.neuralChannels) = true;
        txBinned(~channels,:)=0;
    else
        txBinned = [];
    end
    % bin the HLFP data
    if options.useHLFP
        if ~options.gaussSmoothHalfWidth || options.useFA
            sumSquaresHLFP = cumsum(continuous.HLFP'.^2);
        else
%            numHLFPChannels = size(continuous.HLFPsmoothed,1);
            numHLFPChannels = double(DecoderConstants.NUM_HLFP_CHANNELS);
            sumSquaresHLFP = cumsum(continuous.HLFPsmoothed'.^2);
        end
        % be sure to apply the HLFP_DIVISOR to scale the HLFP data appropriately
        HLFPBinned = diff(sumSquaresHLFP(1:binsizeHighD:end,:))'...
            ./single(options.HLFPDivisor);
        clear sumSquaresHLFP
        
        % eliminate unused channels
        channels = false([size(HLFPBinned,1) 1]);
        channels(options.neuralChannelsHLFP) = true;
        HLFPBinned(~channels,:)=0;
        dm.hLFPDivisor = options.HLFPDivisor;
    else
        HLFPBinned = [];
    end

    discretemodel.invSoftNormVals = ones([numTxChannels+numHLFPChannels 1],'single');

    %  calculate normalization factors if desired
    if options.useTx && options.normalizeTx
        normFactorsTx = calcNormFactors(txBinned',options.txNormFactor)';
        % normalize and save over the original binned tx data
        txBinned = bsxfun(@times, txBinned, normFactorsTx(:));
        discretemodel.invSoftNormVals(1:size(txBinned, 1)) = normFactorsTx;
    end
    if options.useHLFP && options.normalizeHLFP
        normFactorsHLFP = calcNormFactors(HLFPBinned',options.HLFPNormFactor)';
        % normalize and save over the original binned LFP data
        HLFPBinned = bsxfun(@times, HLFPBinned, normFactorsHLFP(:));
        discretemodel.invSoftNormVals(numTxChannels+(1:size(HLFPBinned, 1))) = normFactorsHLFP;
    end

    %  create low dimensional projector matrices (if desired)
    % default is just a unitary projection
    discretemodel.projector = zeros([numTxChannels + numHLFPChannels, options.numOutputDims],'double');
    discretemodel.pcaMeans = zeros([numTxChannels + numHLFPChannels,1],'double');
    if options.usePCA | options.useFA
        numPCsToKeep = options.numPCsToKeep;
        removePCs = options.removePCs;
        assert(numPCsToKeep <= options.numOutputDims, ...
               ['onlineDfromR: too many PCs for number of possible output dimensions']);

        if ~options.useTx && ~options.useHLFP
            error('calculateLowDProjection: dont know how to do this w/o tx or hlfp');
        end
        if ~options.useTx
            txBinned = zeros(size(HLFPBinned));
        elseif ~options.useHLFP
            HLFPBinned = zeros(size(txBinned));
        end
%        Z = [txBinned;HLFPBinned];
        Z = zeros(DecoderConstants.NUM_CONTINUOUS_CHANNELS, size(txBinned, 2));
        Z(1:size(txBinned, 1), :) = txBinned;
        Z(numTxChannels + (1:size(HLFPBinned, 1)), :) = HLFPBinned;
        
        if ~options.useTx
            Z(1:numTxChannels,:) = 0;
        end
        if ~options.useHLFP
            Z(numTxChannels+(1:numHLFPChannels),:) = 0;
        end

        if options.usePCA
            % princomp expects data to be [Nobs x Ndims]
            discretemodel.pcaMeans = mean(Z',1)';

            [PCs,scores,eVals] = princomp(Z', 'econ');
            % save only the number of PCs we actually want...
            discretemodel.projector(:,1:numPCsToKeep) = PCs(:,1:numPCsToKeep);
            discretemodel.latent = eVals;
            fprintf('calculateLowDProjection: I just calculated the low D projection for a HMMPCA decoder\n');
            discretemodel.discreteDecoderType = DecoderConstants.DISCRETE_DECODER_TYPE_HMMPCA;
            if ~isempty(removePCs) && any(removePCs)
                discretemodel.projectors(:,removePCs) = 0;
            end
        elseif options.useFA
            %% send data into FA code
            dat(1).trialId = 1;
            dat(1).spikes = Z;
 
            binWidth = options.binSize;
            kernSD = options.gaussSmoothHalfWidth;
            blocksStr = num2str(options.blocksToFit,'%g_');
            blocksStr = blocksStr(1:end-1);
            outputDir = sprintf('Data/FA/HMM_%s_%gms',blocksStr,kernSD);
            runIdx = 1;
            method = 'fa';
            xDim = 6;
            if ~isdir(outputDir),
                disp(['calculateLowDProjection: mkdir ' outputDir]);
                mkdir(outputDir);
            end
            result = neuralTraj(runIdx, dat, 'method', method, ...
                                'xDim', xDim, 'outputDir',outputDir, ...
                                'binWidth', binWidth ,'kernSDList',[kernSD]);

            % Orthonormalize neural trajectories
            [estParams, seqTrain] = postprocess(result, 'kernSD', kernSD);

            numContinuousChannels = numTxChannels + numHLFPChannels;
            allNeuralChannels = [options.neuralChannels(:); ...
                                options.neuralChannelsHLFP(:)+numTxChannels];
            %% pull out FA-related terms
            % lambda
            lambda1 = estParams.Corth;
            lambda = zeros(numContinuousChannels, xDim);
            lambda(allNeuralChannels,:) = estParams.Corth;
            % psi
            psi1 = estParams.R;
            psiDiag = zeros(numContinuousChannels,1);
            psiDiag(allNeuralChannels) = diag(psi1);
            psi = diag(psiDiag);
            % offsets
            means1 = estParams.d;
            means = zeros(numContinuousChannels,1);
            means(allNeuralChannels) = means1;

            %% calculate beta (project matrix)
            B=lambda'*pinv(psi+lambda*lambda');
            
            % %% check to make sure output matches what we expect:
            % % bin Z by binWidth
            % sumZ = cumsum(Z');
            % Zbinned = diff(sumZ(1:binWidth:end,:))';
            % xorth = B*bsxfun(@minus,sqrt(Zbinned),means);
            % plot(xorth(1,:));
            % hold on;
            % plot(seqTrain.xorth(1,:),'k');

            %% save these parameters
            discretemodel.projector(:,1:numPCsToKeep) = B(1:numPCsToKeep,:)';
            discretemodel.pcaMeans = means;

            discretemodel.discreteDecoderType = DecoderConstants.DISCRETE_DECODER_TYPE_HMMFA;
            fprintf('calculateLowDProjection: I just calculated the low D projection for a HMMFA decoder\n');
        end
    else
        if options.numOutputDims ~= numTxChannels+numHLFPChannels
            error('dont understand requested output dimensionality without PCA or FA...?')
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
        discretemodel.discreteDecoderType = DecoderConstants.DISCRETE_DECODER_TYPE_HMMLDA;
        fprintf('calculateLowDProjection: assuming you want an HMMLDA decoder\n');
    end
    
    discretemodel.options = options;
    