%%
datasets = {
    't5.2018.03.14',{[5 7],[6 8],[10 11 12 13 14 15],[16 17],[18 19],[20 21]},{'R_joy','L_joy','Bi','Leg','Head','Eye'},[5];
    't5.2018.05.30',{[2 3 4 8 9 10 11 12 13],[14 15 16 17 18 19 21 22 23 24]},{'DualArm','ArmLegDir'},[2];
    't5.2018.06.04',{[2 3 4 5 6],[10 11 12 13 14 15 16 17 18 19 20 21 22 23]},{'DualArm','ArmHeadDir'},[2];
    
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 19 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
        
    't5.2018.06.18',{[4 6 7 8 9 10 12],[18 19 20 21 22],[15],[13 14]},{'LArmRArm','EyeRArm','Head','Eye'},[4];
    't5.2018.06.20',{[16 17 18 19 20 21 22]},{'ArmSeq'},[17];
};

%%
for d=1:length(datasets)
    
    if any(strcmp(datasets{d,1},{'t5.2018.03.19', 't5.2018.03.21', 't5.2018.04.02'}))
        nDirCon = 2;
    else
        nDirCon = 4;
    end
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    %bNums = [5 7 6 8 16 17];
    bNums = horzcat(datasets{d,2}{:});
    if strcmp(datasets{d,1}(1:2),'t5')
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
    else
        movField = 'glove';
        filtOpts.filtFields = {'glove'};
    end
    filtOpts.filtCutoff = 10/500;
    [ R, stream ] = getStanfordRAndStream( sessionPath, bNums, 3.5, datasets{d,4}, filtOpts );
    
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
    
    %speedThresh = 0.06;
    %moveOccurred = false(size(allR));
    %for t=1:length(allR)
    %    moveOccurred(t) = any(allR(t).glove_speed>speedThresh);
    %end

    %smoothWidth = 0;
    %datFields = {'glove','cursorPosition','currentTarget','xk'};
    %binMS = 20;
    %unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );

    if strcmp(datasets{d,1}(1:2),'t5')
        afSet = {'goCue','goCue'};
        twSet = {[-1500,3000],[-1500,0]};
        pfSet = {'goCue','delay'};
    else
        afSet = {'goCue'};
        twSet = {[-1500,6500]};
        pfSet = {'goCue'};
    end
        
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 60;
        if strcmp(datasets{d,1}(1:2),'t5')
            datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
        else
            datFields = {'glove','currentMovement','glove_speed'};
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

        allOutCell = cell(length(datasets{d,2}),1);
        for blockSetIdx = 1:length(datasets{d,2})
            
            %all activity
            %if strcmp(datasets{d,3}{blockSetIdx},'I')
            %    trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [allR.isSuccessful]' & ~moveOccurred';
            %elseif strcmp(datasets{d,3}{blockSetIdx},'M')
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx});
            %end
            trlIdx = find(trlIdx);
            movCues = alignDat.currentMovement(alignDat.eventIdx(trlIdx));
            codeList = unique(movCues);
            
            codeLegend = cell(length(codeList),1);
            for c=1:length(codeList)
                tmp = getMovementText(codeList(c));
                codeLegend{c} = tmp(10:end);
            end
            
            %single-factor
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
                movCues, timeWindow/binMS, binMS/1000, {'CD','CI'} );
            lineArgs = cell(length(codeList),1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'CD','CI'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        
            allOutCell{blockSetIdx} = dPCA_out;
            
            %%
            bField = 'goCue';
            colors = jet(length(codeList))*0.8;
            
            if ~any(strcmp(datasets{d,3}{blockSetIdx},{'Head'}))
                rejectThresh = 0.15*10e-4;
                cd = triggeredAvg(alignDat.([movField '_speed']), alignDat.eventIdx(trlIdx), timeWindow/binMS);
                highSpeedTrl = (any(cd>rejectThresh,2));
            else
                highSpeedTrl = false(size(trlIdx));
            end
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);

                hold on
                for t=1:length(plotIdx)
                    outerTrlIdx = plotIdx(t);
                    gloveSpeed = double(allR(outerTrlIdx).([movField '_speed'])');

                    showIdx = (allR(outerTrlIdx).(bField)+timeWindow(1)):(allR(outerTrlIdx).(bField)+timeWindow(2));
                    showIdx(showIdx>length(gloveSpeed))=[];
                    showIdx(showIdx<1) = [];
                    plot(gloveSpeed(showIdx),'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
                cd = triggeredAvg(alignDat.([movField '_speed']), alignDat.eventIdx(plotIdx), timeWindow/binMS);
                hold on
                plot(nanmean(cd),'Color',colors(codeIdx,:));
            end
            legend(codeLegend);
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
                cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
                tmpMean = squeeze(nanmedian(cd,1));
                traj = cumsum(tmpMean);

                hold on
                plot(traj,'Color',colors(codeIdx,:),'LineWidth',2);
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
                cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
                tmpMean = squeeze(nanmean(cd,1));
                traj = cumsum(tmpMean);

                hold on
                plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
            end
            legend(codeLegend);
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj2_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj2_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %anova for the three time periods
            pNames = {'Delay','Beep1','Beep2'};
            periodTime = {[-1500,0],[0,1500],[1500,3000]};
            dimTitles = {'X','Y'};
            figure('Position',[322         596        1229         502]);
            for p=1:length(periodTime)
                binIdx = (round(periodTime{p}(1)/binMS):round(periodTime{p}(2)/binMS)) - timeWindow(1)/binMS;
                binIdx(binIdx<1)=[];
                
                for dimIdx=1:2
                    tmpDat = [];
                    for codeIdx=1:length(codeList)
                        plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
                        cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
                        
                        tmp = mean(squeeze(cd(:,binIdx,dimIdx)),2);
                        tmpDat = [tmpDat; [tmp, repmat(codeIdx,length(tmp),1)]];
                    end
                    
                    pVal = anova1(tmpDat(:,1), tmpDat(:,2), 'off');
                    subplot(2,3,(dimIdx-1)*3+p);
                    boxplot(tmpDat(:,1), tmpDat(:,2));
                    set(gca,'XTickLabel',codeLegend);
                    title([pNames{p} ' ' dimTitles{dimIdx} ' p=' num2str(pVal)]);
                    set(gca,'FontSize',16);
                end
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_anova_.png'],'png');

            close all;
        end %block set
        
        if ~strcmp(datasets{d,1},'t5.2018.03.14')
            if strcmp(datasets{d,1},'t5.2018.05.30')
                dualSetIdx = 2;
            elseif strcmp(datasets{d,1},'t5.2018.06.04')
                dualSetIdx = 2;
            elseif strcmp(datasets{d,1},'t5.2018.03.19')
                dualSetIdx = 1:5;
            elseif strcmp(datasets{d,1},'t5.2018.03.21')
                dualSetIdx = 1:2;
            elseif strcmp(datasets{d,1},'t5.2018.04.02')
                dualSetIdx = 1:8;
            elseif strcmp(datasets{d,1},'t5.2018.06.18')
                dualSetIdx = 1:2;
            elseif strcmp(datasets{d,1},'t5.2018.06.20')
                dualSetIdx = 1;
            end

            for outerMovSetIdx = dualSetIdx

                %---dual movement----
                allIdx = find(ismember(alignDat.bNumPerTrial, datasets{d,2}{outerMovSetIdx}));

                movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
                codeList = unique(movCues);

    %           BI_LEFT_LEFT(195)
    %           BI_LEFT_RIGHT(196)
    %           BI_LEFT_UP(197)
    %           BI_LEFT_DOWN(198)
    % 
    %           BI_RIGHT_LEFT(199)
    %           BI_RIGHT_RIGHT(200)
    %           BI_RIGHT_UP(201)
    %           BI_RIGHT_DOWN(202)
    % 
    %           BI_UP_LEFT(203)
    %           BI_UP_RIGHT(204)
    %           BI_UP_UP(205)
    %           BI_UP_DOWN(206)
    % 
    %           BI_DOWN_LEFT(207)
    %           BI_DOWN_RIGHT(208)
    %           BI_DOWN_UP(209)
    %           BI_DOWN_DOWN(210)
                
                factorMap = [
                    187, 1, 0;
                    188, 2, 0;
                    189, 3, 0;
                    190, 4, 0;
                    191, 0, 1;
                    192, 0, 2;
                    193, 0, 3;
                    194, 0, 4;
                    195, 1, 1;
                    196, 1, 2;
                    197, 1, 3;
                    198, 1, 4;
                    199, 2, 1;
                    200, 2, 2;
                    201, 2, 3;
                    202, 2, 4;
                    203, 3, 1;
                    204, 3, 2;
                    205, 3, 3;
                    206, 3, 4;
                    207, 4, 1;
                    208, 4, 2;
                    209, 4, 3;
                    210, 4, 4;   ];            
                movFactors = zeros(length(movCues),2);
                for x=1:length(movCues)
                    fIdx = find(factorMap(:,1)==movCues(x));
                    movFactors(x,:) = factorMap(fIdx,2:3);
                end

                noSingleMovements = find(~ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
                dPCA_out_dual = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements)), ...
                    movFactors(noSingleMovements,:), timeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'} );

                lineArgs_dual = cell(nDirCon,nDirCon);
                colors = jet(nDirCon)*0.8;
                ls = {'-',':','--','-.'};
                for x=1:nDirCon
                    for c=1:nDirCon
                        lineArgs_dual{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
                    end
                end

                %2-factor dPCA
                 labels = {'Dir Eff1', 'Dir Eff2', 'CI', 'Eff1 x Eff2'};
                [~, allHandles, axFromDualMovements] = twoFactor_dPCA_plot( dPCA_out_dual,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs_dual, labels, 'sameAxes');
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');

                %---single movement----
                allIdx = find(ismember(alignDat.bNumPerTrial, datasets{d,2}{outerMovSetIdx}));
                movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
                codeList = unique(movCues);

                factorMap = [
                    187, 1, 0;
                    188, 2, 0;
                    189, 3, 0;
                    190, 4, 0;
                    191, 1, 1;
                    192, 2, 1;
                    193, 3, 1;
                    194, 4, 1;
                    195, 1, 1;
                    196, 1, 2;
                    197, 1, 3;
                    198, 1, 4;
                    199, 2, 1;
                    200, 2, 2;
                    201, 2, 3;
                    202, 2, 4;
                    203, 3, 1;
                    204, 3, 2;
                    205, 3, 3;
                    206, 3, 4;
                    207, 4, 1;
                    208, 4, 2;
                    209, 4, 3;
                    210, 4, 4;   ];            
                movFactors = zeros(length(movCues),2);
                for x=1:length(movCues)
                    fIdx = find(factorMap(:,1)==movCues(x));
                    movFactors(x,:) = factorMap(fIdx,2:3);
                end

                singleMovements = find(ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
                dPCA_out_single = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
                    movFactors(singleMovements,:), timeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'} );

                lineArgs_single = cell(nDirCon,2);
                colors = jet(nDirCon)*0.8;
                ls = {':','-'};
                for x=1:nDirCon
                    for c=1:2
                        lineArgs_single{x,c} = {'Color',colors(x,:),'LineWidth',2,'LineStyle',ls{c}};
                    end
                end

                labelsSingle = {'Dir', 'Effector', 'CI', 'Dir x Eff'};
                labelsDual = {'Dir Eff1', 'Dir Eff2', 'CI', 'Eff1 x Eff2'};

                %2-factor dPCA
                [yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot( dPCA_out_single,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs_single, labelsSingle, 'sameAxes', []);
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMove_dPCA_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMove_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');

                %same axes
                fullAx = [vertcat(axFromDualMovements{:}); vertcat(axFromSingle{:})];
                fullLims = [min(fullAx(:)), max(fullAx(:))];
                [yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot( dPCA_out_single,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs_single, labelsSingle, 'sameAxes', [], fullLims);
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMoveSameAx_dPCA_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMoveSameAx_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');

                [~, allHandles, axFromDualMovements] = twoFactor_dPCA_plot( dPCA_out_dual,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs_dual, labels, 'sameAxes', [], fullLims);
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2moveSameAx_dPCA_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2moveSameAx_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');

                %==transfer of single-movement dimensions to dual context==
                allIdx = find(ismember(alignDat.bNumPerTrial, datasets{d,2}{outerMovSetIdx}));
                movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
                codeList = unique(movCues);

                factorMap = [
                    187, 1, 0;
                    188, 2, 0;
                    189, 3, 0;
                    190, 4, 0;
                    191, 1, 1;
                    192, 2, 1;
                    193, 3, 1;
                    194, 4, 1;
                    195, 1, 1;
                    196, 1, 2;
                    197, 1, 3;
                    198, 1, 4;
                    199, 2, 1;
                    200, 2, 2;
                    201, 2, 3;
                    202, 2, 4;
                    203, 3, 1;
                    204, 3, 2;
                    205, 3, 3;
                    206, 3, 4;
                    207, 4, 1;
                    208, 4, 2;
                    209, 4, 3;
                    210, 4, 4;   ];            
                movFactors = zeros(length(movCues),2);
                for x=1:length(movCues)
                    fIdx = find(factorMap(:,1)==movCues(x));
                    movFactors(x,:) = factorMap(fIdx,2:3);
                end

                allDecPos = cell(length(movSets),2);
                movSets = {[187,188,189,190],[191,192,193,194]};
                for setIdx=1:length(movSets)
                    %single movement context
                    singleMovements = find(ismember(movCues, movSets{setIdx}));
                    dPCA_out_single = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
                        movFactors(singleMovements,1), timeWindow/binMS, binMS/1000, {'Dir','CI'} );

                    lineArgs = cell(nDirCon,1);
                    colors = jet(length(lineArgs))*0.8;
                    for l=1:length(lineArgs)
                        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
                    end
                    yLimSingle = oneFactor_dPCA_plot( dPCA_out_single,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                        lineArgs, {'CD','CI'}, 'sameAxes');
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_1fac_set_' num2str(setIdx) '_' pfSet{alignSetIdx} '.png'],'png');
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_1fac_set_' num2str(setIdx) '_' pfSet{alignSetIdx} '.svg'],'svg');

                    %dual context
                    dualMovements = find(~ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
                    dPCA_out_dual = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(dualMovements)), ...
                        movFactors(dualMovements,setIdx), timeWindow/binMS, binMS/1000, {'Dir','CI'} );

                    lineArgs = cell(nDirCon,1);
                    colors = jet(length(lineArgs))*0.8;
                    for l=1:length(lineArgs)
                        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
                    end
                    oneFactor_dPCA_plot( dPCA_out_dual,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                        lineArgs, {'CD','CI'}, 'sameAxes');
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_1fac_set_' num2str(setIdx) '_' pfSet{alignSetIdx} '.png'],'png');
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_1fac_set_' num2str(setIdx) '_' pfSet{alignSetIdx} '.svg'],'svg');

                    %apply to dual context
                    cross_dPCA = do_dPCA_cross( dPCA_out_single, dPCA_out_dual );
                    cross_dPCA.Z = cat(2,cross_dPCA.Z,dPCA_out_single.Z);

                    yLims = vertcat(yLimSingle{:});
                    yLims = [min(yLims(:)), max(yLims(:))];

                    lineArgs = cell(nDirCon*2,1);
                    colors = jet(nDirCon)*0.8;
                    l = 1;
                    styles = {'--','-'};
                    for styleIdx=1:2
                        for colorIdx=1:nDirCon
                            lineArgs{l} = {'Color',colors(colorIdx,:),'LineWidth',2,'LineStyle',styles{styleIdx}};
                            l = l + 1;
                        end
                    end

                    oneFactor_dPCA_plot( cross_dPCA,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                        lineArgs, {'CD','CI'}, 'sameAxes', []);
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_1fac_set_' num2str(setIdx) '_crossDual' pfSet{alignSetIdx} '.png'],'png');
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_1fac_set_' num2str(setIdx) '_crossDual' pfSet{alignSetIdx} '.svg'],'svg');
                    close all;
                    
                    %single-bin decoding
                    dirFactorMap = [
                        187, 1, 0;
                        188, 2, 0;
                        189, 3, 0;
                        190, 4, 0;
                        191, 0, 1;
                        192, 0, 2;
                        193, 0, 3;
                        194, 0, 4;
                        195, 1, 1;
                        196, 1, 2;
                        197, 1, 3;
                        198, 1, 4;
                        199, 2, 1;
                        200, 2, 2;
                        201, 2, 3;
                        202, 2, 4;
                        203, 3, 1;
                        204, 3, 2;
                        205, 3, 3;
                        206, 3, 4;
                        207, 4, 1;
                        208, 4, 2;
                        209, 4, 3;
                        210, 4, 4;   ];    
                    dirMap = [0 0;
                        -1, 0;
                        1, 0;
                        0, 1;
                        0, -1];
                    
                    movDir = zeros(size(alignDat.zScoreSpikes,1), 4);
                    twBinned = [timeWindow(1)/binMS, timeWindow(2)/binMS];
                    currentMovementByTrl = alignDat.currentMovement(alignDat.eventIdx);
                    
                    for trlIdx=1:length(currentMovementByTrl)
                        cue = currentMovementByTrl(trlIdx);
                        entryIdx = find(cue==dirFactorMap(:,1));
                        if isempty(entryIdx)
                            continue;
                        end
                        
                        dirs = [dirMap(dirFactorMap(entryIdx, 2)+1,:), ...
                            dirMap(dirFactorMap(entryIdx, 3)+1,:)];
                        loopIdx = (alignDat.eventIdx(trlIdx)+twBinned(1)+1):(alignDat.eventIdx(trlIdx)+twBinned(2));
                        movDir(loopIdx,:) = repmat(dirs, length(loopIdx), 1);
                    end

                    singleMovements = find(ismember(movCues, movSets{setIdx}));
                    epochsToUse = [alignDat.eventIdx(allIdx(singleMovements))+10, alignDat.eventIdx(allIdx(singleMovements))+60];
                    loopIdxToUse = expandEpochIdx(epochsToUse);
                    
                    coef = buildLinFilts(movDir(loopIdxToUse,(1:2)+(setIdx-1)*2), alignDat.zScoreSpikes(loopIdxToUse,:), 'inverseLinear');
                    decDir = alignDat.zScoreSpikes*coef;
                    
                    avgDec = zeros(length(movSets{setIdx}), 76, 2);
                    for movIdx=1:length(movSets{setIdx})
                        trlIdx = allIdx(ismember(movCues,movSets{setIdx}(movIdx)));
                        concatDat = triggeredAvg( decDir, alignDat.eventIdx(trlIdx), [-25,50] );
                        avgDec(movIdx, :, :) = squeeze(mean(concatDat,1));
                    end

                    avgDecCross = zeros(length(movSets{setIdx}), 76, 2);
                    for movIdx=1:4
                        trlIdx = allIdx(ismember(movCues, dirFactorMap(dirFactorMap(:,setIdx+1)==movIdx,1)));
                        concatDat = triggeredAvg( decDir, alignDat.eventIdx(trlIdx), [-25,50] );
                        avgDecCross(movIdx, :, :) = squeeze(mean(concatDat,1));
                    end
                    
                    pos = zeros(4,52,2);
                    posCross = zeros(4,52,2);
                    for movIdx=1:4
                        decVel = squeeze(avgDec(movIdx,:,:));
                        pos(movIdx,:,:) = cumsum(decVel(25:end,:));

                        decVel = squeeze(avgDecCross(movIdx,:,:));
                        posCross(movIdx,:,:) = cumsum(decVel(25:end,:));
                    end
                    maxValue = max([abs(pos(:)); abs(posCross(:))]);
                    
                    pos = pos / maxValue;
                    posCross = posCross / maxValue;
                    
                    allDecPos{setIdx,1} = pos;
                    allDecPos{setIdx,2} = posCross;
                end
                
                figure
                for setIdx=1:2
                    subplot(1,2,setIdx);
                    hold on
                    for movIdx=1:4
                        pos = squeeze(allDecPos{setIdx,1}(movIdx,:,:));
                        plot(pos(:,1), pos(:,2), '-', 'LineWidth', 2, 'Color', colors(movIdx,:));
                        
                        posCross = squeeze(allDecPos{setIdx,2}(movIdx,:,:));
                        plot(posCross(:,1), posCross(:,2), '-', 'LineWidth', 2, 'Color', colors(movIdx,:), 'LineStyle', '--');
                    end
                    axis equal;
                    xlim([-1.1, 1.1]);
                    ylim([-1.1, 1.1]);
                end
            end
        end
        
        if strcmp(datasets{d,1},'t5.2018.03.14')
            %    't5.2018.03.14',{[5 7],[6 8],[10 11 12 13 14 15],[16 17],[18 19],[20 21]},{'R_joy','L_joy','Bi','Leg','Head','Eye'},[5];
            rIdx = find(ismember(alignDat.bNumPerTrial, [5 7]));
            %eIdx = find(ismember(alignDat.bNumPerTrial, [20]));
            lIdx = find(ismember(alignDat.bNumPerTrial, [6 8]));
            allIdx = [rIdx; lIdx];
            
            %end
            movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
            codeList = unique(movCues);
            
            movType = zeros(length(allIdx),1);
            movType(1:length(rIdx)) = 0;
            movType((length(rIdx)+1):end) = 1;
            
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx), ...
                [movType, movCues], timeWindow/binMS, binMS/1000, {'Eff', 'Dir', 'CI', 'Eff x Dir'} );
            
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
                lineArgs, {'Eff', 'Dir', 'CI', 'Eff x Dir'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        end
        
        if strcmp(datasets{d,1},'t5.2018.03.14')
            effIdx = cell(5,1);
            effIdx{1} = find(ismember(alignDat.bNumPerTrial, [5 7]));
            effIdx{2} = find(ismember(alignDat.bNumPerTrial, [6 8]));
            effIdx{3} = find(ismember(alignDat.bNumPerTrial, [16 17]));
            effIdx{4} = find(ismember(alignDat.bNumPerTrial, [18 19]));
            effIdx{5} = find(ismember(alignDat.bNumPerTrial, [20 21]));
            
            allIdx = [effIdx{1}; effIdx{2}; effIdx{3}; effIdx{4}; effIdx{5}];

            %end
            movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
            codeList = unique(movCues);
            
            movType = zeros(length(allIdx),1);
            currIdx = 1;
            for x=1:length(effIdx)
                movType(currIdx:(currIdx+length(effIdx{x})-1)) = x;
                currIdx = currIdx + length(effIdx{x});
            end
            
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx), ...
                [movType, movCues], timeWindow/binMS, binMS/1000, {'Eff', 'Dir', 'CI', 'Eff x Dir'} );
            
            lineArgs = cell(length(effIdx),4);
            colors = jet(4)*0.8;
            ls = {'-',':','--','-.','-'};
            for x=1:length(effIdx)
                for c=1:4
                    lineArgs{x,c} = {ls{x},'Color',colors(c,:),'LineWidth',2};
                end
            end
            
            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'Eff', 'Dir', 'CI', 'Eff x Dir'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        end
        
        if strcmp(datasets{d,1},'t5.2018.03.14')
            allIdx = find(ismember(alignDat.bNumPerTrial, [10:15]));

            movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
            codeList = unique(movCues);
            
