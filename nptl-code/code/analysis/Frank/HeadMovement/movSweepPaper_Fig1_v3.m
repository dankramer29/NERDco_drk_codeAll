%%
blockList = [5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1500 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'Fig1'];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep 't5.2018.10.22' filesep];

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

globalIdx = 0;
alignEvents = zeros(length(R),2);
allBlocks = zeros(size(allSpikes,1),1);
for t=1:length(R)
    loopIdx = (globalIdx+1):(globalIdx + size(R(t).spikeRaster,2));
    allBlocks(loopIdx) = R(t).blockNum;
    alignEvents(t,1) = globalIdx + R(t).(alignField);
    alignEvents(t,2) = globalIdx + R(t).trialStart;
    globalIdx = globalIdx + size(R(t).spikeRaster,2);
end

[trlCodeList,~,trlCodesRemap] = unique(trlCodes);

%%
%load sorted spikes
sortedSpikes = load([paths.dataPath filesep 'Derived' filesep 'sortedUnits' filesep 't5.2018.10.22' filesep 'alignedRaster.mat']);
cSortedRaster = horzcat(sortedSpikes.bothRasters{:});
cSortedUnitList = vertcat(sortedSpikes.bothUnitLists{:});
cSortedUnitList((size(sortedSpikes.bothUnitLists{1},1)+1):end,1) = cSortedUnitList((size(sortedSpikes.bothUnitLists{1},1)+1):end,1) + 96;

nTX = size(allSpikes,2);
nSorted = size(cSortedRaster,2);
allSpikes = [allSpikes, cSortedRaster];

%%
%delay times
dTimes = zeros(length(R),1);
for t=1:length(R)
    dTimes(t) = R(t).startTrialParams.delayPeriodDuration;
end

%%
nBins = (timeWindow(2)-timeWindow(1))/binMS;
snippetMatrix = zeros(nBins, size(allSpikes,2));
baselineMatrix = zeros(length(trlCodes), size(allSpikes,2));
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
    
    baselineIdx = (alignEvents(t,2)-200):(alignEvents(t,2)+200);
    baselineIdx(baselineIdx<1) = [];
    baselineMatrix(t,:) = mean(allSpikes(baselineIdx,:)*binMS);
end

%%
bNumPerTrial = [R.blockNum];
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);

for b=1:length(blockList)
    disp(b);
    blockTrl = find(bNumPerTrial==blockList(b));

    binIdx = find(blockRows==blockList(b));
    baselineMatrix(blockTrl,:) = baselineMatrix(blockTrl,:) - mean(snippetMatrix(binIdx,:));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(binIdx,:)));
end
rawSnippetMatrix = snippetMatrix;
baselineMatrix = bsxfun(@times, baselineMatrix, 1./std(snippetMatrix));
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));

%%
clear R allSpikes
pack;

%%
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix(:,1:nTX), 3.0);
smoothSnippetMatrix_sorted = gaussSmooth_fast(snippetMatrix(:,(nTX+1):end), 3.0);

timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
yLims = [];
axHandles=[];
plotIdx = 1;

