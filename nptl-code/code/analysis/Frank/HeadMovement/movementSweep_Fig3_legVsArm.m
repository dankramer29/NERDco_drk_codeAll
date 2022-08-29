%%
blockList = [7 8 9 10 11 12 13 14 15 16];

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1500 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'Fig3'];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep 't5.2018.11.19' filesep];

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, blockList, [], 4.5 );

trlCodes = zeros(size(R));
for t=1:length(trlCodes)
    trlCodes(t) = R(t).startTrialParams.currentMovement;
end

alignField = 'goCue';

allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
meanRate = mean(allSpikes)*1000;
tooLow = meanRate < 1.0;

allSpikes(:,tooLow) = [];
%allSpikes = gaussSmooth_fast(allSpikes, 30);

globalIdx = 0;
alignEvents = zeros(length(R),2);
allBlocks = zeros(size(allSpikes,1),1);
for t=1:length(R)
    loopIdx = (globalIdx+1):(globalIdx + length(R(t).spikeRaster));
    allBlocks(loopIdx) = R(t).blockNum;
    alignEvents(t,1) = globalIdx + R(t).(alignField);
    alignEvents(t,2) = globalIdx + R(t).trialStart;
    globalIdx = globalIdx + size(R(t).spikeRaster,2);
end

[trlCodeList,~,trlCodesRemap] = unique(trlCodes);

%%
nBins = (timeWindow(2)-timeWindow(1))/binMS;
snippetMatrix = zeros(nBins, size(allSpikes,2));
blockRows = zeros(nBins, 1);
validTrl = false(length(trlCodes),1);
globalIdx = 1;

for t=1:length(trlCodes)
    disp(t);
    loopIdx = (alignEvents(t,1)+timeWindow(1)):(alignEvents(t,1)+timeWindow(2));

    if loopIdx(1)<1 || loopIdx(end)>size(allSpikes,1)
        loopIdx(loopIdx<1)=[];
        loopIdx(loopIdx>size(allSpikes,1))=[];
    else
        validTrl(t) = true;
    end
        
    newRow = zeros(nBins, size(allSpikes,2));
    binIdx = 1:binMS;
    for b=1:nBins
        if binIdx(end)>length(loopIdx)
            continue;
        end
        newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
        binIdx = binIdx + binMS;
    end

    newIdx = (globalIdx):(globalIdx+nBins-1);
    globalIdx = globalIdx+nBins;
    blockRows(newIdx) = repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1);
    snippetMatrix(newIdx,:) = newRow;
end

%%
bNumPerTrial = [R.blockNum];
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);

for b=1:length(blockList)
    disp(b);
    blockTrl = find(bNumPerTrial==blockList(b));
    
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (eventIdx(blockTrl(t))-140):(eventIdx(blockTrl(t))-100)];
    end
    msIdx(msIdx<1) = [];
    
    binIdx = find(blockRows==blockList(b));
    %snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(msIdx,:)));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(binIdx,:)));
end
rawSnippetMatrix = snippetMatrix;
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));

%%
clear R allSpikes
pack;

%%
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix, 3.0);

%across all conditions
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
dPCA_out = apply_dPCA_simple( snippetMatrix, eventIdx, ...
    trlCodesRemap, [-500, 1000]/binMS, binMS/1000, {'CI','CD'},[3 3],'standard','ortho' );
close(gcf);

%%
trls_Coded = [
   94 ...
   95 ...
   96 ...
   97 ...
  218 ...
  219 ...
  220 ...
  221 ...
  222 ...
  223 ...
  224 ...
  225 ...
  226 ...
  227 ...
  228 ...
  229 ...
  230 ...
  231 ...
  232 ...
  233 ...
  234 ...
  235 ...
  236 ...
  237 ...
  238 ...
  239 ...
  240 ...
  241 ...
  242 ...
  243 ...
  244 ...
  245 ...
  246 ...
  247 ...
  248 ...
  249 ...
  250 ...
  251 ...
  252];

