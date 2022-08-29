% This was the example script Frank sent me to look at the T8 Radial 8 task data. I've
% made a few modifications like pointing to my own local paths and also calculating the
% relative push from 
%
%
slc1=load([CachedDatasetsRootNPTL '/NPTL/t8.2017.10.18/Data/SLC Data/PC1/SLCdata_2017_1018_155221(4).mat']);
slc2=load([CachedDatasetsRootNPTL '/NPTL/t8.2017.10.18/Data/SLC Data/PC1/SLCdata_2017_1018_155650(5).mat']);
ncs = load([CachedDatasetsRootNPTL '/NPTL/t8.2017.10.18/Data/NCS Data/Blocks_Single_2017.10.18.16.00_(5).mat']);

%target position and binned neural features (20ms bin)
targPos = double([slc1.task.goal.values(:,1:2); slc2.task.goal.values(:,1:2)]);
binnedTX = double([slc1.ncTX.values; slc2.ncTX.values]);
binnedSP = double([slc1.spikePower.values; slc2.spikePower.values]);
 
%here are the TX thresholds
thresholds = slc1.sSLC.features.ncTX.min_threshold(1,:);

%get M2 (Kalman gain K)
ncTXInds = ncs.singleBlock.sSLCsent.decoders.kalman.ncTXInds;
spInds = ncs.singleBlock.sSLCsent.decoders.kalman.spikePowerInds;
 
M2 = zeros(2,384);
M2(:,ncTXInds) = ncs.singleBlock.sSLCsent.decoders.kalman.K_pad(1:2,1:length(ncTXInds));
M2(:,192+spInds) = ncs.singleBlock.sSLCsent.decoders.kalman.K_pad(1:2,(length(ncTXInds)+1):(length(ncTXInds)+length(spInds)));
 
%As a sanity check I am comparing the neural push reconstructed offline to the one saved online - they
%are very close. Features must be z-scored before applying M2.
%They are not identical due to bias correction occuring
%online during the block. 
txMeans = ncs.singleBlock.sSLCsent.decoders.kalman.ncTXMeans;
txStandardDeviations = 1./ncs.singleBlock.sSLCsent.decoders.kalman.ncTXNorm;

spMeans = ncs.singleBlock.sSLCsent.decoders.kalman.spikePowerMeans;
spStandardDeviations = 1./ncs.singleBlock.sSLCsent.decoders.kalman.spikePowerNorm;

neuralPush = double([slc1.task.kalmanUnsmoothed(:,1:2); slc2.task.kalmanUnsmoothed(:,1:2)]);

concatFeatures = [binnedTX, binnedSP];
concatMean = [txMeans, spMeans];
concatSD = [txStandardDeviations, spStandardDeviations];
neuralPushOfflineReconstruction = ((concatFeatures-concatMean)./concatSD)*M2';

neuralPushOfflineReconstruction_TX = ((concatFeatures(:,1:192)-concatMean(:,1:192))./concatSD(:,1:192))*M2(:,1:192)';
normAllTx = mean( norms( neuralPushOfflineReconstruction_TX' ) );
neuralPushOfflineReconstruction_Sp = ((concatFeatures(:,193:end)-concatMean(:,193:end))./concatSD(:,193:end))*M2(:,193:end)';
normAllSp = mean( norms( neuralPushOfflineReconstruction_Sp' ) );
fprintf('Threshold crossings contribute %.1f%%, Spike power contributes %.1f%% of overall neural push\n', ...
    100* normAllTx / (normAllTx + normAllSp),  100* normAllSp / (normAllTx + normAllSp) )

figure
hold on
plot(neuralPush(:,1));
plot(neuralPushOfflineReconstruction(:,1));
legend({'Actual Push','Offline Reconstructed Push'});

%%
%make PSTHs

%first, code each trial based on the target position
theta = linspace(0,2*pi,9);
theta = theta(1:8);
targList = [cos(theta)', sin(theta)']*14 + [0,40.5];

targOnset = find(any(abs(diff(targPos)),2))+1;
trlTargPos = targPos(targOnset+5,:);
targCodes = nan(length(trlTargPos),1);
for t=1:length(targCodes)
    err = matVecMag(targList - trlTargPos(t,:),2);
    [minErr,minIdx] = min(err);
    if minErr<0.01
        targCodes(t) = minIdx;
    end
end

%outerReaches = find(~isnan(targCodes));
outerReaches = find(ismember(targCodes, [1 3 5 7]));

%define colors
colors = hsv(4)*0.8;
lineArgs = cell(4,1);
for x = 1:4
    lineArgs{x} = {'LineWidth',1,'Color',colors(x,:)};
end

%set psth options struct
psthOpts = makePSTHOpts();
psthOpts.gaussSmoothWidth = 3.0;
psthOpts.neuralData = {[binnedTX, binnedSP]};
psthOpts.timeWindow = [-10,100];
psthOpts.trialEvents = targOnset(outerReaches);
psthOpts.trialConditions = targCodes(outerReaches);
psthOpts.conditionGrouping = {1:4};
psthOpts.lineArgs = lineArgs;
psthOpts.plotCI = 1;
psthOpts.CIColors = colors;

psthOpts.plotsPerPage = 10;
psthOpts.plotDir = '/Users/frankwillett/Data/Derived/examplePSTHs/';
psthOpts.prefix = 'PSTH';

featLabels = cell(384,1);
for f=1:192
    featLabels{f} = ['TX ' num2str(f)];
    featLabels{f+192} = ['SP ' num2str(f)];
end
psthOpts.featLabels = featLabels;

%make psths
makePSTH_simple(psthOpts);
