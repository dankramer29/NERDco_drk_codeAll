function options = defaultFilterOptions()

    options.blocksToFit = [];

    options.useTx = true;
    options.useHLFP = true;
    options.neuralChannels = [];
    options.neuralChannelsHLFP = [];


    options.multsOrThresholds = [];
    options.useFixedThresholds = true;
    options.arraySpecificThresholds = [];

    options.delayMotor = 0;
    options.binSize = 15;
    options.gaussSmoothHalfWidth = 25;
    options.tSkip = 150;

    options.minChannels = 5;
    options.maxChannels = 50;

    options.usePCA = false;
    options.numPCsToKeep = 10;
    options.removePCs = [1];

    options.withinSampleXval = 9;
    options.useVFB = false;
    options.normalizeTx = false;
    options.txNormFactor = 0.1;
    options.normalizeHLFP = false;
    options.hLFPNormFactor = 0.1;
    options.normBinSize = 50;
    options.showFigures = true;
    options.addCorrectiveBias = false;
    options.ridgeLambda = 0;
    options.neuralOnsetAlignment = false;
    options.useAcaus = true;
    options.useSqrt = false;
    options.useDwell = true;
    options.hLFPDivisor = 2500;
    options.kinematics = 'mouse';
    options.normalizeRadialVelocities = 0;
    options.rescaleSpeeds = 0;
    options.eliminateDelay = false;