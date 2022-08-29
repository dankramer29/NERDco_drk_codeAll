%%
movTypes = {[1 2 3 4 5 6 7 8 9 10],'armAndLeg'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

excludeChannels = [];
sessionName = 't5.2018.12.05';
folderName = 'Fig2';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1200 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep folderName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, blockList );

trlCodes = zeros(size(R));
for t=1:length(trlCodes)
    trlCodes(t) = R(t).startTrialParams.currentMovement;
end

alignField = 'goCue';

allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
meanRate = mean(allSpikes)*1000;
tooLow = meanRate < 1.0;

allSpikes(:,tooLow) = [];

%cxChan = [3, 53, 86, 92, 93, 94];
%allSpikes(:,cxChan) = [];
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
    
    %baselineIdx = (alignEvents(t,2)-200):(alignEvents(t,2)+200);
    baselineIdx = (alignEvents(t,2)+0):(alignEvents(t,2)+400);
    baselineIdx(baselineIdx<1) = [];
    baselineMatrix(t,:) = mean(allSpikes(baselineIdx,:)*binMS);
end

%%
bNumPerTrial = [R.blockNum];
for b=1:length(blockList)
    disp(b);
    blockTrl = find(bNumPerTrial==blockList(b));
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (alignEvents(blockTrl(t),2)):(alignEvents(blockTrl(t),2)+200)];
    end
    
    binIdx = find(blockRows==blockList(b));
    baselineMatrix(blockTrl,:) = baselineMatrix(blockTrl,:) - mean(snippetMatrix(binIdx,:));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(binIdx,:)));
end
rawSnippetMatrix = snippetMatrix;

baselineMatrix = bsxfun(@times, baselineMatrix, 1./std(snippetMatrix));
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix, 3);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);

%%
clear R allSpikes
pack;

%%
%single trial projection bars
timeWindow = [-1000 3000];
movWindow = [20, 60];

codeSets = {
    [131 132 134 136 138 139 177 178],...
    [122 123 125 127 129 130 175 176],...
    [148 149 150 152 154 155],...
    [140 141 142 144 146 147],...
    };

movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'};

baselineTrls = triggeredAvg(snippetMatrix, eventIdx(trlCodes==218), movWindow);

[ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_marg( trlCodes', smoothSnippetMatrix, eventIdx, baselineTrls, movWindow, ...
    binMS, timeWindow, codeSets, 'none' );
singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, movLabels );

saveas(gcf,[outDir filesep 'bar_raw.png'],'png');
saveas(gcf,[outDir filesep 'bar_raw.svg'],'svg');

mnMod = zeros(length(codeSets),1);
for c=1:length(codeSets)
    mnMod(c,1) = mean(cVar_marg(codeSets{c},1));
end
disp(mnMod(2)/mnMod(1));
disp(mnMod(4)/mnMod(3));

%%
%measurements from: Keep your hands apart: independent representations of ipsilateral and
%contralateral forelimbs in primary motor cortex
%*Ethan A Heming, *Kevin P Cross, Tomohiko Takei, Douglas J Cook, Stephen H Scott 
%(Figure 7)

%0 is top of figure
ipsiY_P = [32, 188, 72.75, 162];
contraY_P = [32, 188, 62.5, 166.25];
alignment_P = [32, 188, 159.33, 156.66];

ipsiY_M = [266, 422, 319, 395];
contraY_M = [266, 422, 327, 391];
alignment_M = [266, 422, 379, 374];

allDat = {ipsiY_P, contraY_P, alignment_P, ipsiY_M, contraY_M, alignment_M};
procDat = cell(size(allDat));
for x=1:length(allDat)
    yAx = allDat{x}(2)-allDat{x}(1);
    procDat{x} = [(allDat{x}(2)-allDat{x}(3))/yAx, (allDat{x}(2)-allDat{x}(4))/yAx];
end

%%
%variance explained
mPCA_out = cell(length(codeSets),1);
for setIdx=1:length(codeSets)
    margGroupings = {{1, [1 2]}, {2}};
    margNames = {'Movement','Time'};

    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 5;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'pcaAxes';
    opts_m.alignMode = 'rotation';
    opts_m.plotCI = true;

    trlIdx = find(ismember(trlCodes, codeSets{setIdx}));
    remapCodes = trlCodes(trlIdx);
    [~,~,remapCodes] = unique(remapCodes);
    
    mPCA_out{setIdx} = apply_mPCA_general( gaussSmooth_fast(snippetMatrix, 2), eventIdx(trlIdx), ...
        remapCodes, [20,100], 0.01, opts_m);
    close all;
end

