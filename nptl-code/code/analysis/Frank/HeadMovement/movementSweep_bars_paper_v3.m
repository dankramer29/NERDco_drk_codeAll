%%
blockList = [5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1500 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'all'];
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
tooLow = meanRate < 0.5;

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
    
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (eventIdx(blockTrl(t))-140):(eventIdx(blockTrl(t))-100)];
    end
    msIdx(msIdx<1) = [];
    
    binIdx = find(blockRows==blockList(b));
    %snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(msIdx,:)));
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
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix, 3.0);

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
timeWindow = [-500,2500];
movWindow = (20:60);
baselineWindow = (-119:-80);

[ cVar, cVar_proj, rawProjPoints, dPCA_out ] = modulationMagnitude( trlCodesReorder', smoothSnippetMatrix, eventIdx, baselineMatrix, movWindow, ...
    baselineWindow, binMS, timeWindow, codeSets, 'baseline_mn' );

singleTrialBarPlot( codeSets, rawProjPoints, cVar_proj, movLabelsReorder(2:end) );
saveas(gcf,[outDir filesep 'bar_dPCA_sp.png'],'png');
saveas(gcf,[outDir filesep 'bar_dPCA_sp.svg'],'svg');
saveas(gcf,[outDir filesep 'bar_dPCA_sp.pdf'],'pdf');

mnMod = zeros(length(codeSets),1);
for c=1:length(codeSets)
    mnMod(c) = mean(cVar_proj(codeSets{c},1));
end

save([outDir filesep 'barData_specialBaseline'],'cVar','cVar_proj', 'dPCA_out','rawProjPoints');

%%
dPCA_out = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodesReorder, codeSets{pIdx}));
    mc = trlCodesReorder(trlIdx)';

    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        mc, timeWindow/binMS, binMS/1000, {'CI','CD'}, 20, 'xval' );
    close(gcf);
end

save([outDir filesep 'eff_dPCA_movSweep.mat'],'dPCA_out');

%%
cVar = zeros(length(codeList),1);
cVar_proj = zeros(length(codeList),1);
rawProjPoints = cell(length(codeList),2);
movWindow = (20:60);
%baselineWindow = -149:-119;
baselineWindow = -119:-80;

nothingTrl = find(ismember(trlCodesReorder, 1));
nothingDat = triggeredAvg(snippetMatrix, eventIdx(nothingTrl), [-150,300]);
useNothing = true;

for pIdx = 1:length(codeSets)
    cdIdx = find(dPCA_out{pIdx}.cval.whichMarg==1);
    cdIdx = cdIdx(1:6);
    
    nothingDat_reduced = zeros(size(nothingDat,1),size(nothingDat,2),6);
    for t=1:size(nothingDat,1)
        nothingDat_reduced(t,:,:) = squeeze(nothingDat(t,:,:)) * dPCA_out{pIdx}.cval.resortW{1}(:,cdIdx);
    end
    
    for codeIdx=1:length(codeSets{pIdx})
        dataLabels = [];
        dataMatrix = [];
        nTrials = size(dPCA_out{pIdx}.cval.Z_singleTrial,1);
        
        timeOffset = (-timeWindow(1)/binMS);
        
        movWindowActivity = squeeze(dPCA_out{pIdx}.cval.Z_singleTrial(:,cdIdx,codeIdx,timeOffset+movWindow));
        if useNothing
            baselineWindowActivity = nothingDat_reduced(:,timeOffset+movWindow,:);
            baselineWindowActivity = permute(baselineWindowActivity,[3 2 1]);
        else
            baselineWindowActivity = squeeze(dPCA_out{pIdx}.cval.Z_singleTrial(:,cdIdx,codeIdx,timeOffset+baselineWindow));
        end
        
        ma = squeeze(nanmean(movWindowActivity,3));
        ma = ma(all(~isnan(ma),2),:);
        
        ba = squeeze(nanmean(baselineWindowActivity,3))';
        ba = ba(all(~isnan(ba),2),:);
        
        nTrials = size(ba,1);    
        minLen = min(size(ba,1),size(ma,1));
        ba = ba(1:minLen,:);
        ma = ma(1:minLen,:);
        
        dataMatrix = [ba; ma];
        dataLabels = [ones(size(ba,1),1); ones(size(ma,1),1)+1];
        
        badIdx = find(any(isnan(dataMatrix),2));
        dataMatrix(badIdx,:) = [];
        dataLabels(badIdx,:) = [];

        nResample = 10000;
        
        testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
        end
        
        cVar(codeSets{pIdx}(codeIdx),1) = testStat;
        cVar(codeSets{pIdx}(codeIdx),2) = prctile(resampleVec,99);
        
        ci = bootci(nResample, {@normStat, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)});
        cVar(codeSets{pIdx}(codeIdx),3:4) = ci;    
        
        %single trial projection metric       
        [cVar_proj(codeSets{pIdx}(codeIdx),1), rawProjPoints{codeSets{pIdx}(codeIdx),1}, ...
            rawProjPoints{codeSets{pIdx}(codeIdx),2}] = projStat_cv(dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:));

        nResample = 10000;
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = projStat_cv(dataMatrix(shuffLabels==1,:), dataMatrix(shuffLabels==2,:));
        end

        ci = bootci(nResample, {@projStat_cv, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)}, 'type','per');
        cVar_proj(codeSets{pIdx}(codeIdx),2) = prctile(resampleVec,99);
        cVar_proj(codeSets{pIdx}(codeIdx),3) = mean(resampleVec);
        cVar_proj(codeSets{pIdx}(codeIdx),4:5) = ci;    

        [H,P,CI] = ttest2(rawProjPoints{codeSets{pIdx}(codeIdx),2}, rawProjPoints{codeSets{pIdx}(codeIdx),1});
        cVar_proj(codeSets{pIdx}(codeIdx),6:7) = CI;
    end
