%%
%see movementTypes.m for code definitions
% movTypes = {[13 14 15 16],'armJoint'
%     [18 19 20 21],'leg'};
% blockList = horzcat(movTypes{:,1});
% blockList = sort(blockList);
% 
% excludeChannels = [];
% sessionName = 't5.2017.12.21';
% folderName = 'ipsi_vs_contra';

% movTypes = {[3 4 5 6 7],'armJoint'
%     [10 11 12 13 14],'leg'};
% blockList = horzcat(movTypes{:,1});
% blockList = sort(blockList);
% 
% excludeChannels = [];
% sessionName = 't5.2018.10.17';
% folderName = 'ipsi_vs_contra_dataset2';

movTypes = {[1 2 3 4 5 6 7 8 9 10],'armAndLeg'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

excludeChannels = [];
sessionName = 't5.2018.12.05';
folderName = 'ipsi_vs_contra_dataset3';

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
movWindow = (20:60);
baselineWindow = (-119:-80);

codeSets = {
    [131 132 134 136 138 139 177 178],...
    [122 123 125 127 129 130 175 176],...
    [148 149 150 152 154 155],...
    [140 141 142 144 146 147],...
    };

nothingTrl = find(ismember(trlCodes, 218));
nothingDat = triggeredAvg(snippetMatrix, eventIdx(nothingTrl), [-100, 300]);
useNothing = true;

[ cVar, cVar_proj, rawProjPoints, dPCA_out ] = modulationMagnitude( trlCodes', smoothSnippetMatrix, eventIdx, nothingDat, movWindow, ...
    baselineWindow, binMS, timeWindow, codeSets, 'nothing_control' );

movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'};
singleTrialBarPlot( codeSets, rawProjPoints, cVar_proj, movLabels );
saveas(gcf,[outDir filesep 'bar_dPCA_sp.png'],'png');
saveas(gcf,[outDir filesep 'bar_dPCA_sp.svg'],'svg');
saveas(gcf,[outDir filesep 'bar_dPCA_sp.pdf'],'pdf');

mnMod = zeros(length(codeSets),1);
for c=1:length(codeSets)
    mnMod(c) = mean(cVar_proj(codeSets{c},1));
end

save([outDir filesep 'barData_nothing'],'cVar','cVar_proj', 'dPCA_out','rawProjPoints');

%%
%similarity matrix across movements using correlation
dPCA_all = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesRemap, [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );

nCon = size(dPCA_all.featureAverages,2);
cWindow = 60:100;

simMatrix = zeros(nCon, nCon);
fa = dPCA_all.featureAverages(:,:,cWindow);
fa = fa(:,:)';
fa = mean(fa);

subractEffMean = true;
setIdx = {[1:6, 25:26], [7:12, 27:28], 13:18, 19:24, 29};
effMeans = zeros(length(fa), length(setIdx));
setMemberships = zeros(29,1);

for s=1:length(setIdx)
    tmp = dPCA_all.featureAverages(:,setIdx{s},cWindow);
    tmp = tmp(:,:);
    
    effMeans(:,s) = mean(tmp');
    setMemberships(setIdx{s}) = s;
end

for x=1:nCon
    avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
    avgTraj = mean(avgTraj(cWindow,:));%-fa;
    if subractEffMean
        avgTraj = avgTraj - effMeans(:,setMemberships(x))';
    end
   
    for y=1:nCon
        avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
        avgTraj_y = mean(avgTraj_y(cWindow,:));%-fa;
        if subractEffMean
            avgTraj_y = avgTraj_y - effMeans(:,setMemberships(y))';
        end
        
        simMatrix(x,y) = corr(avgTraj', avgTraj_y');
    end
end

reorderIdx = [1:6, 25:26, 7:12, 27:28, 13:24];
simMatrix = simMatrix(reorderIdx,reorderIdx);

figure('Position',[680   866   391   232]);
crossMats = {simMatrix(1:8,9:16), simMatrix(17:22,23:28)};
titles = {'Arm','Leg'};
for c=1:length(crossMats)
    cMat = crossMats{c};
    diagEntries = 1:(size(cMat,1)+1):numel(cMat);
    otherEntries = setdiff(1:numel(cMat), diagEntries);    
    
    subplot(1,2,c);
    hold on
    plot((rand(length(diagEntries),1)-0.5)*0.55, cMat(diagEntries), 'o');
    plot(1 + (rand(length(otherEntries),1)-0.5)*0.55, cMat(otherEntries), 'ro');
    set(gca,'XTick',[0 1],'XTickLabel',{'Same','Different'},'XTickLabelRotation',45);
    ylim([-1.0,1.0]);
    ylabel('Correlation');
    set(gca,'FontSize',20,'LineWidth',2);
    xlim([-0.5,1.5]);
    title(titles{c});
end 
saveas(gcf,[outDir filesep 'corrDots.png'],'png');
saveas(gcf,[outDir filesep 'corrDots.svg'],'svg');
    
crossMat1 = simMatrix(1:8, 9:16);
diagEntries = 1:9:numel(crossMat1);
otherEntries = setdiff(1:numel(crossMat1), diagEntries);
anova1([crossMat1(diagEntries)'; crossMat1(otherEntries)'], ...
    [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);

crossMat1 = simMatrix(17:22, 23:28);
diagEntries = 1:7:numel(crossMat1);
otherEntries = setdiff(1:numel(crossMat1), diagEntries);
anova1([crossMat1(diagEntries)'; crossMat1(otherEntries)'], ...
    [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);

movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'};
cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

plotSets = {1:16, 17:28, [1:6, 19 20 17 18 21 22]};
fPos = {[680   678   560   420],[721   767   406   302],[680   678   560   420]};
for plotIdx=1:length(plotSets)
    figure('Position',fPos{plotIdx});
    imagesc(simMatrix(plotSets{plotIdx},plotSets{plotIdx}),[-1 1]);
    set(gca,'XTick',1:nCon,'XTickLabel',movLabels(plotSets{plotIdx}),'XTickLabelRotation',45);
    set(gca,'YTick',1:nCon,'YTickLabel',movLabels(plotSets{plotIdx}));
    set(gca,'FontSize',16);
    set(gca,'YDir','normal');
    colormap(cMap);
    colorbar;

    if plotIdx==1
        colors = [173,150,61;
            119,122,205;]/255;
        idxSets = {1:8, 9:16}; 
    elseif plotIdx==2
        colors = [91,169,101;
            197,90,159;]/255;
        idxSets = {1:6,7:12}; 
    else
        colors = [91,169,101;
            197,90,159;]/255;
        idxSets = {1:6,7:12};         
    end
    
    for setIdx = 1:length(idxSets)
        newIdx = idxSets{setIdx};
        rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
    end
    axis tight;
    
    saveas(gcf,[outDir filesep 'corrMatrix_' num2str(plotIdx) '.png'],'png');
    saveas(gcf,[outDir filesep 'corrMatrix_' num2str(plotIdx) '.svg'],'svg');
end

%%
%similarity matrix across movements using projection
dPCA_all = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesRemap, [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );

nCon = size(dPCA_all.featureAverages,2);
cWindow = 60:100;

simMatrix = zeros(nCon, nCon);
fa = dPCA_all.featureAverages(:,:,cWindow);
fa = fa(:,:)';
fa = mean(fa);

subractEffMean = true;
setIdx = {[1:6, 25:26], [7:12, 27:28], 13:18, 19:24};
setMemberships = zeros(28,1);

for s=1:length(setIdx)
    setMemberships(setIdx{s}) = s;
end

for x=1:nCon
    %get the top dimensions this movement lives in
    avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
    effAvg = squeeze(nanmean(dPCA_all.featureAverages(:,setIdx{setMemberships(x)},:),2))';
    avgTraj = avgTraj - effAvg;
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
    topDim = COEFF(:,1:4);
    
    for y=1:nCon
        avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
        effAvg = squeeze(nanmean(dPCA_all.featureAverages(:,setIdx{setMemberships(y)},:),2))';
        avgTraj_y = avgTraj_y - effAvg;
        
        reconTraj = (avgTraj_y*topDim)*topDim';
        errTraj = avgTraj_y - reconTraj;
        
        SSTOT = sum(avgTraj_y(:).^2);
        SSERR = sum(errTraj(:).^2);
        
        simMatrix(x,y) = 1 - SSERR/SSTOT;
    end
end

reorderIdx = [1:6, 25:26, 7:12, 27:28, 13:24];
simMatrix = simMatrix(reorderIdx,reorderIdx);

crossMat1 = simMatrix(1:8, 9:16);
diagEntries = 1:9:numel(crossMat1);
otherEntries = setdiff(1:numel(crossMat1), diagEntries);
anova1([crossMat1(diagEntries)'; crossMat1(otherEntries)'], ...
    [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);

crossMat1 = simMatrix(17:22, 23:28);
diagEntries = 1:7:numel(crossMat1);
otherEntries = setdiff(1:numel(crossMat1), diagEntries);
anova1([crossMat1(diagEntries)'; crossMat1(otherEntries)'], ...
    [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);

movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'};
cMap = parula;

simMatrix = simMatrix ./ repmat(diag(simMatrix)',size(simMatrix,1),1);
for x=1:length(simMatrix)
    simMatrix(x,x) = 0;
end

figure
imagesc(simMatrix);
set(gca,'XTick',1:nCon,'XTickLabel',movLabels,'XTickLabelRotation',45);
set(gca,'YTick',1:nCon,'YTickLabel',movLabels);
set(gca,'FontSize',16);
set(gca,'YDir','normal');
colormap(cMap);
colorbar;

colors = [100,168,96;
153,112,193;
185,141,62;
204,84,94]/255;

idxSets = {1:8, 9:16, 17:22, 23:28}; 
for setIdx = 1:length(idxSets)
    newIdx = idxSets{setIdx};
    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
end
axis tight;

%%
% movSets = {[122 123 125 127 129 130 175 176],'armJointLeft'
%     [131 132 134 136 138 139 177 178],'armJointRight'
%     [140 141 142 144 146 147],'legJointLeft'
%     [148 149 150 152 154 155],'legJointRight'
%     [158 159 160 161 162 163],'armDirRight'
%     [164 165 166 167 168 169],'armDirLeft'
%     [1 2 3 5 6 7],'Cursor'};
    
%2-factor dPCA
%see movementTypes.m for code definitions
legendSets = {{'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise'},...
    {'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'},...
    {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise','AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'}};
movSets_2Fac = {[122 123 125 127 129 130 175 176],[131 132 134 136 138 139 177 178]
    [140 141 142 144 146 147],[148 149 150 152 154 155],
    [122 123 125 127 129 130 175 176 140 141 142 144 146 147],[131 132 134 136 138 139 177 178 148 149 150 152 154 155]};
    
timeWindow = [-1200, 3000];
dPCA_out = cell(size(movSets_2Fac,1),1);
codes = cell(size(movSets_2Fac,1),2);
plotNames = {'arm','leg','armLeg'};
for pIdx = 1:2
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

    %dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
    %    newCodes, timeWindow/binMS, binMS/1000, {'Movement','Effector','CI','MxE Interaction'}, 30 );
    %close(gcf);
    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        newCodes, timeWindow/binMS, binMS/1000, {'Movement','Effector','CI','MxE Interaction'}, 30, 'none', 'ortho' );
    close(gcf);
    
    colors = jet(length(movSets_2Fac{pIdx,1}))*0.8;
    lineArgs_2fac = cell(length(movSets_2Fac{pIdx,1}), 2);
    for x=1:length(lineArgs_2fac)
        lineArgs_2fac{x,1} = {'Color',colors(x,:),'LineStyle',':','LineWidth',2};
        lineArgs_2fac{x,2} = {'Color',colors(x,:),'LineStyle','-','LineWidth',2};
    end
    timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
    
    %[yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot_pretty( dPCA_out{pIdx}, timeAxis, lineArgs_2fac, ...
    %    {'Movement','Effector','CI','MxE Interaction'}, 'sameAxesGlobal' );
    
    layoutInfo.nPerMarg = 3;
    layoutInfo.fPos = [136   510   867   552];
    layoutInfo.gap = [0.03 0.01];
    layoutInfo.marg_h = [0.07 0.02];
    layoutInfo.marg_w = [0.15 0.07];
    layoutInfo.colorFactor = 1;
    layoutInfo.textLoc = [0.73, 0.15];
    layoutInfo.plotLayout = 'horizontal';
    
    [yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot_pretty_2( dPCA_out{pIdx}, timeAxis, lineArgs_2fac, ...
        {'Movement','Laterality','CI','MxL Interaction'}, ...
        'sameAxesGlobal', [], [-2.5, 2.5], dPCA_out{pIdx}.dimCI, colors, layoutInfo );
    for x=1:length(allHandles)
        for y=1:length(allHandles{x})
            plot(allHandles{x}(y), [1.5 1.5], get(allHandles{x}(y),'YLim'), '--k','LineWidth',2);
            set(gcf,'Renderer','painters');
            set(allHandles{x}(y),'FontSize',18,'XLim',[-1,2.5]);
            if x==1 && y==1
                axes(allHandles{x}(y));
                text(0.3,0.9,'Go','Units','Normalized','FontSize',16);
                text(0.7,0.9,'Return','Units','Normalized','FontSize',16);
            end
            if x==1
                axes(allHandles{x}(y));
                ylabel(['Dimension ' num2str(y) ' (SD)'],'FontSize',16);
            end
        end
    end
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '.svg'],'svg');
    
    figure('Position',[262   877   237   209]);
    hold on;
    for c=1:size(colors,1)
        plot([0,0],[1,1],'Color',colors(c,:),'LineWidth',2);
    end
    axis off;
    legend(legendSets{pIdx},'box','off');
    set(gca,'FontSize',16);
    
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_legend.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_2fac_' plotNames{pIdx} '_legend.svg'],'svg');
    
    close all;
end    

save([outDir filesep 'dPCA_laterality'],'dPCA_out');

%%
%effector & laterality marginalizations
reorderIdx = [1:6, 25:26, 7:12, 27:28, 13:24];
movSets = {[122 123 125 127 129 130 175 176],[131 132 134 136 138 139 177 178]
    [140 141 142 144 146 147],[148 149 150 152 154 155]};
factorMap = [122 1 1;
    123 1 1;
    125 1 1;
    127 1 1;
    129 1 1;
    130 1 1;
    175 1 1;
    176 1 1;
    131 2 1;
    132 2 1;
    134 2 1;
    136 2 1;
    138 2 1;
    139 2 1;
    177 2 1;
    178 2 1;
    140 1 2;
    141 1 2;
    142 1 2;
    144 1 2;
    146 1 2;
    147 1 2;
    148 2 2;
    149 2 2;
    150 2 2;
    152 2 2;
    154 2 2;
    155 2 2;
    ];

newFactors = nan(length(trlCodes),2);
for t=1:length(trlCodes)
    tableIdx = find(trlCodes(t)==factorMap(:,1));
    if isempty(tableIdx)
        continue;
    end
    newFactors(t,:) = factorMap(tableIdx,2:3);
end

trlIdx = ~isnan(newFactors(:,1));
dPCA_lat_eff = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
    newFactors(trlIdx,:), timeWindow/binMS, binMS/1000, {'Laterality','Effector','CI','LxE Interaction'}, 30, 'standard' );

dPCA_all = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesRemap, [-1200, 3000]/binMS, binMS/1000, {'CI','CD'} );

fa = dPCA_all.featureAverages(:,reorderIdx,:);
reorderIdx = [1:6, 25:26, 7:12, 27:28, 13:24];

lineArgs = cell(length(reorderIdx),1);
effSets = {1:8, 9:16, 17:22, 23:28};
colors = [0.8 0.3 0.3;
    0.8 0.3 0.3;
    0.3 0.3 0.8;
    0.3 0.3 0.8];
ls = {'-',':','-',':'};

for effIdx=1:length(effSets)
    for x=1:length(effSets{effIdx})
        lineArgs{effSets{effIdx}(x)} = {'Color', colors(effIdx,:), 'LineStyle', ls{effIdx}, 'LineWidth', 2};
    end
end

dPCA_newAx = dPCA_all;
dPCA_newAx.Z = zeros(size(dPCA_lat_eff.W,2),size(dPCA_newAx.Z,2),size(dPCA_newAx.Z,3));
for x=1:size(dPCA_newAx.featureAverages,2)
    dPCA_newAx.Z(:,x,:) = (squeeze(dPCA_newAx.featureAverages(:,x,:))'*dPCA_lat_eff.W)';
end

dPCA_newAx.Z = dPCA_newAx.Z(:,reorderIdx,:);
dPCA_newAx.whichMarg = dPCA_lat_eff.whichMarg;

timeAxis = ((-1200/binMS):(3000/binMS))/100;
layout.gap = [0.01 0.01];
layout.marg_h = [0.05 0.01];
layout.marg_w = [0.15 0.10];
layout.fPos = [135   686   929   382];
layout.nPerMarg = 2;
layout.textLoc = [0.75 0.7];
layout.colorFactor = 1;
layout.plotLayout = 'horizontal';

[yAxesFinal, allAxHandles] = general_dPCA_plot( dPCA_newAx, timeAxis, lineArgs, {'Laterality','Effector','CI','LxE Interaction'}, ...
    'sameAxes', [], [-1.2 2], [], [], layout);

for x=1:length(allAxHandles)
    for y=1:length(allAxHandles{x})
        set(allAxHandles{x}(y),'XLim',[-1, 2.5]);
        plot(allAxHandles{x}(y), [1.5,1.5], get(allAxHandles{x}(y),'YLim'),'--k','LineWidth',2);
    end
end

axes(allAxHandles{1}(1));
ylabel('Dimension 1 (SD)','FontSize',18);
text(0.15,1.7,'Go','FontSize',16);
text(1.65,1.7,'Return','FontSize',16);

axes(allAxHandles{1}(2));
ylabel('Dimension 2 (SD)','FontSize',18);
set(gca,'YTick',[-1,0,1]);

saveas(gcf,[outDir filesep 'lat_v_eff.png'],'png');
saveas(gcf,[outDir filesep 'lat_v_eff.svg'],'svg');
%%
%cross effector laterality dimension
legendSets = {{'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise'},...
    {'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'}};
movSets_2Fac = {[122 123 125 127 129 130 175 176],[131 132 134 136 138 139 177 178]
    [140 141 142 144 146 147],[148 149 150 152 154 155]};
    
timeWindow = [-1200, 3000];
dPCA_out = cell(size(movSets_2Fac,1),1);
codes = cell(size(movSets_2Fac,1),2);
plotNames = {'arm','leg'};
for pIdx = 1:2
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

    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        newCodes, timeWindow/binMS, binMS/1000, {'Movement','Effector','CI','MxE Interaction'}, 30, 'standard' );
    close(gcf);
end
    
%%
%cross-dims
for whichMarg=2:3
    latDim = cell(2,1);
    for pIdx = 1:2
        crossIdx = 3-pIdx;
        fv = dPCA_out{crossIdx}.featureVals;
        cdIdx = find(dPCA_out{pIdx}.whichMarg==whichMarg);

        con1 = size(fv,2);
        con2 = size(fv,3);
        nSteps = size(fv,4);
        nReps = size(fv,5);

        latDim{pIdx} = zeros(con1, con2, nSteps, nReps);
        for c1=1:con1
            for c2=1:con2
                for repIdx=1:nReps
                    neuralAct = squeeze(fv(:,c1,c2,:,repIdx));
                    latDim{pIdx}(c1,c2,:,repIdx) = neuralAct'*dPCA_out{pIdx}.W(:,cdIdx(1));
                end
            end
        end
    end
    latDim = latDim([2 1]);

    figure('Position',[201   373   479   425]);
    for rowIdx = 1:2
        for colIdx=1:2
            colors = jet(length(movSets_2Fac{colIdx,1}))*0.8;
            lineArgs_2fac = cell(length(movSets_2Fac{colIdx,1}), 2);
            for x=1:length(lineArgs_2fac)
                lineArgs_2fac{x,1} = {'Color',colors(x,:),'LineStyle',':','LineWidth',2};
                lineArgs_2fac{x,2} = {'Color',colors(x,:),'LineStyle','-','LineWidth',2};
            end
            timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);

            subtightplot(2,2,(rowIdx-1)*2+colIdx,[0.03 0.03],[0.15 0.1],[0.15 0.03]);
            hold on;

            for c1=1:size(dPCA_out{colIdx}.Z,2)
                for c2=1:size(dPCA_out{colIdx}.Z,3)
                    if rowIdx~=colIdx
                        tmp = squeeze(latDim{colIdx}(c1,c2,:,:));
                        badIdx = find(all(isnan(tmp)));
                        tmp(:,badIdx) = [];
                        [mn,~,CI] = normfit(tmp');
                    else
                        dimIdx = find(dPCA_out{rowIdx}.whichMarg==whichMarg);
                        dimIdx = dimIdx(1);
                        mn = squeeze(dPCA_out{rowIdx}.Z(dimIdx,c1,c2,:));
                        CI = squeeze(dPCA_out{rowIdx}.dimCI(dimIdx,c1,c2,:,:))';
                    end

                    plot(timeAxis, mn,'LineWidth',2,lineArgs_2fac{c1,c2}{:});
                    errorPatch(timeAxis', CI',colors(c1,:), 0.2);
                end
            end

            if rowIdx==2
                xlabel('Time (s)');
            else
                set(gca,'XTickLabel',[]);
            end

            if colIdx==1
                ylabel('Laterality\newlineDimension (SD)');
            else
                set(gca,'YTickLabel',[]);
            end

            set(gca,'FontSize',16,'LineWidth',1);
            xlim([timeAxis(1), timeAxis(end)]);
            ylim([-2.0, 2.4]);
            if rowIdx==1 && colIdx==1
                title('Arm');
            elseif rowIdx==1 && colIdx==2
                title('Leg');
            end

            plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
            plot([1.5,1.5],get(gca,'YLim'),'--k','LineWidth',2);
            xlim([-1,2.5]);
        end
    end
    saveas(gcf,[outDir filesep 'latDimCross_' num2str(whichMarg) '.png'],'png');
    saveas(gcf,[outDir filesep 'latDimCross_' num2str(whichMarg) '.svg'],'svg');
end

%%
%linear classifier, separate sets
armJoint = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'IndexRaise','ThumbRaise'};
legJoint = {'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'};

movTypeText = {'Arm Joints','Leg Joints'};
movLegends = {armJoint, legJoint};

setIdx = {1,2};
setNames = {'arm','leg'};

reorderIdxSets = {[7:12, 15:16, 1:6, 13:14], [7:12, 1:6]};
boxSets = {{1:8, 9:16}, {1:6, 7:12}}; 

colors = [100,168,96;
153,112,193;
185,141,62;
204,84,94]/255;
colorSets = {colors(1:2,:), colors(3:4,:)};
subtractEffMean = false;

for setPtr = 1:length(setIdx)
    codes = cell(size(movTypes,1),2);
    for pIdx = setIdx{setPtr}
        trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});

        codes{pIdx,1} = unique(trlCodes(trlIdx));
        codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
    end 

    remapTable = [];
    currentIdx = 0;
    for c=1:length(codes)
        newIdx = currentIdx + (1:length(codes{c,2}))';
        remapTable = [remapTable; [newIdx, codes{c,2}]];
        currentIdx = currentIdx + length(codes{c,2});
    end

    allFeatures = [];
    allCodes = [];
    for pIdx = setIdx{setPtr}
        trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
        if strcmp(movTypes{pIdx,2},'cursor_CL')
            %ignore return
            trlIdx(trlCodes(trlIdx)>7)=false;
        end
        trlIdx = find(trlIdx);

        newCodes = trlCodesRemap(trlIdx);
        newData = [];
        for n=1:length(newCodes)
            tmp = [];
            dataIdx = 20:30;
            for binIdx=1:10
                loopIdx = dataIdx + eventIdx(trlIdx(n));
                tmp = [tmp, mean(snippetMatrix(loopIdx,:))];
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
    
    if subtractEffMean
        for bIdx=1:length(boxSets{setPtr})
            effMem = ismember(allCodesRemap,boxSets{setPtr}{bIdx});
            allFeatures(effMem,:) = allFeatures(effMem,:) - mean(allFeatures(effMem,:));
        end
    end

    obj = fitcdiscr(allFeatures,allCodesRemap,'DiscrimType','diaglinear');
    cvmodel = crossval(obj);
    L = kfoldLoss(cvmodel);
    predLabels = kfoldPredict(cvmodel);

    C = confusionmat(allCodesRemap, predLabels);
    for rowIdx=1:size(C,1)
        C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
    end
    C = C(reorderIdxSets{setPtr}, reorderIdxSets{setPtr});
    movLabels = movLegends{setPtr}(reorderIdxSets{setPtr});

    figure('Position',[143   730   507   369]);
    imagesc(C);
    set(gca,'XTick',1:length(allCodesRemap),'XTickLabel',movLabels,'XTickLabelRotation',45);
    set(gca,'YTick',1:length(allCodesRemap),'YTickLabel',movLabels);
    set(gca,'FontSize',14);
    colorbar;
    title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
    set(gca,'YDir','normal');
    
    idxSets = boxSets{setPtr};
    colors = colorSets{setPtr};
    for setItr = 1:length(idxSets)
        newIdx = idxSets{setItr};
        rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setItr,:));
    end
    axis tight;
    
    saveas(gcf,[outDir filesep 'linearClassifier_' setNames{setPtr} '.png'],'png');
    saveas(gcf,[outDir filesep 'linearClassifier_' setNames{setPtr} '.svg'],'svg');
