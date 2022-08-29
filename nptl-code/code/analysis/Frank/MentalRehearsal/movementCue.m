%%
%have:
%WIA of audio cued 4 directional head & joystick movements with good movement &
%eye controls
%WIA of radial 8 cursor-cued head movements with good movement &
%eye controls
%mental rehearsal pilots of VMR, cognitive VMR, symbol memorization

%to collect:
%WIA of: distances, speeds
%watching movements with and without task context
%(watch + imagine) vs. imagine or watch alone
%watching a PDM task? 
%repeat mental rehearsal of cognitive VMR

%todo: PD correlations cross-square, between prep & move, E vs. I vs. W
%todo: classifier accuracy, cross-square
%todo: dPCA CD, cross-square
%todo: get T5 data with the same four movements ?

datasets = {
    't5.2018.02.19',{[18 22],[24],[21],[23],[21 23],[25],[20]},{'E_closed','E_opened','IC1','IC2','IC23','I_opened','E_joy'},[18];
    't5.2018.02.21',{[8 11],[10 12],[13 14],[18],[19],[18 19],[20],[23]},{'E_head','I_abstract','I_head','J1','J2','E_joy','I_joy','E_tongue'},[8];
    't5.2018.03.05',{[1 2],[4 5],[9 10]},{'E_head','I_head','E_joy'},[1];
    't5.2018.03.09',{[0 1],[3 4]},{'E_joy','I_joy'},[0];
    
    't6.2013.08.08',{[7 12],[8],[11],[10]},{'M','I','W','S'},[7];
    't6.2013.09.04',{[0 6 10],[2 7],[3 8],[4 9]},{'M','I','W','S'},[0];
    't6.2013.10.09',{[0 4],[1],[2],[3]},{'M','I','W','S'},[0];
    
    't7.2013.11.26',{[9,14,18],[11,15],[12,16],[13,17]},{'M','I','W','S'},[9];
    't7.2014.06.26',{[103 107 112],[104 108],[105 110],[106 111]},{'M','I','W','S'},[103]; 
    
    't8.2015.09.24',{[0,3,8,12],[1,4,10],[2,5,11]},{'M','I','W'},[0]};

E_vs_I = {'t5.2018.02.19',[18 22],[21 23],[28 29];
    't5.2018.02.21',[8 11],[13 14],[16 17];
    't5.2018.02.21',[18 19],[20],[21 22];
    't5.2018.03.05',[1 2],[4 5],[6 7];
    't5.2018.03.09',[0 1],[3 4],[6 7];
    't6.2013.08.08',[7 12],[8],[11];
    't6.2013.09.04',[0 6 10],[2 7],[3 8];
    't6.2013.10.09', [0 4],[1],[2];
    't7.2013.11.26',[9,14,18],[11,15],[12,16];
    't7.2014.06.26',[103,107,112],[104,108],[105 110];
    't8.2015.09.24',[0,3,8,12],[1,4,10],[2 5 11];
    };

watchDat = {
    't5.2018.02.19',{[28 29]},{'W'};
    't5.2018.02.21',{[16 17],[21 22]},{'W12h','W34j'};
    't5.2018.03.05',{[6 7]},{'W'};
    't5.2018.03.09',{[6 7]},{'W'}};

