%%
datasets = {
    't5.2019.01.07',{[8 14 15 19 22],[6 13 16 18 23],[7 12 17 20 21]},{'Single_Radial16','Dual_Radial8','Quad_Radial4'};
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    allStats = cell(length(datasets{d,2}),3);
    accStats = zeros(length(datasets{d,2}),3);
    
    allStats_meanSub = cell(length(datasets{d,2}),3);
    accStats_meanSub = zeros(length(datasets{d,2}),3);
    
    for blockSetIdx=1:length(datasets{d,2})
        disp(['Set ' num2str(blockSetIdx)]);
        
        clear allR;
        
        bNums = horzcat(datasets{d,2}{blockSetIdx});
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
        filtOpts.filtCutoff = 10/500;
        R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{blockSetIdx}), 4.5, datasets{d,2}{blockSetIdx}(1), filtOpts );

        allR = []; 
        for x=1:length(R)
            for t=1:length(R{x})
                R{x}(t).blockNum=bNums(x);
                R{x}(t).tPosLoop = repmat(R{x}(t).posTarget(1:2),1,length(R{x}(t).stateTimer));
            end
            allR = [allR, R{x}];
        end
        clear R;

        targPos = horzcat(allR.posTarget)';
        [targList, ~, targCodes] = unique(targPos, 'rows');
        targList(:,2) = -targList(:,2);
        
        centerCode = find(all(targList==0,2) | targList(:,4)~=0);
        if ~isempty(centerCode)
            useTrl = find(~ismember(targCodes,centerCode));
        else
            useTrl = 1:length(targCodes);
        end
        
        noGoCue = false(size(allR));
        for t=1:length(allR)
            if isempty(allR(t).timeGoCue)
                noGoCue(t) = true;
            end
        end
        useTrl = setdiff(useTrl, find(noGoCue));
        
        %%        
        alignFields = {'timeGoCue'};
        smoothWidth = 0;
        datFields = {'windowsMousePosition','windowsMousePosition_speed'};
        timeWindow = [-1000,2000];
        binMS = 20;
        alignDat = binAndAlignR( allR(useTrl), timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 1.0;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        alignDat.rawSpikes = alignDat.rawSpikes * 50;
        
        %%
        %get mean rates for each trial in the appropriate window
        concatDat = triggeredAvg(alignDat.rawSpikes, alignDat.eventIdx, [15,50]);
        avgRate = squeeze(mean(concatDat,2));
        tCodes = targCodes(useTrl);
        tCodeList = unique(tCodes);
        
        %split the data into 16 cells, one for each target
        dataCell = cell(length(tCodeList),1);
        numTrialsPerTarg = zeros(length(tCodeList),1);
        for t=1:length(tCodeList)
            trlIdx = find(tCodes==tCodeList(t));
            dataCell{t} = avgRate(trlIdx,:);
            numTrialsPerTarg(t) = length(trlIdx);
        end
        
        %trim to have same number of samples b/c bootci is picky
        minSamples = min(numTrialsPerTarg);
        for t=1:length(tCodeList)
            dataCell{t} = dataCell{t}(1:minSamples,:);
        end
        
        %bootstrap resample
        sampleEst = minDistAndDimBootFun(dataCell{:});
        
        nBoot = 1000;
        [CI,bootstat] = bootci(nBoot,{@minDistAndDimBootFun,dataCell{:}});
        
        %I noticed that for some of the statistics, the bootstrapped
        %distribution is biased and the sample statistic lies outside of
        %it. In this case, the CI that bootci returns is way too small.
        %bootci can only handle mild bias. So I think its best to just
        %artificially recenter the CIs. It's not perfect but I don't know
        %how to get a CI otherwise. 
        CI_centered = prctile(bootstat,[2.5,50,97.5]);
        CI_centered = sampleEst+CI_centered([1 3],:)-CI_centered(2,:);
        
        allStats{blockSetIdx,1} = sampleEst;
        allStats{blockSetIdx,2} = CI_centered;
        allStats{blockSetIdx,3} = CI;
        
        %%
        %get mean and CI for accuracy of cross-validated naive bayes decoding
        obj = fitcdiscr(avgRate,tCodes,'DiscrimType','diaglinear');
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);
        nClasses = length(tCodeList);
        predLabels = kfoldPredict(cvmodel);
        
        [accStats(blockSetIdx,1), accStats(blockSetIdx,2:3)] = binofit(sum(predLabels==tCodes),length(tCodes));
        
        %%
        %subtract effector-specific means
        tList = unique(targCodes);
        figure
        hold on
        for x=1:length(tList)
            text(targList(tList(x),1), targList(tList(x),2), num2str(tList(x)));
        end
        xlim([-1200,1200]);
        ylim([-1200,1200]);
        
        if strfind(datasets{d,3}{blockSetIdx}, 'Dual_Radial8')
            targLayout = targList(:,1:2);
            targLayout(1:8,:) = targLayout(1:8,:) - mean(targLayout(1:8,:));
            targLayout(1:8,:) = targLayout(1:8,:)./matVecMag(targLayout(1:8,:),2);
            targLayout(9:16,:) = targLayout(9:16,:) - mean(targLayout(9:16,:));
            targLayout(9:16,:) = targLayout(9:16,:)./matVecMag(targLayout(9:16,:),2);
            
            codeSets = {[1 3 5 7 8 6 4 2],[9 11 13 15 16 14 12 10]};
            taskType='Dual';
            idxSets = codeSets;
            
        elseif strfind(datasets{d,3}{blockSetIdx}, 'Quad_Radial4')
            idxSets = {[1 4 7 3],[2 6 8 5],[11 15 17 14],[10 13 16 12]};
        elseif strfind(datasets{d,3}{blockSetIdx}, 'Single_Radial16')
            targLayout = targList(:,1:2);
            
            idxSets = {[15 19 23 24 20 16],[1 5 9 10 6 2],[17 21 25 26 22 18],[3 7 11 12 8 4]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
            taskType='Quad';
        end
        
        meanSubtractedRate = avgRate;
        for setIdx=1:length(idxSets)
            trlIdx = find(ismember(tCodes, idxSets{setIdx}));
            meanSubtractedRate(trlIdx,:) = meanSubtractedRate(trlIdx,:) - mean(avgRate(trlIdx,:));
        end
        
        obj = fitcdiscr(meanSubtractedRate,tCodes,'DiscrimType','diaglinear');
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);
        nClasses = length(tCodeList);
        predLabels = kfoldPredict(cvmodel);
        
        [accStats_meanSub(blockSetIdx,1), accStats_meanSub(blockSetIdx,2:3)] = binofit(sum(predLabels==tCodes),length(tCodes));
        
        %split the data into 16 cells, one for each target
        dataCell = cell(length(tCodeList),1);
        numTrialsPerTarg = zeros(length(tCodeList),1);
        for t=1:length(tCodeList)
            trlIdx = find(tCodes==tCodeList(t));
            dataCell{t} = meanSubtractedRate(trlIdx,:);
            numTrialsPerTarg(t) = length(trlIdx);
        end
        
        %trim to have same number of samples b/c bootci is picky
        minSamples = min(numTrialsPerTarg);
        for t=1:length(tCodeList)
            dataCell{t} = dataCell{t}(1:minSamples,:);
        end
        
        %bootstrap resample
        sampleEst = minDistAndDimBootFun(dataCell{:});
        
        nBoot = 1000;
        [CI,bootstat] = bootci(nBoot,{@minDistAndDimBootFun,dataCell{:}});
        CI_centered = prctile(bootstat,[2.5,50,97.5]);
        CI_centered = sampleEst+CI_centered([1 3],:)-CI_centered(2,:);
        
        allStats_meanSub{blockSetIdx,1} = sampleEst;
        allStats_meanSub{blockSetIdx,2} = CI_centered;
        allStats_meanSub{blockSetIdx,3} = CI;
    end %block set
    
    %%
    %scree
    colors = jet(3)*0.8;
    
    figure('Position',[680   833   391   265]);
    hold on
    for t=1:size(allStats,1)
        lHandles(t)=plot(allStats{t,1}(18:end),'LineWidth',2,'Color',colors(t,:));
        errorPatch( (1:10)', allStats{t,2}(:,18:end)', colors(t,:), 0.2 );
    end
    ylim([0,100]);
    legend(lHandles,{'Single Radial 16','Dual Radial 8','Quad Radial 4'});
    set(gca,'FontSize',16);
    xlabel('# of Dimensions');
    ylabel('Cumulative Variance\newlineExplained (%)');
    xlim([1 10]);
    
    saveas(gcf,[outDir filesep 'scree.fig'],'fig');
    saveas(gcf,[outDir filesep 'scree.svg'],'svg');
    saveas(gcf,[outDir filesep 'scree.png'],'png');
    
    %%
    %min dist
    figure('Position',[680   873   217   225]);
    hold on;
    bar([allStats{1,1}(1), allStats{2,1}(1), allStats{3,1}(1)],'FaceColor','w','LineWidth',2);
    for t=1:3
        jitterX = (rand(16,1)-0.5)*0.2;
        plot(t+jitterX,allStats{t,1}(2:17),'ko','MarkerSize',6,'Color',[0.7 0.7 0.7]);
        errorbar(t, allStats{t,1}(1), allStats{t,1}(1)-allStats{t,2}(1,1), allStats{t,2}(2,1)-allStats{t,1}(1), 'k', 'LineWidth',2);
    end

    xlim([0.5,3.5]);
    set(gca,'FontSize',16);
    set(gca,'XTick',[1 2 3],'XTickLabel',{'Single 16','Dual 8','Quad 4'},'XTickLabelRotation',45);
    ylabel('Distance to \newlineClosest Neighbor (Hz)');
    
    saveas(gcf,[outDir filesep 'minDist.fig'],'fig');
    saveas(gcf,[outDir filesep 'minDist.svg'],'svg');
    saveas(gcf,[outDir filesep 'minDist.png'],'png');

    %%
    %accuracy
    figure('Position',[680   873   217   225]);
    hold on;
    bar(accStats(:,1),'FaceColor','w','LineWidth',2);
    for t=1:3
        errorbar(t, accStats(t,1), accStats(t,1)-accStats(t,2), accStats(t,3)-accStats(t,1), 'k', 'LineWidth',2);
    end

    xlim([0.5,3.5]);
    set(gca,'FontSize',16);
    set(gca,'XTick',[1 2 3],'XTickLabel',{'Single 16','Dual 8','Quad 4'},'XTickLabelRotation',45);
    ylabel('Offline Decoding\newlineAccuracy');
    
    saveas(gcf,[outDir filesep 'acc.fig'],'fig');
    saveas(gcf,[outDir filesep 'acc.svg'],'svg');
    saveas(gcf,[outDir filesep 'acc.png'],'png');
    
end %datasets