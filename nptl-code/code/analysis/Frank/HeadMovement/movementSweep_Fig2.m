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
    binMS, timeWindow, codeSets, 'subtractMean' );
singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, movLabels );

saveas(gcf,[outDir filesep 'bar_marg.png'],'png');
saveas(gcf,[outDir filesep 'bar_marg.svg'],'svg');

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
    opts.margNames = margNames;
    opts.margGroupings = margGroupings;
    opts.maxDim = [5 5 5];
    opts.CIMode = 'none';
    opts.orthoMode = 'standard_dpca';
    opts.useCNoise = true;

    cutIdx = trlIdx(cutTrl);
    dPCA_full = apply_dPCA_general( smoothSnippetMatrix, eventIdx(cutIdx), ...
        newCodes_relabel, timeWindowMov/binMS, binMS/1000, opts);
    Z = dPCA_full.Z;
    cvLat = zeros(size(Z,2), size(Z,3), size(Z, 4));
    nMov = size(Z,2);
    
    for movIdx=1:nMov
        disp(movIdx);

        trainMov = setdiff(1:nMov, movIdx);
        trlIdx_inner = find(ismember(newCodes_relabel(:,1), trainMov));

        relabelCodes = newCodes_relabel(trlIdx_inner,:);
        [~,~,relabelCodes(:,1)] = unique(relabelCodes(:,1));

        dPCA_x = apply_dPCA_general( smoothSnippetMatrix, eventIdx(cutIdx(trlIdx_inner)), relabelCodes, [-100,300], 0.010, opts);
        close(gcf);

        latAx = find(dPCA_x.whichMarg==2);
        tmpFA = squeeze(dPCA_full.featureAverages(:,movIdx,:,:));
        cvProj = dPCA_x.W(:,latAx(1))'*tmpFA(:,:);

        sz = size(tmpFA);
        cvProj = reshape(cvProj, sz(2:end));
        cvLat(movIdx,:,:) = cvProj;
    end

    colors = jet(nMov)*0.8;
    ls = {'--','-'};

    figure;
    hold on;
    for l=1:2
        for movIdx=1:nMov
            plot(squeeze(cvLat(movIdx,l,:)),'Color',colors(movIdx,:),'LineStyle',ls{l},'LineWidth',2);
        end
    end
    
    %PCA of factor difference vectors
    diffVec = squeeze(dPCA_full.featureAverages(:,:,1,:) - dPCA_full.featureAverages(:,:,2,:));
    diffVecUnroll = diffVec(:,:);
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(diffVecUnroll');
    
    colors = jet(nMov)*0.8;
    figure
    hold on;
    for movIdx=1:nMov
        tmp = COEFF(:,1)'*squeeze(diffVec(:,movIdx,:));
        plot(tmp,'LineWidth',2,'Color',colors(movIdx,:));
    end
    
    %%
    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 5;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'parametric';
    apply_mPCA_general( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
        newCodes_relabel, [-100,300], 0.010, opts_m);

    opts.margNames = margNames;
    opts.margGroupings = margGroupings;
    opts.maxDim = 10;
    opts.CIMode = 'none';
    opts.orthoMode = 'ortho';
    opts.useCNoise = true;

    totalRecon = zeros(length(lambdas),1);
    lambdas = 1e-05 * 1.5.^[0:25];
    for l=10:length(lambdas)
        opts.optimalLambda = lambdas(l);
        tmpOut = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
            newCodes_relabel, timeWindowMov/binMS, binMS/1000, opts  );
        totalRecon(l) = tmpOut.cval.explVar.cumulativeDPCA(end);
        close(gcf);
    end
    
    dPCA_out_xval{pIdx} = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
        newCodes_relabel, timeWindowMov/binMS, binMS/1000, opts  );
     
    %dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
    %    newCodes(cutTrl,:), timeWindowMov/binMS, binMS/1000, margNames, [5 5 5], 'none', 'standard_dPCA', margGroupings, true );
    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
        newCodes(cutTrl,:), timeWindowMov/binMS, binMS/1000, margNames, [5 5 5], 'none', 'standard_dpca', margGroupings, true );
    close(gcf);
    
    dPCA_out_xval{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
        newCodes(cutTrl,:), timeWindowMov/binMS, binMS/1000, margNames, [5 5 5], 'xval', 'standard_dpca', margGroupings, true );
    %dPCA_out_xval{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx(cutTrl)), ...
    %    newCodes(cutTrl,:), timeWindowMov/binMS, binMS/1000, margNames, [5 5 5], 'xval', 'standard_dPCA', margGroupings, true );
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

idxSets = {2:9, 10:17, 18:23, 24:29}; 
for setIdx = 1:length(idxSets)
    newIdx = idxSets{setIdx};
    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
end
axis tight;
set(gca,'YDir','normal');

saveas(gcf,[outDir filesep 'linearClassifier_all.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier_all.svg'],'svg');