%%
for d=[6,8,10]
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Wia_movCue' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = horzcat(datasets{d,2}{:});
    if strcmp(datasets{d,1}(1:2),'t5')
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
    else
        movField = 'glove';
        filtOpts.filtFields = {'glove'};
    end
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 3.5, datasets{d,4}, filtOpts );
    
    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            if strcmp(datasets{d,1}(1:2),'t5')
                R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
            end
        end
        allR = [allR, R{x}];
    end
    
    if strcmp(datasets{d,1}, 't8.2015.09.24')
        for t=1:length(allR)
            allR(t).currentMovement = zeros(size(allR(t).clock)) + double(allR(t).startTrialParams.currentMovement);
        end
        blockBinned = cell(length(bNums),2);
        blockBinned_us = cell(length(bNums),2);
        for blockIdx=1:length(bNums)
            blockBinned{blockIdx,1} = load([outDir filesep num2str(bNums(blockIdx)) ' SyncPulse.mat']);
            blockBinned{blockIdx,2} = load([outDir filesep num2str(bNums(blockIdx)) ' TX.mat']);
            blockBinned_us(blockIdx,:) = blockBinned(blockIdx,:);
            blockBinned{blockIdx,2}.binnedTX{1} = gaussSmooth_fast(blockBinned{blockIdx,2}.binnedTX{1}, 3);
        end
    end

    if strcmp(datasets{d,1}(1:2),'t5')
        afSet = {'goCue'};
        twSet = {[-1500,1000]};
        pfSet = {'goCue'};
    else
        afSet = {'goCue'};
        twSet = {[-2500,2000]};
        pfSet = {'goCue'};
    end
        
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 60;
        if strcmp(datasets{d,1}(1:2),'t5')
            datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed','clock'};
        else
            datFields = {'glove','currentMovement','glove_speed','clock'};
        end
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        if strcmp(datasets{d,1}(1:2),'t5')
            binMS_unsmooth = 50;
        else
            binMS_unsmooth = 100;
        end
        alignDat_unsmooth = binAndAlignR( allR, timeWindow, binMS_unsmooth, 0, alignFields, datFields );
        
        %%
        %if t8, add in binned TX
        if strcmp(datasets{d,1}, 't8.2015.09.24')
            alignDat.zScoreSpikes = zeros(size(alignDat.zScoreSpikes,1), 96);
            for blockIdx=1:length(bNums)
                timeDiff = median(blockBinned{blockIdx,1}.siTot{1}.xpcTime - blockBinned{blockIdx,1}.siTot{1}.cbTimeMS);
                blockTXTimes = blockBinned{blockIdx,2}.binTimes{1} + timeDiff;
                
                trlIdx = find(alignDat.bNumPerTrial==bNums(blockIdx));
                for t=1:length(trlIdx)
                    loopIdx = (alignDat.eventIdx(trlIdx(t))+timeWindow(1)/binMS):(alignDat.eventIdx(trlIdx(t))+timeWindow(2)/binMS);
                    loopIdx(1) = [];
                    for x=1:length(loopIdx)
                        [~,minIdx] = min(abs(alignDat.clock(loopIdx(x)) - blockTXTimes));
                        alignDat.zScoreSpikes(loopIdx(x),:) = blockBinned{blockIdx,2}.binnedTX{1}(minIdx,:);
                    end
                end
            end  
            alignDat.zScoreSpikes = zscore(alignDat.zScoreSpikes);
            
            alignDat_unsmooth.zScoreSpikes = zeros(size(alignDat_unsmooth.zScoreSpikes,1), 96);
            for blockIdx=1:length(bNums)
                timeDiff = median(blockBinned_us{blockIdx,1}.siTot{1}.xpcTime - blockBinned_us{blockIdx,1}.siTot{1}.cbTimeMS);
                blockTXTimes = blockBinned_us{blockIdx,2}.binTimes{1} + timeDiff;
                
                trlIdx = find(alignDat_unsmooth.bNumPerTrial==bNums(blockIdx));
                for t=1:length(trlIdx)
                    loopIdx = (alignDat_unsmooth.eventIdx(trlIdx(t))+timeWindow(1)/binMS_unsmooth):(alignDat_unsmooth.eventIdx(trlIdx(t))+timeWindow(2)/binMS_unsmooth);
                    loopIdx(1) = [];
                    for x=1:length(loopIdx)
                        [~,minIdx] = min(abs(alignDat_unsmooth.clock(loopIdx(x)) - blockTXTimes));
                        usIdx = (minIdx-2):(minIdx+2);
                        alignDat_unsmooth.zScoreSpikes(loopIdx(x),:) = mean(blockBinned_us{blockIdx,2}.binnedTX{1}(usIdx,:),1);
                    end
                end
            end  
            alignDat_unsmooth.zScoreSpikes = zscore(alignDat_unsmooth.zScoreSpikes);
        end
        
        %%
        %append T5 watch
        if strcmp(datasets{d,1}(1:2), 't5')
            watchRow = find(strcmp(datasets{d,1}, watchDat(:,1)));
            
            datasets{d,2} = [datasets{d,2}, watchDat{watchRow,2}];
            datasets{d,3} = [datasets{d,3}, watchDat{watchRow,3}];
            watchAD = load([outDir filesep 'watchAlignDat.mat']);
            
            watchAD.alignDat_raw.currentMovement = zeros(length(watchAD.alignDat_raw.zScoreSpikes),1);
            watchAD.alignDat_smooth.currentMovement = zeros(length(watchAD.alignDat_smooth.zScoreSpikes),1);
            
            watchAD.alignDat_raw.currentMovement(watchAD.alignDat_raw.eventIdx) = watchAD.alignDat_raw.movementByTrial;
            watchAD.alignDat_smooth.currentMovement(watchAD.alignDat_smooth.eventIdx) = watchAD.alignDat_smooth.movementByTrial;
            
            watchAD.alignDat_raw.eventIdx = watchAD.alignDat_raw.eventIdx + length(alignDat_unsmooth.zScoreSpikes);
            watchAD.alignDat_smooth.eventIdx = watchAD.alignDat_smooth.eventIdx + length(alignDat.zScoreSpikes);

            %right, left, up, down
            %67,71,72,73
            %left, right, up, down
            %183, 184, 185, 186

            if strcmp(datasets{d,1},'t5.2018.02.19')
                swapCodes = [73, 71, 67, 72];
            else
                swapCodes = [186, 183, 184, 185];
            end
            for swapIdx=1:length(swapCodes)
                watchAD.alignDat_raw.currentMovement(watchAD.alignDat_raw.currentMovement==swapIdx) = swapCodes(swapIdx);
                watchAD.alignDat_smooth.currentMovement(watchAD.alignDat_smooth.currentMovement==swapIdx) = swapCodes(swapIdx);
            end
            
            fNames = {'zScoreSpikes','eventIdx','windowsMousePosition','windowsMousePosition_speed','bNumPerTrial','currentMovement'};
            for fIdx=1:length(fNames)
                alignDat_unsmooth.(fNames{fIdx}) = [alignDat_unsmooth.(fNames{fIdx}); watchAD.alignDat_raw.(fNames{fIdx})];
                alignDat.(fNames{fIdx}) = [alignDat.(fNames{fIdx}); watchAD.alignDat_smooth.(fNames{fIdx})];
            end
        end
        
        %%
