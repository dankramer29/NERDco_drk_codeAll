function buildVKFT7(streams)

if ~exist('streams','var')
    streams = [];
end

global CURRENT_FILTER_NUMBER
if isempty(CURRENT_FILTER_NUMBER)
    CURRENT_FILTER_NUMBER = 1;
else
    CURRENT_FILTER_NUMBER = CURRENT_FILTER_NUMBER + 1;
end

%whichArray = rigHardwareConstants.ARRAY_T7_MEDIAL;
%whichArray = rigHardwareConstants.ARRAY_T7_LATERAL;
%whichArray = rigHardwareConstants.ARRAY_T7_BOTH;

%% hard-coded options.withinSampleXval = 9;
options.withinSampleXval = 9;
options.kinematics = 'mouse';
options.useAcaus = true;
options.normBinSize = 50;
options.txNormFactor = options.normBinSize*0.03;
options.hLFPNormFactor = options.normBinSize*0.03;
options.usePCA = false;
options.useTx = true;
options.showFigures = true;
%options.whichArray = whichArray;

% %% fix the state model

% %% for 15 ms models (with 25ms gaussian smoothing)
% options.savedModel.A = [1 0 50 0 0;
%                         0 1 0 50 0;
%                         0 0 0.979 0 0;
%                         0 0 0 0.979 0;
%                         0 0 0 0 1];
% options.savedModel.W = [0 0 0 0 0;
%                         0 0 0 0 0;
%                         0 0 0.0025 0 0;
%                         0 0 0 0.0025 0;
%                         0 0 0 0 0];
%           

%% options that are prompted
prompt.startingFilterNum = num2str(CURRENT_FILTER_NUMBER);
prompt.blocksToFit = '';
prompt.binSize = '15';
prompt.delayMotor = '60';
prompt.useVFB = 'false';
%prompt.fixedThreshold = '-100';
prompt.rmsMultiplier = '';
prompt.useHLFP = 'false';
prompt.normalizeTx = 'false';
prompt.normalizeHLFP = 'false';
prompt.tSkip = '150';
prompt.useDwell = 'true';
prompt.hLFPDivisor = '2500';
prompt.maxChannels = '50';
prompt.gaussSmoothHalfWidth = '25';
prompt.rescaleSpeeds = '0';
prompt.neuralOnsetAlignment = 'false';
prompt.addCorrectiveBias = 'false';
prompt.useSqrt = 'false';
prompt.ridgeLambda = '0';
prompt.normalizeRadialVelocities = '0';

% hardcoded
chExcludeLateral = [1:18 20 22:24 26 28 33:36 43 44 56 65:71 75:79];
allChannelsLateral = [1:96];
chExcludeMedial = [];
allChannelsMedial = [1:96];


allChannels = [allChannelsLateral allChannelsMedial+96];
excludeChannels = [chExcludeLateral];
prompt.arraySpecificThresholds = '-70 -70';


options.neuralChannels = setdiff(allChannels,excludeChannels);
options.neuralChannelsHLFP = options.neuralChannels;
options.normalizeRadialVelocities = false;


buildFilterDialog(streams, options, prompt);