varExpl = zeros(length(codeSets), length(codeSets), 10);
for setIdxOuter = 1:length(codeSets)
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(mPCA_out{setIdxOuter}.Xmargs{1}');
    
    for setIdxInner = 1:length(codeSets)
        topTen = COEFF(:,1:10);
        totalVar = sum(mPCA_out{setIdxInner}.Xmargs{1}(:).^2);
        
        for nDim = 1:10
            recon = (mPCA_out{setIdxInner}.Xmargs{1}'*topTen(:,1:nDim))*topTen(:,1:nDim)';
            reconVar = sum(recon(:).^2);
            
            varExpl(setIdxOuter, setIdxInner, nDim) = reconVar/totalVar;
        end
    end
end

%%
crossPairs = {[1 2],[3 4]};

for pairIdx=1:length(crossPairs)
    cp = crossPairs{pairIdx};
    
    cMat_contra = corr(mPCA_out{cp(1)}.Xmargs{1}', mPCA_out{cp(1)}.Xmargs{1}');
    cMat_ipsi = corr(mPCA_out{cp(2)}.Xmargs{1}', mPCA_out{cp(2)}.Xmargs{1}');
    
    P_contra = symamd(cMat_contra>0.4);
    P_ipsi = symamd(cMat_ipsi>0.4);
    
    cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
    
    figure;
    subplot(2,2,1);
    imagesc(cMat_contra(P_contra,P_contra),[-0.5 0.5]);
    colormap(cMap);
    
    subplot(2,2,2);
    imagesc(cMat_ipsi(P_contra,P_contra),[-0.5 0.5]);
    colormap(cMap);
    
    subplot(2,2,3);
    imagesc(cMat_contra(P_ipsi,P_ipsi),[-0.5 0.5]);
    colormap(cMap);
    
    subplot(2,2,4);
    imagesc(cMat_ipsi(P_ipsi,P_ipsi),[-0.5 0.5]);
    colormap(cMap);
    
    cMat_contra_unroll = cMat_contra(:);
    cMat_ipsi_unroll = cMat_ipsi(:);

    diagIdx = cMat_contra_unroll>0.99999;
    cMat_contra_unroll(diagIdx)=[];
    cMat_ipsi_unroll(diagIdx)=[];
end

figure;
subplot(1,2,pairIdx);
plot(cMat_contra_unroll, cMat_ipsi_unroll, 'k.');
xlim([-1,1]);
ylim([-1,1]);
axis equal;
set(gca,'LineWidth',2,'FontSize',16);

figure;
imagesc(cMat_contra(P,P),[-0.5 0.5]);
cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
colormap(cMap);
%%
setNames = {'Contra. Arm','Ipsi. Arm','Contra. Leg','Ipsi. Leg'};
colors = lines(4);

figure('Position',[680         870        1135         228]);
for setIdx = 1:length(codeSets)
    subplot(1,4,setIdx);
    hold on;
    
    lHandles = zeros(4,1);
    for innerSetIdx=1:length(codeSets)
        lHandles(innerSetIdx)=plot(100*squeeze(varExpl(setIdx,innerSetIdx,:))','-o','LineWidth',2);
    end
    
    if setIdx==1
        legend(lHandles,setNames{:},'AutoUpdate','off');
    end
    title([setNames{setIdx} ' Space']);
    
    set(gca,'FontSize',16);
    set(gca,'LineWidth',2);
    xlabel('# Components');
    ylabel('% Variance Explained');
end

saveas(gcf,[outDir filesep 'setFVAF.png'],'png');
saveas(gcf,[outDir filesep 'setFVAF.svg'],'svg');

figure('Position',[97         731        1135         290]);
for setIdx = 1:length(codeSets)
    subplot(1,4,setIdx);
    hold on;
    
    alignScores = zeros(length(codeSets),1);
    for innerSetIdx=1:length(codeSets)
        alignScores(innerSetIdx) = varExpl(setIdx,innerSetIdx,10)/varExpl(innerSetIdx,innerSetIdx,10);
    end

    if setIdx==1
        alignScores = [alignScores; procDat{3}(1); procDat{6}(1)];
        xLabels = [setNames, {'Ipsi. Arm Monk P','Ipsi. Arm Monk M'}];
    elseif setIdx==2
        alignScores = [alignScores; procDat{3}(2); procDat{6}(2)];
        xLabels = [setNames, {'Ipsi. Arm Monk P','Ipsi. Arm Monk M'}];
    else
        xLabels = setNames;
    end
    
    alignScores(setIdx) = [];
    xLabels(setIdx) = [];
    
    bar(alignScores,'LineWidth',2,'FaceColor','w');
    title([setNames{setIdx} ' Space']);
    
    set(gca,'FontSize',16);
    set(gca,'XTick',1:length(xLabels),'XTickLabel',xLabels,'XTickLabelRotation',45);
    ylabel('Alignment');
    set(gca,'LineWidth',2);
    xlim([0,6]);
    ylim([0 0.7]);
end

saveas(gcf,[outDir filesep 'setAlignment.png'],'png');
saveas(gcf,[outDir filesep 'setAlignment.svg'],'svg');

%%
%average firing rate change from baseline
%bar plot
colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;
jitterWidth = 0.0;

figure('Position',[164   798   231   291]);
hold on;
for effIdx=1:4
    lightColor = colors(effIdx,:)*0.7 + ones(1,3)*0.3;
    darkColor = colors(effIdx,:)*0.7 + zeros(1,3)*0.3;
    
    dataPoints = cVar_marg(codeSets{effIdx},5);
    bar(effIdx, mean(dataPoints), 'FaceColor', colors(effIdx,:), 'LineWidth', 1);
        
    jitterX = rand(length(dataPoints),1)*jitterWidth-jitterWidth/2;
    plot(effIdx+jitterX, dataPoints, 'o', 'Color', 'k', 'LineWidth', 1);
    
    %[mn,~,CI] = normfit(dataPoints);
    %errorbar(effIdx, mn, mn-CI(1), CI(2)-mn, '.k','LineWidth',2);
end

for m=1:length(codeSets{3})
    plot([3 4], [cVar_marg(codeSets{3},5), cVar_marg(codeSets{4},5)], 'k-')
end

for m=1:length(codeSets{1})
    plot([1 2], [cVar_marg(codeSets{1},5), cVar_marg(codeSets{2},5)], 'k-')
end

set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);

axis tight;
xlim([0.5, 4+0.5]);
ylabel('\Delta Firing Rate (SD)','FontSize',22);
set(gca,'TickLength',[0 0]);
set(gca,'XTick',1:4,'XTickLabel',{'Contra. Arm','Ipsi. Arm','Contra. Leg',' Ipsi. Leg'},'XTickLabelRotation',45);

saveas(gcf,[outDir filesep 'bar_signedFR.png'],'png');
saveas(gcf,[outDir filesep 'bar_signedFR.svg'],'svg');

[h,p]=ttest(cVar_marg(codeSets{1},5)-cVar_marg(codeSets{2},5))
[h,p]=ttest(cVar_marg(codeSets{3},5)-cVar_marg(codeSets{4},5))

%%
%2-factor dPCA
%see movementTypes.m for code definitions
legendSets = {{'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise'},...
    {'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'},...
    {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise','AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'}};
movSets_2Fac = {[122 123 125 127 129 130 175 176],[131 132 134 136 138 139 177 178]
    [140 141 142 144 146 147],[148 149 150 152 154 155],
    [122 123 125 127 129 130 175 176],[131 132 134 136 138 139 177 178]};
    
timeWindow = [-1200, 3000];
dPCA_out = cell(size(movSets_2Fac,1),1);
dPCA_out_xval = cell(size(movSets_2Fac,1),1);
codes = cell(size(movSets_2Fac,1),2);
plotNames = {'arm_example','leg_all','arm_all'};
movCodesToPlot = {[2 3 4 6],[1:6],[1:8]};
allCrossValues_cell = cell(length(plotNames),1);

for pIdx = 1:length(plotNames)
    trlIdx = find(ismember(trlCodes, horzcat(movSets_2Fac{pIdx,:})));
    
    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));

    newCodes = zeros(length(trlIdx),2);
    for t=1:length(trlIdx)
        [a1,a3] = ismember(trlCodes(trlIdx(t)), movSets_2Fac{pIdx,1});
        [b1,b3] = ismember(trlCodes(trlIdx(t)), movSets_2Fac{pIdx,2});
        if a1==1
            newCodes(t,2) = 1;
            newCodes(t,1) = a3;
        else
            newCodes(t,2) = 2;
            newCodes(t,1) = b3;
        end
    end

    margGroupings = {{1, [1 3], [1 2], [1 2 3]}, {2, [2 3]}, {3}};
    margNames = {'Movement','Laterality','Time'};
    timeWindowMov = [-1200 3000];
    
    cutTrl = find(ismember(newCodes(:,1), movCodesToPlot{pIdx}));
    allCodes = unique(newCodes(cutTrl,:),'rows');
    
    newCodes_relabel = newCodes(cutTrl,:);
    [~,~,newCodes_relabel(:,1)] = unique(newCodes_relabel(:,1));
        
    %%    
    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
        newCodes(cutTrl,:), timeWindowMov/binMS, binMS/1000, margNames, [5 5 5], 'none', 'standard_dpca', margGroupings, true );
    close(gcf);
    
    dPCA_out_xval{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
        newCodes(cutTrl,:), timeWindowMov/binMS, binMS/1000, margNames, [5 5 5], 'xval', 'standard_dpca', margGroupings, true );
    close(gcf);
    
    movIdx = find(dPCA_out_xval{pIdx}.whichMarg==1);
    movIdx = movIdx(1:end);
    movMod = squeeze(mean(dPCA_out_xval{pIdx}.Z(movIdx,:,:,150:200),4));
    
    colors = jet(size(movMod,2))*0.8;
    
    figure('Position',[680   885   302   213]);
    hold on
    for movCon=1:size(movMod,2)
        plot(movMod(1,movCon,1), movMod(2,movCon,1), 'o','Color',colors(movCon,:),'MarkerFaceColor',colors(movCon,:));
        plot([0,movMod(1,movCon,1)], [0,movMod(2,movCon,1)], '--','Color',colors(movCon,:), 'LineWidth',2);
        
        plot(movMod(1,movCon,2), movMod(2,movCon,2), 'o','Color',colors(movCon,:),'MarkerFaceColor',colors(movCon,:),'MarkerSize',12);
        plot([0,movMod(1,movCon,2)], [0,movMod(2,movCon,2)], '-','Color',colors(movCon,:), 'LineWidth', 2);
    end
    axis equal;
    set(gca,'LineWidth',2,'FontSize',16);
    xlabel('dPC_1 (Movement)');
    ylabel('dPC_2 (Movement)');
    saveas(gcf,[outDir filesep 'dPCA_dot_plane_' plotNames{pIdx} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_dot_plane_' plotNames{pIdx} '.svg'],'svg');
    
    figure('Position',[680   885   302   213]);
    hold on
    for movCon=1:size(movMod,2)
        mTraj = squeeze(dPCA_out_xval{pIdx}.Z(movIdx(1:2),:,:,120:200));
        
        plot(squeeze(mTraj(1,movCon,1,:)), squeeze(mTraj(2,movCon,1,:)), ':','Color',colors(movCon,:),'LineWidth',2);
        %plot(squeeze(mTraj(1,movCon,1,1)), squeeze(mTraj(2,movCon,1,1)), 'o','Color',colors(movCon,:),'MarkerFaceColor',colors(movCon,:),'MarkerSize',6);
        %plot(squeeze(mTraj(1,movCon,1,end)), squeeze(mTraj(2,movCon,1,end)), 'x','Color',colors(movCon,:),'LineWidth',2,'MarkerSize',6);
        
        plot(squeeze(mTraj(1,movCon,2,:)), squeeze(mTraj(2,movCon,2,:)), '-','Color',colors(movCon,:),'LineWidth',2);
        %plot(squeeze(mTraj(1,movCon,2,1)), squeeze(mTraj(2,movCon,2,1)), 'o','Color',colors(movCon,:),'LineWidth',2);
        %plot(squeeze(mTraj(1,movCon,2,end)), squeeze(mTraj(2,movCon,2,end)), 'x','Color',colors(movCon,:),'LineWidth',2);
    end
    axis equal;
    set(gca,'LineWidth',2,'FontSize',16);
    xlabel('dPC_1 (Movement)');
    ylabel('dPC_2 (Movement)');
    saveas(gcf,[outDir filesep 'dPCA_traj_plane_' plotNames{pIdx} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_traj_plane_' plotNames{pIdx} '.svg'],'svg');

    colors = jet(size(movMod,2))*0.8;
    lineArgs_2fac = cell(size(movMod,2), 2);
    for x=1:length(lineArgs_2fac)
        lineArgs_2fac{x,1} = {'Color',colors(x,:),'LineStyle',':','LineWidth',2};
        lineArgs_2fac{x,2} = {'Color',colors(x,:),'LineStyle','-','LineWidth',2};
    end
    timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
        
    layoutInfo.nPerMarg = 3;
    layoutInfo.fPos = [136   510   867   552];
    layoutInfo.gap = [0.03 0.01];
    layoutInfo.marg_h = [0.07 0.02];
    layoutInfo.marg_w = [0.15 0.07];
    layoutInfo.colorFactor = 1;
    layoutInfo.textLoc = [0.025, 0.85];
    layoutInfo.plotLayout = 'horizontal';
    layoutInfo.verticalBars = [0];
    plotTitles = {'Movement','Laterality','Timing'};
    
    [yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot_pretty_2( dPCA_out_xval{pIdx}.cval, timeAxis, lineArgs_2fac, ...
        plotTitles, 'sameAxesGlobal', [], [-2.5, 4], dPCA_out_xval{pIdx}.cval.dimCI, colors, layoutInfo );
    for x=1:length(allHandles)
        for y=1:length(allHandles{x})
            plot(allHandles{x}(y), [1.5 1.5], get(allHandles{x}(y),'YLim'), '--k','LineWidth',2);
            set(gcf,'Renderer','painters');
            set(allHandles{x}(y),'FontSize',18,'XLim',[-1,2.5]);
            if x==2 && y==1
                axes(allHandles{x}(y));
                text(0.3,0.9,'Go','Units','Normalized','FontSize',16);
                text(0.73,0.9,'Return','Units','Normalized','FontSize',16);
            end
            if x==1
                axes(allHandles{x}(y));
                ylabel(['Dimension ' num2str(y) ' (SD)'],'FontSize',16);
            end
        end
    end
    
    set(gcf,'Position',[37   438   674   558]);
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '.svg'],'svg');
    
    componentVarPlot( dPCA_out_xval{pIdx}, plotTitles, 9 );
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_componentVar.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_componentVar.svg'],'svg');
    
    componentAnglePlot( dPCA_out_xval{pIdx}, 9 );
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_componentAngle.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_componentAngle.svg'],'svg');
    
    figure('Position',[262   877   237   209]);
    hold on;
    for c=1:size(colors,1)
        plot([0,0],[1,1],'Color',colors(c,:),'LineWidth',2);
    end
    axis off;
    legend(legendSets{pIdx}(movCodesToPlot{pIdx}),'box','off');
    set(gca,'FontSize',16);
    
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_legend.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_legend.svg'],'svg');
    
    close all;
    
    %%
    %laterality component
    latDim = find(dPCA_out{pIdx}.whichMarg==2);
    coef = dPCA_out{pIdx}.V(:,latDim(1));
    
    figure('Position',[680   872   295   226]);
    hold on;
    hist(coef,20);
    plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
    plot([mean(coef), mean(coef)],get(gca,'YLim'),'-r','LineWidth',2);
    xlabel('Laterality Component Coefficients');
    ylabel('Count');
    xlim([-0.4,0.4]);
    set(gca,'FontSize',16,'LineWidth',2)
    
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_latDimCoeff.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_latDimCoeff.svg'],'svg');
    
    %%
    %PSTH
    lineArgs_psth = cell(16,1);
    colors = jet(8)*0.8;
    for m=1:8
        lineArgs_psth{m} = {'LineWidth',2,'Color',colors(m,:),'LineStyle',':'};
        lineArgs_psth{m+8} = {'LineWidth',2,'Color',colors(m,:),'LineStyle','-'};
    end
    
    psthOpts = makePSTHOpts();
    psthOpts.timeStep = binMS/1000;
    psthOpts.gaussSmoothWidth = 0;
    psthOpts.neuralData = {smoothSnippetMatrix};
    psthOpts.timeWindow = timeWindow/binMS;
    psthOpts.trialEvents = eventIdx(trlIdx);
    psthOpts.trialConditions = newCodes(:,1) + (newCodes(:,2)-1)*8;
    psthOpts.conditionGrouping = {1:16};
    psthOpts.lineArgs = lineArgs_psth;

    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = outDir;

    featLabels = cell(size(smoothSnippetMatrix,2),1);
    usedIdx = find(~tooLow);
    for f=1:size(smoothSnippetMatrix,2)
        featLabels{f} = [num2str(usedIdx(f))];
    end
    psthOpts.featLabels = featLabels;

    psthOpts.prefix = 'TX';
    psthOpts.plotCI = 1;
    psthOpts.CIColors = [colors; colors];
    out = makePSTH_simple(psthOpts);

end    

save([outDir filesep 'dPCA_laterality'],'dPCA_out','allCrossValues_cell','dPCA_out_xval');

%%
%single channel tuning counting
movTypeText = {'ArmContra','ArmIpsi','LegContra','LegIpsi'};
codeSetsReduced = {[122 123 125 127 129 130 175 176],[131 132 134 136 138 139 177 178],[140 141 142 144 146 147],[148 149 150 152 154 155]};
    
dPCA_for_FRAvg = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodes, codeSetsReduced{pIdx}));
    dPCA_for_FRAvg{pIdx} = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
        trlCodes(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 20);
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
%single channel correlation, BINNED
setPairs = {[1 2],[3 4]};
nUnits = size(dPCA_for_FRAvg{1}.featureAverages,1);
neuralCorr = zeros(nUnits,2);

timeOffset = -timeWindow(1)/binMS;
movWindow = (20:60);

for pairIdx=1:length(setPairs)
    pair = setPairs{pairIdx};
    for unitIdx=1:size(dPCA_for_FRAvg{pIdx}.featureAverages,1)
        unitAct_1 = squeeze(dPCA_for_FRAvg{pair(1)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        meanAct_1 = squeeze(nanmean(unitAct_1,2))';
        
        unitAct_2 = squeeze(dPCA_for_FRAvg{pair(2)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        meanAct_2 = squeeze(nanmean(unitAct_2,2))';
        
        neuralCorr(unitIdx, pairIdx) = corr(nanmean(meanAct_1)', nanmean(meanAct_2)');
    end
end

%shuffle distributions
nRep = 1000;
nEdges = 20;
edges = linspace(-1,1,nEdges);
shuffDist = zeros(nRep, nEdges-1, 2);

for pairIdx=1:length(setPairs)
    pair = setPairs{pairIdx};
    
    unitAct_1 = squeeze(dPCA_for_FRAvg{pair(1)}.featureVals(:,:,movWindow+timeOffset,:));
    meanAct_1 = squeeze(nanmean(nanmean(unitAct_1,3),4))';

    unitAct_2 = squeeze(dPCA_for_FRAvg{pair(2)}.featureVals(:,:,movWindow+timeOffset,:));
    meanAct_2 = squeeze(nanmean(nanmean(unitAct_2,3),4))';
    
    totalAct = [meanAct_1; meanAct_2];
    for n=1:nRep
        shuffleAct = totalAct;
        shuffleAct = shuffleAct(randperm(size(shuffleAct,1)),:);
        
        shuffCorr = diag(corr(shuffleAct(1:(end/2),:), shuffleAct(((end/2)+1):end,:)));  
        N = histc(shuffCorr,edges);
        shuffDist(n,:,pairIdx) = N(1:(end-1));
    end
end    
    
%true distributions
binCenters = edges(1:(end-1)) + (edges(2)-edges(1))/2;
plotTitles = {'Arm','Leg'};

figure('Position',[ 680   885   627   213]);
for x=1:2
    subplot(1,2,x);
    hold on;
    
    N = histc(neuralCorr(:,x),edges);
    bar(binCenters, N(1:(end-1)),'k' );
    
    mnShuff = mean(squeeze(shuffDist(:,:,x)),1);
    plot(binCenters, mnShuff, 'r','LineWidth',2);
    
    xlabel('Correlation');
    ylabel('# Electrodes');
    title(plotTitles{x});
    set(gca,'FontSize',16,'LineWidth',2);
end

saveas(gcf,[outDir filesep 'singleElectrodeCorr_bin.png'],'png');
saveas(gcf,[outDir filesep 'singleElectrodeCorr_bin.svg'],'svg');

%%
%single channel correlation, ACROSS TIME
dPCA_for_FRAvg = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodes, codeSetsReduced{pIdx}));
    dPCA_for_FRAvg{pIdx} = apply_dPCA_simple( gaussSmooth_fast(snippetMatrix, 2.5), eventIdx(trlIdx), ...
        trlCodes(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 20);
    close(gcf);
end

setPairs = {[1 2],[3 4]};
nUnits = size(dPCA_for_FRAvg{1}.featureAverages,1);
neuralCorr = zeros(nUnits,2);
neuralCorr_unbiased = zeros(nUnits,2);

timeOffset = -timeWindow(1)/binMS;
movWindow = (20:100);

for pairIdx=1:length(setPairs)
    pair = setPairs{pairIdx};
    for unitIdx=1:size(dPCA_for_FRAvg{pIdx}.featureAverages,1)
        unitAct_1 = squeeze(dPCA_for_FRAvg{pair(1)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        meanAct_1 = squeeze(nanmean(unitAct_1,3))';
        meanAct_1 = meanAct_1 - mean(meanAct_1,2);
        meanAct_1 = meanAct_1(:);
        
        unitAct_2 = squeeze(dPCA_for_FRAvg{pair(2)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        meanAct_2 = squeeze(nanmean(unitAct_2,3))';
        meanAct_2 = meanAct_2 - mean(meanAct_2,2);
        meanAct_2 = meanAct_2(:);
        
        neuralCorr(unitIdx, pairIdx) = corr(meanAct_1, meanAct_2);
        
        unitAct_1 = squeeze(dPCA_for_FRAvg{pair(1)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        unitAct_2 = squeeze(dPCA_for_FRAvg{pair(2)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        
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
        neuralCorr_unbiased(unitIdx, pairIdx) = (mn1-mean(mn1))*(mn2-mean(mn2))'/(unbiasedMag1*unbiasedMag2);
    end
end

%shuffle distributions
nRep = 100;
nEdges = 24;
edges = linspace(-1.2,1.2,nEdges);
shuffDist = zeros(nRep, nEdges-1, 2);
shuffDist_unbiased = zeros(nRep, nEdges-1, 2);

for pairIdx=1:length(setPairs)
    pair = setPairs{pairIdx};
    for n=1:nRep
        
        shuffCorr = zeros(nUnits,2);
        for unitIdx=1:size(dPCA_for_FRAvg{pIdx}.featureAverages,1)
            %biased
            unitAct_1 = squeeze(dPCA_for_FRAvg{pair(1)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
            meanAct_1 = squeeze(nanmean(unitAct_1,3))';

            unitAct_2 = squeeze(dPCA_for_FRAvg{pair(2)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
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
            unitAct_1 = squeeze(dPCA_for_FRAvg{pair(1)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
            unitAct_2 = squeeze(dPCA_for_FRAvg{pair(2)}.featureVals(unitIdx,:,movWindow+timeOffset,:));
            
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
        shuffDist(n,:,pairIdx) = N(1:(end-1));
        
        N = histc(shuffCorr(:,2),edges);
        shuffDist_unbiased(n,:,pairIdx) = N(1:(end-1));
    end
end    
    
%true distributions
sDist = {shuffDist, shuffDist_unbiased};
nc = {neuralCorr, neuralCorr_unbiased};
bNames = {'biased','unbiased'};

binCenters = edges(1:(end-1)) + (edges(2)-edges(1))/2;
plotTitles = {'Arm','Leg'};

for bIdx=1:length(sDist)
    figure('Position',[ 680   885   627   213]);
    for x=1:2
        subplot(1,2,x);
        hold on;

        N = histc(nc{bIdx}(:,x),edges);
        bar(binCenters, N(1:(end-1)),'k' );
        
        mnShuff = mean(squeeze(sDist{bIdx}(:,:,x)),1);
        plot(binCenters, mnShuff, 'r','LineWidth',2);
        
        set(gca,'YLim',[0 22]);
        mn = median(nc{bIdx}(:,x));
        plot([mn, mn], get(gca,'YLim'),'-','LineWidth',2,'Color',[0 0.8 1.0]);

        xlabel('Correlation');
        ylabel('# Electrodes');
        title(plotTitles{x});
        set(gca,'FontSize',16,'LineWidth',2);
        axis tight;
    end

    saveas(gcf,[outDir filesep 'singleElectrodeCorr_timeSeries_' bNames{bIdx} '.png'],'png');
    saveas(gcf,[outDir filesep 'singleElectrodeCorr_timeSeries_' bNames{bIdx} '.svg'],'svg');
end

disp(mean(neuralCorr>0.75));

disp(median(neuralCorr));
disp(median(neuralCorr_unbiased));

disp(median(neuralCorr));
disp(median(neuralCorr_unbiased));

signtest(neuralCorr(:,1))
signtest(neuralCorr(:,2))

signtest(neuralCorr_unbiased(:,1))
signtest(neuralCorr_unbiased(:,2))

%%
%linear classifier
%see movementTypes.m for code definitions
movLabels = {'Nothing',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','RaiseIndex','RaiseThumb',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','RaiseIndex','RaiseThumb',...
    'AnkleUp','AnkleDown','KneeExt','LegRaise','ToeCurl','ToeOpen',...
    'AnkleUp','AnkleDown','KneeExt','LegRaise','ToeCurl','ToeOpen'};
reorderIdx = [29, 7:12, 15:16, 1:6, 13:14, 23:28, 17:22];

colors = [100,168,96;
153,112,193;
185,141,62;
204,84,94]/255;

codes = cell(size(movTypes,1),2);
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
end 

remapTable = [];
currentIdx = 0;
for c=1:size(codes,1)
    newIdx = currentIdx + (1:length(codes{c,2}))';
    remapTable = [remapTable; [newIdx, codes{c,2}]];
    currentIdx = currentIdx + length(codes{c,2});
end

allFeatures = [];
allCodes = [];
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    trlIdx = find(trlIdx);

    newCodes = trlCodesRemap(trlIdx);
    newData = [];
    for n=1:length(newCodes)
        tmp = [];
        %dataIdx = 20:24;
        dataIdx = 20:60;
        for binIdx=1:1
            loopIdx = dataIdx + eventIdx(trlIdx(n));
            tmp = [tmp, mean(snippetMatrix(loopIdx,:),1)];
            dataIdx = dataIdx + length(dataIdx);
        end
        newData = [newData; tmp];
    end

    allFeatures = [allFeatures; newData];
    allCodes = [allCodes; newCodes];
end

allCodesRemap = zeros(size(allCodes));
for x=1:length(remapTable)
    replaceIdx = find(allCodes==remapTable(x,2));
    allCodesRemap(replaceIdx) = x;
end

obj = fitcdiscr(allFeatures,allCodesRemap,'DiscrimType','diaglinear');
cvmodel = crossval(obj);
L = kfoldLoss(cvmodel);
predLabels = kfoldPredict(cvmodel);

C = confusionmat(allCodesRemap, predLabels);
for rowIdx=1:size(C,1)
    C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
end
C = C(reorderIdx, reorderIdx);

figure('Position',[680   620   682   478]);
imagesc(C);
set(gca,'XTick',1:length(movLabels),'XTickLabel',movLabels,'XTickLabelRotation',45);
set(gca,'YTick',1:length(movLabels),'YTickLabel',movLabels);
set(gca,'FontSize',14);
colorbar;
title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);

idxSets = {2:9, 10:17, 18:23, 24:29}; 
for setIdx = 1:length(idxSets)
    newIdx = idxSets{setIdx};
    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
end
axis tight;
set(gca,'YDir','normal');

saveas(gcf,[outDir filesep 'linearClassifier_all.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier_all.svg'],'svg');

%%
%using neural activity without laterality & effector dimensions
timeWindow = [-1000 3000];
movWindow = [20, 60];

codeSets = {
    [131 132 134 136 138 139 177 178],...
    [122 123 125 127 129 130 175 176],...
    [148 149 150 152 154 155],...
    [140 141 142 144 146 147],...
    };

reorderIdx = [1:6, 25:26, 7:12, 27:28, 13:24];
movSets = {[122 123 125 127 129 130],[131 132 134 136 138 139]
    [140 141 142 144 146 147],[148 149 150 152 154 155]};
factorMap = [122 1 1 1;
    123 2 1 2;
    125 2 1 3;
    127 2 1 4;
    129 2 1 5;
    130 2 1 6;
    175 2 1 7;
    176 2 1 8;
    
    131 1 1 1;
    132 1 1 2;
    134 1 1 3;
    136 1 1 4;
    138 1 1 5;
    139 1 1 6;
    177 1 1 7;
    178 1 1 8;
    
    140 2 2 9;
    141 2 2 10;
    142 2 2 11;
    144 2 2 12;
    146 2 2 13;
    147 2 2 14;
    
    148 1 2 9;
    149 1 2 10;
    150 1 2 11;
    152 1 2 12;
    154 1 2 13;
    155 1 2 14;
    ];

newFactors = nan(length(trlCodes),3);
for t=1:length(trlCodes)
    tableIdx = find(trlCodes(t)==factorMap(:,1));
    if isempty(tableIdx)
        continue;
    end
    newFactors(t,:) = factorMap(tableIdx,2:end);
end

trlIdx = find(~isnan(newFactors(:,1)));

margGroupings = {{1, [1 4]}, ...
    {2, [2 4]}, ...
    {[1 2] ,[1 2 4]}, ...
    {4}, ...
    {3, [1 3], [2 3], [3 4], [1 3 4], [2 3 4], [1 2 3], [1 2 3 4]}};
margNames = {'Laterality','Effector','L x E','Time','Movement'};

opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 5;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

mPCA_out = apply_mPCA_general( smoothSnippetMatrix, eventIdx(trlIdx), ...
    newFactors(trlIdx,:), [-100,300], 0.010, opts_m);

movDimIdx = mPCA_out.whichMarg==5;
movDim = mPCA_out.readoutZ_unroll(:,movDimIdx);

allFeatures = [];
allCodes = [];
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    trlIdx = find(trlIdx);

    newCodes = trlCodesRemap(trlIdx);
    newData = [];
    for n=1:length(newCodes)
        tmp = [];
        %dataIdx = 20:24;
        dataIdx = 30:30;
        for binIdx=1:1
            loopIdx = dataIdx + eventIdx(trlIdx(n));
            tmp = [tmp, mean(movDim(loopIdx,:),1)];
            dataIdx = dataIdx + length(dataIdx);
        end
        newData = [newData; tmp];
    end

    allFeatures = [allFeatures; newData];
    allCodes = [allCodes; newCodes];
end

allCodesRemap = zeros(size(allCodes));
for x=1:length(remapTable)
    replaceIdx = find(allCodes==remapTable(x,2));
    allCodesRemap(replaceIdx) = x;
end

obj = fitcdiscr(allFeatures,allCodesRemap,'DiscrimType','diaglinear');
cvmodel = crossval(obj);
L = kfoldLoss(cvmodel);
predLabels = kfoldPredict(cvmodel);

C = confusionmat(allCodesRemap, predLabels);
for rowIdx=1:size(C,1)
    C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
end
C = C(reorderIdx, reorderIdx);

figure('Position',[680   620   682   478]);
imagesc(C);
set(gca,'XTick',1:length(movLabels),'XTickLabel',movLabels,'XTickLabelRotation',45);
set(gca,'YTick',1:length(movLabels),'YTickLabel',movLabels);
set(gca,'FontSize',14);
colorbar;
title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);

idxSets = {2:9, 10:17, 18:23, 24:29}; 
for setIdx = 1:length(idxSets)
    newIdx = idxSets{setIdx};
    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
end
axis tight;
set(gca,'YDir','normal');

%%
%sliding window
allAccuracy = zeros(length(idxSets), 25);
windowIdxStart = -20:20;

for codeSetIdx = 1:length(idxSets)
    disp(codeSetIdx);
    for wIdx = 1:length(windowIdxStart)
        allFeatures = [];
        for pIdx = 1:size(movTypes,1)
            trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
            trlIdx = find(trlIdx);

            newCodes = trlCodesRemap(trlIdx);
            newData = [];
            for n=1:length(newCodes)
                tmp = [];
                dataIdx = (windowIdxStart(wIdx)):(windowIdxStart(wIdx)+2);
                for binIdx=1:1
                    loopIdx = dataIdx + eventIdx(trlIdx(n));
                    tmp = [tmp, mean(snippetMatrix(loopIdx,:),1)];
                    dataIdx = dataIdx + length(dataIdx);
                end
                newData = [newData; tmp];
            end

            allFeatures = [allFeatures; newData];
        end

        trlIdx = find(ismember(allCodesRemap, idxSets{codeSetIdx}));
        obj = fitcdiscr(allFeatures(trlIdx,:),allCodesRemap(trlIdx),'DiscrimType','diaglinear');
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);
        
        allAccuracy(codeSetIdx, wIdx) = 1-L;
    end
end

figure
plot(allAccuracy','LineWidth',2);
legend({'Contra Arm','Ipsi Arm','Contra Leg','Ipsi Leg'});
