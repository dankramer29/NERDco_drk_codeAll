function [discretemodel combinedmodel] = fitDiscreteModel(doptions)
% doptions.dataPath => e.g. /Users/chethan/localdata/20130903/
% doptions.blocksToFit => vector of block numbers to use to fit
% doptions.continuousmodel => a continuous model - if passed in, will 
%    return a second argument which is the combined model

%% first load the relevant rstructures
dpath = doptions.dataPath;

R=[];
for nb = 1:length(doptions.blocksToFit)
    blockNum = doptions.blocksToFit(nb);
    [R1, taskDetails] = parseBlockInSession(blockNum, true, false, ...
                                            dpath);
    R = [R(:);R1(:)];
end
taskConstants = processTaskDetails(taskDetails);

options.shiftSpikes = 60;
options.shiftHLFP = 60;
options.useTx = true;
options.thresh = zeros(96,1)-65;
options.normalizeTx = true;
options.txNormFactor = 1;
options.useHLFP = true;
options.normalizeHLFP = true;
options.HLFPNormFactor = 5000/double(DecoderConstants.HLFP_DIVISOR);
options.usePCA = true;
options.numPCsToKeep = 20;
options.binSize = 50;
options.restSpeedThresholdPercent = 0.05;
options.numOutputDims = double(DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS);

[discretemodel] = calculateDiscreteParams(R,taskConstants,options);
options = discretemodel.options;
[D] = onlineDfromR(R,taskConstants,discretemodel,options);

hmmOptions = options;
% fit the classifier / HMM
probStayMove = 0.98^(50/options.binSize);
probLeaveMove = 1-probStayMove;
probStayClick = 0.85^(50/options.binSize);
probLeaveClick = 1-probStayClick;
hmmOptions.trans = [probStayMove  probLeaveClick;
                    probLeaveMove probStayClick];
hmmOptions.stateModel = DiscreteStates.STATE_MODEL_MOVECLICK;
% use the 'clickState' field of the Dstruct to indicate clicks
hmmOptions.clickSource = DiscreteStates.STATE_SOURCE_CLICK;
% set the 'click state threshold' (the point at which the binned click signal is considered an actual click) to 0.1
hmmOptions.clickStateThreshold = 0.1;
hmmOptions.showLowD = true;
discretemodel = fitGaussianHMM(D,discretemodel,hmmOptions);
discretemodel.options = hmmOptions;

%% combine if requested
if isfield(doptions,'continuousmodel')
    combinedmodel = combineContinuousDiscrete(doptions.continuousmodel,discretemodel);
end
