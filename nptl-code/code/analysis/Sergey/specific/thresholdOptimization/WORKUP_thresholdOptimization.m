% Trying several different threshold options, to see if we can do better
% offline decode.
%
% Created by Sergey Stavisky 3 February 2017
%
%

%% Analysis parameters: key thigns
clear
% experiment = 't5.2017.01.25'; 
% trainBlockOL = 2; % open-loop
% trainBlockCL = [5,6]; % closed-loop that was used for most of the dayr


experiment = 't5.2017.02.01'; 
trainBlockOL = 3; % open-loop
trainBlockCL = [5,6,7]; % closed-loop that was used for most of the dayr



sweep.thresholdType = 'mults'; % for RMS multiplier
% sweep.thresholdsToTry = [-4.5, -3]; % dev
sweep.thresholdsToTry = [-10:0.1:-1];

% sweep.thresholdType = 'fixed'; % fixed threshold
% sweep.thresholdsToTry = [-25:-1:-300];
% sweep.thresholdsToTry = [-200 -100]; % DEV
sweep.trainingData = 'CL'; % use the CL train block
% sweep.trainingData = 'OL'; % use the OL train block

%% Secondary things in analysis.
% These are taken from the standard filter build options we've been using.
switch sweep.trainingData
    case 'OL'
        options.kinematics = 'mouse';
        options.blocksToFit = trainBlockOL;
        options.savedModel.A = [1 0 0 15 0 0 0;0 1 0 0 15 0 0;0 0 1 0 0 15 0;0 0 0 0.979 0 0 0;0 0 0 0 0.979 0 0;0 0 0 0 0 0.979 0;0 0 0 0 0 0 1];
        options.savedModel.W = [0 0 0 0 0 0 0;0 0 0 0 0 0 0;0 0 0 0 0 0 0;0 0 0 1.4142135623731e-10 0 0 0;0 0 0 0 1.4142135623731e-10 0 0;0 0 0 0 0 1.4142135623731e-10 0;0 0 0 0 0 0 0];

    case 'CL'
        options.kinematics = 'refit';
        options.blocksToFit = trainBlockCL;
        if isfield( options, 'savedModel')
            options = rmfield( options, 'savedModel' );
        end
end


options.withinSampleXval = 9; % cross validation
options.useAcaus = 1;
options.normBinSize = 50;
options.txNormFactor = 1.5;
options.hLFPNormFactor = 1.5;
options.usePCA = false;
options.useTx = true;
options.showFigures = false;
options.whichArray = rigHardwareConstants.ARRAY_T5_BOTH;
options.neuralChannels = 1:192;
options.neuralChannelsHLFP = 1:192;
options.normalizeRadialVelocities = false;
options.binSize = 15;
options.delayMotor = 60;
options.useVFB = false;
options.rmsMultiplier = []; % use dto set threhsold but actually options.multsOrThresholds is what is used during build
options.useHLFP = false;
options.normalizeTx = true;
options.normalizeHLFP = true;
options.tSkip = 150;
options.useDwell = true;
options.hLFPDivisor = 2500;
options.maxChannels = 200;
options.gaussSmoothHalfWidth = 25;
options.neuralOnsetAlignment = false;
options.addCorrectiveBias = false;
options.useSqrt = false;
options.ridgeLambda = 0;
options.fixedThreshold = -95;
options.arraySpecificThresholds = [];
options.rescaleSpeeds = false;
options.numPCsToKeep = 20;
options.minChannels = 1;
options.removePCs = [];



%% Will want to add full NPTL rig codebase to path to make sure no little pieces are missing.
addCompleteNPTLpath % in Sergey's personal Analysis git repo


%% Set up various options
% We're going to want modelConstants.sessionRoot to point to a network data
% directory, not to a local cart directory
participant = experiment(1:2);


sessionPath = ['/net/experiments/' participant '/' experiment '/'];
modelConstants.sessionRoot = sessionPath; % lets me call GUI build scripts

optionsCur = options;

switch sweep.thresholdType
    case 'fixed'
        optionsCur.useFixedThresholds = true;
        
    case 'mults'
        optionsCur.useFixedThresholds = false;
end

% prepare results structure that will get fixed.
clear('results');
results.thresholdType = sweep.thresholdType;


for iSweep = 1 : numel( sweep.thresholdsToTry )
    % these are set specifically based on what I'm optimizing
    optionsCur.multsOrThresholds = sweep.thresholdsToTry(iSweep);
    fprintf('\n\n\n[%s] Sweeping parameter %i/%i\n\n\n', ...
        datestr(now,14), iSweep, numel( sweep.thresholdsToTry ) );
    results.threshold(iSweep) = optionsCur.multsOrThresholds;
    try
        [models, modelsFull, summary] = filterSweep(sessionPath,optionsCur);
        [results.meanDecodeR(iSweep), results.numberChannels(iSweep)] = max( summary{1}.meanDecodeR );
    catch
        results.meanDecodeR(iSweep) = nan;
        results.numberChannels(iSweep) = nan;
    end
end


% Make the plot
figh = figure;
plot( results.threshold, results.meanDecodeR);
xlabel('Threshold');
ylabel('meanDecodeR');
titlestr = [experiment ' B' mat2str( options.blocksToFit  )];
figh.Name = titlestr;
title( titlestr );
[bestMeanDecodeR, bestThreshInd] = max( results.meanDecodeR );
fprintf('%s had max meanDecodeR of %g using threshold %g\n', ...
    titlestr, bestMeanDecodeR, results.threshold(bestThreshInd) )