end

%%
%linear classifier
%see movementTypes.m for code definitions
movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','RaiseIndex','RaiseThumb',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','RaiseIndex','RaiseThumb',...
    'AnkleUp','AnkleDown','KneeExt','LegRaise','ToeCurl','ToeOpen',...
    'AnkleUp','AnkleDown','KneeExt','LegRaise','ToeCurl','ToeOpen'};
reorderIdx = [7:12, 15:16, 1:6, 13:14, 23:28, 17:22];

colors = [100,168,96;
153,112,193;
185,141,62;
204,84,94]/255;

codes = cell(size(movTypes,1),2);
for pIdx = 1:2
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    if strcmp(movTypes{pIdx,2},'cursor_CL')
        %ignore return
        trlIdx(trlCodes(trlIdx)>7)=false;
    end

    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
end 

remapTable = [];
currentIdx = 0;
for c=1:length(codes)
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
        dataIdx = 20:100;
        for binIdx=1:1
            loopIdx = dataIdx + eventIdx(trlIdx(n));
            tmp = [tmp, mean(snippetMatrix(loopIdx,:))];
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

idxSets = {1:8, 9:16, 17:22, 23:28}; 
for setIdx = 1:length(idxSets)
    newIdx = idxSets{setIdx};
    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
end
axis tight;

saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');

%%
%linear classifier
%see movementTypes.m for code definitions
movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','RaiseIndex','RaiseThumb',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','RaiseIndex','RaiseThumb',...
    'AnkleUp','AnkleDown','KneeExt','LegRaise','ToeCurl','ToeOpen',...
    'AnkleUp','AnkleDown','KneeExt','LegRaise','ToeCurl','ToeOpen'};
reorderIdx = [7:12, 15:16, 1:6, 13:14, 23:28, 17:22];

colors = [100,168,96;
153,112,193;
185,141,62;
204,84,94]/255;

allFeatures = [];
allCodes = [];
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    trlIdx = find(trlIdx);

    newCodes = trlCodesRemap(trlIdx);
    newData = [];
    for n=1:length(newCodes)
        tmp = [];
        dataIdx = 20:100;
        for binIdx=1:1
            loopIdx = dataIdx + eventIdx(trlIdx(n));
            tmp = [tmp, mean(snippetMatrix(loopIdx,:))];
            dataIdx = dataIdx + length(dataIdx);
        end
        newData = [newData; tmp];
    end

    allFeatures = [allFeatures; newData];
    allCodes = [allCodes; newCodes];
end

obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
cvmodel = crossval(obj);
L = kfoldLoss(cvmodel);
predLabels = kfoldPredict(cvmodel);

C = confusionmat(allCodes, predLabels);
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

idxSets = {1:8, 9:16, 17:22, 23:28}; 
for setIdx = 1:length(idxSets)
    newIdx = idxSets{setIdx};
    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
end
axis tight;

saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');