end    

figure;
hold on;
plot3(dataMatrix(dataLabels==1,1), dataMatrix(dataLabels==1,2),  dataMatrix(dataLabels==1,3),'o');
plot3(dataMatrix(dataLabels==2,1), dataMatrix(dataLabels==2,2),  dataMatrix(dataLabels==2,3),'ro');

save([outDir filesep 'barData'],'cVar','cVar_proj', 'dPCA_out','rawProjPoints');

% dataMatrix = [randn(30,1); randn(30,1)+1];
% dataLabels = [ones(30,1); ones(30,1)+1];
% 
% nResample = 10000;
% resampleVec = zeros(nResample,1);
% for resampleIdx=1:nResample
%     shuffLabels = dataLabels(randperm(length(dataLabels)));
%     resampleVec(resampleIdx) = mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:));
% end

%%
%todo: single class decoding, generic PC space, vs. nothing class
%why is cohen's d the same for all movements?

%generic modulation in PC space
cVar = zeros(length(codeList),1);
cVar_proj = zeros(length(codeList),1);
rawProjPoints = cell(length(codeList),2);
movWindow = (20:60);
baselineWindow = -149:-119;
%baselineWindow = -119:-80;

nothingTrl = find(ismember(trlCodesReorder, 1));
nothingDat = triggeredAvg(snippetMatrix, eventIdx(nothingTrl), [-150,300]);
useNothing = true;

for pIdx = 1:length(codeSets)    
    for codeIdx=1:length(codeSets{pIdx})

        timeOffset = (-timeWindow(1)/binMS);
        
        fa = squeeze(dPCA_out{pIdx}.featureAverages(:,codeIdx,:))';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(fa);
        
        movWindowActivity = squeeze(dPCA_out{pIdx}.featureVals(:,codeIdx,timeOffset+movWindow,:));
        if useNothing
            baselineWindowActivity = nothingDat(:,timeOffset+movWindow,:);
            baselineWindowActivity = permute(baselineWindowActivity,[3 2 1]);
        else
            baselineWindowActivity = squeeze(dPCA_out{pIdx}.featureVals(:,codeIdx,timeOffset+baselineWindow,:));
        end
        
        ma = squeeze(nanmean(movWindowActivity,2))';
        ma = ma(all(~isnan(ma),2),:);
        ma = (ma - MU)*COEFF(:,1:3);
        
        ba = squeeze(nanmean(baselineWindowActivity,2))';
        ba = ba(all(~isnan(ba),2),:);
        ba = (ba - MU)*COEFF(:,1:3);
        
        nTrials = size(ba,1);
                
        minLen = min(size(ba,1),size(ma,1));
        ba = ba(1:minLen,:);
        ma = ma(1:minLen,:);

        dataMatrix = [ba; ma];
        dataLabels = [ones(size(ba,1),1); ones(size(ma,1),1)+1];
        nResample = 10000;
        
        testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
        end
        
        cVar(codeSets{pIdx}(codeIdx),1) = testStat;
        cVar(codeSets{pIdx}(codeIdx),2) = prctile(resampleVec,99);
        
        ci = bootci(nResample, {@normStat, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)});
        cVar(codeSets{pIdx}(codeIdx),3:4) = ci;    
        
        %single trial projection metric       
        [cVar_proj(codeSets{pIdx}(codeIdx),1), rawProjPoints{codeSets{pIdx}(codeIdx),1}, ...
            rawProjPoints{codeSets{pIdx}(codeIdx),2}] = projStat_cv(dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:));

        nResample = 10000;
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = projStat_cv(dataMatrix(shuffLabels==1,:), dataMatrix(shuffLabels==2,:));
        end

        ci = bootci(nResample, {@projStat_cv, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)}, 'type','per');
        cVar_proj(codeSets{pIdx}(codeIdx),2) = prctile(resampleVec,99);
        cVar_proj(codeSets{pIdx}(codeIdx),3) = mean(resampleVec);
        cVar_proj(codeSets{pIdx}(codeIdx),4:5) = ci;    

        [H,P,CI] = ttest2(rawProjPoints{codeSets{pIdx}(codeIdx),2}, rawProjPoints{codeSets{pIdx}(codeIdx),1});
        cVar_proj(codeSets{pIdx}(codeIdx),6:7) = CI;
    end