movLabels = {'SayBa','SayGa','TurnRight','TurnLeft','TurnUp','TurnDown','TiltRight','TiltLeft','Forward','Backward',...
    'TongueUp','TongueDown','TongueLeft','TongueRight','MouthOpen','JawClench','LipsPucker','EyebrowsRaise','NoseWrinkle',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen','IndexRaise','TumbRaise','Nothing'};

codeList = unique(trlCodes);
reorderIdx = [34, ...
    1 2 11 12 13 14 15 16 17 18 19, ...
    3 4 5 6 7 8 9 10, ...
    20 21 22 23 24 25 32 33, ...
    26 27 28 29 30 31];

trlCodesReorder = trlCodes;
for t=1:length(reorderIdx)
    tmp = find(trlCodes==codeList(reorderIdx(t)));
    trlCodesReorder(tmp) = t;
end

movLabelsReorder = movLabels(reorderIdx);

movTypeText = {'Face','Head','Arm','Leg'};
codeSets = {[2 3 8:12 4:7], 13:20, 21:28, 29:34};
movLabelsSets = movLabelsReorder(horzcat(codeSets{:}));

codeSetsWithNothing = codeSets;
for c=1:length(codeSets)
    codeSetsWithNothing{c} = [1, codeSets{c}];
end

%%
%single trial projection bars
timeWindow = [-1500,3000];
movWindow = [20, 60];
baselineTrls = triggeredAvg(snippetMatrix(:,1:nTX), eventIdx(trlCodesReorder==1), movWindow);

[ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_marg( trlCodesReorder', snippetMatrix(:,1:nTX), eventIdx, baselineTrls, movWindow, ...
    binMS, timeWindow, codeSets, 'raw' );
singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, movLabelsReorder(2:end) );
saveas(gcf,[outDir filesep 'bar_raw_movSweepAll.png'],'png');
saveas(gcf,[outDir filesep 'bar_raw_movSweepAll.svg'],'svg');

mnMod = zeros(length(codeSets),1);
for c=1:length(codeSets)
    mnMod(c,1) = mean(cVar_marg(codeSets{c},1));
end
disp(mnMod./mnMod(3,:));

save([outDir filesep 'barData_movSweepAll'],'cVar_marg','rawProjPoints_marg','scatterPoints', 'mnMod');

%%
tw =  timeWindow/binMS;
tw(1) = tw(1) + 1;
tw(2) = tw(2) - 1;
    
margGroupings = {{1, [1 2]}, {2}};
margNames = {'Condition-dependent', 'Condition-independent'};
opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 5;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

mPCA_out = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText) 
    trlIdx = find(ismember(trlCodesReorder, codeSets{pIdx}));
    mc = trlCodesReorder(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSnippetMatrix, eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end
close all;

%%
timeStep = binMS/1000;
timeAxis = (tw(1):tw(2))*timeStep;
nDimToShow = 3;

for setIdx = 1:length(codeSets)
    figure('Position',[680   185   442   913]);
    for c=1:length(codeSets{setIdx})
        concatDat = triggeredAvg( mPCA_out{setIdx}.readoutZ_unroll(:,1:nDimToShow), eventIdx(trlCodesReorder==codeSets{setIdx}(c)), tw );
        %concatDat = triggeredAvg( mPCA_out{setIdx}.readoutZ_unroll(:,6:8), eventIdx(trlCodesReorder==codeSets{setIdx}(c)), tw );

        for dimIdx=1:nDimToShow
            subtightplot(11,nDimToShow,(c-1)*nDimToShow + dimIdx);
            hold on;

            nDat = squeeze(concatDat(:,:,dimIdx));
            nDat = nDat(:);
            
            imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)), prctile(nDat,[2.5 97.5]));
            axis tight;
            plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
            plot([1.5,1.5],get(gca,'YLim'),'-k','LineWidth',2);

            cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
            colormap(cMap);

            if dimIdx==1
                ylabel(movLabelsReorder{codeSets{setIdx}(c)},'FontSize',12,'FontWeight','bold');
            end
            if c==1
                title(['Dimension ' num2str(dimIdx)],'FontSize',16);
            end

            if c==length(codeList)
                set(gca,'YTick',[]);
                xlabel('Time (s)');
            else
                set(gca,'XTick',[],'YTick',[]);
            end
        end
    end
end

%%
%multi-dims
timeAxis = (tw(1)/100):(binMS/1000):(tw(2)/100);

axHandles = [];
yLims = [];
nAx = 3;
baselineTrls = triggeredAvg(smoothSnippetMatrix(:,1:nTX), eventIdx(trlCodesReorder==1), timeWindow/binMS);
mnBaseline = squeeze(mean(baselineTrls,1));

