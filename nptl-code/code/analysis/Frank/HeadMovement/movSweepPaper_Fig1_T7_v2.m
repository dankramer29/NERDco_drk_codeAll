%makeUniversalMovCueDatasets.m was used first to prepare the data

%%
rootDir = '/Users/frankwillett/Data/BG Datasets/movementSweepDatasets';
sessDir = [rootDir filesep 'processedDatasets'];
outDirRoot = '/Users/frankwillett/Data/Derived/movementSweepBrown/';
paths = getFRWPaths();
addpath(genpath(paths.codePath));
    
sessionList = {'t7.2013.08.23 Whole body cued movts, new cable (TOUCH)'};
for sessIdx=1:length(sessionList)
    load([sessDir filesep sessionList{sessIdx} '.mat']);
    
    %get sorted units
    sortedUnits = load([paths.dataPath filesep 'Derived' filesep 'sortedUnits' filesep sessionList{sessIdx} filesep 'alignedRaster.mat']);
    dataset.features.sorted = horzcat(sortedUnits.bothRasters{:});
    dataset.sortedList = vertcat(sortedUnits.bothUnitLists{:});
    dataset.sortedArrayNum = [ones(size(sortedUnits.bothUnitLists{1},1),1); ones(size(sortedUnits.bothUnitLists{2},1),1)+1];
    smoothSorted = gaussSmooth_fast(dataset.features.sorted, 3);
    
    %remove channels with low firing rate
    tooLowChans = find(mean(dataset.features.nsp_tx2)*50<1);
    
    %remove trials with no neural data
    remIdx = [];
    for t=1:length(dataset.goCueIdx)
        loopIdx = (-200:200)+dataset.goCueIdx(t);
        loopIdx(loopIdx<1) = [];
        loopIdx(loopIdx>length(dataset.features.nsp_sp))=[];
        if any(all(dataset.features.nsp_sp(loopIdx,:)==0,2))
            remIdx = [remIdx, t];
        end
    end
    dataset.goCueIdx(remIdx) = [];
    dataset.movCues(remIdx) = [];
    
    %make cue sets 
    if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        cueSets = {[1,2],[3,4],[5,6],[7,8],[9,10],[11,12],[13,14],[15,16],[17,18],[19,20],[21,22],[23,24],[25,26],[27,28],...
            [13,14,15,16,17,18,19,20,25,26,27,28],[13,15,17,19,25,28],[1,2,3,4,5,6,7,8,9,10,11,12]};
        psthSets = [18,16];
    end
    
    %convert all features to double precision
    featNames = fieldnames(dataset.features);
    for f=1:length(featNames)
        dataset.features.(featNames{f}) = double(dataset.features.(featNames{f}));
    end
    
    %mean-subract for each block
    blockList = unique(dataset.blockIdx);
    for b=1:length(blockList)
        loopIdx = find(dataset.blockIdx==blockList(b));
        firstGoCue = find(dataset.goCueIdx>loopIdx(1),1,'first');
        loopIdx = loopIdx(loopIdx>dataset.goCueIdx(firstGoCue));
        
        for f=1:length(featNames)
            dataset.features.(featNames{f})(loopIdx,:) = dataset.features.(featNames{f})(loopIdx,:)-mean(dataset.features.(featNames{f})(loopIdx,:));
        end
    end
    
    %z-score all features
    for f=1:length(featNames)
        dataset.features.(featNames{f}) = zscore(dataset.features.(featNames{f}));
    end
    
    %smooth features
    if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        high_TX = dataset.features.nsp_tx2;
        high_TX(:,tooLowChans) = [];
        highChans = setdiff(1:192, tooLowChans);
        
        neuralFeatures = gaussSmooth_fast(high_TX, 3);
        unsmoothedFeatures = high_TX;
    end
    
    %%
    %make data for bar plot
    cVar = zeros(length(cueSets),5);
    rawProjPoints = cell(length(cueSets),2);
    movWindow = [10, 80];
    
    for setIdx=1:14
        trlIdx_1 = find(ismember(dataset.movCues, cueSets{setIdx}(1)));
        trlIdx_2 = find(ismember(dataset.movCues, cueSets{setIdx}(2)));
        
        trls_1 = triggeredAvg(high_TX, dataset.goCueIdx(trlIdx_1), movWindow);
        trls_2 = triggeredAvg(high_TX, dataset.goCueIdx(trlIdx_2), movWindow);
        
        trls_1 = squeeze(nanmean(trls_1,2));
        trls_2 = squeeze(nanmean(trls_2,2));
        
        minLen = min(size(trls_1,1), size(trls_2,1));
        trls_1 = trls_1(1:minLen,:);
        trls_2 = trls_2(1:minLen,:);
        
        dataMatrix = [trls_1; trls_2];
        dataLabels = [ones(size(trls_1,1),1); ones(size(trls_2,1),1)+1];
        
        nResample = 1000;

        %population distance metric
        testStat = lessBiasedDistance( trls_1, trls_2 );
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = lessBiasedDistance(dataMatrix(shuffLabels==2,:), dataMatrix(shuffLabels==1,:)); 
        end

        cVar(setIdx,1) = testStat;
        cVar(setIdx,2) = prctile(resampleVec,99);

        %[ci,bootstats] = bootci(nResample, {@lessBiasedDistance, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)});
        %cVar(setIdx,3:4) = ci;    
        
        ci = jackCI_full( testStat, @lessBiasedDistance, {dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)} );
        cVar(setIdx,3:4) = ci; 

        %cross-validated projection     
        [~, rawProjPoints{setIdx,1}, rawProjPoints{setIdx,2}] = projStat_cv_paper(dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:), testStat);
    end
    
    %%
    %bar plot with raw points
    cueSets_large = {[9:10], [7:8], [1:6], [13:14]};
    movLabels = {'Hand Open/Close','Wrist Flex/Ext','Wrist Pro/Sup','Elbow Flex/Ext',...
        'Sho Flex/Ext','Sho Ab/Add','Head Down/Up','Head Left/Right',...
        'Smile/Frown','Tongue Out/In','Eyes Up/Down','Eyes Left/Right',...
        'Hip Ext/Flex','Ankle Ext/Flex'};
    allCues = horzcat(cueSets_large{:});

    singleTrialBarPlot( cueSets_large, rawProjPoints, cVar, movLabels(allCues) );
    set(gcf,'Position',[873   406   394   338]);
    axis tight;
    
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'bar_fullActivity.png'],'png');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep  'bar_fullActivity.svg'],'svg');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep  'bar_fullActivity.pdf'],'pdf');
    
    %%
    %modulation size relative to arm
    avgArm = mean(cVar(1:6,1));
    mean(cVar(1:6,1)/avgArm)
    mean(cVar(7:8,1)/avgArm)
    mean(cVar(9:10,1)/avgArm)
    mean(cVar(13:14,1)/avgArm)
    
    %%
    %correlation matrix
    effSets = {1:12, 13:16, 17:20, 21:24, 25:28};
    boxSets = {1:12, 13:16, 17:20, 21:24, 25:28};
   
    timeWindow = [0, 100];
    dPCA_out = apply_dPCA_simple( neuralFeatures, dataset.goCueIdx, ...
        dataset.movCues, timeWindow, 0.02, {'CD','CI'} );
    close all;
    
    simMatrix = plotCorrMat_cv( dPCA_out.featureVals(:,:,:,1:18), 10:80, dataset.cueLabels, effSets, boxSets );
    
    %%
    %arm vs. leg correlations
    testEntries = [9,10,3,4,25,26,27,28];   
    cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

    figure
    imagesc(simMatrix(testEntries,testEntries),[-1 1]);
    colormap(cMap);
    set(gca,'XTick',1:length(testEntries),'XTickLabel',dataset.cueLabels(testEntries),'XTickLabelRotation',45);
    set(gca,'YTick',1:length(testEntries),'YTickLabel',dataset.cueLabels(testEntries));
    set(gca,'FontSize',16);
    set(gca,'YDir','normal');
    colorbar;

    tmp = simMatrix(testEntries,testEntries);
    
    figure('Position',[68   728   306   228]);
    imagesc(tmp(1:4,5:8),[-0.5 0.5]);
    colormap(cMap);
    set(gca,'XTick',1:4,'XTickLabel',dataset.cueLabels(testEntries(5:8)),'XTickLabelRotation',45);
    set(gca,'YTick',1:4,'YTickLabel',dataset.cueLabels(testEntries(1:4)));
    set(gca,'FontSize',16);
    set(gca,'YDir','normal');
    colorbar;
    
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'corrMat.png'],'png');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'corrMat.svg'],'svg');
    
    reducedMat = simMatrix(testEntries,testEntries);
    reducedMat = reducedMat(1:4,5:end);
    
    diagEntries = 1:(size(reducedMat,1)+1):numel(reducedMat);
    otherEntries = setdiff(1:numel(reducedMat), diagEntries);    
    
    anova1([reducedMat(diagEntries)'; reducedMat(otherEntries)'], ...
        [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);
    
    figure('Position',[680   866   391   232]);
    subplot(1,2,1);
    hold on
    plot((rand(length(diagEntries),1)-0.5)*0.55, reducedMat(diagEntries), 'o');
    plot(1 + (rand(length(otherEntries),1)-0.5)*0.55, reducedMat(otherEntries), 'ro');
    set(gca,'XTick',[0 1],'XTickLabel',{'Matched','Different'},'XTickLabelRotation',45);
    ylim([-0.5, 0.5]);
    ylabel('Correlation');
    set(gca,'FontSize',20,'LineWidth',2);
    xlim([-0.5,1.5]);
    title('Arm vs. Leg','FontSize',18);

    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'corrDots.png'],'png');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'corrDots.svg'],'svg');
        
    %%
    %single unit & TX significance counting
    featType = {high_TX, dataset.features.sorted};
    pValAll = cell(2,1);
    modSDAll = cell(2,1);
    
    for featIdx=1:length(featType)
        movTypeText = {'Face','Neck','Arm','Leg'};
        codeSetPair = {[17 18 19 20], [13 14 15 16], 1:12, [25 26 27 28]};
        timeWindow = [-150, 200];

        dPCA_out = cell(length(codeSetPair),1);
        for pIdx=1:length(codeSetPair)
            trlIdx = find(ismember(dataset.movCues, codeSetPair{pIdx}));
            trlShuff = trlIdx(randperm(length(trlIdx)));
            dPCA_out{pIdx} = apply_dPCA_simple( featType{featIdx}, dataset.goCueIdx(trlIdx), ...
                dataset.movCues(trlIdx), timeWindow, 0.02, {'CD','CI'}, 20);
            close(gcf);
        end

        nUnits = size(dPCA_out{1}.featureAverages,1);
        pVal = zeros(nUnits, length(codeSetPair));
        modSD = zeros(nUnits, length(codeSetPair));

        timeOffset = -timeWindow(1);
        movWindow = (10:80);

        for pIdx = 1:length(codeSetPair)    
            for unitIdx=1:size(dPCA_out{pIdx}.featureAverages,1)
                unitAct = squeeze(dPCA_out{pIdx}.featureVals(unitIdx,:,movWindow+timeOffset,:));
                meanAcrossTrial = squeeze(nanmean(unitAct,3))';
                meanAct = squeeze(nanmean(unitAct,2))';

                pVal(unitIdx, pIdx) = anova1(meanAct,[],'off');
                modSD(unitIdx, pIdx) = nanstd(mean(meanAcrossTrial));
            end
        end    
        
        pValAll{featIdx} = pVal;
        modSDAll{featIdx} = modSD;
    end
    
    %%
    %PSTHS
    featType = {gaussSmooth_fast(high_TX,3), gaussSmooth_fast(dataset.features.sorted,3)};
    featName = {'TX','Sorted'};
    
    for featIdx=1:length(featType)
        cueList = unique(dataset.movCues);
        lineArgs = cell(length(cueList),1);
        twoColors = [0.8 0 0; 0 0 0.8];
        colors = [];

        altIdx = 1;
        for x=1:length(cueList)
            lineArgs{x} = {'LineWidth',1,'Color',twoColors(altIdx,:)};
            colors = [colors; twoColors(altIdx,:)];

            if altIdx==1
                altIdx=2;
            else
                altIdx=1;
            end
        end

        psthOpts = makePSTHOpts();
        psthOpts.gaussSmoothWidth = 0;
        psthOpts.neuralData = featType(featIdx);
        psthOpts.timeWindow = [-150, 150];
        psthOpts.trialEvents = dataset.goCueIdx;
        psthOpts.trialConditions = dataset.movCues;
        psthOpts.conditionGrouping = {17:18, 19:20, 13:14, 15:16, 1:2, 3:4, 5:6, 7:8, 9:10, 11:12, 25:26, 27:28};
        psthOpts.lineArgs = lineArgs;

        psthOpts.plotsPerPage = 10;
        psthOpts.plotDir = [outDirRoot sessionList{sessIdx}];

        featLabels = cell(size(featType{featIdx},2),1);
        if strcmp(featName{featIdx},'Sorted')
            for f=1:length(featLabels)
                featLabels{f} = num2str([num2str(dataset.sortedArrayNum(f)) ' - ' num2str(dataset.sortedList(f,1)) ' - ' num2str(dataset.sortedList(f,2))]);
            end        
        else
            for f=1:length(featLabels)
                featLabels{f} = num2str(highChans(f));
            end
        end
        psthOpts.featLabels = featLabels;

        psthOpts.prefix = 'all';
        psthOpts.plotCI = 1;
        psthOpts.CIColors = colors;

        makePSTH_simple(psthOpts);

        close all;
    end
   
    %%
    %decoding
    cueSets_large = {[9:10], [7:8], [1:6], [13:14]};
    movLabels = {'Hand Open/Close','Wrist Flex/Ext','Wrist Pro/Sup','Elbow Flex/Ext',...
        'Sho Flex/Ext','Sho Ab/Add','Head Down/Up','Head Left/Right',...
        'Smile/Frown','Tongue Out/In','Eyes Up/Down','Eyes Left/Right',...
        'Hip Ext/Flex','Ankle Ext/Flex'};
    
    windowIdx = 10:40;
    windowIdx2 = 41:80;
    decDataset = dataset;
    eyeTrials = find(ismember(dataset.movCues, 21:24));
    decDataset.goCueIdx(eyeTrials) = [];
    decDataset.movCues(eyeTrials) = [];
    decDataset.cueLabels = {'HandOpen','HandClose','WristFlex','WristExt','WristPro','WristSup',...
        'ElbowFlex','ElbowExt','ShoFlex','ShoExt','ShoAb','ShoAdd','HeadDown','HeadUp',...
        'HeadLeft','HeadRight','Smile','Frown','TongueOut','TongueIn','EyesUp','EyesDown','EyesLeft',...
        'EyesRight','HipExt','HipFlex','AnkleExt','AnkleFlex'};
    decDataset.cueLabels(21:24) = [];
    decDataset.cueOrdering = [17:20, 13:16, 1:12, 21:24];

    allFeatures = [];
    allCodes = [];
    for trlIdx=1:length(decDataset.goCueIdx)
        loopIdx = windowIdx + decDataset.goCueIdx(trlIdx);
        loopIdx2 = windowIdx2 + decDataset.goCueIdx(trlIdx);
        allFeatures = [allFeatures; mean(neuralFeatures(loopIdx,:)), mean(neuralFeatures(loopIdx2,:))];
        allCodes = [allCodes; decDataset.movCues(trlIdx)];
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
        [PHAT, PCI] = binofit(C_counts(r,r),sum(C_counts(r,:)),0.05); 
        disp(decDataset.cueLabels(r));
        disp(PCI);
    end
    
    figure('Position',[680   616   642   482]); 
    imagesc(C(decDataset.cueOrdering, decDataset.cueOrdering));
    set(gca,'XTick',1:length(C),'XTickLabel',decDataset.cueLabels(decDataset.cueOrdering),'XTickLabelRotation',45);
    set(gca,'YTick',1:length(C),'YTickLabel',decDataset.cueLabels(decDataset.cueOrdering));
    title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
    set(gca,'FontSize',16);
    set(gca,'YDir','normal');
    colormap(parula);
    colorbar;
        
    colorSetIdx = {1:4, 5:8, 9:20, 21:24};
    colors = [173,150,61;
    119,122,205;
    91,169,101;
    197,90,159;
    202,94,74]/255;

    currentColor = 1;
    for c=1:length(colorSetIdx)
        newIdx = colorSetIdx{c};
        rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(c,:));
    end
    axis tight;
    
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'discreteDecodeAll.png'],'png');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'discreteDecodeAll.svg'],'svg');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'discreteDecodeAll.pdf'],'pdf');
    
    %%
    %mPCA to find dimensions of the movement marginalization
    margGroupings = {{1, [1 2]}, {2}};
    margNames = {'Movement', 'Time'};
    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 5;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'pcaAxes';
    opts_m.alignMode = 'rotation';
    opts_m.plotCI = true;

    binMS = 20;
    cueSets_large = {[17:20], [13:16], [1:12], [25:28]};
    timeWindow = [-149, 149];
    mPCA_out = cell(length(cueSets_large),1);
    for setIdx=1:length(cueSets_large)
        trlIdx = find(ismember(dataset.movCues, cueSets_large{setIdx}));
        mc = dataset.movCues(trlIdx);
        [~,~,mcOneBased] = unique(mc);

        mPCA_out{setIdx} = apply_mPCA_general( neuralFeatures, dataset.goCueIdx(trlIdx), ...
            mcOneBased, timeWindow, binMS/1000, opts_m );
        close all;
    end
    
    %%
    %plot example mPCA dims
    binMS = 20;
    timeAxis = (timeWindow(1):timeWindow(2))*(binMS/1000);
    axHandles = [];
    yLims = [];
    nAx = 3;
    movTypeText = {'Face','Neck','Arm','Leg'};

    figure('Position',[71   122   806   806]);
    for pIdx=1:length(movTypeText)
        for axIdx=1:nAx
            cdIdx = find(mPCA_out{pIdx}.whichMarg==1);
            ax = subtightplot(4,length(movTypeText),length(movTypeText)*(axIdx-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
            axHandles = [axHandles; ax];
            hold on

            colors = jet(size(mPCA_out{pIdx}.Z,2))*0.8;
            lineHandles = zeros(size(mPCA_out{pIdx}.Z,2),1);
            for conIdx=1:size(mPCA_out{pIdx}.Z,2)
                lineHandles(conIdx) = plot(timeAxis, squeeze(mPCA_out{pIdx}.Z(cdIdx(axIdx),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                errorPatch( timeAxis', squeeze(mPCA_out{pIdx}.margResample.CIs(cdIdx(axIdx),conIdx,:,:)), colors(conIdx,:), 0.2 );
            end

            axis tight;
            yLims = [yLims; get(gca,'YLim')];
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
        end

        subtightplot(4,length(movTypeText),length(movTypeText)*(4-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
        hold on;
        lineHandles = zeros(size(mPCA_out{pIdx}.Z,2),1);
        for conIdx=1:size(mPCA_out{pIdx}.Z,2)
            lineHandles(conIdx) = plot(0,0,'LineWidth',2,'Color',colors(conIdx,:));
        end

        lHandle = legend(lineHandles, dataset.cueLabels(cueSets_large{pIdx}),'Location','South','box','off','FontSize',10);
        lPos = get(lHandle,'Position');
        lPos(1) = lPos(1)+0.05;
        set(lHandle,'Position',lPos);
        axis off
    end

    finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
    for p=1:length(axHandles)
        set(axHandles(p), 'YLim', finalLimits);
        plot(axHandles(p),[0, 0],finalLimits*0.9,'--k','LineWidth',2);
    end

    set(gcf,'Renderer','painters');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'mPCA_exampleDims_ax.png'],'png');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'mPCA_exampleDims_ax.svg'],'svg');
end

