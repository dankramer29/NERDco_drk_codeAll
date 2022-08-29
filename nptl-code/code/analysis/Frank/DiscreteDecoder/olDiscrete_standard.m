%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.08.20',{[11 12 13],[15],[18 19 20],[21,22,23]},{'Quad_Radial4_Slow','Quad_Radial4_Fast','Quad_Radial8_Slow','Quad_Radial8_Fast'};
    't5.2018.08.22',{[3],[7 8 9],[14],[17 18]},{'Radial8_650','Radial8_1000','Radial8_800','DualJoystick_800'};
    't5.2018.08.27',{[1 3 5],[9,11,12,13,14,15,16],[20 21],[22 23]},{'DualJoystick_800','CardinalJoint32_Delay','RightFoot_Radial8_Delay','Tongue_Radial8_Delay'};
    't5.2018.08.29',{[1 2 3],[4,5,6],[7,8,9],[10,11,12],[16,17,18],[19,20,21]},{'RightHand','LeftHand','RightFoot','LeftFoot','Head','Tongue'};
    't5.2018.09.05',{[3],[5],[6]},{'OLJoy1','CLJoy1','OLJoy2'};
};

%%
for d=5:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    for blockSetIdx=1:length(datasets{d,2})
    %for blockSetIdx=7
        clear allR;
        
        bNums = horzcat(datasets{d,2}{blockSetIdx});
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
        filtOpts.filtCutoff = 10/500;
        R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{blockSetIdx}), 3.5, datasets{d,2}{blockSetIdx}(1), filtOpts );

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

        centerCode = find(all(targList==0,2) | targList(:,4)~=0);
        if ~isempty(centerCode)
            useTrl = find(targCodes~=centerCode);
        else
            useTrl = 1:length(targCodes);
        end
        
        %%        
        alignFields = {'timeGoCue'};
        smoothWidth = 0;
        datFields = {'windowsMousePosition','windowsMousePosition_speed'};
        timeWindow = [-1000,2000];
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);
        
        %%
        %single-factor