end    

figure;
hold on;
plot3(dataMatrix(dataLabels==1,1), dataMatrix(dataLabels==1,2),  dataMatrix(dataLabels==1,3),'o');
plot3(dataMatrix(dataLabels==2,1), dataMatrix(dataLabels==2,2),  dataMatrix(dataLabels==2,3),'ro');

%%
cohenD = zeros(size(cVar,1),1);
for x=1:size(cVar,1)
    poolSD = std([rawProjPoints{x,1} - mean(rawProjPoints{x,1}); ...
        rawProjPoints{x,2} - mean(rawProjPoints{x,2})]);
    cohenD(x) = (mean(rawProjPoints{x,2})-mean(rawProjPoints{x,1}))/poolSD;
end

for setIdx=1:length(codeSets)
    disp(mean(cohenD(codeSets{setIdx})));
end

%%
%bar plot
colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

figure('Position',[164   751   989   338]);
plotIdx = 1;
colorIdx = 1;

hold on
for pIdx=1:length(codeSets)
    lightColor = colors(pIdx,:)*0.7 + ones(1,3)*0.3;
    darkColor = colors(pIdx,:)*0.7 + zeros(1,3)*0.3;
    for movIdx=1:length(codeSets{pIdx})
        mIdx = codeSets{pIdx}(movIdx);

        base = mean(rawProjPoints{mIdx,1});
        
        bar(plotIdx, mean(rawProjPoints{mIdx,2})-base, 'FaceColor', colors(colorIdx,:), 'LineWidth', 1);
        
        jitterX = rand(length(rawProjPoints{mIdx,1}),1)*0.5-0.25;
        plot(plotIdx+jitterX, rawProjPoints{mIdx,1}-base, 's', 'Color', lightColor, 'MarkerSize', 2);            

        jitterX = rand(length(rawProjPoints{mIdx,2}),1)*0.5-0.25;
        plot(plotIdx+jitterX, rawProjPoints{mIdx,2}-base, 'o', 'Color', darkColor, 'MarkerSize', 2);
        
        height = mean(rawProjPoints{mIdx,2})-base;
        CI = cVar_proj(mIdx,4:5)-cVar_proj(mIdx,1);
        errorbar(plotIdx, height, CI(1), CI(2), '.k','LineWidth',1);
        
        %plot([plotIdx-0.4, plotIdx+0.4],[cVar_proj(mIdx,2), cVar_proj(mIdx,2)],':k','LineWidth',2);
        
        %plot([plotIdx, plotIdx],[-cVar_proj(mIdx,5)/2, -cVar_proj(mIdx,4)/2]-base,...
        % 'Color',colors(pIdx,:),'LineWidth',20);
        %plot([plotIdx, plotIdx],[cVar_proj(mIdx,4)/2, cVar_proj(mIdx,5)/2]-base,...
        % 'Color',colors(pIdx,:),'LineWidth',20);

        %plot([plotIdx, plotIdx],[mean(rawProjPoints{mIdx,1}), mean(rawProjPoints{mIdx,2})]-base,...
        %'Color',colors(pIdx,:),'LineWidth',5);

        plotIdx = plotIdx + 1;
    end
    colorIdx = colorIdx + 1;
end
set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabelsSets,'XTickLabelRotation',45);

axis tight;
xlim([0.5, 33.5]);
ylabel('\Delta Neural Activity (SD)','FontSize',22);
set(gca,'TickLength',[0 0]);
%plot(get(gca,'XLim'),[0,0],'-k','LineWidth',1);

saveas(gcf,[outDir filesep 'bar_dPCA_sp.png'],'png');
saveas(gcf,[outDir filesep 'bar_dPCA_sp.svg'],'svg');
saveas(gcf,[outDir filesep 'bar_dPCA_sp.pdf'],'pdf');

%%
%multi-dims
axHandles = [];
yLims = [];
nAx = 1;

