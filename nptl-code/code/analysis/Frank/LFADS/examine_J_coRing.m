%%
fileTrain = '/Users/frankwillett/Data/Derived/post_LFADS/R_2016-02-02_1/model_runs_h5_train_posterior_sample_and_average';
fileValid = '/Users/frankwillett/Data/Derived/post_LFADS/R_2016-02-02_1/model_runs_h5_valid_posterior_sample_and_average';
fileInput = '/Users/frankwillett/Data/Derived/post_LFADS/R_2016-02-02_1/R_2016-02-02_1.h5';

resultTrain = hdf5load(fileTrain);
resultValid = hdf5load(fileValid);
resultInput = hdf5load(fileInput);

matData = load('/Users/frankwillett/Data/Derived/post_LFADS/R_2016-02-02_1/originalData');
trlCodes = load('/Users/frankwillett/Data/Derived/post_LFADS/R_2016-02-02_1/trialCodes');

figure
subplot(2,1,1);
imagesc(resultValid.output_dist_params(:,:,4));

subplot(2,1,2);
imagesc(resultInput.valid_data(:,:,4));

%compare trial averages of real data vs. trial averages of LFADS rates
lfads_rates = zeros(size(matData.all_data));
lfads_factors = zeros(20,size(matData.all_data,2),size(matData.all_data,3));
lfads_rates(:,:,trlCodes.shuffCodesTrain) = resultTrain.output_dist_params;
lfads_rates(:,:,trlCodes.shuffCodesValid) = resultValid.output_dist_params;
lfads_factors(:,:,trlCodes.shuffCodesTrain) = resultTrain.factors;
lfads_factors(:,:,trlCodes.shuffCodesValid) = resultValid.factors;

conCodeList = unique(matData.conCodes);
for c=1:length(conCodeList)
    trlIdx = find(matData.conCodes==conCodeList(c));
    
    averageReal = mean(matData.all_data(:,:,trlIdx),3);
    averageLFADS = mean(lfads_rates(:,:,trlIdx),3);
    
    figure('Position',[560   229   321   719]);
    subplot(2,1,1);
    imagesc(averageReal);

    subplot(2,1,2);
    imagesc(averageLFADS);
end

