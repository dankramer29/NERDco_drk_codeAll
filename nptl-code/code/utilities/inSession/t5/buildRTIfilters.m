function buildRTIfilters(streams)

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

%% hard-coded options
options.withinSampleXval = 9; %SELF: note that cross-validation will have to be turned off when doing this for 1 trial each time, iteratively updating filter after each click (but a lot of other things will have to change too) 
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
options.eliminateFailures = false; %BJ: not applicable to RTI
options.eliminateDelay = false; %BJ: not applicable to RTI

%% options that were prompted in buildRefitT5, but don't need to be promted for RTI:
options.binSize = 15;
options.delayMotor = 0;
options.useVFB = false;
options.useHLFP = false;
options.normalizeTx = true;
options.normalizeHLFP = true;
options.tSkip = 0;  %SELF: this skips the first tSkip ms of each "trial", I think; not relevant for RTI but will error out without it because it (along with a bunch of other fields) manually gets assigned to Toptions, etc. (grrrr)
options.useDwell = true;  %SELF: not sure whether this will be needed/used for RTI
options.hLFPDivisor = 2500;
options.maxChannels = 200;
options.gaussSmoothHalfWidth = 25;
options.addCorrectiveBias = false;  %SELF: don't use for now; this doesn't seem to be correcting bias in decoded velocity, but in #s of trials in each direction? (see filterSweep)
options.useSqrt = false;
options.ridgeLambda = 0;
% limit # of channels to sweep to save time during filter builds:
options.minChannels = 10;
options.maxChannels = 120;

%% new RTI-specific options:
options.RTI.useRTI = true;
options.RTI.tStartBeforeClick = 2000;  %how many ms before each click to start accumulating data toward RTI build 
options.RTI.tStopBeforeClick = 200;  %how many ms before each click to stop accumulating kin data toward RTI build (so total length of each trial will be tUseBeforeClick - tSkipBeforeClick)

%% killing the state model - CP 20150729 - SELF: left over from buildRefitT5; is there an easy way to just keep the prevoius state model, whatever it was? (Load the previous filter each time, or something?)
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
prompt.startingFilterNum = num2str(CURRENT_FILTER_NUMBER);  %NOTE: filter num is assumed to be first prompt downstream! 
prompt.blocksToFit = '';
prompt.fixedThreshold = '';
prompt.rmsMultiplier = '-4.5';

%% new options added by Frank for gain & smoothing reparameterization: 
prompt.alpha = '0.94';
prompt.beta = '0.1';
prompt.singleDOFNorm = 'false';


% build a channel exclusion list
allChannels = 1:192;
%updated 9/27/17:
excludeChannels = [2 46 66 67 68 69 73 76 77 78 82 83 85 86 94 95 96];

options.neuralChannels = setdiff(allChannels,excludeChannels);
options.neuralChannelsHLFP = options.neuralChannels;

options.normalizeRadialVelocities = false;

[RTIdata, options] = buildFilterDialog(streams, options, prompt);  %options has some added fields after going through buildFilterDialog (prompt gets added to it, defaults get set, etc.)

% keyboard %SELF: TEMP: save RTIdata and options to workspace so can call click decoder build part alone:
 
%% automatically proceed to build HMM, reusing RTIdata and same options & threshold values as obtained above, as much as possible 
output = buildHMM_RTI(RTIdata.R_moveAndClick, options, RTIdata.actualThreshVals);


