function buildVKFT6(streams)

if ~exist('streams','var')
    streams = [];
end

global CURRENT_FILTER_NUMBER
if isempty(CURRENT_FILTER_NUMBER)
    CURRENT_FILTER_NUMBER = 1;
else
    CURRENT_FILTER_NUMBER = CURRENT_FILTER_NUMBER + 1;
end

whichArray = rigHardwareConstants.ARRAY_T6;


options.withinSampleXval = 9;
options.kinematics = 'mouse';
options.useAcaus = true;
options.normBinSize = 50;
options.txNormFactor = options.normBinSize*0.03;
options.hLFPNormFactor = options.normBinSize*0.03;
options.usePCA = false;
options.useTx = true;
options.showFigures = true;
options.whichArray = whichArray;


%% for 15 ms models (with 25ms gaussian smoothing)
options.savedModel.A = [1 0 15 0 0;
                        0 1 0 15 0;
                        0 0 0.979 0 0;
                        0 0 0 0.979 0;
                        0 0 0 0 1];
options.savedModel.W = [0 0 0 0 0;
                        0 0 0 0 0;
                        0 0 0.0016 0 0;
                        0 0 0 0.0016 0;
                        0 0 0 0 0] * sqrt(2);
          

%% options that are prompted
prompt.startingFilterNum = num2str(CURRENT_FILTER_NUMBER);
prompt.blocksToFit = '';
prompt.binSize = '15';
prompt.delayMotor = '60';
prompt.useVFB = 'false';
%prompt.fixedThreshold = '-100';
prompt.rmsMultiplier = '';
prompt.useHLFP = 'true';
prompt.normalizeTx = 'true';
prompt.normalizeHLFP = 'true';
prompt.tSkip = '150';
prompt.useDwell = 'true';
prompt.hLFPDivisor = '2500';
prompt.maxChannels = '200';
prompt.gaussSmoothHalfWidth = '25';
prompt.neuralOnsetAlignment = 'false';
prompt.addCorrectiveBias = 'false';
prompt.useSqrt = 'false';
prompt.ridgeLambda = '0';
prompt.normalizeRadialVelocities = '0';
prompt.fixedThreshold = num2str(-50);


%% list revised on 2014-03-25
options.neuralChannels = ...
    [ 32	45    60:64 ...
    65    66    67    68    69    70    71    72    73    74 ...
    75    76    77    78    79    80    81    82    83    84 ...
    85    86    87    88    89    90    91    92    93    94 ...
    95    96 ...
    ];

%% list revised 2014-03-25
options.neuralChannelsHLFP = [...
    1:9  ...
    10 11 13:17 19 ...
    20:28 ...
    30:35 37 38 ...
    40:49    ...
    50:59   ...
    60:69    ...
    70:79    ...
    80:89    ...
    90:96];

options.normalizeRadialVelocities = false;


buildFilterDialog(streams, options, prompt);