%         dPCA_out = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(useTrl), ...
%             targCodes(useTrl), timeWindow/binMS, binMS/1000, {'CD','CI'} );
%         
%         codeList = unique(targCodes(useTrl));
%         lineArgs = cell(length(codeList),1);
%         colors = jet(length(lineArgs))*0.8;
%         for l=1:length(lineArgs)
%             lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
%         end
%         
%         %legIdx = [2,5,6,8,10,13,14,15];
%         %for l=1:length(legIdx)
%         %    lineArgs{legIdx(l)}{end+1}='LineStyle';
%         %    lineArgs{legIdx(l)}{end+1}=':';
%         %end
%         
%         oneFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
%             lineArgs, {'CD','CI'}, 'sameAxes');
%         saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.png'],'png');
%         saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.svg'],'svg');

        %%  
        %single bin classifier
        trialLens = zeros(length(useTrl),1);
        for x=1:length(useTrl)
            trialLens(x) = allR(useTrl(x)).trialLength;
        end
        avgTrialLen = mean(trialLens)/1000;
        
        windowBinList = 5:5:150;
        skipBinList = 0:5:50;
        bitrate = zeros(length(windowBinList), length(skipBinList));
        accuracy = zeros(length(windowBinList), length(skipBinList));

        for windowIdx=1:length(windowBinList)
            disp(windowIdx);
            for skipIdx=1:length(skipBinList)
                disp(skipIdx);

                allFeatures = [];
                allCodes = [];
                nBins = windowBinList(windowIdx);
                skipBins = skipBinList(skipIdx);
                
                if nBins+skipBins>(avgTrialLen*50)
                    continue;
                end

                for outerIdx = 1:length(useTrl)
                    trlIdx = useTrl(outerIdx);
                    loopIdx = (alignDat.eventIdx(trlIdx)+skipBins):((alignDat.eventIdx(trlIdx)+skipBins+nBins));
                    if any(loopIdx<1 | loopIdx>length(alignDat.meanSubtractSpikes))
                        continue;
                    end
                    
                    newData = mean(alignDat.meanSubtractSpikes(loopIdx,:));

                    allFeatures = [allFeatures; newData];
                    allCodes = [allCodes; targCodes(trlIdx)];
                end

                nClasses = length(unique(allCodes));

                obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
                cvmodel = crossval(obj);
                L = kfoldLoss(cvmodel);
                predLabels = kfoldPredict(cvmodel);

                nTrials = length(allCodes);
                bitrate(windowIdx, skipIdx) = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*avgTrialLen);
                accuracy(windowIdx, skipIdx) = 1-L;
            end
        end

        windowBinList_str = cell(size(windowBinList));
        for x=1:length(windowBinList_str)
            windowBinList_str{x} = num2str(windowBinList(x)*0.02);
        end

        skipBinList_str = cell(size(skipBinList));
        for x=1:length(skipBinList)
            skipBinList_str{x} = num2str(skipBinList(x)*0.02);
        end

        [~, maxIdx] = max(bitrate(:));
        [bestWindowIdx, bestSkipIdx] = ind2sub(size(bitrate), maxIdx);
        
        figure('Position',[153         526        1602         415]);
        subplot(1,2,1);
        hold on;
        imagesc(bitrate');
        plot(bestWindowIdx, bestSkipIdx, 'kx', 'MarkerSize', 12, 'LineWidth', 2);
        set(gca,'XTick',1:length(windowBinList_str),'XTickLabel',windowBinList_str,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(skipBinList_str),'YTickLabel',skipBinList_str);
        colorbar;
        xlabel('Window Length');
        ylabel('Skip Interval');
        set(gca,'FontSize',16);
        title(['Achieved Bit Rate (max=' num2str(max(bitrate(:))) '), trialLen=' num2str(avgTrialLen)]);
        axis tight;
        
        [~, maxIdx] = max(accuracy(:));
        [bestWindowIdx, bestSkipIdx] = ind2sub(size(accuracy), maxIdx);
        
        subplot(1,2,2);
        hold on;
        imagesc(accuracy');
        plot(bestWindowIdx, bestSkipIdx, 'kx', 'MarkerSize', 12, 'LineWidth', 2);
        set(gca,'XTick',1:length(windowBinList_str),'XTickLabel',windowBinList_str,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(skipBinList_str),'YTickLabel',skipBinList_str);
        colorbar;
        xlabel('Window Length');
        ylabel('Skip Interval');
        set(gca,'FontSize',16);
        title(['Accuracy (max=' num2str(max(accuracy(:))) '), trialLen=' num2str(avgTrialLen)]);
        axis tight;

        saveas(gcf,[outDir filesep 'linearClassifier_sweep_' datasets{d,3}{blockSetIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'linearClassifier_sweep_' datasets{d,3}{blockSetIdx} '.svg'],'svg');

        %%
        [bestBitRate, maxIdx] = max(accuracy(:));
        [bestWindowIdx, bestSkipIdx] = ind2sub(size(bitrate), maxIdx);
        
        allFeatures = [];
        allCodes = [];
        nBins = windowBinList(bestWindowIdx);
        skipBins = skipBinList(bestSkipIdx);

        for outerIdx = 1:length(useTrl)
            trlIdx = useTrl(outerIdx);
            loopIdx = (alignDat.eventIdx(trlIdx)+skipBins):((alignDat.eventIdx(trlIdx)+skipBins+nBins));
            if any(loopIdx<1 | loopIdx>length(alignDat.meanSubtractSpikes))
                continue;
            end
                    
            newData = mean(alignDat.meanSubtractSpikes(loopIdx,:));

            allFeatures = [allFeatures; newData];
            allCodes = [allCodes; targCodes(trlIdx)];
        end

        nClasses = length(unique(allCodes));

        obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);
        predLabels = kfoldPredict(cvmodel);

        C = confusionmat(allCodes, predLabels);

        nTrials = length(allCodes);
        bestBitrate = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*avgTrialLen);

        movLabels = cell(size(C,1),1);
        for m=1:size(C,1)
            movLabels{m} = num2str(m);
        end

        figure('Position',[680         275        1112         823]);
        imagesc(C);
        set(gca,'XTick',1:length(allCodes),'XTickLabel',movLabels,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(allCodes),'YTickLabel',movLabels);
        set(gca,'FontSize',14);
        colorbar;
        title(['X-Validated Accuracy: ' num2str(1-L,3) ', bit rate: ' num2str(bestBitrate)]);

        saveas(gcf,[outDir filesep 'linearClassifier_C_' datasets{d,3}{blockSetIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'linearClassifier_C_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
        
        %%
        %table entry
        tableRow = [bestBitrate, 1-L, skipBins/50, nBins/50, avgTrialLen];
        header = {'Bit Rate','Accuracy','Skip Time','Integration Time','Trial Length'};
        save([outDir filesep datasets{d,3}{blockSetIdx} '_table.mat'],'tableRow');
        
%         %%
%         %target legend
%         useList = targList(setdiff(1:size(targList,1), centerCode),:);
%         
%         figure
%         hold on
%         for x=1:size(useList,1)
%             text(useList(x,1), useList(x,2), num2str(x), 'FontSize', 12);
%         end
%         set(gca,'YDir','reverse')
%         xlim([-700,700]);
%         ylim([-700,700]);
%         axis equal;
%         
%         saveas(gcf,[outDir filesep 'targetLegend_' datasets{d,3}{blockSetIdx} '.png'],'png');
%         saveas(gcf,[outDir filesep 'targetLegend_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
%         
%         %%
%         %target legend color cues
%         figure
%         hold on
%         for x=1:size(useList,1)
%             plot(useList(x,1), useList(x,2),'o', 'MarkerSize',20,'MarkerFaceColor',colors(x,:),'Color',colors(x,:));
%         end
%         set(gca,'YDir','reverse')
%         xlim([-700,700]);
%         ylim([-700,700]);
%         axis equal;
%         
%         saveas(gcf,[outDir filesep 'targetLegendColor_' datasets{d,3}{blockSetIdx} '.png'],'png');
%         saveas(gcf,[outDir filesep 'targetLegendColor_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
%         
%         close all;
    end
end

%%
%table
datasets = {
    't5.2018.08.20',{[11 12 13],[15],[18 19 20],[21,22,23]},{'Quad_Radial4_Slow','Quad_Radial4_Fast','Quad_Radial8_Slow','Quad_Radial8_Fast'};
    't5.2018.08.22',{[3],[7 8 9],[14],[17 18]},{'Radial8_650','Radial8_1000','Radial8_800','DualJoystick_800'};
    't5.2018.08.27',{[1 3 5],[9,11,12,13,14,15,16],[20 21],[22 23]},{'DualJoystick_800','CardinalJoint32_Delay','RightFoot_Radial8_Delay','Tongue_Radial8_Delay'};
    't5.2018.09.05',{[3],[5],[6]},{'OLJoy1','CLJoy1','OLJoy2'};
};

allDat = [];
allRowNames = [];

for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    for blockSetIdx=1:length(datasets{d,2})
        load([outDir filesep datasets{d,3}{blockSetIdx} '_table.mat'],'tableRow');
        allDat = [allDat; tableRow];
        allRowNames = [allRowNames; {[datasets{d,1} '_' datasets{d,3}{blockSetIdx}]}];
    end
end

csvwrite('DiscreteDecodingTable.csv',allDat);
