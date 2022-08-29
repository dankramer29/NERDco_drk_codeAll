function discretemodel = calculateDiscreteParams(R,options)
%% Check options and set defaults:
%% SNF: this includes always saying useFA is false
%% options for the neural data
    % bin size
    checkOption(options,'binSize','must specify whether to use bin size (in MS)');
    % useSpikes
    checkOption(options,'useTx','must specify whether to use nctx');
    % how much (in MS) to shift the spikes relative to state vector
    checkOption(options,'shiftSpikes','must specify how much to shift spikes (in MS)');
    % which nctx channels to use    
    checkOption(options,'neuralChannels','must specify which nctx channels to use');
    % tx thresholds (in uV)
    checkOption(options,'thresh','must specify thresholds for crossing (in uV)','useTx');
    % useHLFP
    checkOption(options,'useHLFP','must specify whether to use HLFP');
    % how much (in MS) to shift the HLFP relative to state vector
    checkOption(options,'shiftHLFP','must specify how much to shift HLFP (in MS)');
    % which hlfp channels to use    
    checkOption(options,'neuralChannelsHLFP','must specify which hlfp channels to use');
    % HLFP Divisor
    checkOption(options,'HLFPDivisor','must specify an HLFPDivisor if using hlfp','useHLFP');
    % whether or not to normalize tx
    options=setDefault(options,'normalizeTx',false);
    % spikeSoftNorm factor 
    checkOption(options,'txNormFactor','must specify a TX soft normalization factor','normalizeTx');
    % whether or not to normalize hlfp
    options=setDefault(options,'normalizeHLFP',false);
    % HLFPSoftnorm factor
    checkOption(options,'HLFPNormFactor','must specify an HLFP soft normalization factor','normalizeHLFP');
    % whether or not to use PCA
    checkOption(options,'usePCA','must specify whether to use PCA');
    % whether or not to use FA
    options = setDefault(options,'useFA',false); %SNF: WTF so this is never a real option?? 
    % how many PCs to keep
    if options.usePCA
        checkOption(options,'numPCsToKeep','must specify number of PCs to keep','usePCA');
    elseif options.useFA
        checkOption(options,'numPCsToKeep','must specify number of PCs (factors) to keep','useFA');
    end
    % smooth the spike/lfp bands?
    options = setDefault(options,'gaussSmoothHalfWidth',0);
%% options for the discrete data
    % restSpeedThreshold
    checkOption(options,'restSpeedThresholdPercent','must specify a rest speed threshold percentage');
    % what output dimensionality is the decoder expecting
    options = setDefault(options,'numOutputDims',DecoderConstants.NUM_CONTINUOUS_CHANNELS);    
%% Steps:
    %  shift the neural data for motor delays (if desired)
    if options.shiftSpikes
        R = shiftRstruct(R,'minAcausSpikeBand',-options.shiftSpikes);
    end
    if options.shiftHLFP
        R = shiftRstruct(R,'HLFP',-options.shiftHLFP);
    end
    % stream the cursor position data
    cp = [R.cursorPosition]';
    % save the binsize
    discretemodel.dtMS = options.binSize;
    % bin%SNF: by just cutting out data instead of something more elegant like averaging over that period. Weird. 
    cursorPosition = double(cp(1:options.binSize:end,:));
    dCursorPosition = diff(cursorPosition)/options.binSize;
    % estimate the velocity distribution
    speed = sqrt(sum(dCursorPosition'.^2));
    options.restSpeedThreshold = quantile(speed,options.restSpeedThresholdPercent);
    % stream the neural data
    clockDiff = diff(double([R.clock]));
    if any(clockDiff>1)
        disp(['warning: Rstruct is not contiguous. max ' num2str(max(clockDiff)-1) ' skipped samples in a row']);
    end
    continuous.clock = [R.clock];
%% smooth data if requested
    if options.gaussSmoothHalfWidth
        if ~isfield(R,'SBsmoothed')
            R = smoothR(R,options.thresh,options.gaussSmoothHalfWidth,true);
        end
        continuous.SBsmoothed = [R.SBsmoothed];
        continuous.HLFPsmoothed = [R.HLFPsmoothed];
    end
    continuous.minAcausSpikeBand = [R.minAcausSpikeBand];
    continuous.HLFP = [R.HLFP];

    dm = calculateLowDProjection(continuous, options);
    f = fields(dm);
    for nn = 1:length(f)
        discretemodel.(f{nn}) = dm.(f{nn});
    end