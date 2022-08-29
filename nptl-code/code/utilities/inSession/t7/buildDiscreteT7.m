function buildDiscreteT7()

%%CHANGES
% alignment off
% LDA on
% PCA off
% stay move prob lowered from 0.999

whichArray = rigHardwareConstants.ARRAY_T7_BOTH;
options.whichArray = whichArray;

prompt.blocksToFit = '';
prompt.binSize = '45';
prompt.delayMotor = '-200';
%prompt.useFixedThresholds = 'true';
prompt.fixedThreshold = '';
prompt.normalize = 'true';
prompt.HLFPDivisor = '2500';
prompt.numPCsToKeep = '3';
prompt.clickSource = 'dwell';
%prompt.outputBinSize = prompt.binSize;
prompt.statesToUse = '2';
prompt.gaussSmoothHalfWidth = '45';
prompt.maxClickLength = '300';
prompt.rollingTimeConstant = '4000';
prompt.normFactor = num2str(str2num(prompt.binSize) * 0.03);
prompt.useTx = 'true';
prompt.useHLFP = 'false';
prompt.clickStateThreshold = '0.1';
prompt.usePCA = 'true';
prompt.neuralAlignment = 'false';
prompt.arraySpecificThresholds = '-80 -95';

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
    prompt.fixedThreshold = '-95';
    disp('Configured for T7, Medial Array');
  case rigHardwareConstants.ARRAY_T7_LATERAL
    allChannels = allChannelsLateral;
    excludeChannels = chExcludeLateral;
    prompt.fixedThreshold = '-80';
    disp('Configured for T7, Lateral Array');
  case rigHardwareConstants.ARRAY_T7_BOTH
    allChannels = [allChannelsLateral allChannelsMedial];%1:192;
    excludeChannels = [chExcludeLateral chExcludeMedial];
    disp('Configured for T7, Both Arrays');
    prompt.arraySpecificThresholds = '-80 -95';
  otherwise
    error('dont recognize this array configuration')
end
options.neuralChannels = setdiff(allChannels,excludeChannels);
options.neuralChannelsHLFP = options.neuralChannels;
% set the transition probability (assuming 50ms model -> gets corrected in build)
options.probStayMove = 0.999;
options.probStayClick = 0.85;
options.useFA = false;
options.useLDA = false;

buildHMMDialog([],options,prompt);