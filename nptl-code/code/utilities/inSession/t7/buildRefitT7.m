function buildRefitT7(streams)

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
whichArray = rigHardwareConstants.ARRAY_T7_BOTH;

%% hard-coded options.withinSampleXval = 9;
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

% %% fix the state model - this was for 50ms models

% %% for 15 ms models (with 25ms gaussian smoothing)
% options.savedModel.A = [1 0 15 0 0;
%                         0 1 0 15 0;
%                         0 0 0.979 0 0;
%                         0 0 0 0.979 0;
%                         0 0 0 0 1];
% options.savedModel.W = [0 0 0 0 0;
%                         0 0 0 0 0;
%                         0 0 0.0016 0 0;
%                         0 0 0 0.0016 0;
%                         0 0 0 0 0];


%% options that are prompted
prompt.startingFilterNum = num2str(CURRENT_FILTER_NUMBER);
prompt.blocksToFit = '';
prompt.binSize = '15';
prompt.delayMotor = '0';
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
prompt.addCorrectiveBias = 'false';
prompt.useSqrt = 'false';
prompt.ridgeLambda = '0';
prompt.normalizeRadialVelocities = '0';
prompt.rescaleSpeeds = '1';

%% wonky channels exist. make a channel exclusion list, dependent on which array(s) is/are being used
chExcludeLateral = [73 75];
chExcludeMedial = [97 100 114 117 120 130 162 168 169 178]; %% email from Anish, 2014-03-14

%% medial channel list based on psths from t7.2014.03.18
%% 24, 34 excluded based on spikepanels from t7.2014.04.01
allChannelsMedial = [26 28 29 30 31 41 45 47 49 53 57 58 59 60 61 63 64 78 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96]+96;
%allChannelsLateral = [1:96];

%% lateral channel list based on spikepanels from t7.2014.06.17
allChannelsLateral = [ 1 2 3 4 5 6 7 8 9 10 ...
                    11 12 13 14 15 16 17 18 19 20 ...
                    22 23 24 26 27 28 29 ...
                    31 33 34 35 36 37 38 40 ...
                    48 ...
                    65 66 67 68 69 70 ...
                    71 72];


switch options.whichArray
  case rigHardwareConstants.ARRAY_T7_MEDIAL
    %allChannels = 1:96;
    allChannels = allChannelsMedial-96;
    excludeChannels = chExcludeMedial-96;
    prompt.fixedThreshold = '-90';
    disp('Configured for T7, Medial Array');
  case rigHardwareConstants.ARRAY_T7_LATERAL
    allChannels = allChannelsLateral;
    excludeChannels = chExcludeLateral;
    prompt.fixedThreshold = '-70';
    disp('Configured for T7, Lateral Array');
  case rigHardwareConstants.ARRAY_T7_BOTH
    allChannels = [allChannelsLateral allChannelsMedial];%1:192;
    excludeChannels = [chExcludeLateral chExcludeMedial];
    disp('Configured for T7, Both Arrays');
    prompt.arraySpecificThresholds = '-70 -90';
  otherwise
    error('dont recognize this array configuration')
end
options.neuralChannels = setdiff(allChannels,excludeChannels);
options.neuralChannelsHLFP = options.neuralChannels;

buildFilterDialog(streams, options, prompt);

