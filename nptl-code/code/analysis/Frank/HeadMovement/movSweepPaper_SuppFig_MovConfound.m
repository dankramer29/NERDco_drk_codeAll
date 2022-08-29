%%
%blockList = [1 2 3 4 5 6 7 8 9 10];
%sessionName = 't5.2019.02.25';

%second session has less breathing artifact, and gentler movements
blockList = [2 3 4 5 6 7 8 9 12];
sessionName = 't5.2019.03.25';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1500 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'SuppFigMov' filesep sessionName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

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
    loopIdx = (globalIdx+1):(globalIdx + length(R(t).spikeRaster));
    allBlocks(loopIdx) = R(t).blockNum;
    alignEvents(t,1) = globalIdx + R(t).(alignField);
    alignEvents(t,2) = globalIdx + R(t).trialStart;
    globalIdx = globalIdx + size(R(t).spikeRaster,2);
end

[trlCodeList,~,trlCodesRemap] = unique(trlCodes);

%%
%delay times
dTimes = zeros(length(R),1);
for t=1:length(R)
    dTimes(t) = R(t).startTrialParams.delayPeriodDuration;
end

%%
%rigid bodies
allRB = [R.rigidBodyPosXYZ; R.rigidBodyRotXYZ; R.rigidBodyPosXYZ_2; R.rigidBodyRotXYZ_2; ...
    R.rigidBodyPosXYZ_3; R.rigidBodyRotXYZ_3;]';

rotIdx = [4:6, 10:12, 16:18];
xyzIdx = [1:3, 7:9, 13:15];

tmp = allRB(:,rotIdx);
tmp(tmp<-2.7) = pi+(tmp(tmp<-2.7)+pi);
allRB(:,rotIdx) = tmp;

filtCutoff = 10/500;
[B,A] = butter(4,filtCutoff);
allRB(:,xyzIdx) = filtfilt(B,A,double(allRB(:,xyzIdx)));

%%
nRB = 18;
nBins = (timeWindow(2)-timeWindow(1))/binMS;
snippetMatrix = zeros(nBins, size(allSpikes,2));
rigidBodies = zeros(nBins, nRB);
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
    newRow_rb = zeros(nBins, nRB);
    binIdx = 1:binMS;
    for b=1:nBins
        if binIdx(end)>length(loopIdx)
            continue;
        end
        newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
        newRow_rb(b,:) = mean(allRB(loopIdx(binIdx),:));
        binIdx = binIdx + binMS;
    end

    newIdx = (globalIdx):(globalIdx+nBins-1);
    globalIdx = globalIdx+nBins;
    blockRows(newIdx) = repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1);
    
    snippetMatrix(newIdx,:) = newRow;
    rigidBodies(newIdx,:) = newRow_rb;
    
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
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix, 3.0);

timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
yLims = [];
axHandles=[];
plotIdx = 1;

% TURN_HEAD_RIGHT(67)
% TURN_HEAD_LEFT(71)
% TURN_HEAD_UP(72)
% TURN_HEAD_DOWN(73)
% 
% MOUTH_OPEN(86)
% PUCKER_LIPS(88)
% RAISE_EYEBROWS(89)
% NOSE_WRINKLE(90)
% 
% LEFT_ARM_RAISE(123)
% LEFT_WRIST_EXT(127)
% LEFT_WRIST_FLEX(128)
% LEFT_CLOSE_HAND(129)
% LEFT_OPEN_HAND(130)
% 
% RIGHT_ARM_RAISE(132)
% RIGHT_WRIST_EXT(136)
% RIGHT_WRIST_FLEX(137)
% RIGHT_CLOSE_HAND(138)
% RIGHT_OPEN_HAND(139)
% 
% LEFT_ANKLE_UP(140)
% LEFT_ANKLE_DOWN(141)
% LEFT_LEG_UP(144)
% LEFT_TOE_CURL(146)
% LEFT_TOE_OPEN(147)
% 
% RIGHT_ANKLE_UP(148)
% RIGHT_ANKLE_DOWN(149)
% RIGHT_LEG_UP(152)
% RIGHT_TOE_CURL(154)
% RIGHT_TOE_OPEN(155)
      
movLabels = {'HeadRight','HeadLeft','HeadUp','HeadDown','MouthOpen','LipsPucker','EyebrowsRaise','NoseWrinkle',...
    'LArmRaise','LWristExt','LWristFlex','LCloseHand','LOpenHand','RArmRaise','RWristExt','RWristFlex','RCloseHand','ROpenHand',...
    'LAnkleUp','LAnkleDown','LLegUp','LToeCurl','LToeOpen','RAnkleUp','RAnkleDown','RLegUp','RToeCurl','RToeOpen','Nothing'};