figure('Position',[71   122   806   806]);
for pIdx=1:length(movTypeText)
    for axIdx=1:nAx
        cdIdx = find(mPCA_out{pIdx}.whichMarg==1);
        ax = subtightplot(4,length(movTypeText),length(movTypeText)*(axIdx-1) + pIdx,[0.01 0.01],[0.15, 0.10],[0.05 0.05]);
        axHandles = [axHandles; ax];
        hold on

        colors = jet(size(mPCA_out{pIdx}.Z,2))*0.8;
        lineHandles = zeros(size(mPCA_out{pIdx}.Z,2),1);
        for conIdx=1:size(mPCA_out{pIdx}.Z,2)
            lineHandles(conIdx) = plot(timeAxis, squeeze(mPCA_out{pIdx}.Z(cdIdx(axIdx),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
            errorPatch( timeAxis', squeeze(mPCA_out{pIdx}.margResample.CIs(cdIdx(axIdx),conIdx,:,:)), colors(conIdx,:), 0.2 );
        end
        
        %plot the nothing condition
        %cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        %projBaseline = mnBaseline * dPCA_out{pIdx}.W(:,cdIdx(1));
        %plot(timeAxis, projBaseline, '-k', 'LineWidth', 2);
        
        axis tight;
        yLims = [yLims; get(gca,'YLim')];

        plot(get(gca,'XLim'),[0 0],'k');
        set(gca,'LineWidth',1.5,'FontSize',16);

        if axIdx==nAx
            xlabel('Time (s)');
        else
            set(gca,'XTickLabels',[]);
        end
        
        if pIdx==1
            ylabel(['Dimension ' num2str(axIdx) ' (SD)']);
        else
            set(gca,'YTickLabel',[]);
        end
        
        if axIdx==1
            title(movTypeText{pIdx},'FontSize',20);
        end
        
        if axIdx==nAx
            text(0.7,0.8,'Return','Units','Normalized','FontSize',16);
            text(0.37,0.8,'Go','Units','Normalized','FontSize',16);
        end
    end

    subtightplot(4,length(movTypeText),length(movTypeText)*(4-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
    hold on;
    lineHandles = zeros(size(mPCA_out{pIdx}.Z,2),1);
    for conIdx=1:size(mPCA_out{pIdx}.Z,2)
        lineHandles(conIdx) = plot(0,0,'LineWidth',2,'Color',colors(conIdx,:));
    end
    
    lHandle = legend(lineHandles, movLabelsReorder(codeSets{pIdx}),'Location','South','box','off','FontSize',10);
    lPos = get(lHandle,'Position');
    lPos(1) = lPos(1)+0.05;
    set(lHandle,'Position',lPos);
    axis off
end

finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
for p=1:length(axHandles)
    set(axHandles(p), 'YLim', finalLimits);
    plot(axHandles(p),[0, 0],finalLimits*0.9,'--k','LineWidth',2);
    plot(axHandles(p),[1.5, 1.5],finalLimits*0.9,'--k','LineWidth',2);
end

set(gcf,'Renderer','painters');
saveas(gcf,[outDir filesep 'mPCA_exampleDims.png'],'png');
saveas(gcf,[outDir filesep 'mPCA_exampleDims.svg'],'svg');

%%
%linear classifier
movLabels = {'SayBa','SayGa','TurnRight','TurnLeft','TurnUp','TurnDown','TiltRight','TiltLeft','Forward','Backward',...
    'TongueUp','TongueDown','TongueLeft','TongueRight','MouthOpen','JawClench','LipsPucker','EyebrowsRaise','NoseWrinkle',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen','IndexRaise','TumbRaise','Nothing'};

codeList = unique(trlCodes);
reorderIdx = [34 1 2 15 16 17 18 19 11 12 13 14, ...
    3 4 5 6 7 8 9 10, ...
    20 21 22 23 24 25 32 33, ...
    26 27 28 29 30 31];

dataIdxStart = 20:60;
nDecodeBins = 1;

allFeatures = [];
allCodes = trlCodes;
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
for t=1:length(trlCodes)
    tmp = [];
    dataIdx = dataIdxStart;
    for binIdx=1:nDecodeBins
        loopIdx = dataIdx + eventIdx(t);
        tmp = [tmp, mean(snippetMatrix(loopIdx,1:nTX))];
        dataIdx = dataIdx + length(dataIdx);
    end
    
    allFeatures = [allFeatures; tmp];
end

allCodesRemap = zeros(size(allCodes));
for x=1:length(codeList)
    replaceIdx = find(allCodes==codeList(reorderIdx(x)));
    allCodesRemap(replaceIdx) = x;
end

obj = fitcdiscr(allFeatures,allCodesRemap,'DiscrimType','diaglinear');
cvmodel = crossval(obj);
L = kfoldLoss(cvmodel);
predLabels = kfoldPredict(cvmodel);

C = confusionmat(allCodesRemap, predLabels);
C_counts = C;
for rowIdx=1:size(C,1)
    C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
end

for r=1:size(C_counts,1)
    [PHAT, PCI] = binofit(C_counts(r,r),sum(C_counts(r,:)),0.01); 
    disp(PCI);
end
    
colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

figure('Position',[212   524   808   567]);
hold on;

imagesc(C);
set(gca,'XTick',1:length(movLabels),'XTickLabel',movLabels(reorderIdx),'XTickLabelRotation',45);
set(gca,'YTick',1:length(movLabels),'YTickLabel',movLabels(reorderIdx));
set(gca,'FontSize',16);
set(gca,'LineWidth',2);
colorbar;
title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);

codeSets = {[2:12],[13:20],[21:28],[29:34]};
currentIdx = 1;
currentColor = 1;
for c=1:length(codeSets)
    newIdx = currentIdx + (1:length(codeSets{c}))';
    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(currentColor,:));
    currentIdx = currentIdx + length(codeSets{c});
    currentColor = currentColor + 1;
end
axis tight;

saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');
saveas(gcf,[outDir filesep 'linearClassifier.pdf'],'pdf');

%%
%single channel tuning counting
movTypeText = {'Face','Head','Arm','Leg'};
codeSetsReduced = {[2 3 4 5 6 7 8 9 10 11 12],13:20,21:28,29:34};
movLabelsSets = movLabelsReorder(horzcat(codeSetsReduced{:}));

dPCA_for_FRAvg = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodesReorder, codeSetsReduced{pIdx}));
    dPCA_for_FRAvg{pIdx} = apply_dPCA_simple( snippetMatrix(:,1:nTX), eventIdx(trlIdx), ...
        trlCodesReorder(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 20);
    close(gcf);
end

nUnits = size(dPCA_for_FRAvg{1}.featureAverages,1);
pVal = zeros(length(codeSetsReduced), nUnits);
modSD = zeros(length(codeSetsReduced), nUnits);
modSize_cv = zeros(length(codeSetsReduced), nUnits);
codes = cell(size(codeSetsReduced,1),2);

timeOffset = -timeWindow(1)/binMS;
movWindow = (20:60);
baselineWindow = -119:-80;

for pIdx = 1:length(codeSetsReduced)    
    for unitIdx=1:size(dPCA_for_FRAvg{pIdx}.featureAverages,1)
        unitAct = squeeze(dPCA_for_FRAvg{pIdx}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        meanAcrossTrial = squeeze(nanmean(unitAct,3))';
        meanAct = squeeze(nanmean(unitAct,2))';

        pVal(pIdx, unitIdx) = anova1(meanAct,[],'off');
        modSD(pIdx, unitIdx) = nanstd(mean(meanAcrossTrial));
        
        allCVEstimates = zeros(size(meanAct,1),1);
        for t=1:size(meanAct,1)
            trainIdx = setdiff(1:size(meanAct,1), t);
            testIdx = t;
            
            meanSubMod_train = nanmean(meanAct(trainIdx,:),1)-nanmean(nanmean(meanAct(trainIdx,:)));
            meanSubMod_test = meanAct(testIdx,:)-nanmean(nanmean(meanAct(testIdx,:)));
            
            allCVEstimates(t) = meanSubMod_train*meanSubMod_test';
        end
        modSize_cv(pIdx, unitIdx) = sign(nanmean(allCVEstimates))*sqrt(abs(nanmean(allCVEstimates)));
    end
end    
modSize_cv = modSize_cv';

%correlation between tuning strength for different categories
figure; 
imagesc(corr(modSize_cv));

[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(modSize_cv);

%num tuned
sigUnit = find(any(pVal<0.001));
disp(mean(pVal'<0.001));

%categorize mixed tuning
isTuned = pVal<0.001;
numCategories = sum(isTuned);

%%
%single channel FVAF
movTypeText = {'Face','Head','Arm','Leg'};
codeSetsReduced = {[2 3 4 5 6 7 8 9 10 11 12],13:20,21:28,29:34};
movLabelsSets = movLabelsReorder(horzcat(codeSetsReduced{:}));

dPCA_for_FRAvg = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodesReorder, codeSetsReduced{pIdx}));
    dPCA_for_FRAvg{pIdx} = apply_dPCA_simple( snippetMatrix(:,1:nTX), eventIdx(trlIdx), ...
        trlCodesReorder(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 20);
    close(gcf);
end

nUnits = size(dPCA_for_FRAvg{1}.featureAverages,1);
FVAF = zeros(nUnits, length(codeSetsReduced));
codes = cell(size(codeSetsReduced,1),2);

timeOffset = -timeWindow(1)/binMS;
movWindow = (20:60);
baselineWindow = -119:-80;

for pIdx = 1:length(codeSetsReduced)    
    for unitIdx=1:size(dPCA_for_FRAvg{pIdx}.featureAverages,1)
        unitAct = squeeze(dPCA_for_FRAvg{pIdx}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        meanAcrossTrial = squeeze(nanmean(unitAct,3))';
        meanAct = squeeze(nanmean(unitAct,2))';

        meanPerMov = nanmean(meanAct);
        grandMean = nanmean(meanAct(:));
        
        err = meanPerMov-meanAct;
        ss_err = nansum(err(:).^2);
        
        err_grand_mean = meanAct-grandMean;
        ss_tot = nansum(err_grand_mean(:).^2);
        
        FVAF(unitIdx,pIdx) = 1 - ss_err/ss_tot;
    end
end    


%%
%sorted unit PSTHs

%unit quality information
unitQuality = [2,2,2,4,4,...
    2,2,2,1,2,3,4,3,3,4,3,3,3,3,3,3,3,3,4,3,3,4,4];

%1.1 - 2
%1.9 - 2
%17.1 - 2
%30.1 - 4
%39.1 - 4

%array 2;
%1.1 - 2
%25.1 - 2; 25.2 - 2
%32 ?
%33.1 - 2; 33.2 - 3
%41.1 - 4
%55.1 - 3; 55.2 - 3
%63.1 - 4
%70.1 - 3
%71.1 - 3; 71.2 - 3
%73.1 - 3
%78.1 - 3; 78.2 - 3; 78.3 - 3
%83.1 - 3
%84.1 - 4
%87.1 - 3
%88.1 - 3
%93.1 - 4
%94.1 - 4

allColors = zeros(length(codeSets),3);
lineArgs = cell(length(codeSets),1);
for setIdx = 1:length(codeSets)
    colors = hsv(length(codeSets{setIdx}))*0.8;
    for x=1:length(codeSets{setIdx})
        lineArgs{codeSets{setIdx}(x)} = {'LineWidth',1,'Color',colors(x,:)};
        allColors(codeSets{setIdx}(x),:) = colors(x,:);
    end
end

psthOpts = makePSTHOpts();
psthOpts.timeStep = binMS/1000;
psthOpts.gaussSmoothWidth = 0;
psthOpts.neuralData = {smoothSnippetMatrix_sorted};
psthOpts.timeWindow = timeWindow/binMS;
psthOpts.trialEvents = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
psthOpts.trialConditions = trlCodesReorder;
psthOpts.conditionGrouping = codeSets;
psthOpts.lineArgs = lineArgs;

psthOpts.plotsPerPage = 10;
psthOpts.plotDir = outDir;

featLabels = cell(nSorted,1);
for f=1:nSorted
    featLabels{f} = [num2str(cSortedUnitList(f,1)) ' - ' num2str(cSortedUnitList(f,2)) ' (' num2str(unitQuality(f)) ')'];
end
psthOpts.featLabels = featLabels;

psthOpts.prefix = 'sorted';
psthOpts.plotCI = 1;
psthOpts.CIColors = allColors;

out = makePSTH_simple(psthOpts);

unitIdx = find(cSortedUnitList(:,1)==30);
movIdx = (-timeWindow(1)/binMS) + 90;

figure
for col=1:4
    subplot(1,4,col);
    hold on;
    for x=1:length(codeSets{col})
        mn = out.psth{codeSets{col}(x)}(movIdx,unitIdx,1);
        ci = squeeze(out.psth{codeSets{col}(x)}(movIdx,unitIdx,2:3));
        plot(x,mn,'o');
        plot([x,x],ci,'-');
    end
end

%%
%channel TX PSTHs
allColors = zeros(length(codeSets),3);
lineArgs = cell(length(codeSets),1);
for setIdx = 1:length(codeSets)
    colors = jet(length(codeSets{setIdx}))*0.8;
    for x=1:length(codeSets{setIdx})
        lineArgs{codeSets{setIdx}(x)} = {'LineWidth',1,'Color',colors(x,:)};
        allColors(codeSets{setIdx}(x),:) = colors(x,:);
    end
end

psthOpts = makePSTHOpts();
psthOpts.timeStep = binMS/1000;
psthOpts.gaussSmoothWidth = 0;
psthOpts.neuralData = {smoothSnippetMatrix};
psthOpts.timeWindow = timeWindow/binMS;
psthOpts.trialEvents = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
psthOpts.trialConditions = trlCodesReorder;
psthOpts.conditionGrouping = codeSets;
psthOpts.lineArgs = lineArgs;

psthOpts.verticalLineEvents = [0, 1.5];
psthOpts.plotsPerPage = 10;
psthOpts.plotDir = outDir;

txChanNum = find(~tooLow);
featLabels = cell(nTX,1);
for f=1:nTX
    featLabels{f} = num2str(txChanNum(f));
end
psthOpts.featLabels = featLabels;

psthOpts.prefix = 'TX';
psthOpts.plotCI = 1;
psthOpts.CIColors = allColors;
makePSTH_simple(psthOpts);

psthOpts.prefix = 'TX_10';
psthOpts.neuralData = {smoothSnippetMatrix(:,find(txChanNum==10))};
psthOpts.featLabels{1} = '';
psthOpts.plotsPerPage = 1;
psthOpts.marg_h = [0.3, 0.03];
psthOpts.marg_w = [0.06, 0.03];
psthOpts.fontSize = 14;
psthOpts.plotUnits = false;

makePSTH_simple(psthOpts);

axChildren = get(gcf,'Children');
axes(axChildren(end));
ylabel('Firing Rate (SD)','FontSize',14);
set(gca,'YTick',[0,1,2],'YTickLabel',{'0','1','2'});

for x=1:3
    set(axChildren(x),'YTick',[0,1,2]);
end

set(gcf,'Position',[453   613   802   153]);
saveas(gcf,[outDir filesep 'exampleChannel_10.png'],'png');
saveas(gcf,[outDir filesep 'exampleChannel_10.svg'],'svg');

%%
trlCodeListReorder = trlCodeList(reorderIdx);
for t=2:length(trlCodeList)
    retVal2 = t5_2018_10_22_getMovementText(trlCodeListReorder(t));
    disp(retVal2);
end