%           BI_LEFT_LEFT(195)
%           BI_LEFT_RIGHT(196)
%           BI_LEFT_UP(197)
%           BI_LEFT_DOWN(198)
% 
%           BI_RIGHT_LEFT(199)
%           BI_RIGHT_RIGHT(200)
%           BI_RIGHT_UP(201)
%           BI_RIGHT_DOWN(202)
% 
%           BI_UP_LEFT(203)
%           BI_UP_RIGHT(204)
%           BI_UP_UP(205)
%           BI_UP_DOWN(206)
% 
%           BI_DOWN_LEFT(207)
%           BI_DOWN_RIGHT(208)
%           BI_DOWN_UP(209)
%           BI_DOWN_DOWN(210)
            
            factorMap = [195, 1, 1;
                196, 1, 2;
                197, 1, 3;
                198, 1, 4;
                199, 2, 1;
                200, 2, 2;
                201, 2, 3;
                202, 2, 4;
                203, 3, 1;
                204, 3, 2;
                205, 3, 3;
                206, 3, 4;
                207, 4, 1;
                208, 4, 2;
                209, 4, 3;
                210, 4, 4;   ];            
            movFactors = zeros(length(movCues),2);
            for x=1:length(movCues)
                fIdx = find(factorMap(:,1)==movCues(x));
                movFactors(x,:) = factorMap(fIdx,2:3);
            end
            
            noUp = find(~ismember(movCues, [197, 201, 203, 204, 205, 206, 209]));
            
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noUp)), ...
                movFactors(noUp,:), timeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'} );
            
            lineArgs = cell(3,3);
            colors = jet(3)*0.8;
            ls = {'-',':','--'};
            for x=1:3
                for c=1:3
                    lineArgs{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
                end
            end
            
            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'Dir L', 'Dir R', 'CI', 'L x R'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        end
        
    end %alignment set
end
