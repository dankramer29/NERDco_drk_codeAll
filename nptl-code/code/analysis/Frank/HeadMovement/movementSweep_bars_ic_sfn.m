%%
%see movementTypes.m for code definitions
movTypes = {[13 14 15 16],'armJoint'
    [18 19 20 21],'leg'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

excludeChannels = [];
sessionName = 't5.2017.12.21';
filterName = '003-blocks008-thresh-4.5-ch60-bin15ms-smooth25ms-delay0ms.mat';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1200 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'ipsi_vs_contra'];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%
%load cursor filter for threshold values, use these across all movement types
model = load([paths.dataPath filesep 'BG Datasets' filesep sessionName filesep 'Data' filesep 'Filters' filesep ...
    filterName]);

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, setdiff(blockList,[1 2 3]), model.model );

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
for b=1:length(blockList)
    disp(b);
    blockTrl = find(bNumPerTrial==blockList(b));
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (alignEvents(blockTrl(t),2)):(alignEvents(blockTrl(t),2)+200)];
    end
    
    binIdx = find(blockRows==blockList(b));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(binIdx,:)));
end
rawSnippetMatrix = snippetMatrix;
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix, 3);

%%
clear R allSpikes
pack;

%%
movWindow = 20:100;
baselineWindow = -140:-100;

cVar = zeros(length(trlCodeList),1);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
codes = cell(size(movTypes,1),2);
all_dPCA = cell(size(movTypes,1),2);

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
    reducedSnippedMatrix = snippetMatrix * dPCA_out.W(:,cdIdx);

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
            
            dataMatrix = [dataMatrix; mean(reducedSnippedMatrix(loopIdxBaseline,:)); mean(reducedSnippedMatrix(loopIdxWindow,:))];
            dataLabels = [dataLabels; 1; 2];
        end
        
        nResample = 10000;
        testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
        end
        
        cVar(codes{pIdx,2}(codeIdx),1) = testStat;
        cVar(codes{pIdx,2}(codeIdx),2) = prctile(resampleVec,99);
        
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            class2 = dataMatrix(dataLabels==2,:);
            class2 = class2(randi(size(class2,1), size(class2,1), 1),:);
            
            class1 = dataMatrix(dataLabels==1,:);
            class1 = class1(randi(size(class1,1), size(class1,1), 1),:);
            
            testStat = norm(mean(class2) - mean(class1));
            resampleVec(resampleIdx) = testStat;
        end
        cVar(codes{pIdx,2}(codeIdx),3:4) = prctile(resampleVec,[2.5,97.5]);    
    end
end    

%%
%bar plot
movSets = {
    [131 132 134 136 138 139 177 178],'armJointRight'    
    [122 123 125 127 129 130 175 176],'armJointLeft'
    [148 149 150 152 154 155],'legJointRight'
    [140 141 142 144 146 147],'legJointLeft'
    };

movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'};
concatCodes = sort(horzcat(codes{:,1}));

colors = [100,168,96;
153,112,193;
185,141,62;
204,84,94]/255;

figure('Position',[164   751   989   338]);
plotIdx = 1;
colorIdx = 1;

hold on
for setIdx=1:length(movSets)
    [~,rowIdx] = ismember(movSets{setIdx,1}, concatCodes);
    dat = cVar(rowIdx,1) - cVar(rowIdx,2);
    CI = cVar(rowIdx,3:4) - cVar(rowIdx,2);
    
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
set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabels,'XTickLabelRotation',45);

axis tight;
xlim([0.5, 28.5]);
ylabel('\Delta Neural Activity\newlinein Separating Dimensions\newline(a.u.)','FontSize',22);
set(gca,'TickLength',[0 0]);

saveas(gcf,[outDir filesep 'bar_dPCA.png'],'png');
saveas(gcf,[outDir filesep 'bar_dPCA.svg'],'svg');
saveas(gcf,[outDir filesep 'bar_dPCA.pdf'],'pdf');

%%
for setIdx=1:length(movSets)
    [~,rowIdx] = ismember(movSets{setIdx,1}, concatCodes);
    dat = cVar(rowIdx,1) - cVar(rowIdx,2);
    disp(mean(dat));
end

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
    {'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'}};
movSets_2Fac = {[122 123 125 127 129 130 175 176],[131 132 134 136 138 139 177 178]
    [140 141 142 144 146 147],[148 149 150 152 154 155]};
    
dPCA_out = cell(size(movSets_2Fac,1),1);
eventIdx = (-timeWindow(1)/binMS):nBins:size(smoothSnippetMatrix,1);
codes = cell(size(movSets_2Fac,1),2);
plotNames = {'arm','leg'};
for pIdx = 1:size(movSets_2Fac,1)
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
        newCodes, timeWindow/binMS, binMS/1000, {'Movement','Effector','CI','MxE Interaction'}, 30, 'xval' );
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
    
    [yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot_pretty( dPCA_out{pIdx}.cval, timeAxis, lineArgs_2fac, ...
        {'Movement','Effector','CI','MxE Interaction'}, 'sameAxesGlobal', [], [], dPCA_out{pIdx}.cval.dimCI, colors, [0.2 0.7] );
    for x=1:length(allHandles)
        for y=1:length(allHandles{x})
            plot(allHandles{x}(y), [1.5 1.5], allYAxes{x}, '--k','LineWidth',2);
            set(gcf,'Renderer','painters');
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
    eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
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
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
for pIdx = 1:2
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
dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
    newCodes, timeWindow/binMS, binMS/1000, {'Movement','Effector','CI','MxE Interaction'}, 30 );

colors = jet(length(movSets_2Fac{pIdx,1}))*0.8;
lineArgs_2fac = cell(length(movSets_2Fac{pIdx,1}), 2);
for x=1:length(lineArgs_2fac)
    lineArgs_2fac{x,1} = {'Color',colors(x,:),'LineStyle',':','LineWidth',2};
    lineArgs_2fac{x,2} = {'Color',colors(x,:),'LineStyle','-','LineWidth',2};
end
timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);

dimCI = dPCA_CI( dPCA_out{pIdx}, smoothSnippetMatrix, eventIdx(trlIdx), newCodes, timeWindow/binMS );
[yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot_pretty( dPCA_out{pIdx}, timeAxis, lineArgs_2fac, ...
    {'Movement','Effector','CI','MxE Interaction'}, 'sameAxesGlobal', [], [], dimCI, colors );