codeList = unique(trlCodes);
reorderIdx = [29, 1:28];

trlCodesReorder = trlCodes;
for t=1:length(reorderIdx)
    tmp = find(trlCodes==codeList(reorderIdx(t)));
    trlCodesReorder(tmp) = t;
end

movLabelsReorder = movLabels(reorderIdx);

movTypeText = {'Head','Face','LArm','RArm','LLeg','RLeg'};
codeSets = {2:5,6:9,10:14,15:19,20:24,25:29};
movLabelsSets = movLabelsReorder(horzcat(codeSets{:}));

codeSetsWithNothing = codeSets;
for c=1:length(codeSets)
    codeSetsWithNothing{c} = [1, codeSets{c}];
end

%%
%single trial projection bars
timeWindow = [-1500,3000];
movWindow = [20, 60];
baselineTrls = triggeredAvg(snippetMatrix, eventIdx(trlCodesReorder==1), movWindow);

[ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_marg( trlCodesReorder', smoothSnippetMatrix, eventIdx, baselineTrls, movWindow, ...
    binMS, timeWindow, codeSets, 'subtractMean' );
singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, movLabelsReorder(2:end) );
saveas(gcf,[outDir filesep 'bar_marg_movSweepAll.png'],'png');
saveas(gcf,[outDir filesep 'bar_marg_movSweepAll.svg'],'svg');

%%
%internal baseline bars
movWindow = [20, 60];
baselineWindow = [-10, 10];

[ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_internalBaseline( trlCodesReorder', smoothSnippetMatrix, eventIdx, ...
    movWindow, baselineWindow, codeSets, 'raw' );
singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, movLabelsReorder(2:end) );
saveas(gcf,[outDir filesep 'bar_intBase_movSweepAll.png'],'png');
saveas(gcf,[outDir filesep 'bar_intBase_movSweepAll.svg'],'svg');

%%
%similarity matrix across movements using correlation
dPCA_all = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesReorder', [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );

nCon = size(dPCA_all.featureAverages,2);
cWindow = 60:100;

movTypeText = {'Nothing','Head','Face','LArm','RArm','LLeg','RLeg'};
codeSets = {1,2:5,6:9,10:14,15:19,20:24,25:29};
simMatrix = plotCorrMat_cv( dPCA_all.featureVals(:,:,:,1:20), cWindow, {'Nothing',movLabels{:}}, codeSets, [] );

%%
%PCA-subtraction
timeWindow = [-1500,3000];
movWindow = [20, 60];
%trShuff = trlCodesReorder(randperm(length(trlCodesReorder)));

baselineTrls = triggeredAvg(snippetMatrix, eventIdx(trlCodesReorder==1), movWindow);
[ cVar_dpca, rawProjPoints_dpca ] = modulationMagnitude_mpca( trlCodesReorder', smoothSnippetMatrix, snippetMatrix, eventIdx, baselineTrls, movWindow, ...
    binMS, codeSets );
singleTrialBarPlot( codeSets, rawProjPoints_dpca, cVar_dpca, movLabelsReorder(2:end) );
saveas(gcf,[outDir filesep 'bar_marg_movSweepAll.png'],'png');
saveas(gcf,[outDir filesep 'bar_marg_movSweepAll.svg'],'svg');

mnMod = zeros(length(codeSets),2);
for c=1:length(codeSets)
    mnMod(c,1) = mean(cVar_marg(codeSets{c},1));
end
disp(mnMod./mnMod(3,:));

save([outDir filesep 'barData_movSweepAll_pcaSub'],'cVar_marg','rawProjPoints_marg', 'scatterPoints', 'mnMod');

%%
%neural PCA
figure('Position',[680   474   925   624]);
for setIdx=1:length(codeSets)
    subplot(2,3,setIdx);
    hold on;

    allTrls = [];
    cLabel = [];
    for c=1:length(codeSets{setIdx})
        newTrls = triggeredAvg(snippetMatrix, eventIdx(trlCodesReorder==codeSets{setIdx}(c)), movWindow);
        allTrls = [allTrls; squeeze(mean(newTrls,2))];
        cLabel = [cLabel; repmat(c,30,1)];
    end

    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allTrls);

    colors = lines(length(codeSets{setIdx}));
    for c=1:length(codeSets{setIdx})
        plotIdx = find(cLabel==c);
        plot(SCORE(plotIdx,3), SCORE(plotIdx,4), 'o', 'Color', colors(c,:), 'MarkerFaceColor', colors(c,:));
    end

    legend(movLabelsReorder(codeSets{setIdx}));

    axis equal;
end
    
