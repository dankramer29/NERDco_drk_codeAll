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
%effector & laterality marginalizations
timeWindow = [-1000 3000];
movWindow = [20, 60];

% codeSets = {
%     [131 132 134 136 138 139 177 178],...
%     [122 123 125 127 129 130 175 176],...
%     [148 149 150 152 154 155],...
%     [140 141 142 144 146 147],...
%     };
% 
% movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
%     'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
%     'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen',...
%     'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'};
% 
% codeSets = {
%     [131 132 134 136 138 139],...
%     [122 123 125 127 129 130],...
%     [148 149 150 152 154 155],...
%     [140 141 142 144 146 147],...
%     };

% reorderIdx = [1:24];
% movSets = {[122 123 125 127 129 130],[131 132 134 136 138 139]
%     [140 141 142 144 146 147],[148 149 150 152 154 155]};
% factorMap = [122 1 1 1;
%     123 1 1 2;
%     125 1 1 3;
%     127 1 1 4;
%     129 1 1 5;
%     130 1 1 6;
%     131 2 1 1;
%     132 2 1 2;
%     134 2 1 3;
%     136 2 1 4;
%     138 2 1 5;
%     139 2 1 6;
%     140 1 2 1;
%     141 1 2 2;
%     142 1 2 3;
%     144 1 2 4;
%     146 1 2 5;
%     147 1 2 6;
%     148 2 2 1;
%     149 2 2 2;
%     150 2 2 3;
%     152 2 2 4;
%     154 2 2 5;
%     155 2 2 6;
%     ];

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
    123 1 1 2;
    125 1 1 3;
    127 1 1 4;
    129 1 1 5;
    130 1 1 6;
    175 1 1 7;
    176 1 1 8;
    
    131 2 1 1;
    132 2 1 2;
    134 2 1 3;
    136 2 1 4;
    138 2 1 5;
    139 2 1 6;
    177 2 1 7;
    178 2 1 8;
    
    140 1 2 9;
    141 1 2 10;
    142 1 2 11;
    144 1 2 12;
    146 1 2 13;
    147 1 2 14;
    
    148 2 2 9;
    149 2 2 10;
    150 2 2 11;
    152 2 2 12;
    154 2 2 13;
    155 2 2 14;
    ];

newFactors = nan(length(trlCodes),3);
for t=1:length(trlCodes)
    tableIdx = find(trlCodes(t)==factorMap(:,1));
    if isempty(tableIdx)
        continue;
    end
    newFactors(t,:) = factorMap(tableIdx,2:end);
end

% margGroupings = {{1, [1 4]}, ...
%     {2, [2 4]}, ...
%     {[1 2] ,[1 2 4]}, ...
%     {4}, ...
%     {3, [1 3], [2 3], [3 4], [1 3 4], [2 3 4], [1 2 3], [1 2 3 4]}};
% margNames = {'Laterality','Effector','LxE','Time','Movement'};
margGroupings = {{1, [1 4], [1 2] ,[1 2 4]}, ...
    {2, [2 4]}, ...
    {4}, ...
    {3, [1 3], [2 3], [3 4], [1 3 4], [2 3 4], [1 2 3], [1 2 3 4]}};
margNames = {'Laterality','Effector','Time','Movement'};

trlIdx = find(~isnan(newFactors(:,1)));

opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 3;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

apply_mPCA_general( smoothSnippetMatrix, eventIdx(trlIdx), ...
    newFactors(trlIdx,:), [-100,300], 0.010, opts_m);

%%
opts.margNames = margNames;
opts.margGroupings = margGroupings;
opts.maxDim = [5 5 5 5];
opts.CIMode = 'none';
opts.orthoMode = 'standard_dpca';
opts.useCNoise = true;

dPCA_full = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx), ...
    newFactors(trlIdx,:), timeWindow/binMS, binMS/1000, opts);
Z = dPCA_full.Z;
cvLat = zeros(size(Z,2), size(Z,3), size(Z, 4), size(Z, 5));
nMov = size(Z,4);

for movIdx=1:nMov
    disp(movIdx);

    trainMov = setdiff(1:nMov, movIdx);
    trlIdx_inner = find(ismember(newFactors(trlIdx,3), trainMov));

    relabelCodes = newFactors(trlIdx(trlIdx_inner),:);
    [~,~,relabelCodes(:,3)] = unique(relabelCodes(:,3));

    dPCA_x = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx(trlIdx_inner)), relabelCodes, [-100,300], 0.010, opts);
    close(gcf);

    latAx = find(dPCA_x.whichMarg==1);
    tmpFA = squeeze(dPCA_full.featureAverages(:,:,:,movIdx,:));
    cvProj = dPCA_x.W(:,latAx(1))'*tmpFA(:,:);

    sz = size(tmpFA);
    cvProj = reshape(cvProj, sz(2:end));
    cvLat(:,:,movIdx,:) = cvProj;
end

colors = jet(2)*0.8;
ls = {'--','-'};

figure;
hold on;
for latIdx=1:2
    for effIdx=1:2
        for movIdx=1:nMov
            plot(squeeze(cvLat(latIdx, effIdx, movIdx, :)),'Color',colors(effIdx,:),'LineStyle',ls{latIdx},'LineWidth',2);
        end
    end
end