move_names_Coded = {...
     'ELBOW_FLEX';...
     'ELBOW_EXT';...
     'WRIST_EXT';...
     'WRIST_FLEX';...
     'NOTHING';...
     'SHOULDER_ABDUCT';...
     'SHOULDER_ADDUCT';...
     'SHOULDER_FLEX';...
     'SHOULDER_EXTEND';...
     'SHOULDER_EXT_ROT';...
     'SHOULDER_INT_ROT';...
     'WRIST_ULNAR_DEV';...
     'WRIST_RADIAL_DEV';...
     'WRIST_PRO';...
     'WRIST_SUP';...
     'HAND_CLOSE';...
     'HAND_OPEN';...
     'ANKLE_RIGHT';...
     'ANKLE_LEFT';...
     'ANKLE_GAS_UP'; ...
     'ANKLE_GAS_DOWN';    ...
     'INDEX_FLEX';...
     'INDEX_EXTEND';   ...
     'REACH_FRONT';...
     'REACH_RIGHT';...
     'REACH_UP';...
     'REACH_NOSE';...
     'REACH_HEART';...
     'REACH_BEHIND_HEAD';...
     'REACH_STEERING_RIGHT';...
     'JOYSTICK_UP';...
     'JOYSTICK_DOWN';...
     'JOYSTICK_LEFT';...
     'JOYSTICK_RIGHT';  ...
     'HIP_UP';...
     'KNEE_KICK';...
     'TOES_SPREAD';...
     'TOES_CLENCH';...
     'BIGTOE_UP'};
     
%reorderIdx = [5 1 2 3 4 6 7 8 9 10 11 12 13 14 15 16 17 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 ...
%    18 19 20 21 37 38 39];
%reorderIdx = [5 6 7 8 9 10 11 1 2 3 4 12 13 14 15 16 17 22 23 35 36 ...
%    18 19 20 21 37 38 39];
%effSets = {1,2:19,20:28};
reorderIdx = [8 2 3 4 13 12 16 17 35 36 20 21 18 19 38 37];
effSets = {1:8, 9:16};

movLabelsReorder = move_names_Coded(reorderIdx);
movLabels_pretty = {'Shoulder Flex','Elbow Ext','Wrist Ext','Wrist Flex','Wrist Ulnar',...
    'Wrist Radial','Hand Close','Hand Open','Hip Flex','Knee Ext','Ankle Ext','Ankle Flex','Ankle Eversion',...
    'Ankle Inversion','Toes Close','Toes Open'};

%cWindow = 60:100;
cWindow = 70:110;

boxSets = [];
% fa = dPCA_out.featureAverages;
% fa = fa(:,reorderIdx,:);
% simMatrix = plotCorrMat( fa, cWindow, movLabels_pretty, ...
%     effSets, boxSets );
% saveas(gcf,[outDir filesep '_legArmcorrMat.png'],'png');
% saveas(gcf,[outDir filesep '_legArmcorrMat.svg'],'svg');

fv = dPCA_out.featureVals;
fv = fv(:,reorderIdx,:,1:20);
simMatrix = plotCorrMat_cv( fv, cWindow, movLabels_pretty, ...
    effSets, boxSets );
saveas(gcf,[outDir filesep '_legArmcorrMat.png'],'png');
saveas(gcf,[outDir filesep '_legArmcorrMat.svg'],'svg');

figure('Position',[680   866   391   232]);
cMat = simMatrix(1:8, 9:16);
diagEntries = 1:(size(cMat,1)+1):numel(cMat);
otherEntries = setdiff(1:numel(cMat), diagEntries);    

subplot(1,2,1);
hold on
plot((rand(length(diagEntries),1)-0.5)*0.55, cMat(diagEntries), 'o');
plot(1 + (rand(length(otherEntries),1)-0.5)*0.55, cMat(otherEntries), 'ro');
set(gca,'XTick',[0 1],'XTickLabel',{'Matched','Different'},'XTickLabelRotation',45);
ylim([-1.0,1.0]);
ylabel('Correlation');
set(gca,'FontSize',20,'LineWidth',2);
xlim([-0.5,1.5]);
title('Arm vs. Leg','FontSize',18);

saveas(gcf,[outDir filesep 'corrDots_armVLeg.png'],'png');
saveas(gcf,[outDir filesep 'corrDots_armVLeg.svg'],'svg');