%%
rbIdx = {[1:3],[7:9],[13:15]};
rbIdx_all = {[1:6],[7:12],[13:18]};
for r=1:length(rbIdx)
    velFeat = diff(rigidBodies(:,rbIdx_all{r}))*100*100;
    %trShuff = trlCodesReorder(randperm(length(trlCodesReorder)));
    
    baselineTrls = triggeredAvg(velFeat, eventIdx(trlCodesReorder==1), movWindow);
    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_marg( trlCodesReorder', velFeat, eventIdx, baselineTrls, movWindow, ...
        binMS, timeWindow, codeSets, 'subtractMean' );
    singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, movLabelsReorder(2:end), false );
    
    %PCA plot
    tmp = rigidBodies(:,rbIdx_all{r});
    tmp(tmp<-2.9) = pi+(tmp(tmp<-2.9)+pi);
    
    velFeat = diff(tmp)*100*100;
    figure('Position',[680   474   925   624]);
    for setIdx=1:length(codeSetsWithNothing)
        subplot(2,3,setIdx);
        hold on;

        allTrls = [];
        cLabel = [];
        for c=1:length(codeSetsWithNothing{setIdx})
            newTrls = triggeredAvg(velFeat, eventIdx(trlCodesReorder==codeSetsWithNothing{setIdx}(c)), movWindow);
            allTrls = [allTrls; squeeze(mean(newTrls,2))];
            cLabel = [cLabel; repmat(c,size(newTrls,1),1)];
        end
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allTrls);
        
        colors = lines(length(codeSetsWithNothing{setIdx}));
        for c=1:length(codeSetsWithNothing{setIdx})
            plotIdx = find(cLabel==c);
            plot(SCORE(plotIdx,1), SCORE(plotIdx,2), 'o', 'Color', colors(c,:), 'MarkerFaceColor', colors(c,:));
        end
        
        legend(movLabelsReorder(codeSetsWithNothing{setIdx}));
        
        axis equal;
    end
    
end

%%
%multi-dims
axHandles = [];
yLims = [];
nAx = 3;

margGroupings = {{1, [1 2]},{2}};
margNames = {'Condition','Time'};
%margGroupings = {{1,2,[1 2]}};
%margNames = {'All'};
opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 3;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'pcaAxes';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

tw =  timeWindow/binMS;
tw(1) = tw(1) + 1;
tw(2) = tw(2) - 1;
timeAxis = (tw(1):tw(2))/100;
    
mPCA_out = cell(length(movTypeText),3);
for effIdx=1:3
    for pIdx=1:length(movTypeText)
        velFeat = diff(rigidBodies(:,rbIdx_all{effIdx}))*100*100;
        velFeat = [velFeat, matVecMag(velFeat,2)];
        velFeat = zscore(velFeat);
        
        trlIdx = find(ismember(trlCodesReorder, codeSets{pIdx}));
        mc = trlCodesReorder(trlIdx)';
        [~,~,mc] = unique(mc);
        
        mPCA_out{pIdx,effIdx} = apply_mPCA_general( velFeat, eventIdx(trlIdx), ...
            mc, tw, binMS/1000, opts_m );
        
        close all;
    end
end

