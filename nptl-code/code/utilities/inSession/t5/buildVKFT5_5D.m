function buildVKFT5_5D(streams)

if ~exist('streams','var')
    streams = [];
end

global CURRENT_FILTER_NUMBER
if isempty(CURRENT_FILTER_NUMBER)
    CURRENT_FILTER_NUMBER = 1;
else
    CURRENT_FILTER_NUMBER = CURRENT_FILTER_NUMBER + 1;
end

whichArray = rigHardwareConstants.ARRAY_T5_BOTH;

global modelConstants
switch modelConstants.isSim
    case true
        % for dev, use fewer folds
        options.withinSampleXval = 4; % number of cross-validation folds 
    case false
        options.withinSampleXval = 9; % number of cross-validation folds
end
options.kinematics = 'mouse';
options.useAcaus = true;
options.normBinSize = 50;
options.txNormFactor = options.normBinSize*0.03;
options.hLFPNormFactor = options.normBinSize*0.03;
options.usePCA = false;
options.useTx = true;
options.showFigures = true;
options.whichArray = whichArray;

% limit # of channels to sweep to save time during filter builds:
options.minChannels = 10;
options.maxChannels = 130;    


%% for 15 ms models (with 25ms gaussian smoothing)
options.savedModel.A = [1 0 0 0 0   15     0     0     0    0    0;
                        0 1 0 0 0    0    15     0     0    0    0;
                        0 0 1 0 0    0     0    15     0    0    0;
                        0 0 0 1 0    0     0     0    15    0    0;
                        0 0 0 0 1    0     0     0     0   15    0;
                        0 0 0 0 0 0.99     0     0     0    0    0;
                        0 0 0 0 0    0  0.99     0     0    0    0;
                        0 0 0 0 0    0     0  0.99     0    0    0; 
                        0 0 0 0 0    0     0     0  0.99    0    0; 
                        0 0 0 0 0    0     0     0     0 0.99    0; 
                        0 0 0 0 0    0     0     0     0    0    1];
                    
                    
options.savedModel.W = [0 0 0 0 0      0      0      0      0      0 0;
                        0 0 0 0 0      0      0      0      0      0 0;
                        0 0 0 0 0      0      0      0      0      0 0;
                        0 0 0 0 0      0      0      0      0      0 0;
                        0 0 0 0 0      0      0      0      0      0 0;
                        0 0 0 0 0 0.0016      0      0      0      0 0;
                        0 0 0 0 0      0 0.0016      0      0      0 0;
                        0 0 0 0 0      0      0 0.0016      0      0 0;
                        0 0 0 0 0      0      0      0 0.0016      0 0;
                        0 0 0 0 0      0      0      0      0 0.0016 0;
                        0 0 0 0 0      0      0      0      0      0 0] * sqrt(2) .* (2.5e-4)^2; % last conversion is roughly
                                                                                                 % to account for pixels to meters unit change
																								 
																								    

%% options that are prompted
prompt.startingFilterNum = num2str(CURRENT_FILTER_NUMBER);
prompt.blocksToFit = '';
prompt.binSize = '15';
prompt.delayMotor = '60';
prompt.useVFB = 'false';
prompt.useHLFP = 'false';
prompt.normalizeTx = 'true';
prompt.normalizeHLFP = 'true';
prompt.tSkip = '150';
prompt.useDwell = 'true';
prompt.hLFPDivisor = '2500';
prompt.gaussSmoothHalfWidth = '25';
prompt.neuralOnsetAlignment = 'false';
prompt.addCorrectiveBias = 'false';
prompt.useSqrt = 'false';
prompt.ridgeLambda = '0';
% fixed threshold or an RMS multiplier?
% -95 is in the range of -3xRMS, calculated from t5160921 data
prompt.fixedThreshold = ''; 
prompt.rmsMultiplier = num2str(-4.5);
prompt.alpha = '0.94';
prompt.beta = '0.1';
prompt.singleDOFNorm = 'false';
prompt.eliminateFailures = 'true';

% build a channel exclusion list eventually
allChannels = 1:192;
%updated 9/27/17:
excludeChannels = [2 46 66 67 68 69 73 76 77 78 82 83 85 86 94 95 96];

options.neuralChannels = setdiff(allChannels,excludeChannels);
options.neuralChannelsHLFP = options.neuralChannels;

options.normalizeRadialVelocities = false;


buildFilterDialog(streams, options, prompt);