%         for blockSetIdx = 1:length(datasets{d,2})
%             
%             %all activity
%             %if strcmp(datasets{d,3}{blockSetIdx},'I')
%             %    trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [allR.isSuccessful]' & ~moveOccurred';
%             %elseif strcmp(datasets{d,3}{blockSetIdx},'M')
%                 trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx});
%             %end
%             trlIdx = find(trlIdx);
%             movCues = alignDat.currentMovement(alignDat.eventIdx(trlIdx));
%             codeList = unique(movCues);
%             
%             codeLegend = cell(length(codeList),1);
%             for c=1:length(codeList)
%                 tmp = getMovementText(codeList(c));
%                 codeLegend{c} = tmp(10:end);
%             end
%             
%             %single-factor
%             dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
%                 movCues, timeWindow/binMS, binMS/1000, {'CD','CI'} );
%             lineArgs = cell(length(codeList),1);
%             colors = jet(length(lineArgs))*0.8;
%             for l=1:length(lineArgs)
%                 lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
%             end
%             oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
%                 lineArgs, {'CD','CI'}, 'sameAxes');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
%         
%             %%
% %             psthOpts = makePSTHOpts();
% %             psthOpts.gaussSmoothWidth = 0;
% %             psthOpts.neuralData = {zscore(alignDat.zScoreSpikes)};
% %             psthOpts.timeWindow = timeWindow/binMS;
% %             psthOpts.trialEvents = alignDat.eventIdx(trlIdx);
% %             psthOpts.trialConditions = movCues;
% % 
% %             psthOpts.conditionGrouping = {1:length(codeList)};
% %             tmp = lineArgs';
% %             tmp = tmp(:);
% % 
% %             psthOpts.lineArgs = tmp;
% %             psthOpts.plotsPerPage = 10;
% %             psthOpts.plotDir = [outDir filesep datasets{d,3}{blockSetIdx} '_PSTH' filesep];
% %             featLabels = cell(192,1);
% %             for f=1:192
% %                 featLabels{f} = ['C' num2str(f)];
% %             end
% %             psthOpts.featLabels = featLabels;
% %             psthOpts.prefix = [datasets{d,3}{blockSetIdx} '_' pfSet{alignSetIdx}];
% %             psthOpts.subtractConMean = false;
% %             psthOpts.timeStep = binMS/1000;
% %             
% %             pOut = makePSTH_simple(psthOpts);
% %             close all; 
%             
%             %%
%             bField = 'goCue';
%             colors = jet(length(codeList))*0.8;
%             
%             if strcmp(datasets{d,1}(1:2),'t5') && ~any(strcmp(datasets{d,3}{blockSetIdx},{'E_head','E_closed','E_opened','M','S','W'}))
%                 rejectThresh = 0.15*10e-4;
%                 cd = triggeredAvg(alignDat.([movField '_speed']), alignDat.eventIdx(trlIdx), timeWindow/binMS);
%                 highSpeedTrl = (any(cd>rejectThresh,2));
%             else
%                 highSpeedTrl = false(size(trlIdx));
%             end
%             
% %             figure
% %             for codeIdx=1:length(codeList)
% %                 plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
% % 
% %                 hold on
% %                 for t=1:length(plotIdx)
% %                     outerTrlIdx = plotIdx(t);
% %                     gloveSpeed = double(allR(outerTrlIdx).([movField '_speed'])');
% % 
% %                     showIdx = (allR(outerTrlIdx).(bField)+timeWindow(1)):(allR(outerTrlIdx).(bField)+timeWindow(2));
% %                     showIdx(showIdx>length(gloveSpeed))=[];
% %                     showIdx(showIdx<1) = [];
% %                     plot(gloveSpeed(showIdx),'Color',colors(codeIdx,:),'LineWidth',2);
% %                 end
% %             end
% %             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.png'],'png');
% %             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.svg'],'svg');
%             
%             figure
%             for codeIdx=1:length(codeList)
%                 plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
%                 cd = triggeredAvg(alignDat.([movField '_speed']), alignDat.eventIdx(plotIdx), timeWindow/binMS);
%                 hold on
%                 plot(nanmean(cd),'Color',colors(codeIdx,:));
%             end
%             legend(codeLegend);
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.svg'],'svg');
%             
%             figure
%             for codeIdx=1:length(codeList)
%                 plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
%                 cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
%                 tmpMean = squeeze(nanmedian(cd,1));
%                 traj = cumsum(tmpMean);
% 
%                 hold on
%                 plot(traj,'Color',colors(codeIdx,:),'LineWidth',2);
%             end
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.svg'],'svg');
%             
%             figure
%             for codeIdx=1:length(codeList)
%                 plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
%                 cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
%                 tmpMean = squeeze(nanmean(cd,1));
%                 traj = cumsum(tmpMean);
% 
%                 hold on
%                 plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
%             end
%             legend(codeLegend);
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj2_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj2_' pfSet{alignSetIdx} '.svg'],'svg');
%             
%             %anova for the three time periods
%             pNames = {'Delay','Beep1'};
%             periodTime = {[-1000,0],[0,1000]};
%             dimTitles = {'X','Y'};
%             figure('Position',[322         596        1229         502]);
%             for p=1:length(periodTime)
%                 binIdx = (round(periodTime{p}(1)/binMS):round(periodTime{p}(2)/binMS)) - timeWindow(1)/binMS;
%                 binIdx(binIdx<1)=[];
%                 
%                 for dimIdx=1:2
%                     tmpDat = [];
%                     for codeIdx=1:length(codeList)
%                         plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
%                         cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
%                         
%                         tmp = mean(squeeze(cd(:,binIdx,dimIdx)),2);
%                         tmpDat = [tmpDat; [tmp, repmat(codeIdx,length(tmp),1)]];
%                     end
%                     
%                     pVal = anova1(tmpDat(:,1), tmpDat(:,2), 'off');
%                     subplot(2,3,(dimIdx-1)*3+p);
%                     boxplot(tmpDat(:,1), tmpDat(:,2));
%                     set(gca,'XTickLabel',codeLegend);
%                     title([pNames{p} ' ' dimTitles{dimIdx} ' p=' num2str(pVal)]);
%                     set(gca,'FontSize',16);
%                 end
%             end
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_anova_.png'],'png');
% 
%             %%
%             %prep & move subspace analysis
%             % Create the problem structure.
%             goIdx = -timeWindow(1)/binMS;
%             prepIdx = (goIdx-35):goIdx;
%             movIdx = (goIdx+10):(goIdx+45);
%             nPrep = 2;
%             nMov = 2;
%             
%             timeAxis = (timeWindow(1)/binMS):(timeWindow(2)/binMS);
%             nDims = nPrep + nMov;
%                        
%             dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(1:(end/2))), ...
%                 movCues(1:(end/2)), timeWindow/binMS, binMS/1000, {'CD','CI'} );
%             X_half = orthoPrepSpace( dPCA_out.featureAverages, nPrep, nMov, prepIdx, movIdx );
%             fa_train_half = dPCA_out.featureAverages;
%             
%             dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx((end/2):end)), ...
%                 movCues((end/2):end), timeWindow/binMS, binMS/1000, {'CD','CI'} );
%             fa_test_half = dPCA_out.featureAverages;
%             
%             dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
%                 movCues, timeWindow/binMS, binMS/1000, {'CD','CI'} );
%             X_full = orthoPrepSpace( dPCA_out.featureAverages, nPrep, nMov, prepIdx, movIdx );
%             fa_full = dPCA_out.featureAverages;
%             
%             X_set = {X_half, X_half, X_full};
%             fa_set = {fa_train_half, fa_test_half, fa_full};
%             
%             %plot projections
%             nCon = size(fa_full,2);
%             figure('Position',[680           1         926        1097]);
%             for setIdx=1:3
%                 for dimIdx = 1:nDims
%                     subplot(nDims,3,(dimIdx-1)*3+setIdx);
%                     hold on;
%                     for conIdx = 1:nCon
%                         tmp = squeeze(fa_set{setIdx}(:,conIdx,:))';
%                         plot(timeAxis, tmp*X_set{setIdx}(:,dimIdx),'LineWidth',2,'Color',colors(conIdx,:));
%                     end
%                     plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
%                     xlim([timeAxis(1), timeAxis(end)]);
%                 end
%             end
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_prepSubspace_' pfSet{alignSetIdx} '.png'],'png');
%             
%             %%
%             close all;
%         end %block set
        
        E_vs_I_row = find(strcmp(datasets{d,1},E_vs_I(:,1)));
        for rowIdx=1:length(E_vs_I_row)
            eIdx = find(ismember(alignDat.bNumPerTrial, E_vs_I{E_vs_I_row(rowIdx),2}));
            iIdx = find(ismember(alignDat.bNumPerTrial, E_vs_I{E_vs_I_row(rowIdx),3}));
            allIdx = [eIdx; iIdx];
            
            movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
            [codeList, ~, codeNums] = unique(movCues);
            [codeListAll, ~, codeNumsAll] = unique(alignDat.currentMovement(alignDat.eventIdx));
            
            movType = zeros(length(allIdx),1);
            movType(1:length(eIdx)) = 0;
            movType((length(eIdx)+1):end) = 1;
            
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx), ...
                [movType, movCues], timeWindow/binMS, binMS/1000, {'IM', 'Dir', 'CI', 'IM x Dir'} );
            
            lineArgs = cell(2,4);
            colors = jet(4)*0.8;
            ls = {'-',':'};
            for x=1:2
                for c=1:4
                    lineArgs{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
                end
            end
            
            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'IM', 'Dir', 'CI', 'IM x Dir'}, 'sameAxes');
            saveas(gcf,[outDir filesep '2fac_dPCA_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep '2fac_dPCA_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %%
            %dPCA square   
%             conNames = {'Prep E','Mov E','Prep I','Mov I'};
%             setNames = {'E','I'};
%             
%             prepWindow = [-35, 0];
%             movWindow = [10, 45];
%             windows = {prepWindow, movWindow};
%             idxSets = {eIdx, iIdx};
%             dPCA_result = cell(length(windows), length(idxSets));
%             dPCA_all = cell(length(windows), length(idxSets));
%             for windowIdx=1:length(windows)
%                 for setIdx=1:length(idxSets)
%                     dPCA_result{windowIdx, setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(idxSets{setIdx}), ...
%                         alignDat.currentMovement(alignDat.eventIdx(idxSets{setIdx})), windows{windowIdx}, binMS/1000, {'CD','CI'} );
%                     close(gcf);
%                     
%                     dPCA_all{windowIdx, setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(idxSets{setIdx}), ...
%                         alignDat.currentMovement(alignDat.eventIdx(idxSets{setIdx})), timeWindow/binMS, binMS/1000, {'CD','CI'} );
%                     close(gcf);
%                 end
%             end
% 
%             nSquares = length(windows)*length(idxSets);
%             axHandles = cell(nSquares, nSquares);
%             yLims = zeros(nSquares, nSquares, 2);
%             nCon = length(codeList);
%             timeAxis = (timeWindow(1)/binMS):(timeWindow(2)/binMS);
%             
%             figure('Position',[680   268   455   830]);
%             for sRowIdx = 1:nSquares
%                 for colIdx = 1:length(idxSets)
%                     axHandles{sRowIdx, colIdx} = subplot(nSquares, length(idxSets), (sRowIdx-1)*length(idxSets) + colIdx);
%                     hold on;
%                     
%                     cdDim = find(dPCA_result{sRowIdx}.whichMarg==1);
%                     neuralDim = dPCA_result{sRowIdx}.W(:,cdDim);
%                     fa = dPCA_all{1,colIdx}.featureAverages;
%        
%                     for conIdx = 1:nCon
%                         tmp = squeeze(fa(:,conIdx,:))';
%                         plot(timeAxis, tmp*neuralDim(:,1),'LineWidth',2,'Color',colors(conIdx,:));
%                     end
%                     xlim([timeAxis(1), timeAxis(end)]);
%                     axis tight;
%                     yLims(sRowIdx, colIdx, :) = get(gca,'YLim');
%                     
%                     if colIdx==1
%                         ylabel(conNames{sRowIdx});
%                     end
%                     if sRowIdx==1
%                         title(setNames{colIdx});
%                     end
%                     set(gca,'FontSize',16);
%                 end
%             end
%             
%             minLim = min(yLims(:));
%             maxLim = max(yLims(:));
%             for sRowIdx = 1:nSquares
%                 for colIdx = 1:length(idxSets)
%                     set(axHandles{sRowIdx, colIdx},'YLim',[minLim, maxLim]);
%                     plot(axHandles{sRowIdx, colIdx},[0,0],[minLim, maxLim],'--k','LineWidth',2);
%                 end
%             end
%             
%             saveas(gcf,[outDir filesep 'dPCACross_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');
           
            %%
            %PD corr
%             wIdx = find(ismember(alignDat.bNumPerTrial, E_vs_I{E_vs_I_row(rowIdx),4}));
%             idxSets_p = {eIdx, iIdx, wIdx};
%             conNames = {'Prep E','Mov E','Prep I','Mov I','Prep W','Mov W'};
%             
%             nChan = size(alignDat.zScoreSpikes,2);
%             PDs = zeros(length(windows),length(idxSets_p),nChan,nCon);
%             pVals = zeros(length(windows),length(idxSets_p),nChan);
%             R2 = zeros(length(windows),length(idxSets_p),nChan);
%             
%             for windowIdx=1:length(windows)
%                 for setIdx=1:length(idxSets_p)
%                     trl = idxSets_p{setIdx};
%                     designMat = zeros(length(trl), nCon);
%                     featMat = zeros(length(trl), nChan);
%                     for t=1:length(trl)
%                         designMat(t, codeNumsAll(trl(t))) = 1;
%                         
%                         loopIdx = alignDat.eventIdx(trl(t)) + windows{windowIdx};
%                         loopIdx = loopIdx(1):loopIdx(2);
%                         featMat(t, :) = mean(alignDat.zScoreSpikes(loopIdx,:));
%                     end
%                     
%                     for chanIdx=1:nChan
%                         [B,BINT,R,RINT,STATS] = regress(featMat(:,chanIdx), designMat);
%                         pVals(windowIdx, setIdx, chanIdx) = STATS(3);
%                         PDs(windowIdx, setIdx, chanIdx, :) = B;
%                         R2(windowIdx, setIdx, chanIdx) = STATS(1);
%                     end
%                 end
%             end
%             
%             nSquares = length(windows) * length(idxSets_p);
%             windowSetMap = {[1,1],[2,1],[1,2],[2,2],[1,3],[2,3]};
%             corrMat = zeros(nSquares);
%             numChan = zeros(nSquares);
%             for sRowIdx = 1:nSquares
%                 for colIdx = 1:nSquares
%                     lx = windowSetMap{sRowIdx}(1);
%                     ly = windowSetMap{sRowIdx}(2);
%                     sigIdx_row = (squeeze(pVals(lx,ly,:))<0.01);
%                     B_row = squeeze(PDs(lx,ly,:,:));
%                     
%                     lx = windowSetMap{colIdx}(1);
%                     ly = windowSetMap{colIdx}(2);
%                     sigIdx_col = (squeeze(pVals(lx,ly,:))<0.01);
%                     B_col = squeeze(PDs(lx,ly,:,:));
%                     
%                     sigIdx_both = sigIdx_row & sigIdx_col;
%                     if sum(sigIdx_both)<=1
%                         continue
%                     end
%                     cVal = mean(diag(corr(B_row(sigIdx_both,:), B_col(sigIdx_both,:))));
%                     corrMat(sRowIdx, colIdx) = cVal;
%                     
%                     numChan(sRowIdx, colIdx) = length(find(sigIdx_both));
%                 end
%             end
%             
%             figure
%             imagesc(corrMat,[-1,1]);
%             colorbar;
%             set(gca,'XTick',1:nSquares,'XTickLabels',conNames,'YTick',1:nSquares,'YTickLabels',conNames);
%             set(gca,'FontSize',16);
%             saveas(gcf,[outDir filesep 'crossCorr_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');
%             
%             for windowIdx=1:2
%                 sigIdx_E = (squeeze(pVals(windowIdx,1,:))<0.001);
%                 sigIdx_I = (squeeze(pVals(windowIdx,2,:))<0.001);
%                 
%                 E_only = sum(sigIdx_E & ~sigIdx_I);
%                 I_only = sum(sigIdx_I & ~sigIdx_E);
%                 E_and_I = sum(sigIdx_E & sigIdx_I);
%             end
            
            %%
%             %subspace overlap
%             wIdx = find(ismember(alignDat.bNumPerTrial, E_vs_I{E_vs_I_row(rowIdx),4}));
%             idxSets_p = {eIdx, iIdx, wIdx};
%             conNames = {'Prep E','Mov E','Prep I','Mov I','Prep W','Mov W'};
%             shuffTestIdx = cell(length(idxSets_p),1);
%             shuffTrainIdx = cell(length(idxSets_p),1);
%             
%             dPCA_result = cell(length(windows), length(idxSets_p));
%             for windowIdx=1:length(windows)
%                 for setIdx=1:length(idxSets_p)
%                     tmp = randperm(length(idxSets_p{setIdx}));
%                     shuffTestIdx{setIdx} = idxSets_p{setIdx}(tmp(1:round(end/2)));
%                     shuffTrainIdx{setIdx} = idxSets_p{setIdx}(tmp(round(end/2):end));
%                     
%                     dPCA_result{windowIdx, setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(shuffTestIdx{setIdx}), ...
%                         alignDat.currentMovement(alignDat.eventIdx(shuffTestIdx{setIdx})), windows{windowIdx}, binMS/1000, {'CD','CI'} );
%                     close(gcf);
%                 end
%             end
%             
%             nAxes = 3;
%             varSquare = zeros(numel(dPCA_result));
%             shuffIdxTrain_unrolled = {shuffTrainIdx{1}, shuffTrainIdx{1}, shuffTrainIdx{2}, shuffTrainIdx{2}, shuffTrainIdx{3}, shuffTrainIdx{3}};
%             shuffIdx_unrolled = {shuffTestIdx{1}, shuffTestIdx{1}, shuffTestIdx{2}, shuffTestIdx{2}, shuffTestIdx{3}, shuffTestIdx{3}};
%             idxSets_unrolled = {eIdx, eIdx, iIdx, iIdx, wIdx, wIdx};
%             windows_unrolled = {windows{1}, windows{2}, windows{1}, windows{2}, windows{1}, windows{2}};
%                 
%             for outerIdx = 1:numel(dPCA_result)
%                 disp(outerIdx);
%                 trlIdx = idxSets_unrolled{outerIdx};
% 
%                 trlToTrain = shuffIdxTrain_unrolled{outerIdx};
%                 out_train = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlToTrain), ...
%                     alignDat.currentMovement(alignDat.eventIdx(trlToTrain)), windows_unrolled{outerIdx}, binMS/1000, {'CD','CI'} );    
%                 close(gcf);
% 
%                 trlToTest = shuffIdx_unrolled{outerIdx};
%                 out_test = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlToTest), ...
%                     alignDat.currentMovement(alignDat.eventIdx(trlToTest)), windows_unrolled{outerIdx}, binMS/1000, {'CD','CI'} ); 
%                 close(gcf);
% 
%                 fa = out_test.featureAverages;
%                 fa = fa - repmat(mean(fa,2),1,size(fa,2),1);
%                 fa = reshape(fa, size(out_test.featureAverages,1), []);
% 
%                 cdAxes = find(out_train.pca_result.whichMarg==1);
%                 cdAxes = out_train.pca_result.W(:,cdAxes(1:nAxes));
%                 projResult = cdAxes * (cdAxes' * fa);
%                 varSquare(outerIdx, outerIdx) = sum(sum(projResult.^2));
%             end
% 
%             for outerIdx = 1:numel(dPCA_result)
%                 for innerIdx = 1:numel(dPCA_result)
%                     if innerIdx==outerIdx
%                         continue
%                     end
%                     
%                     cdAxes = find(dPCA_result{innerIdx}.pca_result.whichMarg==1);
%                     cdAxes = dPCA_result{innerIdx}.pca_result.W(:,cdAxes(1:nAxes));
%                     
%                     fa = dPCA_result{outerIdx}.featureAverages;
%                     fa = fa - repmat(mean(fa,2),1,size(fa,2),1);
%                     fa = reshape(fa, size(dPCA_result{outerIdx}.featureAverages,1), []);
%                     totalVar = sum(sum(fa.^2));
%                     
%                     projResult = cdAxes * (cdAxes' * fa);
%                     totalVar_inner = sum(sum(projResult.^2));
%                     
%                     varSquare(outerIdx, innerIdx) = totalVar_inner;
%                 end
%             end
%             
%             normSquare = varSquare;
%             for outerIdx = 1:numel(dPCA_result)
%                 normSquare(outerIdx,:) = normSquare(outerIdx,:) / normSquare(outerIdx,outerIdx);
%                 %normSquare(outerIdx,outerIdx)=0;
%             end
%             
%             figure;
%             imagesc(sqrt(normSquare));
%             colorbar;
%             set(gca,'XTick',1:6,'XTickLabels',conNames,'YTick',1:6,'YTickLabels',conNames);
%             set(gca,'FontSize',16);
%             saveas(gcf,[outDir filesep 'crossVar_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');

            %%
            %classifier accuracy
            wIdx = find(ismember(alignDat.bNumPerTrial, E_vs_I{E_vs_I_row(rowIdx),4}));
            idxSets_c = {eIdx, iIdx, wIdx};
            
            L = cell(length(idxSets_c),1);
            L_cross = cell(length(idxSets_c),length(idxSets_c));
            timeAxis_unsmooth = (timeWindow(1)/binMS_unsmooth):(timeWindow(2)/binMS_unsmooth);
            binAxis = (timeAxis_unsmooth(1)+1):timeAxis_unsmooth(end);
            
            for setIdx = 1:length(idxSets_c)
                L{setIdx} = zeros(length(binAxis),length(binAxis));
                for binIdx=1:length(binAxis)
                    disp(binIdx);
                    loopIdx = binAxis(binIdx) + alignDat_unsmooth.eventIdx(idxSets_c{setIdx});

                    obj = fitcdiscr(alignDat_unsmooth.zScoreSpikes(loopIdx,:),codeNumsAll(idxSets_c{setIdx}),'DiscrimType','diaglinear');
                    
                    for innerIdx=1:length(binAxis)
                        loopIdx = binAxis(innerIdx) + alignDat_unsmooth.eventIdx(idxSets_c{setIdx});
                        L{setIdx}(binIdx,innerIdx) = mean(predict(obj, alignDat_unsmooth.zScoreSpikes(loopIdx,:))~=codeNumsAll(idxSets_c{setIdx}));
                    end
                    
                    cvmodel = crossval(obj);
                    L{setIdx}(binIdx,binIdx) = kfoldLoss(cvmodel,'LossFun','classiferror');
                    
                    for crossIdx=1:length(idxSets_c)
                        if crossIdx==setIdx
                            continue
                        end
                        for innerIdx=1:length(binAxis)
                           loopIdx = binAxis(innerIdx) + alignDat_unsmooth.eventIdx(idxSets_c{crossIdx});
                           L_cross{setIdx,crossIdx}(binIdx,innerIdx) = mean(predict(obj, alignDat_unsmooth.zScoreSpikes(loopIdx,:))~=codeNumsAll(idxSets_c{crossIdx}));
                        end
                    end
                    
                    %predLabels = kfoldPredict(cvmodel);
                    %C = confusionmat(allCodesRemap, predLabels);                   
                end
            end
            
            for setIdx = 1:length(idxSets_c)
                for binIdx=1:length(binAxis)
                    if binIdx==1
                        L{setIdx}(binIdx,binIdx) = mean([L{setIdx}(binIdx,binIdx+1), L{setIdx}(binIdx+1,binIdx)]);
                    elseif binIdx==length(binAxis)
                        L{setIdx}(binIdx,binIdx) = mean([L{setIdx}(binIdx,binIdx-1), L{setIdx}(binIdx-1,binIdx)]);
                    else
                        L{setIdx}(binIdx,binIdx) = mean([L{setIdx}(binIdx,binIdx-1), L{setIdx}(binIdx-1,binIdx), ...
                            L{setIdx}(binIdx+1,binIdx), L{setIdx}(binIdx,binIdx+1)]);
                    end
                end
            end
            
            for setIdx = 1:length(idxSets_c)
                L_cross{setIdx, setIdx} = L{setIdx};
            end
            
            colors = hsv(length(idxSets_c))*0.8;
            colorIdx = 1;
            lString = {'E','I','W'};
            
            figure
            hold on
            for setIdx = 1:length(idxSets_c)
                plot(binAxis, 1-diag(L{setIdx}),'Color',colors(setIdx,:),'LineWidth',2);
            end
            ylim([0,1]);
            plot(get(gca,'XLim'),[0.25,0.25],'--k','LineWidth',2);
            plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
            legend(lString);
            set(gca,'FontSize',16);
            saveas(gcf,[outDir filesep 'classifyDiag_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');
            
            
            for setIdx = 1:length(idxSets_c)
                lString2 = cell(length(idxSets_c),1);
                figure
                hold on
                for innerSetIdx = 1:length(idxSets_c)
                    plot(binAxis, 1-diag(L_cross{innerSetIdx,setIdx}),'Color',colors(innerSetIdx,:),'LineWidth',2);
                    lString2{innerSetIdx} = [lString{innerSetIdx} ' to ' lString{setIdx}];
                end
                ylim([0,1]);
                plot(get(gca,'XLim'),[0.25,0.25],'--k','LineWidth',2);
                plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
                legend(lString2);
                set(gca,'FontSize',16);
                saveas(gcf,[outDir filesep 'classifyCross_' lString{setIdx} '_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');
            end
            
            nSets = length(idxSets_c);
            maxVal = max(1-diag(L{1}));
            
            figure
            for setRow=1:nSets
                for setCol=1:nSets
                    subplot(nSets,nSets,(setRow-1)*nSets + setCol);
                    imagesc(1-L_cross{setRow, setCol},[0.25,maxVal]);
                    
                    if setRow==1
                        title(['Test on ' lString{setCol}]);
                    end
                    if setCol==1
                        ylabel(['Build on ' lString{setRow}]);
                    end
                end
            end
            
            saveas(gcf,[outDir filesep 'classifyImage_sameLim_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');

            figure
            for setRow=1:nSets
                for setCol=1:nSets
                    subplot(nSets,nSets,(setRow-1)*nSets + setCol);
                    imagesc(1-L_cross{setRow, setCol});
                    
                    if setRow==1
                        title(['Test on ' lString{setCol}]);
                    end
                    if setCol==1
                        ylabel(['Build on ' lString{setRow}]);
                    end
                end
            end
            
            saveas(gcf,[outDir filesep 'classifyImage_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');
            
%             %%
%             %prep vs. move space
%             goIdx = -timeWindow(1)/binMS;
%             prepIdx = (goIdx-35):goIdx;
%             movIdx = (goIdx+10):(goIdx+45);
%             nPrep = 2;
%             nMov = 2;
%             
%             timeAxis = (timeWindow(1)/binMS):(timeWindow(2)/binMS);
%             nDims = nPrep + nMov;
% 
%             dPCA_out_E = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(eIdx), ...
%                 alignDat.currentMovement(alignDat.eventIdx(eIdx)), timeWindow/binMS, binMS/1000, {'CD','CI'} );
%             X_E = orthoPrepSpace( dPCA_out_E.featureAverages, nPrep, nMov, prepIdx, movIdx );
%             fa_E = dPCA_out_E.featureAverages;
%             
%             dPCA_out_I = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(iIdx), ...
%                 alignDat.currentMovement(alignDat.eventIdx(iIdx)), timeWindow/binMS, binMS/1000, {'CD','CI'} );
%             X_I = orthoPrepSpace( dPCA_out_I.featureAverages, nPrep, nMov, prepIdx, movIdx );
%             fa_I = dPCA_out_I.featureAverages;
%             
%             X_set = {X_E, X_I, X_I, X_E};
%             fa_set = {fa_E, fa_E, fa_I, fa_I};
%             colNames = {'E Same','E Cross','I Same','I Cross'};
%             
%             %plot projections
%             axHandles = cell(length(X_set), nDims);
%             yLims = zeros(length(X_set), nDims, 2);
%             
%             %nCon = size(fa_full,2);
%             figure('Position',[680           1         926        1097]);
%             for setIdx=1:length(X_set)
%                 for dimIdx = 1:nDims
%                     axHandles{setIdx, dimIdx} = subplot(nDims,length(X_set),(dimIdx-1)*length(X_set) + setIdx);
%                     hold on;
%                     for conIdx = 1:nCon
%                         tmp = squeeze(fa_set{setIdx}(:,conIdx,:))';
%                         plot(timeAxis, tmp*X_set{setIdx}(:,dimIdx),'LineWidth',2,'Color',colors(conIdx,:));
%                     end
%                     xlim([timeAxis(1), timeAxis(end)]);
%                     axis tight;
%                     plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
%                     yLims(setIdx, dimIdx, :) = get(gca,'YLim');
%                     
%                     if dimIdx==1
%                         title(colNames{setIdx});
%                     end
%                 end
%             end
%             
%             maxLim = max(yLims(:));
%             minLim = min(yLims(:));
%             for setIdx=1:length(X_set)
%                 for dimIdx = 1:nDims
%                     set(axHandles{setIdx,dimIdx},'YLim',[minLim, maxLim]);
%                     plot(axHandles{setIdx,dimIdx},[0,0],[minLim, maxLim],'--k','LineWidth',2);
%                 end
%             end
%             
%             saveas(gcf,[outDir filesep '2fac_prepSubspace_' num2str(rowIdx) '_' pfSet{alignSetIdx} '.png'],'png');
        end %E_vs_I row
        
        close all;
    end %alignment set
    clear stream allR alignDat
    pack;
end %dataset
