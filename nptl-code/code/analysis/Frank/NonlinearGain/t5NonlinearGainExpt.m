paths = getFRWPaths();
dataset = [paths.dataPath filesep 'BG Datasets' filesep 't5.2017.09.25'];
addpath(genpath(paths.codePath));

saveDir = [paths.dataPath filesep 'Derived' filesep 'nonlinearGain' filesep 't5.2017.09.25'];
mkdir(saveDir);

%%
cd(dataset);
global modelConstants;
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

sessionPath = modelConstants.sessionRoot;
if ~exist([sessionPath 'Analysis' filesep 'Model Optimization'],'dir')
    mkdir([sessionPath 'Analysis' filesep 'Model Optimization']);
end
flDir = [sessionPath modelConstants.dataDir 'FileLogger/'];

blockNums = [5 6 7 8 9];
R = [];
for b=1:length(blockNums)
    R = [R, onlineR(loadStream([flDir num2str(blockNums(b)) '/'], blockNums(b)))];
end
load([sessionPath 'Data' filesep 'Filters' filesep R(1).decoderD.filterName '.mat']);

%%
st = zeros(size(R));
for t=1:length(R)
    st(t) = R(t).startTrialParams.blockNumber;
end

removeTrl = false(size(R));
for b=1:length(blockNums)
    trlIdx = find(st==blockNums(b));
    removeTrl(trlIdx(1))=true;
end
keepTrl = ~removeTrl;

movTime = [R.trialLength]/1000;
colors = hsv(length(blockNums));

figure
hold on
for b=1:length(blockNums)
    trlIdx = find(st==blockNums(b) & keepTrl);
    plot(trlIdx, movTime(trlIdx), 'o', 'Color', colors(b,:), 'MarkerFaceColor',colors(b,:));
end
xlabel('Trial #');
ylabel('Trial Time (s)');
set(gca,'LineWidth',1.5,'FontSize',16);
saveas(gcf,[saveDir filesep 'movTime.png'],'png');

%%
nonlinIdx = ismember(st,[8]);
linIdx = ismember(st, [5]);
keepTrl = keepTrl & (nonlinIdx | linIdx);

figure
anova1(movTime(keepTrl), nonlinIdx(keepTrl));
set(gca,'LineWidth',1.5,'FontSize',16,'XTickLabel',{'Linear','Nonlinear'});
ylabel('Trial Time (s)');

nBins = 4000;
distAvg = [];
speedAvg = [];
for t=1:length(R)
    tmpDist = matVecMag(bsxfun(@plus, R(t).cursorPosition(1:4,:), - R(t).posTarget(1:4))',2);
    tmpSpeed = matVecMag([0 0 0 0; diff(R(t).cursorPosition(1:4,:)')],2)*1000;
    idxToPull = 1:min(length(tmpSpeed),nBins);
    
    newDistRow = nan(1, nBins);
    newDistRow(idxToPull) = tmpDist(idxToPull);
    
    newSpeedRow = nan(1, nBins);
    newSpeedRow(idxToPull) = tmpSpeed(idxToPull);
    
    distAvg = [distAvg; newDistRow];
    speedAvg = [speedAvg; newSpeedRow];
end

timeAxis = (1:nBins)/1000;

figure('Position',[680   766   838   332]);
subplot(1,2,1);
hold on;
plot(timeAxis, nanmedian(distAvg(linIdx & keepTrl,:)),'b','LineWidth',2);
plot(timeAxis, nanmedian(distAvg(nonlinIdx & keepTrl,:)),'r','LineWidth',2);
set(gca,'LineWidth',1.5,'FontSize',16);
xlabel('Time (s)');
ylabel('Distance (m)');

subplot(1,2,2);
hold on;
plot(timeAxis, nanmedian(speedAvg(linIdx,:)),'b','LineWidth',2);
plot(timeAxis, nanmedian(speedAvg(nonlinIdx,:)),'r','LineWidth',2);
set(gca,'LineWidth',1.5,'FontSize',16);
xlabel('Time (s)');
ylabel('Speed (m/s)');
saveas(gcf,[saveDir filesep 'distanceAndSpeed.png'],'png');

%%
for t=1:length(R)
    R(t).spikeRaster = bsxfun(@lt, R(t).minAcausSpikeBand, model.thresholds');
end

opts.filter = false;
data = unrollR_generic(R, 20, opts);

decoder = model.K([2 4 6 8],1:192)/(1-model.alpha);
decoder = bsxfun(@times, decoder, model.invSoftNormVals(1:192)');

decFeatures = (data.spikes/50)*(15/20);
decFeatures = bsxfun(@plus, decFeatures, -mean(decFeatures));

neuralPush = (decFeatures * decoder')*1000/model.beta;

isSuccTrl = [R.isSuccessful];
fTargFits = cell(length(blockNums),1);
for b=1:length(blockNums)
    trlIdx = (st==blockNums(b)) & isSuccTrl;
    loopIdx = expandEpochIdx([data.reachEvents(trlIdx,2)+10, data.reachEvents(trlIdx,3)]);
    fTargFits{b} = fitFTarg(data.targetPos(loopIdx,1:4) - data.cursorPos(loopIdx,1:4), neuralPush(loopIdx,:), 0.1, 10);
end

figure
hold on
for b=1:length(blockNums)
    plot(fTargFits{b}(:,1), fTargFits{b}(:,2), '-o', 'LineWidth', 2, 'Color', colors(b,:));
end
legend({'5','6','7','8','9'});
saveas(gcf,[saveDir filesep 'controlPolicy.png'],'png');

%%
fContrib = bsxfun(@times, decFeatures, matVecMag(decoder',2)');
fContrib = gaussSmooth_fast(fContrib, 10)*1000/model.beta;

biasEst = [R.xkModBiasEst]';
biasEst = biasEst(1:20:end,2:2:8)*1000/model.beta;

figure
imagesc(abs(decFeatures)',[0 2]);

figure
subplot(1,2,1);
hold on
plot(biasEst,'LineWidth',2);

subplot(1,2,2);
hold on
plot(matVecMag(biasEst,2),'LineWidth',2);

figure
hold on
plot(matVecMag(biasEst,2)*14,':','LineWidth',2,'Color',[0.5 0.5 0.5]);
for b=1:length(blockNums)
    trlIdx = find(st==blockNums(b) & keepTrl);
    plot(data.reachEvents(trlIdx,2), movTime(trlIdx), 'o', 'Color', colors(b,:), 'MarkerFaceColor',colors(b,:));
end
xlabel('Trial Start');
ylabel('Trial Time (s)');
set(gca,'LineWidth',1.5,'FontSize',16);
saveas(gcf,[saveDir filesep 'movTime.png'],'png');


figure
hold on
imagesc(fContrib',[0 0.1]);
plot(biasEst*100 + 100,'LineWidth',3);

figure
hold on
for b=1:length(blockNums)
    trlIdx = find(st==blockNums(b) & keepTrl);
    plot(trlIdx, movTime(trlIdx), 'o', 'Color', colors(b,:), 'MarkerFaceColor',colors(b,:));
end

%%
%moving estimate of bias


