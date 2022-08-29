%%
%see movementTypes.m for code definitions
datasets = {'t5.2017.10.04',[21 22 23],[12 14 17 13 15 19]};

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;

%%
for d=1:length(datasets)
    saveableName = [strrep(datasets{d,1},'.','-')];
    outDir = [paths.dataPath filesep 'Derived' filesep 'CuedHeadMovement'];
    mkdir(outDir);
    
    %%
    %load dataset
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
    R = getSTanfordBG_RStruct( sessionPath, datasets{d,2} );
    
    trlCodes = zeros(size(R));
    for t=1:length(trlCodes)
        trlCodes(t) = R(t).startTrialParams.currentMovement;
    end
    [trlCodeList,~,trlCodesRemap] = unique(trlCodes);
    
    timeWindow = [-399 1000];
    alignField = 'goCue';
    
    allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
    meanRate = mean(allSpikes)*1000;
    tooLow = meanRate < 0.5;
    allSpikes(:,tooLow) = [];
    
    allSpikes = gaussSmooth_fast(allSpikes, 15);
    allSpikes = zscore(allSpikes);
    
    globalIdx = 0;
    alignEvents = zeros(size(R));
    for t=1:length(R)
        alignEvents(t) = globalIdx + R(t).(alignField);
        globalIdx = globalIdx + size(R(t).spikeRaster,2);
    end
    
    nBins = (timeWindow(2)-timeWindow(1)+1)/binMS;
    snippetMatrix = [];
    for t=1:length(R)
        loopIdx = (alignEvents(t)+timeWindow(1)):(alignEvents(t)+timeWindow(2));
        
        newRow = zeros(nBins, size(allSpikes,2));
        binIdx = 1:binMS;
        for b=1:nBins
            newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
            binIdx = binIdx + binMS;
        end
        
        snippetMatrix = [snippetMatrix; newRow];
    end
    
    %%
    dPCA_out = apply_dPCA_simple( snippetMatrix, 40:nBins:size(snippetMatrix,1), ...
        trlCodesRemap, [-39, 100], binMS/1000, {'CI','CD'} );
    
    lineArgs = cell(4,1);
    colors = hsv(length(trlCodeList))*0.8;
    if strcmp(datasets{d},'t5.2017.10.04')
        colors = colors([1 3 2 4],:);
        for c=1:length(trlCodeList)
            lineArgs{c} = {'LineWidth',2,'Color',colors(c,:)};
        end
    end

    timeAxis = (-39:100)*binMS;
    margNamesShort = {'Dir','CI'};

    oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, {'CD','CI'}, 'zoomedAxes' );
    saveas(gcf,[outDir filesep 'dPCA.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA.svg'],'svg');
    
    oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, {'CD','CI'}, 'sameAxes' );
    saveas(gcf,[outDir filesep 'dPCA_sameAx.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_sameAx.svg'],'svg');
    
    %%
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 0;
    psthOpts.neuralData = {snippetMatrix};
    psthOpts.timeWindow = [-39, 100];
    psthOpts.trialEvents = 40:nBins:size(snippetMatrix,1);
    psthOpts.trialConditions = trlCodesRemap;
    psthOpts.conditionGrouping = {[1 2 3 4]};
    psthOpts.lineArgs = lineArgs;
    
    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = outDir;
    
    featLabels = cell(192,1);
    chanIdx = find(~tooLow);
    for f=1:length(chanIdx)
        featLabels{f} = num2str(chanIdx(f));
    end
    psthOpts.featLabels = featLabels;
    
    psthOpts.prefix = 'Head';
    pOut = makePSTH_simple(psthOpts);
    close all;
    
    %%
    %load filter
    load('/Users/frankwillett/Data/BG Datasets/t5.2017.10.04/Data/Filters/007-blocks009_010-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat');
    R = getSTanfordBG_RStruct( sessionPath, datasets{d,2}, model );
    
    decFeatures = [[R.spikeRaster]', [R.spikeRaster2]'];
    decFeatures = gaussSmooth_fast(decFeatures, 15);
    
    globalIdx = 0;
    alignEvents = zeros(size(R));
    for t=1:length(R)
        alignEvents(t) = globalIdx + R(t).(alignField);
        globalIdx = globalIdx + size(R(t).spikeRaster,2);
    end
    
    headDir = zeros(size(decFeatures,1),2);
    globalIdx = 0;
    for t=1:length(R)
        loopIdx = (globalIdx+1):(globalIdx+length(R(t).clock));
        if R(t).startTrialParams.currentMovement==67
            headDir(loopIdx,:) = repmat([1, 0], length(loopIdx), 1);
        elseif R(t).startTrialParams.currentMovement==71
            headDir(loopIdx,:) = repmat([-1, 0], length(loopIdx), 1);
        elseif R(t).startTrialParams.currentMovement==72
            headDir(loopIdx,:) = repmat([0, 1], length(loopIdx), 1);
        elseif R(t).startTrialParams.currentMovement==73
            headDir(loopIdx,:) = repmat([0, -1], length(loopIdx), 1);
        end
        globalIdx = globalIdx + length(R(t).clock);
    end
    
    nBins = (timeWindow(2)-timeWindow(1)+1)/binMS;
    headDirMatrix = [];
    snippetMatrix = [];
    for t=1:length(R)
        loopIdx = (alignEvents(t)+timeWindow(1)):(alignEvents(t)+timeWindow(2));
        
        newRow = zeros(nBins, size(decFeatures,2));
        newHeadRow = zeros(nBins, size(headDir,2));
        binIdx = 1:binMS;
        for b=1:nBins
            newRow(b,:) = sum(decFeatures(loopIdx(binIdx),:));
            newHeadRow(b,:) = headDir(loopIdx(binIdx(1)),:);
            binIdx = binIdx + binMS;
        end
        
        snippetMatrix = [snippetMatrix; newRow];
        headDirMatrix = [headDirMatrix; newHeadRow];
    end
    
    snippetMatrix = snippetMatrix * (15/binMS);
    snippetMatrix = bsxfun(@plus, snippetMatrix, -mean(snippetMatrix));
    
    decoder = model.K([2 4 6 8],1:192);
    decoder = bsxfun(@times, decoder, model.invSoftNormVals(1:192)');
    decoder = decoder / (1-model.alpha) / model.beta;
    
    featLabels = cell(192,1);
    for f=1:length(featLabels)
        featLabels{f} = ['TX ' num2str(f)];
    end

    decOut = (snippetMatrix * decoder')*1000;
    
    %%
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 0;
    psthOpts.neuralData = {decOut};
    psthOpts.timeWindow = [-39, 100];
    psthOpts.trialEvents = 40:nBins:size(snippetMatrix,1);
    psthOpts.trialConditions = trlCodesRemap;
    psthOpts.conditionGrouping = {[1 2 3 4]};
    psthOpts.lineArgs = lineArgs;
    
    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = outDir;
    psthOpts.featLabels = {'X','Y','Z','Rot'};
    psthOpts.orderBySNR = 0;
    
    psthOpts.prefix = 'Decoder';
    pOut = makePSTH_simple(psthOpts);
    
    figure('Position',[680   156   387   942]);
    for f=1:4
        subplot(4,1,f);
        hold on;
        for c=1:4
            plot(pOut.timeAxis{c}, pOut.psth{c}(:,f,1), psthOpts.lineArgs{c}{:});
        end
        xlim([pOut.timeAxis{c}(1), pOut.timeAxis{c}(end)]);
        set(gca,'LineWidth',1.5,'FontSize',16);
        xlabel('Time (s)');
        ylabel([psthOpts.featLabels{f} ' Decoder Output']);
        ylim([-1 1]);
    end
    saveas(gcf,[outDir filesep 'bciToHeadDec.png'],'png');
    saveas(gcf,[outDir filesep 'bciToHeadDec.svg'],'svg');
    
    %%
    %make head movement decoder, apply it to BCI data
    %summarize with correlation vs. time, compare to real decoder output
    trlStart = 40:nBins:size(snippetMatrix,1);
    buildIdx = expandEpochIdx([trlStart', trlStart'+100]);
    headFilt = buildLinFilts(headDirMatrix(buildIdx,:), snippetMatrix(buildIdx,:), 'inverseLinear');
    
    %%
    [R_bci, model] = getSTanfordBG_RStruct( sessionPath, datasets{d,3} );
    data = unrollR_generic(R_bci, 20);
    normSpikes = data.spikes / 50;
    normSpikes = bsxfun(@plus, normSpikes, -mean(normSpikes));
    
    dec_BCI = model.K([2 4 6 8],1:192);
    dec_BCI = bsxfun(@times, dec_BCI, model.invSoftNormVals(1:192)');
    dec_BCI = 1000 * dec_BCI / (1-model.alpha) / model.beta;
    dec_BCI = dec_BCI * (15/20);
    
    headFilt = headFilt * (10/20);
    
    bciXY = normSpikes * dec_BCI(1:2,:)';
    headXY = normSpikes * headFilt;
    
    posErr = data.targetPos - data.cursorPos;
    corrVec_bci = zeros(100,2);
    corrVec_head = zeros(100,2);
    for t=1:100
        loopIdx = data.reachEvents(:,2) + t;

        corrVec_bci(t,1) = corr(bciXY(loopIdx,1), posErr(loopIdx,1));
        corrVec_bci(t,2) = corr(bciXY(loopIdx,2), posErr(loopIdx,2));

        corrVec_head(t,1) = corr(headXY(loopIdx,1), posErr(loopIdx,1));
        corrVec_head(t,2) = corr(headXY(loopIdx,2), posErr(loopIdx,2));
    end
    
    timeAxis = (1:100)*0.02;
    
    figure
    subplot(1,2,1);
    hold on
    plot(timeAxis, corrVec_bci(:,1),'LineWidth',2);
    plot(timeAxis, corrVec_head(:,1),'LineWidth',2);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (s)');
    ylabel('X Correlation');
    legend({'BCI Decoder','Head Movement Decoder'});
    
    subplot(1,2,2);
    hold on
    plot(timeAxis, corrVec_bci(:,2),'LineWidth',2);
    plot(timeAxis, -corrVec_head(:,2),'LineWidth',2);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (s)');
    ylabel('Y Correlation');
    legend({'BCI Decoder','Head Movement Decoder'});
    
    saveas(gcf,[outDir filesep 'headToBciDec.png'],'png');
    saveas(gcf,[outDir filesep 'headToBciDec.svg'],'svg');
    %%
    %TURN_HEAD_RIGHT(67)
    %TURN_HEAD_LEFT(71)
    %TURN_HEAD_UP(72)
    %TURN_HEAD_DOWN(73)
    
end