for c=1:length(conCodeList)
    trlIdx = find(matData.conCodes==conCodeList(c));
    trlIdx = intersect(trlIdx, find(matData.trlDelays==1));
    
    figure
    hold on
    for x=1:length(trlIdx)
        plot(lfads_rates(5,:,trlIdx(x))');
    end
end

%%
chanIdx = 1:96;

%%
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/PSTH'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/Utility'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/dPCA'));

%apply to non-delay data, no extra aligning
outer8Codes = [49 46 28 5 1 4 22 45];
trlIdx = find(matData.trlDelays==1 & ismember(matData.conCodes, outer8Codes));

unrollRates = lfads_rates(:,:,trlIdx);
unrollRates = unrollRates(:,:)';
startLoopIdx = 1:200:length(unrollRates);
dPCA_out = apply_dPCA_simple( unrollRates(:,chanIdx), startLoopIdx, ...
    matData.conCodes(trlIdx), [1 200], 0.005, {'Condition-dependent', 'Condition-independent'} );

colors = hsv(8)*0.8;
newLineArgs = cell(size(colors,1),1);
for c=1:size(colors,1)
    newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
end
margNamesShort = {'Dir','CI'};
oneFactor_dPCA_plot( dPCA_out, 1:200, newLineArgs, margNamesShort, 'zoomedAxes' );  

%SFA-rotated dPCA
sfaOut = sfaRot_dPCA( dPCA_out );
oneFactor_dPCA_plot( sfaOut, 1:200, newLineArgs, margNamesShort, 'zoomedAxes' );

%%
%try DBA
trlRates = lfads_rates(chanIdx,:,trlIdx);
trlCodes = matData.conCodes(trlIdx);

setIdx = find(trlCodes==49);
reduceDim = zeros(8,size(trlRates,2),length(setIdx));
for s=1:length(setIdx)
    reduceDim(:,:,s) = dPCA_out.W(:,1:8)' * squeeze(trlRates(:,:,setIdx(s)));
end

testSeq = zeros(20,2,100);
for t=1:size(testSeq,1)
    randIdx = randi(10,1)+10;
    testSeq(t,:,randIdx)=1;
end

figure
hold on
plot(squeeze(testSeq(:,1,:))');
plot(mean(squeeze(testSeq(:,1,:))',2));

sequences = cell(size(testSeq,1),1);
for s=1:length(sequences)
    sequences{s} = squeeze(testSeq(t,:,:))';
end

avgSequence = DBA_mv(sequences);

%%
sequences = cell(size(reduceDim,3),1);
for s=1:length(sequences)
    sequences{s} = squeeze(reduceDim(3,:,s))';
end

avgSequence = DBA_mv(sequences);

figure
hold on
plot(squeeze(reduceDim(3,:,1:end)),'LineWidth',2);
plot(mean(squeeze(reduceDim(3,:,1:end)),2),'k','LineWidth',2);
plot(avgSequence,'--k','LineWidth',2);

X = squeeze(reduceDim(6,:,1));
Y = squeeze(reduceDim(6,:,2));
[DIST,IX,IY] = dtw(X, Y);

figure
hold on
plot(X(IX),'LineWidth',2);
plot(Y(IY),'LineWidth',2);

figure
hold on
plot(mean([X(IX); Y(IY)]));
plot(mean(squeeze(reduceDim(6,:,1:2)),2));
%%
%apply to non-delay data, aligning on CIS increase threshold
CIS_idx = find(dPCA_out.whichMarg==2,1,'first');
decoderVector = dPCA_out.W(:,CIS_idx);

figure
hold on
for t=1:length(trlIdx)
    plot(decoderVector'*lfads_rates(chanIdx,:,trlIdx(t)));
end

moveStartIdx = zeros(length(trlIdx),1);
for t=1:length(trlIdx)
    CIS_proj = decoderVector'*lfads_rates(chanIdx,:,trlIdx(t));
    tmp = find(CIS_proj(25:end)>0.2,1,'first');
    moveStartIdx(t) = tmp + 24;
end

timeWindow = [-20, 120];

figure
hold on
for t=1:length(trlIdx)
    loopIdx = (moveStartIdx(t)+timeWindow(1)):(moveStartIdx(t)+timeWindow(2));
    if loopIdx(end)>200
        badTrls(t) = true;
        continue;
    end
    plot(decoderVector'*lfads_rates(chanIdx,loopIdx,trlIdx(t)));
end

unrollRates = [];
for t=1:length(trlIdx)
    loopIdx = (moveStartIdx(t)+timeWindow(1)):(moveStartIdx(t)+timeWindow(2));
    tmp = lfads_rates(chanIdx,loopIdx,trlIdx(t))';
    unrollRates = [unrollRates; tmp];
end

timeAxis = timeWindow(1):timeWindow(2);
nBins = length(timeAxis);
unrollStartIdx = 1:nBins:size(unrollRates,1);

dPCA_out = apply_dPCA_simple( unrollRates, unrollStartIdx, ...
    matData.conCodes(trlIdx), [1 (length(timeAxis)-1)], 0.005, {'Condition-dependent', 'Condition-independent'} );

colors = hsv(8)*0.8;
newLineArgs = cell(size(colors,1),1);
for c=1:size(colors,1)
    newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
end
margNamesShort = {'Dir','CI'};
oneFactor_dPCA_plot( dPCA_out, 1:(length(timeAxis)-1), newLineArgs, margNamesShort, 'zoomedAxes' );  

%%
%apply to real non-delay data
trlIdx = find(matData.trlDelays==1 & ismember(matData.conCodes, outer8Codes));
unrollRates = matData.all_data(chanIdx,:,trlIdx);
unrollRates = unrollRates(:,:)';
unrollRates = gaussSmooth_fast(unrollRates, 3);
startLoopIdx = 1:200:length(unrollRates);
dPCA_out = apply_dPCA_simple( unrollRates, startLoopIdx, ...
    matData.conCodes(trlIdx), [1 200], 0.005, {'Condition-dependent', 'Condition-independent'} );

colors = hsv(8)*0.8;
newLineArgs = cell(size(colors,1),1);
for c=1:size(colors,1)
    newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
end
margNamesShort = {'Dir','CI'};
oneFactor_dPCA_plot( dPCA_out, 1:200, newLineArgs, margNamesShort, 'zoomedAxes' );    


%%
%original data
load('/Users/frankwillett/Data/Monk/JenkinsData/R_2016-02-02_1.mat');
data = unrollR_co( R, 20, 'Jenkins' );

%use outer ring targets only 
outerIdx = ismember(data.trlCodes, data.outerRingCodes);
delayTimes = vertcat(R.delayTime);
noDelayIdx = ~isnan(delayTimes);
trlIdx = find(outerIdx & noDelayIdx);

conCodes = data.trlCodes(trlIdx);
trlDelays = delayTimes(trlIdx);

%use 0-1000 ms after target appearance
timeStep = 5;
trialLen = 1000;
nBins = floor(trialLen/timeStep);
nTrl = length(trlIdx);
nUnits = 192;

shuffIdx = randperm(nTrl);
trainPct = 0.8;

cursorVel = [0 0 0; diff(data.cursorPos)*1000];
cursorSpeed = matVecMag(cursorVel,2);

all_kin = zeros(3, nBins, nTrl);
all_data = zeros(nUnits, nBins, nTrl);
for x=1:length(trlIdx)
    fullRaster = [R(trlIdx(x)).spikeRaster', R(trlIdx(x)).spikeRaster2'];
    if size(fullRaster,1)<1000
        nextRaster = [R(trlIdx(x)+1).spikeRaster', R(trlIdx(x)+1).spikeRaster2'];
        fullRaster = [fullRaster; nextRaster];
    end

    binCounts = zeros(nBins, nUnits);
    binIdx = 1:5;
    for t=1:nBins
        binCounts(t,:) = sum(fullRaster(binIdx,:));
        binIdx = binIdx+5;
    end

    all_data(:,:,x) = binCounts';
    
end

save('/Users/frankwillett/Data/R_2016-02-02_1/originalData','all_data','conCodes','trlDelays');

%%
%recover missing trial codes, I forgot to save them after shuffling
fileInput = '/Users/frankwillett/Data/R_2016-02-02_1/R_2016-02-02_1.h5';
resultInput = hdf5load(fileInput);
matData = load('/Users/frankwillett/Data/R_2016-02-02_1/originalData');

shuffCodesTrain = zeros(size(resultInput.train_data,3),1);
for t=1:size(resultInput.train_data,3)
    disp(t);
    template = double(resultInput.train_data(:,:,t));
    matchScore = zeros(size(matData.all_data,3),1);
    for x=1:size(matData.all_data,3)
        matchScore(x) = sum(sum(abs(matData.all_data(:,:,x) - template)));
    end
    [~,tmpIdx] = min(matchScore);
    shuffCodesTrain(t) = tmpIdx;
end

shuffCodesValid = zeros(size(resultInput.valid_data,3),1);
for t=1:size(resultInput.valid_data,3)
    disp(t);
    template = double(resultInput.valid_data(:,:,t));
    matchScore = zeros(size(matData.all_data,3),1);
    for x=1:size(matData.all_data,3)
        matchScore(x) = sum(sum(abs(matData.all_data(:,:,x) - template)));
    end
    [~,tmpIdx] = min(matchScore);
    shuffCodesValid(t) = tmpIdx;
end

save('/Users/frankwillett/Data/R_2016-02-02_1/trialCodes','shuffCodesTrain','shuffCodesValid');