%PCA of factor difference vectors
diffVec = squeeze(dPCA_full.featureAverages(:,:,1,:,:) - dPCA_full.featureAverages(:,:,2,:,:));
diffVecUnroll = diffVec(:,:);
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(diffVecUnroll');

colors = jet(nMov)*0.8;
figure
hold on;
for movIdx=1:nMov
    tmp = COEFF(:,1)'*squeeze(diffVec(:,:,movIdx,:));
    plot(tmp,'LineWidth',2,'Color',colors(movIdx,:));
end

%%
opts.margNames = margNames;
opts.margGroupings = margGroupings;
opts.maxDim = [5 5 5 5];
opts.CIMode = 'none';
opts.orthoMode = 'standard_dpca';
opts.useCNoise = true;
opts.optimalLambda = 0;
    
trlIdx = ~isnan(newFactors(:,1));
dPCA_le_standard = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx), ...
    newFactors(trlIdx,:), timeWindow/binMS, binMS/1000, opts );

margColours = lines(5);
componentVarPlot( dPCA_le_standard, margNames, 15, margColours );
    
dPCA_all = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, trlCodesRemap, [-1200, 3000]/binMS, binMS/1000, {'CI','CD'} );
close(gcf);

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

useAx = find(ismember(dPCA_le_standard.whichMarg, [1 2 3]));
dPCA_newAx = dPCA_all;
dPCA_newAx.Z = zeros(size(dPCA_le_standard.W(:,useAx),2),size(dPCA_newAx.Z,2),size(dPCA_newAx.Z,3));
for x=1:size(dPCA_newAx.featureAverages,2)
    dPCA_newAx.Z(:,x,:) = (squeeze(dPCA_newAx.featureAverages(:,x,:))'*dPCA_le_standard.W(:,useAx))';
end

dPCA_newAx.Z = dPCA_newAx.Z(:,reorderIdx,:);
dPCA_newAx.whichMarg = dPCA_le_standard.whichMarg(useAx);
dPCA_newAx.explVar.componentVar = dPCA_le_standard.explVar.componentVar(useAx);

timeAxis = ((-1200/binMS):(3000/binMS))/100;
layout.gap = [0.01 0.01];
layout.marg_h = [0.10 0.01];
layout.marg_w = [0.25 0.10];
layout.fPos = [135   849   654   219];
layout.nPerMarg = 1;
layout.textLoc = [0.75 0.7];
layout.colorFactor = 1;
layout.plotLayout = 'horizontal';
layout.verticalBars = [0, 1.5];

[yAxesFinal, allAxHandles] = general_dPCA_plot( dPCA_newAx, timeAxis, lineArgs, {'Laterality','Arm vs. Leg','Time'}, ...
    'sameAxes', [], [-1.75 2.5], [], [], layout);

for x=1:length(allAxHandles)
    for y=1:length(allAxHandles{x})
        set(allAxHandles{x}(y),'XLim',[-1, 2.5]);
        plot(allAxHandles{x}(y), [1.5,1.5], get(allAxHandles{x}(y),'YLim'),'--k','LineWidth',2);
    end
end

axes(allAxHandles{1}(1));
ylabel('Dimension 1 (SD)','FontSize',18);
text(0.15,3,'Go','FontSize',16);
text(1.65,3,'Return','FontSize',16);

saveas(gcf,[outDir filesep 'lat_v_eff.png'],'png');
saveas(gcf,[outDir filesep 'lat_v_eff.svg'],'svg');

%%
%laterality component
dimNames = {'Laterality','Arm vs. Leg','Time','Movement'};
dimIdx = [1 2 3];
binEdges = linspace(-0.4,0.4,30);
binCenters = binEdges(1:(end-1)) + (binEdges(2)-binEdges(1))/2;

figure('Position',[112   583   789   192]);
hold on;
for x=1:length(dimIdx )
    latDim = find(dPCA_le_standard.whichMarg==dimIdx(x));
    coef = dPCA_le_standard.V(:,latDim(1));

    subplot(1,3,x);
    hold on;
    N = histc(coef,binEdges);
    bar(binCenters, N(1:(end-1)),'FaceColor',[0.4 0.4 1.0]);
    
    xlim([-0.4,0.4]);
    ylim([0, 40]);
    
    plot([0,0],get(gca,'YLim'),':k','LineWidth',2);
    plot([mean(coef), mean(coef)],get(gca,'YLim'),'-r','LineWidth',2);
    xlabel([dimNames{x} ' Coeff.']);
    ylabel('Count');

    set(gca,'FontSize',16,'LineWidth',2)
    [h,p]=ttest(coef)
end

saveas(gcf,[outDir filesep 'dimCoeff.png'],'png');
saveas(gcf,[outDir filesep 'dimCoeff.svg'],'svg');

%%
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(dPCA_le_standard.XMarg{1}');
SCORE = SCORE';
tmp = reshape(SCORE,[113 2 2 14 401]);

figure
hold on
plot(squeeze(tmp(1,1,1,1,:)));
plot(squeeze(tmp(1,2,1,1,:)));

tmp = squeeze(tmp(1,1,1,1,:));

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

subractEffMean = false;
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
    avgTraj = mean(avgTraj(cWindow,:))-fa;
    if subractEffMean
        avgTraj = avgTraj - effMeans(:,setMemberships(x))';
    end
   
    for y=1:nCon
        avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
        avgTraj_y = mean(avgTraj_y(cWindow,:))-fa;
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

