function buildRefitT5(streams)

if ~exist('streams','var')
    streams = [];
end

global CURRENT_FILTER_NUMBER
global modelConstants
if isempty(CURRENT_FILTER_NUMBER)
    CURRENT_FILTER_NUMBER = 1;
else
    CURRENT_FILTER_NUMBER = CURRENT_FILTER_NUMBER + 1;
end

whichArray = rigHardwareConstants.ARRAY_T5_BOTH;

%% hard-coded options
options.withinSampleXval = 9;
options.kinematics = 'refit';
options.useAcaus = true;
options.normalizeTx = false;
options.normalizeHLFP = false;
options.normBinSize = 50;
options.txNormFactor = options.normBinSize*0.03;
options.hLFPNormFactor = options.normBinSize*0.03;
options.usePCA = false;
options.useTx = true;
options.showFigures = true;
options.whichArray = whichArray;
options.neuralOnsetAlignment = false;
options.pixels = false; % whether units are pixels or meters. irrelevant 
%here, unless we decide to hard-code W.

% limit # of channels to sweep to save time during filter builds:
options.minChannels = 10;
options.maxChannels = 150;


%% options that are prompted
prompt.startingFilterNum = num2str(CURRENT_FILTER_NUMBER);
prompt.blocksToFit = '';
prompt.orthoBlocks = '';
prompt.binSize = '15';
prompt.delayMotor = '0';
prompt.useVFB = 'false';
prompt.useHLFP = 'false';
prompt.normalizeTx = 'true';
prompt.normalizeHLFP = 'true';
prompt.tSkip = '150';
prompt.useDwell = 'true';
prompt.hLFPDivisor = '2500';
prompt.gaussSmoothHalfWidth = '25';
prompt.addCorrectiveBias = 'false';
prompt.useSqrt = 'false';
prompt.ridgeLambda = '0';
% fixed threshold or an RMS multiplier?
% -95 is in the range of -3xRMS, calculated from t5160921 data
switch modelConstants.isSim
    case true
        prompt.fixedThreshold = num2str(-95);
        prompt.rmsMultiplier = '';
    case false
        prompt.fixedThreshold = '';
        prompt.rmsMultiplier = num2str(-3.5);
end
prompt.alpha = '0.94';
prompt.beta = '0.1';
prompt.singleDOFNorm = 'false';
prompt.posSubtraction = 'false';
prompt.eliminateFailures = 'true';

% build a channel exclusion list eventually
allChannels = 1:192;
% excludeChannels = [54, 161, 192];  %are we sure these are correct IDs?
%updated 9/27/17:
excludeChannels = [2 46 66 67 68 69 73 76 77 78 82 83 85 86 94 95 96];

options.neuralChannels = setdiff(allChannels,excludeChannels);
options.neuralChannelsHLFP = options.neuralChannels;

options.normalizeRadialVelocities = false;



buildFilterDialog(streams, options, prompt);