figure('Position',[71   418   831   510]);
for pIdx=1:length(movTypeText)
    for axIdx=1:nAx
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        ax = subtightplot(2,length(movTypeText),length(movTypeText)*(axIdx-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
        axHandles = [axHandles; ax];
        hold on

        colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
        lineHandles = zeros(size(dPCA_out{pIdx}.Z,2),1);
        for conIdx=1:size(dPCA_out{pIdx}.Z,2)
            lineHandles(conIdx) = plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(axIdx),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
            errorPatch( timeAxis', squeeze(dPCA_out{pIdx}.dimCI(cdIdx(axIdx),conIdx,:,:)), colors(conIdx,:), 0.2 );
        end
        
        %plot(timeAxis, nothingAvg{pIdx}(:,axIdx),'LineWidth',2,'Color','k');
        %errorPatch( timeAxis', squeeze(nothingCI{pIdx}(:,axIdx,:)), [0 0 0], 0.2 );

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
        
        %if axIdx==nAx
        %    plot([0,1.0]+0.2,[-1,-1],'-k','LineWidth',2);
        %end
        %axis off;
    end

    subtightplot(4,length(movTypeText),length(movTypeText)*(4-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
    hold on;
    lineHandles = zeros(size(dPCA_out{pIdx}.Z,2),1);
    for conIdx=1:size(dPCA_out{pIdx}.Z,2)
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
saveas(gcf,[outDir filesep 'dPCA_exampleDims_ax.png'],'png');
saveas(gcf,[outDir filesep 'dPCA_exampleDims_ax.svg'],'svg');

%%
%single unit counting
movTypeText = {'Face','Head','Arm','Leg'};
codeSetsReduced = {[2 3 4 5 6 7 8 9 10 11 12],13:20,21:28,29:34};
movLabelsSets = movLabelsReorder(horzcat(codeSetsReduced{:}));

dPCA_out = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodesReorder, codeSetsReduced{pIdx}));
    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        trlCodesReorder(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 20);
    close(gcf);
end

nUnits = size(dPCA_out{1}.featureAverages,1);
pVal = zeros(length(codeSetsReduced), nUnits);
modSD = zeros(length(codeSetsReduced), nUnits);
codes = cell(size(codeSetsReduced,1),2);

timeOffset = -timeWindow(1)/binMS;
movWindow = (20:60);
baselineWindow = -119:-80;

for pIdx = 1:length(codeSetsReduced)    
    for unitIdx=1:size(dPCA_out{pIdx}.featureAverages,1)
        unitAct = squeeze(dPCA_out{pIdx}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        meanAcrossTrial = squeeze(nanmean(unitAct,3))';
        meanAct = squeeze(nanmean(unitAct,2))';

        pVal(pIdx, unitIdx) = anova1(meanAct,[],'off');
        
        modSD(pIdx, unitIdx) = nanstd(mean(meanAcrossTrial));
    end
end    

sigUnit = find(any(pVal<0.001));

%num tuned
disp(mean(pVal'<0.001));

%categorize mixed tuning
isTuned = pVal<0.001;
numCategories = sum(isTuned);

%%
eVar = zeros(length(codeSetsReduced),1);
for pIdx = 1:length(codeSetsReduced)
    cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
    cdIdx = cdIdx(1:6);
    
    totalVar = sum(dPCA_out{pIdx}.explVar.margVar(1,cdIdx))*dPCA_out{pIdx}.explVar.totalMarginalizedVar(1);
    totalVar = totalVar / size(dPCA_out{pIdx}.featureAverages,2);
    eVar(pIdx) = totalVar;
end

figure; 
plot(sqrt(eVar)/max(sqrt(eVar)));

%%
%PSTHs for each feature
%get code sets for each movement type

%PSTHS
movTypes = {'Face','Head','Arm','Leg'};
lineArgs = cell(length(trlCodeList),1);
for pIdx = 1:length(movTypes)
    colors = hsv(length(codeSetsReduced{pIdx}))*0.8;
    for x=1:length(codeSetsReduced{pIdx})
        lineArgs{codeSetsReduced{pIdx}(x)} = {'LineWidth',1,'Color',colors(x,:)};
    end
end

psthOpts = makePSTHOpts();
psthOpts.gaussSmoothWidth = 0;
psthOpts.neuralData = {smoothSnippetMatrix};
psthOpts.timeWindow = timeWindow/binMS;
psthOpts.trialEvents = (-timeWindow(1)/binMS):nBins:size(smoothSnippetMatrix,1);
psthOpts.trialConditions = trlCodesReorder;
psthOpts.conditionGrouping = codeSetsReduced;
psthOpts.lineArgs = lineArgs;

psthOpts.plotsPerPage = 10;
psthOpts.plotDir = outDir;

featLabels = cell(192,1);
chanIdx = find(~tooLow);
for f=1:length(chanIdx)
    featLabels{f} = num2str(chanIdx(f));
end
psthOpts.featLabels = featLabels;

tooLowChans = find(tooLow);
usedChans = setdiff(1:192, tooLowChans);

psthOpts.prefix = 'TX';
makePSTH_simple(psthOpts);

%%
%similarity matrix across movements using projection
dPCA_all = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesReorder', [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );

%%
cWindow = 60:100;
fa = dPCA_all.featureAverages(:,:,cWindow);
fa = fa(:,:)';
fa = mean(fa);

avgTraj_baseline = squeeze(dPCA_all.featureAverages(:,1,:))';
avgTraj_baseline = mean(avgTraj_baseline(cWindow,:));
    
nCon = size(dPCA_all.featureAverages,2);
simMatrix = zeros(nCon, nCon);
fVectors = zeros(nCon, size(dPCA_all.featureAverages,1));
for x=1:nCon
    %get the top dimensions this movement lives in
    avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
    avgTraj = mean(avgTraj(cWindow,:))-fa;
   
    for y=1:nCon
        avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
        avgTraj_y = mean(avgTraj_y(cWindow,:))-fa;
        
        simMatrix(x,y) = norm(avgTraj-avgTraj_y);
    end
    fVectors(x,:) = avgTraj;
end

figure
imagesc(simMatrix);
colormap(jet);
set(gca,'XTick',1:nCon,'XTickLabel',movLabelsReorder,'XTickLabelRotation',45);
set(gca,'YTick',1:nCon,'YTickLabel',movLabelsReorder);
set(gca,'FontSize',16);
set(gca,'YDir','normal');
colorbar;

colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

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

%%
cWindow = 60:100;
fa = dPCA_all.featureAverages(:,:,cWindow);
fa = fa(:,:)';
fa = mean(fa);

subtractEffMean = true;
effSets = codeSets;
effSets{end+1} = 1;
effMeans = zeros(length(fa), length(effSets));
setMemberships = zeros(nCon,1);

for s=1:length(effSets)
    tmp = dPCA_all.featureAverages(:,effSets{s},cWindow);
    tmp = tmp(:,:);
    
    effMeans(:,s) = mean(tmp');
    setMemberships(effSets{s}) = s;
end

avgTraj_baseline = squeeze(dPCA_all.featureAverages(:,1,:))';
avgTraj_baseline = mean(avgTraj_baseline(cWindow,:));
    
nCon = size(dPCA_all.featureAverages,2);
simMatrix = zeros(nCon, nCon);
fVectors = zeros(nCon, size(dPCA_all.featureAverages,1));
for x=1:nCon
    %get the top dimensions this movement lives in
    avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
    avgTraj = mean(avgTraj(cWindow,:));
    if subtractEffMean
        avgTraj = avgTraj - effMeans(:,setMemberships(x))';
    else
        avgTraj = avgTraj - fa;
    end
   
    for y=1:nCon
        avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
        avgTraj_y = mean(avgTraj_y(cWindow,:));
        if subtractEffMean
            avgTraj_y = avgTraj_y - effMeans(:,setMemberships(y))';
        else
            avgTraj_y = avgTraj_y - fa;
        end
        
        simMatrix(x,y) = corr(avgTraj', avgTraj_y');
    end
    fVectors(x,:) = avgTraj;
end

cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

figure
imagesc(simMatrix,[-1 1]);
colormap(cMap);
set(gca,'XTick',1:nCon,'XTickLabel',movLabelsReorder,'XTickLabelRotation',45);
set(gca,'YTick',1:nCon,'YTickLabel',movLabelsReorder);
set(gca,'FontSize',16);
set(gca,'YDir','normal');
colorbar;

colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

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

saveas(gcf,[outDir filesep 'corrMat.png'],'png');
saveas(gcf,[outDir filesep 'corrMat.svg'],'svg');
saveas(gcf,[outDir filesep 'corrMat.pdf'],'pdf');

%%
figure
imagesc(abs(simMatrix));
set(gca,'XTick',1:nCon,'XTickLabel',movLabelsReorder,'XTickLabelRotation',45);
set(gca,'YTick',1:nCon,'YTickLabel',movLabelsReorder);
set(gca,'FontSize',16);
set(gca,'YDir','normal');
colormap(copper);
colorbar;

colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

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

%%
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(fVectors); 

figure
hold on
for c=1:length(codeSets)
    for x=1:length(codeSets{c})
        codeIdx = codeSets{c}(x);
        plot(SCORE(codeIdx,1), SCORE(codeIdx,2), 'o', 'MarkerFaceColor', colors(c,:),'Color',colors(c,:),'MarkerSize',12);
    end
end

figure
for pair=1:6
    subplot(2,3,pair);
    hold on;
    axIdx = [(pair-1)*2+1, pair*2];
    
    for c=1:length(codeSets)
        for x=1:length(codeSets{c})
            codeIdx = codeSets{c}(x);
            plot(SCORE(codeIdx,axIdx(1)), SCORE(codeIdx,axIdx(2)), 'o', 'MarkerFaceColor', colors(c,:),'Color',colors(c,:),'MarkerSize',12);
        end
    end
    axis equal;
end

figure
for axIdx=1:6
    subplot(2,3,axIdx);
    hold on;
    for c=1:length(codeSets)
        for x=1:length(codeSets{c})
            codeIdx = codeSets{c}(x);
            fa = squeeze(dPCA_all.featureAverages(:,codeIdx,:))';
            fa_reduced = (fa-MU)*COEFF(:,axIdx);
            plot(fa_reduced,'Color', colors(c,:),'LineWidth',2);
        end
    end
end

%%
nDim = 2;
simMatrix = zeros(nCon, nCon);
for x=1:nCon
    %diagonal    
    fv = dPCA_all.featureVals;
    reconAct = zeros(size(fv,1),size(fv,3),size(fv,4));
    for t=1:size(fv,4)
        trainIdx = setdiff(1:size(fv,4),t);
        avgTraj = nanmean(squeeze(fv(:,x,:,trainIdx)),3);
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
        topDim = COEFF(:,1:nDim);    
        
        testTraj = squeeze(fv(:,x,:,t));
        reconAct(:,:,t) = ((testTraj-MU)*topDim)*topDim';
    end
    goodIdx = find(~isnan(squeeze(reconAct(1,1,:))));

    reconTraj = squeeze(nanmean(reconAct,3));
    errTraj = avgTraj - reconTraj;

    SSTOT = sum(avgTraj(:).^2);
    SSERR = sum(errTraj(:).^2);

    simMatrix(x,x) = 1 - SSERR/SSTOT;
        
    %cross
    avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
    avgTraj = avgTraj - mean(avgTraj);
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
    topDim = COEFF(:,1:nDim);
    
    for y=1:nCon
        avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
        avgTraj_y = avgTraj_y - mean(avgTraj_y);
        
        reconTraj = (avgTraj_y*topDim)*topDim';
        errTraj = avgTraj_y - reconTraj;
        
        SSTOT = sum(avgTraj_y(:).^2);
        SSERR = sum(errTraj(:).^2);
        
        if y~=x
            simMatrix(x,y) = 1 - SSERR/SSTOT;
        end
    end
end

figure
imagesc(simMatrix,[0 1.0]);
set(gca,'XTick',1:nCon,'XTickLabel',movLabelsReorder,'XTickLabelRotation',45);
set(gca,'YTick',1:nCon,'YTickLabel',movLabelsReorder);
set(gca,'FontSize',16);
set(gca,'YDir','normal');
colormap(copper);
colorbar;

colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

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

%%
%arm and leg sets, leave one out
subtractEffAvg = true;

%codeSets = {[2 3 4 5 6 7 8 9 10 11 12],13:20,21:28,29:34};
codeSets = {[2 4 6 10 12],[13 15 17 19],[21 22 23 24 25],[29 31 33]};

varSquare = zeros(length(codeSets));
varAll = cell(length(codeSets));
for s=1:length(codeSets)
    varExpl = zeros(length(codeSets{s}),1);
    for x=1:length(codeSets{s})
        codeIdx = setdiff(codeSets{s}, codeSets{s}(x));
        avgTraj = squeeze(dPCA_all.featureAverages(:,codeIdx,:));
        avgTraj = avgTraj(:,:)';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
        topDim = COEFF(:,1:10);
        
        avgTraj_y = squeeze(dPCA_all.featureAverages(:,codeSets{s}(x),:))';
        if subtractEffAvg
            effAvg = squeeze(nanmean(dPCA_all.featureAverages(:,codeSets{s},:),2))';
            avgTraj_y = avgTraj_y - effAvg;
        end
        avgTraj_y = avgTraj_y - mean(avgTraj_y);

        reconTraj = (avgTraj_y*topDim)*topDim';
        errTraj = avgTraj_y - reconTraj;

        SSTOT = sum(avgTraj_y(:).^2);
        SSERR = sum(errTraj(:).^2);

        varExpl(x) = 1 - SSERR/SSTOT;
    end
    
    varSquare(s,s) = mean(varExpl);

    avgTraj = squeeze(dPCA_all.featureAverages(:,codeSets{s},:));
    avgTraj = avgTraj(:,:)';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
    topDim = COEFF(:,1:10);

    varExpl_cross = cell(length(codeSets),1);
    for y=1:length(codeSets)
        for x=1:length(codeSets{y})
            avgTraj_y = squeeze(dPCA_all.featureAverages(:,codeSets{y}(x),:))';
            if subtractEffAvg
                effAvg = squeeze(nanmean(dPCA_all.featureAverages(:,codeSets{y},:),2))';
                avgTraj_y = avgTraj_y - effAvg;
            end
            avgTraj_y = avgTraj_y - mean(avgTraj_y);

            reconTraj = (avgTraj_y*topDim)*topDim';
            errTraj = avgTraj_y - reconTraj;

            SSTOT = sum(avgTraj_y(:).^2);
            SSERR = sum(errTraj(:).^2);

            varExpl_cross{y}(x) = 1 - SSERR/SSTOT;
        end
        if y~=s
            varSquare(s,y) = mean(varExpl_cross{y});
        end
    end
    
    varExpl_cross{s} = varExpl';
    varAll(s,:) = varExpl_cross;
end

%%
%arm and leg sets, leave one out dPCA
dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesReorder', [-1500, 3000]/binMS, binMS/1000, {'CI','CD'} );
fm = mean(dPCA_out.featureAverages(:,:),2)';

varSquare = zeros(length(codeSets));
for s=1:length(codeSets)
    varExpl = zeros(length(codeSets{s}),1);
    for x=1:length(codeSets{s})
        codeIdx = setdiff(codeSets{s}, codeSets{s}(x));
        
        trlIdx = find(ismember(trlCodesReorder, codeIdx));
        dPCA_inner = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
            trlCodesReorder(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 40);
        close(gcf);
        
        cdIdx = find(dPCA_inner.whichMarg==1);
        cdIdx = cdIdx(1:10);
        ciIdx = find(dPCA_inner.whichMarg==2);
        
        avgTraj_y = squeeze(dPCA_out.featureAverages(:,codeSets{s}(x),:))';
        avgTraj_y = avgTraj_y - fm;

        reconTraj_ci = (avgTraj_y*dPCA_inner.W(:,ciIdx))*dPCA_inner.V(:,ciIdx)';
        reconTraj_cd = (avgTraj_y*dPCA_inner.W(:,cdIdx))*dPCA_inner.V(:,cdIdx)';
        avgTraj_y_cd = avgTraj_y - reconTraj_ci;
        
        errTraj = avgTraj_y_cd - reconTraj_cd;
        SSTOT = sum(avgTraj_y_cd(:).^2);
        SSERR = sum(errTraj(:).^2);

        varExpl(x) = 1 - SSERR/SSTOT;
    end
    
    varSquare(s,s) = mean(varExpl);

    trlIdx = find(ismember(trlCodesReorder, codeSets{s}));
    dPCA_inner = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        trlCodesReorder(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 40);
    close(gcf);
    
    cdIdx = find(dPCA_inner.whichMarg==1);
    cdIdx = cdIdx(1:10);
    ciIdx = find(dPCA_inner.whichMarg==2);
        
    varExpl_cross = cell(length(codeSets),1);
    for y=1:length(codeSets)
        for x=1:length(codeSets{y})
            avgTraj_y = squeeze(dPCA_out.featureAverages(:,codeSets{y}(x),:))';
            avgTraj_y = avgTraj_y - fm;

            reconTraj_ci = (avgTraj_y*dPCA_inner.W(:,ciIdx))*dPCA_inner.V(:,ciIdx)';
            reconTraj_cd = (avgTraj_y*dPCA_inner.W(:,cdIdx))*dPCA_inner.V(:,cdIdx)';
            avgTraj_y_cd = avgTraj_y - reconTraj_ci;

            errTraj = avgTraj_y_cd - reconTraj_cd;
            SSTOT = sum(avgTraj_y_cd(:).^2);
            SSERR = sum(errTraj(:).^2);

            varExpl_cross{y}(x) = 1 - SSERR/SSTOT;
        end
        if y~=s
            varSquare(s,y) = mean(varExpl_cross{y});
        end
    end
end

%%
%bar plot
colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

figure('Position',[164   751   989   338]);
plotIdx = 1;
colorIdx = 1;

hold on
for pIdx=1:length(codeSets)
    dat = cVar(codeSets{pIdx},1); % - cVar(codeSets{pIdx},2);
    CI = cVar(codeSets{pIdx},3:4); % - cVar(codeSets{pIdx},2);
    
    xAxis = (plotIdx):(plotIdx + length(dat) - 1);
    bar(xAxis, dat, 'FaceColor', colors(colorIdx,:), 'LineWidth', 1);
    %for x=1:length(dat)
    %    plot([plotIdx+x-1, plotIdx+x-1], CI(x,:), '-k','LineWidth',1);
    %end
    errorbar(xAxis, dat, dat-CI(:,1), CI(:,2)-dat, '.k','LineWidth',1);
    
    plotIdx = plotIdx + length(dat);
    colorIdx = colorIdx + 1;
end
set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabelsSets,'XTickLabelRotation',45);

axis tight;
xlim([0.5, 33.5]);
ylabel('\Delta Neural Activity\newlinein Separating Dimensions\newline(a.u.)','FontSize',22);
set(gca,'TickLength',[0 0]);

saveas(gcf,[outDir filesep 'bar_dPCA.png'],'png');
saveas(gcf,[outDir filesep 'bar_dPCA.svg'],'svg');
saveas(gcf,[outDir filesep 'bar_dPCA.pdf'],'pdf');

%%
for pIdx=1:length(codeSets)
    dat = cVar(codeSets{pIdx},1);% - cVar(codeSets{pIdx},2);
    disp(mean(dat));
end

%%
dPCA_out = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodesReorder, codeSets{pIdx}));
    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        trlCodesReorder(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 20, 'standard' );
    close(gcf);
end

nothingTrl = find(ismember(trlCodesReorder, 1));
nothingDat = triggeredAvg(smoothSnippetMatrix, eventIdx(nothingTrl), [-150,300]);
useNothing = true;
nothingAvg = cell(length(codeSets),1);
nothingCI = cell(length(codeSets),1);

for pIdx = 1:length(codeSets)
    cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
    cdIdx = cdIdx(1:6);
    
    nothingDat_reduced = zeros(size(nothingDat,1),size(nothingDat,2),6);
    for t=1:size(nothingDat,1)
        nothingDat_reduced(t,:,:) = squeeze(nothingDat(t,:,:)) * dPCA_out{pIdx}.W(:,cdIdx);
    end
    
    nothingAvg{pIdx} = squeeze(mean(nothingDat_reduced,1));
    nothingCI{pIdx} = zeros(size(nothingDat_reduced,2),6,2);
    for dimIdx=1:size(nothingDat_reduced,3)
        [~,~,tmp] = normfit(squeeze(nothingDat_reduced(:,:,dimIdx)));
        nothingCI{pIdx}(:,dimIdx,:) = tmp';
    end
end

%%
%raw data test
movWindow = 20:100;
baselineWindow = -140:-100;

cVar = zeros(length(trlCodeList),1);
codes = cell(size(movTypes,1),2);
all_dPCA = cell(size(movTypes,1),2);

allP = [];
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    trlIdx = find(trlIdx);
    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
    tmpCodes = trlCodesRemap(trlIdx);
    
    dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
    close(gcf);
    
    all_dPCA{pIdx} = dPCA_out;
    
    cdIdx = find(dPCA_out.whichMarg==1);
    cdIdx = cdIdx(1:8);
    
    cLoopIdx = expandEpochIdx([ eventIdx(trlIdx)', eventIdx(trlIdx)'+75]);
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(dPCA_out.featureAverages(:,:)');
    reducedSnippetMatrix = snippetMatrix*COEFF(:,1:5);
    %reducedSnippetMatrix = snippetMatrix;

    for codeIdx=1:length(codes{pIdx,2})
        dataLabels = [];
        dataMatrix = [];
        trlIdxForThisCode = trlIdx(tmpCodes==codes{pIdx,2}(codeIdx));
        for x=1:length(trlIdxForThisCode)
            loopIdxWindow = eventIdx(trlIdxForThisCode(x))+movWindow;
            loopIdxBaseline = eventIdx(trlIdxForThisCode(x))+baselineWindow;
            if any(loopIdxBaseline<=0) || any(loopIdxWindow<=0)
                continue;
            end
            
            dataMatrix = [dataMatrix; mean(reducedSnippetMatrix(loopIdxBaseline,:)); mean(reducedSnippetMatrix(loopIdxWindow,:))];
            dataLabels = [dataLabels; 1; 2];
        end
        
        [D,P,STATS]=manova1(dataMatrix, dataLabels);
        allP = [allP; P];
        
%         nResample = 10000;
%         testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
%         resampleVec = zeros(nResample,1);
%         for resampleIdx=1:nResample
%             shuffLabels = dataLabels(randperm(length(dataLabels)));
%             resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
%         end
%         
%         cVar(codes{pIdx,2}(codeIdx),1) = testStat;
%         cVar(codes{pIdx,2}(codeIdx),2) = prctile(resampleVec,99);
%         
%         resampleVec = zeros(nResample,1);
%         for resampleIdx=1:nResample
%             class2 = dataMatrix(dataLabels==2,:);
%             class2 = class2(randi(size(class2,1), size(class2,1), 1),:);
%             
%             class1 = dataMatrix(dataLabels==1,:);
%             class1 = class1(randi(size(class1,1), size(class1,1), 1),:);
%             
%             testStat = norm(mean(class2) - mean(class1));
%             resampleVec(resampleIdx) = testStat;
%         end
%         cVar(codes{pIdx,2}(codeIdx),3:4) = prctile(resampleVec,[2.5,97.5]);    
    end
end    

%%
%effector
effCodes = trlCodesReorder;
for t=1:length(effCodes)
    for s=1:length(codeSets)
        if ismember(trlCodesReorder(t), codeSets{s})
            effCodes(t) = s;
        end
    end
end

dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    effCodes', [-1500, 3000]/binMS, binMS/1000, {'CI','CD'} );
cdIdx = find(dPCA_out.whichMarg==1);

figure
for axIdx=1:6
    subplot(2,3,axIdx);
    hold on;
    for c=1:length(codeSets)
        for x=1:length(codeSets{c})
            codeIdx = codeSets{c}(x);
            fa = squeeze(dPCA_all.featureAverages(:,codeIdx,:))';
            fa_reduced = (fa-MU)*dPCA_out.W(:,cdIdx(axIdx));
            plot(fa_reduced,'Color', colors(c,:),'LineWidth',2);
        end
    end
end

