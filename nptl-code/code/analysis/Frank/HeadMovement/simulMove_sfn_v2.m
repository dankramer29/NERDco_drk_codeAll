%%
datasets = {
    't5.2018.05.30',{[14 15 16 17 18 19 21 22 23 24]},{'ArmLegDir'},[14];
    't5.2018.06.04',{[10 11 12 13 14 15 16 17 18 19 20 21 22 23]},{'ArmHeadDir'},[10];
    
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 17 18 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
        
    't5.2018.06.18',{[4 6 7 8 9 10 12],[18 19 20 21 22]},{'LArmRArm','EyeRArm'},[4];
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
    
    clear R;

    %%
    alignFields = {'goCue'};
    smoothWidth = 60;
    if strcmp(datasets{d,1}(1:2),'t5')
        datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
    else
        datFields = {'glove','currentMovement','glove_speed'};
    end
    timeWindow = [-1500,3000];
    binMS = 20;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 0.5;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];

    if strcmp(datasets{d,1},'t5.2018.05.30')
        dualSetIdx = 1;
    elseif strcmp(datasets{d,1},'t5.2018.06.04')
        dualSetIdx = 1;
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

        %%
        %---dual movement----
        allIdx = find(ismember(alignDat.bNumPerTrial, datasets{d,2}{outerMovSetIdx}));
        movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
        eventIdx = alignDat.eventIdx(allIdx);
        varianceSummary = zeros(4,3);

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
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA.svg'],'svg');

        %eff 1
        axIdx = find(dPCA_out_dual.whichMarg==1);
        effDim = dPCA_out_dual.W(:,axIdx(1:min(4,length(axIdx))));
        [ varianceSummary(1,1), varianceSummary(1,2:3) ] = getSimulVariance( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, effDim, 10:50, 100 );
        
        %eff 2
        axIdx = find(dPCA_out_dual.whichMarg==2);
        effDim = dPCA_out_dual.W(:,axIdx(1:min(4,length(axIdx))));
        movWindow = 10:50;
        [ varianceSummary(2,1), varianceSummary(2,2:3) ] = getSimulVariance( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, effDim, 10:50, 100 );
        
        %%
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
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMove_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMove_dPCA.svg'],'svg');

        %same axes
        fullAx = [vertcat(axFromDualMovements{:}); vertcat(axFromSingle{:})];
        fullLims = [min(fullAx(:)), max(fullAx(:))];
        [yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot( dPCA_out_single,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
            lineArgs_single, labelsSingle, 'sameAxes', [], fullLims);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMoveSameAx_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMoveSameAx_dPCA.svg'],'svg');

        [~, allHandles, axFromDualMovements] = twoFactor_dPCA_plot( dPCA_out_dual,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
            lineArgs_dual, labels, 'sameAxes', [], fullLims);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2moveSameAx_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2moveSameAx_dPCA.svg'],'svg');
        
        %eff 2
        movSets = {[187,188,189,190],[191,192,193,194]};
        dPCA_single_set = cell(length(movSets),1);
        for setIdx=1:length(movSets)
            singleMovements = find(ismember(movCues, movSets{setIdx}));
            dPCA_single_set{setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
                movFactors(singleMovements,1), timeWindow/binMS, binMS/1000, {'Dir','CI'} );
            
            axIdx = find(dPCA_single_set{setIdx}.whichMarg==1);
            effDim = dPCA_single_set{setIdx}.W(:,axIdx(1:4));
            movWindow = 10:50;
            [ varianceSummary(setIdx+2,1), varianceSummary(setIdx+2,2:3) ] = getSimulVariance( eventIdx(singleMovements), movCues(singleMovements), ...
                alignDat.zScoreSpikes, effDim, 10:50, 100 );
        end
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_varSummary'],'varianceSummary');
        
        %%
        %2D dPC trajectories
        axHandles = zeros(6,1);
        
        plotWindow = 10:125;
        figure('Position',[252   357   550   745]);
        for setIdx=1:2
            axHandles(setIdx) = subtightplot(3,2,setIdx);
            hold on;
            
            axIdx = find(dPCA_single_set{setIdx}.whichMarg==1);
            nCon = size(dPCA_single_set{setIdx}.Z,2);
            
            for conIdx=1:nCon
                xTraj = squeeze(dPCA_single_set{setIdx}.Z(axIdx(1),conIdx,:));
                yTraj = squeeze(dPCA_single_set{setIdx}.Z(axIdx(2),conIdx,:));
                plot(xTraj(plotWindow), yTraj(plotWindow), 'Color', colors(conIdx,:), 'LineWidth', 2);
            end
            axis tight;
        end
    
        colors = jet(nDirCon)*0.8;
        ls = {'-',':','--','-.'};
        for effIdx=1:2
            axHandles(2+effIdx) = subtightplot(3,2,2+effIdx);
            hold on;
            
            axIdx = find(dPCA_out_dual.whichMarg==effIdx);
            nCon = size(dPCA_out_dual.Z,2);
            
            for conIdx_x=1:nCon
                for conIdx_y=1:nCon
                    xTraj = squeeze(dPCA_out_dual.Z(axIdx(1),conIdx_x,conIdx_y,:));
                    yTraj = squeeze(dPCA_out_dual.Z(axIdx(2),conIdx_x,conIdx_y,:));
                    plot(xTraj(plotWindow), yTraj(plotWindow), 'LineStyle',ls{conIdx_y},'Color',colors(conIdx_x,:), 'LineWidth', 2);
                end
            end
            axis tight;
        end
        
        colors = jet(nDirCon)*0.8;
        ls = {'-',':','--','-.'};
        for effIdx=1:2
            axHandles(4+effIdx) = subtightplot(3,2,4+effIdx);
            hold on;
            
            axIdx = find(dPCA_single_set{effIdx}.whichMarg==1);
            W = dPCA_single_set{effIdx}.W(:,axIdx(1:2));
            nCon = size(dPCA_out_dual.Z,2);
            
            for conIdx_x=1:nCon
                for conIdx_y=1:nCon
                    neuralAct = squeeze(dPCA_out_dual.featureAverages(:,conIdx_x,conIdx_y,:))';
                    traj = neuralAct*W;
                    plot(traj(plotWindow,1), traj(plotWindow,2), 'LineStyle',ls{conIdx_y},'Color',colors(conIdx_x,:),'LineWidth',2);
                end
            end
            axis tight;
        end
        
        allLim = [];
        for x=1:length(axHandles)
            yLimits = get(axHandles(x),'YLim');
            xLimits = get(axHandles(x),'XLim');
            allLim = [allLim; xLimits, yLimits];
        end
        finalLimits = [min(allLim(:,1)), max(allLim(:,2)), min(allLim(:,3)), max(allLim(:,4))];
        
        for x=1:length(axHandles)
            axes(axHandles(x));
            axis off;
            xlim(finalLimits(1:2));
            ylim(finalLimits(3:4));
        end
        
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'dPCA_traj.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'dPCA_traj.svg'],'svg');
        
        close all;
        
        %%
        if nDirCon==2
            continue
        end
        
        %%
        %encoding PD metrics
        %==transfer of single-movement dimensions to dual context==
        singleMovementCodes = [187,188,189,190,191,192,193,194];
        
        %single-bin encoding models
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

        %single movement encoding
        singleMovements = find(ismember(movCues, singleMovementCodes));
        
        epochsToUse = [alignDat.eventIdx(allIdx(singleMovements))+10, ...
            alignDat.eventIdx(allIdx(singleMovements))+60];
        singleTrlAvg = zeros(length(epochsToUse),size(alignDat.zScoreSpikes,2));
        singleTrlMoveDir = zeros(length(epochsToUse),4);
        
        for t=1:length(epochsToUse)
            loopIdx = epochsToUse(t,1):epochsToUse(t,2);
            singleTrlAvg(t,:) = mean(alignDat.zScoreSpikes(loopIdx,:));
            singleTrlMoveDir(t,:) = mean(movDir(loopIdx,:));
        end
        
        %dual movement encoding
        cuesToUse = setdiff(dirFactorMap(:,1), singleMovementCodes);
        dualMovements = find(ismember(movCues, cuesToUse));
        
        epochsToUse = [alignDat.eventIdx(allIdx(dualMovements))+10, ...
            alignDat.eventIdx(allIdx(dualMovements))+60];
        dualTrlAvg = zeros(length(epochsToUse),size(alignDat.zScoreSpikes,2));
        dualMoveDir = zeros(length(epochsToUse),4);
        
        for t=1:length(epochsToUse)
            loopIdx = epochsToUse(t,1):epochsToUse(t,2);
            dualTrlAvg(t,:) = mean(alignDat.zScoreSpikes(loopIdx,:));
            dualMoveDir(t,:) = mean(movDir(loopIdx,:));
        end
        
        meanStats = simulMovePDStat( singleTrlAvg, singleTrlMoveDir, dualTrlAvg, dualMoveDir );
        
        bootStats = zeros(1000,4);
        for n=1:1000
            disp(n);
            singleIdx = randi(size(singleTrlAvg,1), size(singleTrlAvg,1), 1);
            dualIdx = randi(size(dualTrlAvg,1), size(dualTrlAvg,1), 1);
            bootStats(n,:) = simulMovePDStat( singleTrlAvg(singleIdx,:), singleTrlMoveDir(singleIdx,:), dualTrlAvg(dualIdx,:), dualMoveDir(dualIdx,:) );
        end
        
        statCI = prctile(bootStats, [2.5, 97.5]);
        
        %%
        epochsToUse = [alignDat.eventIdx(allIdx(singleMovements))+10, ...
            alignDat.eventIdx(allIdx(singleMovements))+60];
        loopIdxToTrain = expandEpochIdx(epochsToUse);
        coef_single = buildLinFilts(alignDat.zScoreSpikes(loopIdxToTrain,:), [ones(length(loopIdxToTrain),1), movDir(loopIdxToTrain,:)], 'standard')';
        
        pValSingle = zeros(size(alignDat.zScoreSpikes,2),1);
        for x=1:size(alignDat.zScoreSpikes,2)
            trlAvgRates = zeros(length(epochsToUse),1);
            trlAvgDir = zeros(length(epochsToUse),4);
            for t=1:length(epochsToUse)
                loopIdx = epochsToUse(t,1):epochsToUse(t,2);
                trlAvgRates(t) = mean(alignDat.zScoreSpikes(loopIdx,x));
                trlAvgDir(t,:) = mean(movDir(loopIdx,:));
            end
            
            tmpMS = trlAvgRates - mean(trlAvgRates);
            [B,BINT,R,RINT,STATS] = regress(tmpMS,trlAvgDir);
            pValSingle(x) = STATS(3);
        end

        %dual movement encoding
        cuesToUse = setdiff(dirFactorMap(:,1), singleMovementCodes);
        dualMovements = find(ismember(movCues, cuesToUse));
        epochsToUse = [alignDat.eventIdx(allIdx(dualMovements))+10, ...
            alignDat.eventIdx(allIdx(dualMovements))+60];
        
        loopIdxToTrain = expandEpochIdx(epochsToUse);
        coef_dual = buildLinFilts(alignDat.zScoreSpikes(loopIdxToTrain,:), [ones(length(loopIdxToTrain),1), movDir(loopIdxToTrain,:)], 'standard')';
        
        pValDual = zeros(size(alignDat.zScoreSpikes,2),1);
        for x=1:size(alignDat.zScoreSpikes,2)
            trlAvgRates = zeros(length(epochsToUse),1);
            trlAvgDir = zeros(length(epochsToUse),4);
            for t=1:length(epochsToUse)
                loopIdx = epochsToUse(t,1):epochsToUse(t,2);
                trlAvgRates(t) = mean(alignDat.zScoreSpikes(loopIdx,x));
                trlAvgDir(t,:) = mean(movDir(loopIdx,:));
            end
            
            tmpMS = trlAvgRates - mean(trlAvgRates);
            [B,BINT,R,RINT,STATS] = regress(tmpMS,trlAvgDir);
            pValDual(x) = STATS(3);
        end
        
        %summarize
        sigUnits = find(pValSingle<0.001 & pValDual<0.001);

        figure
        hold on
        plot(coef_single(sigUnits,2), coef_dual(sigUnits,2), 'o');
        plot(coef_single(sigUnits,3), coef_dual(sigUnits,3), 'ro');
        axis equal;
        
        figure
        hold on
        plot(coef_single(sigUnits,4), coef_dual(sigUnits,4), 'o');
        plot(coef_single(sigUnits,5), coef_dual(sigUnits,5), 'ro');
        axis equal;

        %%
        %velocity decoding metrics
        %==transfer of single-movement dimensions to dual context==
        movSets = {[187,188,189,190],[191,192,193,194]};
        allDecPos = cell(length(movSets),3);
        allDecCI = cell(length(movSets),3);
        
        for setIdx=1:length(movSets)
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

            nFolds = length(singleMovements)/2;
            cvInd = crossvalind('Kfold', length(singleMovements), nFolds);
            decDir = zeros(size(alignDat.zScoreSpikes,1),2);
            for foldIdx=1:nFolds
                trainIdx = cvInd~=foldIdx;
                epochsToUse = [alignDat.eventIdx(allIdx(singleMovements(trainIdx)))+10, ...
                    alignDat.eventIdx(allIdx(singleMovements(trainIdx)))+60];
                loopIdxToTrain = expandEpochIdx(epochsToUse);

                coef = buildLinFilts(movDir(loopIdxToTrain,(1:2)+(setIdx-1)*2), alignDat.zScoreSpikes(loopIdxToTrain,:), 'inverseLinear');
                for colIdx=1:size(coef,2)
                    coef(:,colIdx) = coef(:,colIdx)/norm(coef(:,colIdx));
                end
                
                testIdx = cvInd==foldIdx;
                epochsToUse = [alignDat.eventIdx(allIdx(singleMovements(testIdx)))+10, ...
                    alignDat.eventIdx(allIdx(singleMovements(testIdx)))+60];
                loopIdxToTest = expandEpochIdx(epochsToUse);
                decDir(loopIdxToTest,:) = alignDat.zScoreSpikes(loopIdxToTest,:)*coef;
            end

            allEpochs = [alignDat.eventIdx(allIdx(singleMovements))+10, ...
                alignDat.eventIdx(allIdx(singleMovements))+60];
            loopIdxSingle = expandEpochIdx(allEpochs);
            loopIdxTheRest = setdiff(1:size(alignDat.zScoreSpikes,1), loopIdxSingle);
            decDir(loopIdxTheRest,:) = alignDat.zScoreSpikes(loopIdxTheRest,:)*coef;

            avgDec = zeros(length(movSets{setIdx}), 51, 2);
            ciDec = zeros(length(movSets{setIdx}), 51, 2, 2);
            for movIdx=1:length(movSets{setIdx})
                trlIdx = allIdx(ismember(movCues,movSets{setIdx}(movIdx)));
                concatDat = triggeredAvg( decDir, alignDat.eventIdx(trlIdx), [10,60] );
                pos = cumsum(concatDat,2);
                avgDec(movIdx, :, :) = squeeze(mean(pos,1));
                for dimIdx=1:size(pos,3)
                    for stepIdx=1:size(pos,2)
                        [~,~,ciDec(movIdx, stepIdx, dimIdx, :)] = normfit(squeeze(pos(:, stepIdx, dimIdx)));
                    end
                end
            end

            avgDecCross = zeros(length(movSets{setIdx}), 51, 2);
            ciDecCross = zeros(length(movSets{setIdx}), 51, 2, 2);
            for movIdx=1:length(movSets{setIdx})
                cuesToUse = dirFactorMap(:,setIdx+1)==movIdx;
                cuesToUse(1:8) = 0;
                trlIdx = allIdx(ismember(movCues, dirFactorMap(cuesToUse,1)));

                concatDat = triggeredAvg( decDir, alignDat.eventIdx(trlIdx), [10,60] );
                pos = cumsum(concatDat,2);
                avgDecCross(movIdx, :, :) = squeeze(mean(pos,1));
                for dimIdx=1:size(pos,3)
                    for stepIdx=1:size(pos,2)
                        [~,~,ciDecCross(movIdx, stepIdx, dimIdx, :)] = normfit(squeeze(pos(:, stepIdx, dimIdx)));
                    end
                end
            end
            
            mcList = unique(movCues);
            avgDecNoAvg = zeros(length(mcList), 51, 2);
            ciDecNoAvg = zeros(length(mcList), 51, 2, 2);
            for movIdx=1:length(mcList)
                trlIdx = allIdx(ismember(movCues,mcList(movIdx)));
                concatDat = triggeredAvg( decDir, alignDat.eventIdx(trlIdx), [10,60] );
                pos = cumsum(concatDat,2);
                avgDecNoAvg(movIdx, :, :) = squeeze(mean(pos,1));
                for dimIdx=1:size(pos,3)
                    for stepIdx=1:size(pos,2)
                        [~,~,ciDecNoAvg(movIdx, stepIdx, dimIdx, :)] = normfit(squeeze(pos(:, stepIdx, dimIdx)));
                    end
                end
            end

            %maxValue = max([abs(avgDec(:)); abs(avgDecCross(:))]);
            maxValue = 1;
            
            avgDec = avgDec / maxValue;
            avgDecCross = avgDecCross / maxValue;
            ciDec = ciDec / maxValue;
            ciDecCross = ciDecCross / maxValue;

            allDecPos{setIdx,1} = avgDec;
            allDecPos{setIdx,2} = avgDecCross;
            allDecPos{setIdx,3} = avgDecNoAvg;

            allDecCI{setIdx,1} = ciDec;
            allDecCI{setIdx,2} = ciDecCross;
            allDecCI{setIdx,3} = ciDecNoAvg;
        end

        %%
        %decoder built on dual condition
        movSets = {[187,188,189,190],[191,192,193,194]};
        allDecPos_dual = cell(length(movSets),2);
        allDecCI_dual = cell(length(movSets),2);
        for setIdx=1:length(movSets)
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
            dualMovements = find(~ismember(movCues, horzcat(movSets{setIdx})));
            
            nFolds = 10;
            cvInd = crossvalind('Kfold', length(singleMovements), nFolds);
            decDir = zeros(size(alignDat.zScoreSpikes,1),2);
            for foldIdx=1:nFolds
                trainIdx = cvInd~=foldIdx;
                epochsToUse = [alignDat.eventIdx(allIdx(dualMovements(trainIdx)))+10, ...
                    alignDat.eventIdx(allIdx(dualMovements(trainIdx)))+60];
                loopIdxToTrain = expandEpochIdx(epochsToUse);

                coef = buildLinFilts(movDir(loopIdxToTrain,(1:2)+(setIdx-1)*2), alignDat.zScoreSpikes(loopIdxToTrain,:), 'inverseLinear');
                for colIdx=1:size(coef,2)
                    coef(:,colIdx) = coef(:,colIdx)/norm(coef(:,colIdx));
                end
                
                testIdx = cvInd==foldIdx;
                epochsToUse = [alignDat.eventIdx(allIdx(dualMovements(testIdx)))+10, ...
                    alignDat.eventIdx(allIdx(dualMovements(testIdx)))+60];
                loopIdxToTest = expandEpochIdx(epochsToUse);
                decDir(loopIdxToTest,:) = alignDat.zScoreSpikes(loopIdxToTest,:)*coef;
            end

            allEpochs = [alignDat.eventIdx(allIdx(singleMovements))+10, ...
                alignDat.eventIdx(allIdx(singleMovements))+60];
            loopIdxSingle = expandEpochIdx(allEpochs);
            loopIdxTheRest = setdiff(1:size(alignDat.zScoreSpikes,1), loopIdxSingle);
            decDir(loopIdxTheRest,:) = alignDat.zScoreSpikes(loopIdxTheRest,:)*coef;

            avgDec = zeros(length(movSets{setIdx}), 51, 2);
            ciDec = zeros(length(movSets{setIdx}), 51, 2, 2);
            for movIdx=1:length(movSets{setIdx})
                trlIdx = allIdx(ismember(movCues,movSets{setIdx}(movIdx)));
                concatDat = triggeredAvg( decDir, alignDat.eventIdx(trlIdx), [10,60] );
                pos = cumsum(concatDat,2);
                avgDec(movIdx, :, :) = squeeze(mean(pos,1));
                for dimIdx=1:size(pos,3)
                    for stepIdx=1:size(pos,2)
                        [~,~,ciDec(movIdx, stepIdx, dimIdx, :)] = normfit(squeeze(pos(:, stepIdx, dimIdx)));
                    end
                end
            end

            avgDecCross = zeros(length(movSets{setIdx}), 51, 2);
            ciDecCross = zeros(length(movSets{setIdx}), 51, 2, 2);
            for movIdx=1:length(movSets{setIdx})
                cuesToUse = dirFactorMap(:,setIdx+1)==movIdx;
                cuesToUse(1:8) = 0;
                trlIdx = allIdx(ismember(movCues, dirFactorMap(cuesToUse,1)));

                concatDat = triggeredAvg( decDir, alignDat.eventIdx(trlIdx), [10,60] );
                pos = cumsum(concatDat,2);
                avgDecCross(movIdx, :, :) = squeeze(mean(pos,1));
                for dimIdx=1:size(pos,3)
                    for stepIdx=1:size(pos,2)
                        [~,~,ciDecCross(movIdx, stepIdx, dimIdx, :)] = normfit(squeeze(pos(:, stepIdx, dimIdx)));
                    end
                end
            end
            
            mcList = unique(movCues);
            avgDecNoAvg = zeros(length(mcList), 51, 2);
            ciDecNoAvg = zeros(length(mcList), 51, 2, 2);
            for movIdx=1:length(mcList)
                trlIdx = allIdx(ismember(movCues,mcList(movIdx)));
                concatDat = triggeredAvg( decDir, alignDat.eventIdx(trlIdx), [10,60] );
                pos = cumsum(concatDat,2);
                avgDecNoAvg(movIdx, :, :) = squeeze(mean(pos,1));
                for dimIdx=1:size(pos,3)
                    for stepIdx=1:size(pos,2)
                        [~,~,ciDecNoAvg(movIdx, stepIdx, dimIdx, :)] = normfit(squeeze(pos(:, stepIdx, dimIdx)));
                    end
                end
            end

            maxValue = 1;
            
            avgDec = avgDec / maxValue;
            avgDecCross = avgDecCross / maxValue;
            ciDec = ciDec / maxValue;
            ciDecCross = ciDecCross / maxValue;

            allDecPos_dual{setIdx,1} = avgDec;
            allDecPos_dual{setIdx,2} = avgDecCross;
            allDecPos_dual{setIdx,3} = avgDecNoAvg;

            allDecCI_dual{setIdx,1} = ciDec;
            allDecCI_dual{setIdx,2} = ciDecCross;
            allDecCI_dual{setIdx,3} = ciDecNoAvg;
        end
        
        %%
        %decoder variance summary
        decVariance = zeros(4,3);
        decVariance(1,1) = mean(matVecMag(squeeze(allDecPos{1,1}(:,end,:)),2));
        decVariance(2,1) = mean(matVecMag(squeeze(allDecPos{2,1}(:,end,:)),2));
        
        for effIdx=1:2
            tmpAvg = [];
            for movIdx=1:length(movSets{effIdx})
                cuesToUse = dirFactorMap(:,effIdx+1)==movIdx;
                cuesToUse(1:8) = 0;
                
                sTmp = squeeze(allDecPos_dual{effIdx,3}(:,end,:));
                tmpAvg = [tmpAvg; mean(sTmp(cuesToUse,:))];
            end
            decVariance(2+effIdx,1) = mean(matVecMag(tmpAvg,2));
        end

        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_varSummaryDecVel'],'decVariance');
        
        %%
        movTitles = {'Eff 1','Eff 2'};
        axHandles = zeros(3,2);
        
        figure('Position',[680   328   598   770]);
        for decTypeIdx=1:3
            for setIdx=1:2
                axHandles(decTypeIdx,setIdx) = subtightplot(3,2,(decTypeIdx-1)*2 + setIdx);
                hold on
                
                %--single train--
                if decTypeIdx==1
                    for movIdx=1:4
                        pos = squeeze(allDecPos{setIdx,1}(movIdx,:,:));
                        plot(pos(:,1), pos(:,2), '-', 'LineWidth', 2, 'Color', colors(movIdx,:));

                        rectangle('Position',[squeeze(allDecCI{setIdx,1}(movIdx,end,1,1)), squeeze(allDecCI{setIdx,1}(movIdx,end,2,1)), ...
                            squeeze(allDecCI{setIdx,1}(movIdx,end,1,2))-squeeze(allDecCI{setIdx,1}(movIdx,end,1,1)), ...
                            squeeze(allDecCI{setIdx,1}(movIdx,end,2,2))-squeeze(allDecCI{setIdx,1}(movIdx,end,2,1))], 'Curvature', [1 1], ...
                            'LineWidth', 2, 'EdgeColor', colors(movIdx,:));
                    end
                elseif decTypeIdx==2
                    for movIdx=9:24
                        lsToUse = ls{dirFactorMap(movIdx,2)};
                        colorToUse = colors(dirFactorMap(movIdx,3),:);
                        
                        posCross = squeeze(allDecPos{setIdx,3}(movIdx,:,:));
                        plot(posCross(:,1), posCross(:,2), '-', 'LineWidth', 2, 'Color', colorToUse, 'LineStyle', lsToUse);

                        rectangle('Position',[squeeze(allDecCI{setIdx,3}(movIdx,end,1,1)), squeeze(allDecCI{setIdx,3}(movIdx,end,2,1)), ...
                            squeeze(allDecCI{setIdx,3}(movIdx,end,1,2))-squeeze(allDecCI{setIdx,3}(movIdx,end,1,1)), ...
                            squeeze(allDecCI{setIdx,3}(movIdx,end,2,2))-squeeze(allDecCI{setIdx,3}(movIdx,end,2,1))], 'Curvature', [1 1], ...
                            'LineWidth', 2, 'EdgeColor', colorToUse, 'LineStyle',lsToUse);
                    end
                elseif decTypeIdx==3
                    %--dual train--
                    for movIdx=9:24
                        lsToUse = ls{dirFactorMap(movIdx,2)};
                        colorToUse = colors(dirFactorMap(movIdx,3),:);
                       
                        posCross = squeeze(allDecPos_dual{setIdx,3}(movIdx,:,:));
                        plot(posCross(:,1), posCross(:,2), '-', 'LineWidth', 2, 'Color', colorToUse, 'LineStyle', lsToUse);

                        rectangle('Position',[squeeze(allDecCI_dual{setIdx,3}(movIdx,end,1,1)), squeeze(allDecCI_dual{setIdx,3}(movIdx,end,2,1)), ...
                            squeeze(allDecCI_dual{setIdx,3}(movIdx,end,1,2))-squeeze(allDecCI_dual{setIdx,3}(movIdx,end,1,1)), ...
                            squeeze(allDecCI_dual{setIdx,3}(movIdx,end,2,2))-squeeze(allDecCI_dual{setIdx,3}(movIdx,end,2,1))], 'Curvature', [1 1], ...
                            'LineWidth', 2, 'EdgeColor', colorToUse, 'LineStyle',lsToUse);
                    end
                end
                
                axis tight;
                axis equal;
                axis off;
                if decTypeIdx==1
                    title(movTitles{setIdx});
                end
                set(gca,'FontSize',16);
            end
        end
        axHandles = axHandles(:);
        
        allLim = [];
        for x=1:length(axHandles)
            yLimits = get(axHandles(x),'YLim');
            xLimits = get(axHandles(x),'XLim');
            allLim = [allLim; xLimits, yLimits];
        end
        finalLimits = [min(allLim(:,1)), max(allLim(:,2)), min(allLim(:,3)), max(allLim(:,4))];
        
        for x=1:length(axHandles)
            axes(axHandles(x));
            axis off;
            xlim(finalLimits(1:2));
            ylim(finalLimits(3:4));
        end

        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_decTraj.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_decTraj.svg'],'svg');
        
        close all;
    end
end