diagEntries = 1:(size(cMat,1)+1):numel(cMat);
otherEntries = setdiff(1:numel(cMat), diagEntries);
anova1([cMat(diagEntries)'; cMat(otherEntries)'], ...
    [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);

disp(mean(cMat(diagEntries)'));
disp(mean(cMat(otherEntries)'));

armMat = simMatrix(1:8, 1:8);
legMat = simMatrix(9:16, 9:16);
armLegMat = triu(armMat)+tril(legMat);
armLegOffDiag = legMat(otherEntries);
crossMatOffDiag = cMat(otherEntries);

figure; 
hold on;
plot((rand(length(otherEntries),1)-0.5)*0.55,abs(armLegOffDiag),'bo');
plot(1+(rand(length(otherEntries),1)-0.5)*0.55,abs(crossMatOffDiag),'ro')

%%
%single channel correlation, ACROSS TIME
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
dPCA_out = apply_dPCA_simple( gaussSmooth_fast(snippetMatrix, 2.5), eventIdx, ...
    trlCodesRemap, [-500, 1000]/binMS, binMS/1000, {'CI','CD'},[3 3],'standard','ortho' );
close(gcf);

armIdx = reorderIdx(1:8);
legIdx = reorderIdx(9:end);

nUnits = size(dPCA_out.featureAverages,1);
neuralCorr = zeros(nUnits,1);
neuralCorr_unbiased = zeros(nUnits,1);

tw = [-500,1000];
timeOffset = -tw(1)/binMS;
movWindow = (20:100);

for unitIdx=1:size(dPCA_out.featureAverages,1)
    unitAct_1 = squeeze(dPCA_out.featureVals(unitIdx,armIdx,movWindow+timeOffset,:));
    meanAct_1 = squeeze(nanmean(unitAct_1,3))';
    meanAct_1 = meanAct_1 - mean(meanAct_1,2);
    meanAct_1 = meanAct_1(:);

    unitAct_2 = squeeze(dPCA_out.featureVals(unitIdx,legIdx,movWindow+timeOffset,:));
    meanAct_2 = squeeze(nanmean(unitAct_2,3))';
    meanAct_2 = meanAct_2 - mean(meanAct_2,2);
    meanAct_2 = meanAct_2(:);

    neuralCorr(unitIdx) = corr(meanAct_1, meanAct_2);

    unitAct_1 = squeeze(dPCA_out.featureVals(unitIdx,armIdx,movWindow+timeOffset,:));
    unitAct_2 = squeeze(dPCA_out.featureVals(unitIdx,legIdx,movWindow+timeOffset,:));

    unitAct_1 = reshape(unitAct_1,size(unitAct_1,1)*size(unitAct_1,2),size(unitAct_1,3));
    unitAct_2 = reshape(unitAct_2,size(unitAct_2,1)*size(unitAct_2,2),size(unitAct_2,3));

    s1 = size(unitAct_1,2);
    s2 = size(unitAct_2,2);
    ms = min(s1,s2);

    nanTrl = any(isnan(unitAct_1(:,1:ms)),1) | any(isnan(unitAct_2(:,1:ms)),1);
    unitAct_1 = unitAct_1(:,~nanTrl)';
    unitAct_2 = unitAct_2(:,~nanTrl)';

    unbiasedMag1 = lessBiasedDistance( unitAct_1, zeros(size(unitAct_1)), true );
    unbiasedMag2 = lessBiasedDistance( unitAct_2, zeros(size(unitAct_2)), true );

    mn1 = mean(unitAct_1);
    mn2 = mean(unitAct_2);
    neuralCorr_unbiased(unitIdx) = (mn1-mean(mn1))*(mn2-mean(mn2))'/(unbiasedMag1*unbiasedMag2);
end

%shuffle distributions
nRep = 100;
nEdges = 32;
edges = linspace(-1.6,1.6,nEdges);
shuffDist = zeros(nRep, nEdges-1);
shuffDist_unbiased = zeros(nRep, nEdges-1);
for n=1:nRep

    shuffCorr = zeros(nUnits,2);
    for unitIdx=1:size(dPCA_out.featureAverages,1)
        %biased
        unitAct_1 = squeeze(dPCA_out.featureVals(unitIdx,armIdx,movWindow+timeOffset,:));
        meanAct_1 = squeeze(nanmean(unitAct_1,3))';

        unitAct_2 = squeeze(dPCA_out.featureVals(unitIdx,legIdx,movWindow+timeOffset,:));
        meanAct_2 = squeeze(nanmean(unitAct_2,3))';

        totalAct = cat(2,meanAct_1,meanAct_2);

        shuffleAct = totalAct;
        shuffleAct = shuffleAct(:,randperm(size(shuffleAct,2)));

        mn1 = shuffleAct(:,1:(end/2));
        mn2 = shuffleAct(:,((end/2)+1):end);

        mn1 = mn1 - mean(mn1,2);
        mn2 = mn2 - mean(mn2,2);

        mn1 = mn1(:);
        mn2 = mn2(:);

        shuffCorr(unitIdx,1) = corr(mn1, mn2); 

        %unbiased
        unitAct_1 = squeeze(dPCA_out.featureVals(unitIdx,armIdx,movWindow+timeOffset,:));
        unitAct_2 = squeeze(dPCA_out.featureVals(unitIdx,legIdx,movWindow+timeOffset,:));

        s1 = size(unitAct_1,3);
        s2 = size(unitAct_2,3);
        ms = min(s1,s2);

        totalAct = cat(1, unitAct_1(:,:,1:ms), unitAct_2(:,:,1:ms));
        totalAct = totalAct(randperm(size(totalAct,1)),:,:);

        unitAct_1 = totalAct(1:(end/2),:,:);
        unitAct_2 = totalAct(((end/2)+1):end,:,:);

        unitAct_1 = reshape(unitAct_1,size(unitAct_1,1)*size(unitAct_1,2),size(unitAct_1,3));
        unitAct_2 = reshape(unitAct_2,size(unitAct_2,1)*size(unitAct_2,2),size(unitAct_2,3));

        nanTrl = any(isnan(unitAct_1(:,1:ms)),1) | any(isnan(unitAct_2(:,1:ms)),1);
        unitAct_1 = unitAct_1(:,~nanTrl)';
        unitAct_2 = unitAct_2(:,~nanTrl)';

        unbiasedMag1 = lessBiasedDistance( unitAct_1, zeros(size(unitAct_1)), true );
        unbiasedMag2 = lessBiasedDistance( unitAct_2, zeros(size(unitAct_2)), true );

        mn1 = mean(unitAct_1);
        mn2 = mean(unitAct_2);
        shuffCorr(unitIdx, 2) = (mn1-mean(mn1))*(mn2-mean(mn2))'/(unbiasedMag1*unbiasedMag2);
    end

    N = histc(shuffCorr(:,1),edges);
    shuffDist(n,:) = N(1:(end-1));

    N = histc(shuffCorr(:,2),edges);
    shuffDist_unbiased(n,:) = N(1:(end-1));
end  

%true distributions
sDist = {shuffDist, shuffDist_unbiased};
nc = {neuralCorr, neuralCorr_unbiased};
bNames = {'biased','unbiased'};
binCenters = edges(1:(end-1)) + (edges(2)-edges(1))/2;

for bIdx=1:length(sDist)
    figure('Position',[680   885   300   213]);
    hold on;

    N = histc(nc{bIdx},edges);
    bar(binCenters, N(1:(end-1)),'k' );

    mnShuff = mean(squeeze(sDist{bIdx}),1);
    plot(binCenters, mnShuff, 'r','LineWidth',2);

    set(gca,'YLim',[0 22]);
    mn = median(nc{bIdx});
    plot([mn, mn], get(gca,'YLim'),'-','LineWidth',2,'Color',[0 0.8 1.0]);

    xlabel('Correlation');
    ylabel('# Electrodes');
    title('Arm vs. Leg');
    set(gca,'FontSize',16,'LineWidth',2);
    axis tight;

    saveas(gcf,[outDir filesep 'singleElectrodeCorr_timeSeries_' bNames{bIdx} '.png'],'png');
    saveas(gcf,[outDir filesep 'singleElectrodeCorr_timeSeries_' bNames{bIdx} '.svg'],'svg');
end

disp(mean(neuralCorr_unbiased>0.75));

disp(median(neuralCorr));
disp(median(neuralCorr_unbiased));

disp(mean(neuralCorr));
disp(mean(neuralCorr_unbiased));

signtest(neuralCorr)
signtest(neuralCorr_unbiased)