for margIdx=1:2
    effNames = {'Head','LeftWrist','RightWrist'};
    for effIdx=1:3
        axHandles = [];
        yLims = [];
        figure('Position',[71         226        1364         702]);
        for pIdx=1:length(movTypeText)
            for axIdx=1:nAx
                ax = subtightplot(nAx,length(movTypeText),length(movTypeText)*(axIdx-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
                axHandles = [axHandles; ax];
                hold on

                cdIdx = find(mPCA_out{pIdx,effIdx}.whichMarg==margIdx);
                
                colors = jet(size(mPCA_out{pIdx,effIdx}.Z,2))*0.8;
                lineHandles = zeros(size(mPCA_out{pIdx,effIdx}.Z,2),1);
                for conIdx=1:size(mPCA_out{pIdx,effIdx}.Z,2)
                    lineHandles(conIdx) = plot(timeAxis, squeeze(mPCA_out{pIdx,effIdx}.Z(cdIdx(axIdx),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                    errorPatch( timeAxis', squeeze(mPCA_out{pIdx,effIdx}.margResample.CIs(cdIdx(axIdx),conIdx,:,:)), colors(conIdx,:), 0.2 );
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

    %         subtightplot(4,length(movTypeText),length(movTypeText)*(4-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
    %         hold on;
    %         lineHandles = zeros(size(mPCA_out{pIdx,effIdx}.Z,2),1);
    %         for conIdx=1:size(mPCA_out{pIdx,effIdx}.Z,2)
    %             lineHandles(conIdx) = plot(0,0,'LineWidth',2,'Color',colors(conIdx,:));
    %         end
    % 
    %         lHandle = legend(lineHandles, movLabelsReorder(codeSets{pIdx}),'Location','South','box','off','FontSize',10);
    %         lPos = get(lHandle,'Position');
    %         lPos(1) = lPos(1)+0.05;
    %         set(lHandle,'Position',lPos);
    %         axis off
        end

        finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
        for p=1:length(axHandles)
            set(axHandles(p), 'YLim', finalLimits);
            plot(axHandles(p),[0, 0],finalLimits*0.9,'--k','LineWidth',2);
            plot(axHandles(p),[1.5, 1.5],finalLimits*0.9,'--k','LineWidth',2);
        end

        set(gcf,'Renderer','painters');
        saveas(gcf,[outDir filesep 'mPCA_exampleDims_' effNames{effIdx} '_' margNames{margIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'mPCA_exampleDims_' effNames{effIdx} '_' margNames{margIdx} '.svg'],'svg');
    end
end

%%
%linear classifier
for effIdx=1:3
    figure('Position',[        212         475        1285         616]);
    for setIdx=1:length(codeSets)
        rigidBodyVel = diff(rigidBodies(:,rbIdx_all{effIdx}))*100*100;

        dataIdxStart = 20:60;
        nDecodeBins = 1;

        trlIdx = find(ismember(trlCodesReorder, codeSets{setIdx}));
        mc = trlCodesReorder(trlIdx)';
        [~,~,mc] = unique(mc);
        
        allFeatures = [];
        allCodes = mc;
        eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
        for t=1:length(mc)
            tmp = [];
            dataIdx = dataIdxStart;
            for binIdx=1:nDecodeBins
                loopIdx = dataIdx + eventIdx(trlIdx(t));
                tmp = [tmp, mean(rigidBodyVel(loopIdx,:))];
                dataIdx = dataIdx + length(dataIdx);
            end

            allFeatures = [allFeatures; tmp];
        end

        obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);
        predLabels = kfoldPredict(cvmodel);

        C = confusionmat(allCodes, predLabels);
        C_counts = C;
        for rowIdx=1:size(C,1)
            C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
        end

        for r=1:size(C_counts,1)
            [PHAT, PCI] = binofit(C_counts(r,r),sum(C_counts(r,:)),0.01); 
            disp(PCI);
        end

        colors = lines(6);

        ml = movLabels(codeSets{setIdx}-1);
        
        subplot(2,3,setIdx);
        hold on;
        imagesc(C,[0 1]);
        set(gca,'XTick',1:length(ml),'XTickLabel',ml,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(ml),'YTickLabel',ml);
        set(gca,'FontSize',16);
        set(gca,'LineWidth',2);
        colorbar;
        title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
        axis tight
    end
    saveas(gcf,[outDir filesep 'linearClassifier_' effNames{effIdx} '.png'],'png');
    saveas(gcf,[outDir filesep 'linearClassifier_' effNames{effIdx} '.svg'],'svg');
    saveas(gcf,[outDir filesep 'linearClassifier_' effNames{effIdx} '.pdf'],'pdf');
end

%%
for effIdx=1:3
    figure('Position',[212   524   808   567]);
    for setIdx=1:length(codeSets)
        rigidBodyVel = diff(rigidBodies(:,rbIdx_all{effIdx}))*100*100;

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
                tmp = [tmp, mean(rigidBodyVel(loopIdx,:))];
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

        colors = lines(6);

        subplot(2,3,setIdx);
        hold on;
        imagesc(C);
        set(gca,'XTick',1:length(movLabels),'XTickLabel',movLabels(reorderIdx),'XTickLabelRotation',45);
        set(gca,'YTick',1:length(movLabels),'YTickLabel',movLabels(reorderIdx));
        set(gca,'FontSize',16);
        set(gca,'LineWidth',2);
        colorbar;
        title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);

        codeSets = {2:5,6:9,10:14,15:19,20:24,25:29};
        currentIdx = 1;
        currentColor = 1;
        for c=1:length(codeSets)
            newIdx = currentIdx + (1:length(codeSets{c}))';
            rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(currentColor,:));
            currentIdx = currentIdx + length(codeSets{c});
            currentColor = currentColor + 1;
        end
        axis tight;

        saveas(gcf,[outDir filesep 'linearClassifier_' effNames{effIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'linearClassifier_' effNames{effIdx} '.svg'],'svg');
        saveas(gcf,[outDir filesep 'linearClassifier_' effNames{effIdx} '.pdf'],'pdf');
    end
end

%%
%single channel tuning counting
movTypeText = {'Face','Head','Arm','Leg'};
codeSetsReduced = {[2 3 4 5 6 7 8 9 10 11 12],13:20,21:28,29:34};
movLabelsSets = movLabelsReorder(horzcat(codeSetsReduced{:}));

dPCA_for_FRAvg = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodesReorder, codeSetsReduced{pIdx}));
    dPCA_for_FRAvg{pIdx} = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
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

