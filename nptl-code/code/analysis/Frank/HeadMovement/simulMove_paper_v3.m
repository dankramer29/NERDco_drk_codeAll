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

effNames = {{{'RLeg','RArm'}};
    {{'Head','RArm'}};
    {{'Head','Tongue'},{'LArm','RArm'},{'Head','RArm'},{'LLeg','RLeg'},{'LLeg','RArm'}};
    {{'Head','RArm'},{'RLeg','RArm'}};
    {{'Head','RLeg'},{'Head','LLeg'},{'Head','LArm'},{'LArm','RLeg'},{'LArm','LLeg'},{'LLeg','RLeg'},{'LLeg','RArm'},{'RLeg','RArm'}};
    {{'LArm','RArm'},{'Eyes','RArm'}}};

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
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 4.5, datasets{d,4}, filtOpts );
    
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
    movTimeWindow = [0,1000];
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
        close all;
        
        %%
        %---dual movement----
        allIdx = find(ismember(alignDat.bNumPerTrial, datasets{d,2}{outerMovSetIdx}));
        movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
        eventIdx = alignDat.eventIdx(allIdx);
        varianceSummary = zeros(5,3);

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
            movFactors(noSingleMovements,:), timeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 30, 'xval' );
        
        dPCA_dual_movWindow = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements)), ...
            movFactors(noSingleMovements,:), movTimeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 30, 'xval' );
        
        dPCA_out_dual_oneFactor = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements)), ...
            movCues(noSingleMovements), timeWindow/binMS, binMS/1000, {'CD','CI'}, 30 );

        lineArgs_dual = cell(nDirCon,nDirCon);
        if nDirCon==4
            colors = jet(nDirCon)*0.8;
        else
            colors = [0.8 0.6 0.8;
                0.6 0.2 0.6];
        end
        ls = {'-',':','--','-.'};
        for x=1:nDirCon
            for c=1:nDirCon
                lineArgs_dual{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
            end
        end

        %2-factor dPCA
        eff1 = effNames{d}{outerMovSetIdx}{1};
        eff2 = effNames{d}{outerMovSetIdx}{2};
        
        labels = {eff1, eff2, 'CI', [eff1 ' x ' eff2]};
        layoutInfo.nPerMarg = 1;
        layoutInfo.fPos = [49   846   776   213];
        layoutInfo.gap = [0.03 0.01];
        layoutInfo.marg_h = [0.07 0.02];
        layoutInfo.marg_w = [0.30 0.10];
        layoutInfo.colorFactor = 2;
        layoutInfo.textLoc = [0.7,0.2];
        layoutInfo.plotLayout = 'horizontal';
        layoutInfo.verticalBars = [0,1.5];

        timeAxis = ((timeWindow(1)/binMS):(timeWindow(2)/binMS))/50;
        [yAxesFinal, allHandles, axFromDualMovements] = general_dPCA_plot( dPCA_out_dual.cval, timeAxis, lineArgs_dual, ...
            labels, 'sameAxes', [], [-6,6], dPCA_out_dual.cval.dimCI, colors, layoutInfo );
    
        axes(allHandles{1});
        ylabel('Dimension 1 (SD)');
        
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA.svg'],'svg');
        
        %PCA
        timeAxis = ((timeWindow(1)/binMS):(timeWindow(2)/binMS))/50;
        [yAxesFinal, allHandles, axFromDualMovements] = general_dPCA_plot( dPCA_out_dual.pca_result, timeAxis, lineArgs_dual, ...
            labels, 'sameAxes', [], [-6,6], [], colors, layoutInfo );
        
        %mov window
        timeAxis = ((movTimeWindow(1)/binMS):(movTimeWindow(2)/binMS))/50;
        [yAxesFinal, allHandles, axFromDualMovements] = general_dPCA_plot( dPCA_dual_movWindow.cval, timeAxis, lineArgs_dual, ...
            labels, 'sameAxes', [], [-6,6], dPCA_dual_movWindow.cval.dimCI, colors, layoutInfo );
        
        %eff 1
        axIdx = find(dPCA_dual_movWindow.cval.whichMarg==1);
        dualDim_eff1 = dPCA_dual_movWindow.cval.resortW;
        for x=1:length(dualDim_eff1)
            dualDim_eff1{x} = dualDim_eff1{x}(:,axIdx(1:min(4,length(axIdx))));
        end

        [ varianceSummary(1,1), varianceSummary(1,2:3) ] = getSimulVariance_xval( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, dualDim_eff1, 10:50, 100 );
        
        %eff 2
        axIdx = find(dPCA_dual_movWindow.cval.whichMarg==2);
        dualDim_eff2 = dPCA_dual_movWindow.cval.resortW;
        for x=1:length(dualDim_eff2)
            dualDim_eff2{x} = dualDim_eff2{x}(:,axIdx(1:min(4,length(axIdx))));
        end
        
        [ varianceSummary(2,1), varianceSummary(2,2:3) ] = getSimulVariance_xval( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, dualDim_eff2, 10:50, 100 );
        
        %interaction variance
        axIdx = find(dPCA_dual_movWindow.cval.whichMarg==4);
        interactionDim = dPCA_dual_movWindow.cval.resortW;
        for x=1:length(interactionDim)
            interactionDim{x} = interactionDim{x}(:,axIdx(1:min(4,length(axIdx))));
        end
        
        [ varianceSummary(5,1), varianceSummary(5,2:3) ] = getSimulVariance_xval( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, interactionDim, 10:50, 100 );
                
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
        movFactors_single = zeros(length(movCues),2);
        for x=1:length(movCues)
            fIdx = find(factorMap(:,1)==movCues(x));
            movFactors_single(x,:) = factorMap(fIdx,2:3);
        end

        singleMovements = find(ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
        dPCA_out_single = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
            movFactors_single(singleMovements,:), timeWindow/binMS, binMS/1000, {'Dir', 'Eff', 'CI', 'Dir x Eff'}, 20, 'xval' );
        
        lineArgs_single = cell(nDirCon,2);
        if nDirCon==2
            singleColors = [0.8 0 0;
                1.0 0.6 0.6;
                0.0 0.0 0.8;
                0.6 0.6 1.0];
            for x=1:4
                lineArgs_single{x} = {'Color',singleColors(x,:),'LineWidth',2,'LineStyle','-'};
            end
        else    
            singleColors = jet(nDirCon)*0.8;
            ls = {'-',':'};
            for x=1:nDirCon
                for c=1:2
                    lineArgs_single{x,c} = {'Color',singleColors(x,:),'LineWidth',2,'LineStyle',ls{c}};
                end
            end
        end

        %2-factor dPCA
        labels = {'Dir', 'Effector', 'CI', 'Dir x Eff'};
        layoutInfo.nPerMarg = 1;
        layoutInfo.fPos = [49   846   776   213];
        layoutInfo.gap = [0.03 0.01];
        layoutInfo.marg_h = [0.07 0.02];
        layoutInfo.marg_w = [0.30 0.10];
        layoutInfo.colorFactor = 2;
        layoutInfo.textLoc = [0.7,0.2];
        layoutInfo.plotLayout = 'horizontal';
        layoutInfo.verticalBars = [0,1.5];
        
        timeAxis = ((timeWindow(1)/binMS):(timeWindow(2)/binMS))/50;
        [yAxesFinal, allHandles, axFromSingle] = general_dPCA_plot( dPCA_out_single.cval, timeAxis, lineArgs_single, ...
            labels, 'sameAxes', [], [-6,6], dPCA_out_single.cval.dimCI, singleColors, layoutInfo );
        
        axes(allHandles{1});
        ylabel('Rate (SD)');
        
        %[yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot( dPCA_out_single,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
        %    lineArgs_single, labelsSingle, 'sameAxes', []);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMove_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMove_dPCA.svg'],'svg');

        %same axes
        fullAx = [vertcat(axFromDualMovements{:}); vertcat(axFromSingle{:})];
        fullLims = [min(fullAx(:)), max(fullAx(:))];
        [yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot( dPCA_out_single,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
            lineArgs_single, labels, 'sameAxes', [], fullLims);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMoveSameAx_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_singleMoveSameAx_dPCA.svg'],'svg');

        [~, allHandles, axFromDualMovements] = twoFactor_dPCA_plot( dPCA_out_dual,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
            lineArgs_dual, labels, 'sameAxes', [], fullLims);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2moveSameAx_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2moveSameAx_dPCA.svg'],'svg');
        
        %eff 2
        movSets = {[187,188,189,190],[191,192,193,194]};
        dPCA_single_set = cell(length(movSets),1);
        dPCA_single_set_movWindow = cell(length(movSets),1);
        trlSets_single = cell(length(movSets),1);
        trlSets_single_inner = cell(length(movSets),1);
        lineArgs_singleSets = {lineArgs_single(1:nDirCon), lineArgs_single((1+nDirCon):end)};
        singleEffDim = cell(length(movSets),1);
        
        for setIdx=1:length(movSets)
            singleMovements = find(ismember(movCues, movSets{setIdx}));
            dPCA_single_set{setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
                movFactors_single(singleMovements,1), timeWindow/binMS, binMS/1000, {'Dir','CI'}, 20, 'xval' );
            
            dPCA_single_set_movWindow{setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
                movFactors_single(singleMovements,1), movTimeWindow/binMS, binMS/1000, {'Dir','CI'}, 20, 'xval' );
            
            axIdx = find(dPCA_single_set_movWindow{setIdx}.cval.whichMarg==1);
            singleEffDim{setIdx} = dPCA_single_set_movWindow{setIdx}.cval.resortW;
            for x=1:length(singleEffDim{setIdx})
                singleEffDim{setIdx}{x} = singleEffDim{setIdx}{x}(:,axIdx(1:4));
            end

            movWindow = 10:50;
            [ varianceSummary(setIdx+2,1), varianceSummary(setIdx+2,2:3) ] = getSimulVariance_xval( eventIdx(singleMovements), movCues(singleMovements), ...
                alignDat.zScoreSpikes, singleEffDim{setIdx}, 10:50, 100 );
            
            trlSets_single{setIdx} = allIdx(singleMovements);
            trlSets_single_inner{setIdx} = singleMovements;
            
            labels = {'Dir', 'CI'};
            layoutInfo.nPerMarg = 1;
            layoutInfo.fPos = [49   846   388   213];
            layoutInfo.gap = [0.03 0.01];
            layoutInfo.marg_h = [0.07 0.02];
            layoutInfo.marg_w = [0.30 0.10];
            layoutInfo.colorFactor = 2;
            layoutInfo.textLoc = [0.7,0.2];
            layoutInfo.plotLayout = 'horizontal';
            layoutInfo.verticalBars = [0,1.5];

            timeAxis = ((timeWindow(1)/binMS):(timeWindow(2)/binMS))/50;
            [yAxesFinal, allHandles, axFromSingle] = general_dPCA_plot( dPCA_single_set{setIdx}.cval, timeAxis, lineArgs_singleSets{setIdx}, ...
                labels, 'sameAxes', [], [-6,6], dPCA_single_set{setIdx}.cval.dimCI, colors, layoutInfo );

            axes(allHandles{1});
            ylabel('Rate (SD)');
            
            saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_singleSet_dPCA_' num2str(setIdx) '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_singleSet_dPCA_' num2str(setIdx) '.svg'],'svg');
        end
        
        %%
        %use resampling to compute variance ratios
        %singleEffDim{setIdx}
        %dualDim_eff2
        nResamples = 1000;
        resampleRatios = zeros(nResamples,4);
        allTrlSets = {trlSets_single_inner{1}, trlSets_single_inner{2}, noSingleMovements};
        
        dualMarginSets = {movFactors(noSingleMovements,1), movFactors(noSingleMovements,2)};

        for resampleIdx=1:nResamples
            allRISets = cell(length(allTrlSets),1);
            for x=1:length(allTrlSets)
                cueList = unique(movCues(allTrlSets{x}));
                allRISets{x} = [];
                for c=1:length(cueList)
                    cueTrl = find(movCues(allTrlSets{x})==cueList(c));
                    allRISets{x} = [allRISets{x}; cueTrl(randi(length(cueTrl), length(cueTrl), 1))];
                end
            end
                        
            eff1_single = trlSets_single_inner{1}(allRISets{1});
            eff2_single = trlSets_single_inner{2}(allRISets{2});
            dualTrl = noSingleMovements(allRISets{3});
            
            eff1_var = getSimulVariance_xval( eventIdx(eff1_single), movCues(eff1_single), ...
                alignDat.zScoreSpikes, singleEffDim{1}(allRISets{1}), 10:50, 0 );
            eff2_var = getSimulVariance_xval( eventIdx(eff2_single), movCues(eff2_single), ...
                alignDat.zScoreSpikes, singleEffDim{2}(allRISets{2}), 10:50, 0 );
            
            %movCues(dualTrl)
            eff1_dualVar = getSimulVariance_xval( eventIdx(dualTrl), movCues(dualTrl), ...
                alignDat.zScoreSpikes, dualDim_eff1(allRISets{3}), 10:50, 0 );
            eff2_dualVar = getSimulVariance_xval( eventIdx(dualTrl), movCues(dualTrl), ...
                alignDat.zScoreSpikes, dualDim_eff2(allRISets{3}), 10:50, 0 );
            
            eff1_dualVar_cross = getSimulVariance( eventIdx(eff1_single), movCues(eff1_single), ...
                alignDat.zScoreSpikes, dualDim_eff1{1}, 10:50, 0 );
            eff2_dualVar_cross = getSimulVariance( eventIdx(eff2_single), movCues(eff2_single), ...
                alignDat.zScoreSpikes, dualDim_eff2{1}, 10:50, 0 );
            
            resampleRatios(resampleIdx,:) = [eff1_dualVar/eff1_var, eff2_dualVar/eff2_var, ...
                eff1_dualVar_cross/eff1_var, eff2_dualVar_cross/eff2_var];
        end
          
        varianceSummary(6,:) = [varianceSummary(1,1)/varianceSummary(3,1), prctile(resampleRatios(:,1),[2.5 97.5])];
        varianceSummary(7,:) = [varianceSummary(2,1)/varianceSummary(4,1), prctile(resampleRatios(:,2),[2.5 97.5])];
        
        eff1_dualVar_cross = getSimulVariance( eventIdx(trlSets_single_inner{1}), movCues(trlSets_single_inner{1}), ...
            alignDat.zScoreSpikes, dualDim_eff1{1}, 10:50, 0 );
        eff2_dualVar_cross = getSimulVariance( eventIdx(trlSets_single_inner{2}), movCues(trlSets_single_inner{2}), ...
            alignDat.zScoreSpikes, dualDim_eff2{1}, 10:50, 0 );
        
        varianceSummary(8,:) = [eff1_dualVar_cross/eff1_var, prctile(resampleRatios(:,3),[2.5 97.5])];
        varianceSummary(9,:) = [eff2_dualVar_cross/eff2_var, prctile(resampleRatios(:,4),[2.5 97.5])];
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_varSummary'],'varianceSummary');
                       
        %%
        %example single trial
        cWindow = (-timeWindow(1)/binMS) + (10:50);
        allMN = [squeeze(nanmean(dPCA_single_set{1}.featureAverages(:,:,cWindow),3)), ...
            squeeze(nanmean(dPCA_single_set{2}.featureAverages(:,:,cWindow),3)), ...
            squeeze(nanmean(dPCA_out_dual.featureAverages(:,1,:,cWindow),4)), ...
            squeeze(nanmean(dPCA_out_dual.featureAverages(:,2,:,cWindow),4))];
            
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allMN');
        
        stData = cat(2, squeeze(nanmean(dPCA_single_set{1}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_single_set{2}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,1,:,cWindow,:),4)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,2,:,cWindow,:),4)));
        
        colors = [0.8 0 0;
                 1.0 0.6 0.6;
                 0.0 0.0 0.8;
                 0.6 0.6 1.0;
                 
                 0.8 0.6 0.8;
                 0.8 0.6 0.8;
                 
                0.6 0.2 0.6;
                0.6 0.2 0.6];
            
        markers = {'o','o','o','o','o','x','o','x'};
        
        figure
        hold on
        for c=1:size(stData,2)
            stProj = COEFF'*(squeeze(stData(:,c,:))-MU');
            plot3(stProj(1,:), stProj(2,:), stProj(3,:), markers{c}, 'Color', colors(c,:));
        end
        axis equal;
        
        figure
        hold on
        for c=1:size(stData,2)
            stProj = COEFF'*(squeeze(stData(:,c,:))-MU');
            plot3(stProj(4,:), stProj(5,:), stProj(6,:), markers{c}, 'Color', colors(c,:));
        end
        axis equal;
        
        %1-way eff1
        an_eff1 = allMN(:,[1 2]);
        grandMean_eff1 = squeeze(mean(an_eff1,2));
        factor1_means_eff1 = zeros(size(an_eff1,1),2);
        factor1_means_eff1(:,1) = an_eff1(:,1) - grandMean_eff1;
        factor1_means_eff1(:,2) = an_eff1(:,2) - grandMean_eff1;
        
        %1-way eff2
        an_eff2 = allMN(:,[3 4]);
        grandMean_eff2 = squeeze(mean(an_eff2,2));
        factor1_means_eff2 = zeros(size(an_eff2,1),2);
        factor1_means_eff2(:,1) = an_eff2(:,1) - grandMean_eff2;
        factor1_means_eff2(:,2) = an_eff2(:,2) - grandMean_eff2;
        
        %2-way
        anSquare = zeros(size(allMN,1),2,2);
        anSquare(:,1,1) = allMN(:,5);
        anSquare(:,1,2) = allMN(:,6);
        anSquare(:,2,1) = allMN(:,7);
        anSquare(:,2,2) = allMN(:,8);
        
        grandMean = squeeze(mean(mean(anSquare,2),3));
        factor1_means = zeros(size(anSquare,1),2);
        factor2_means = zeros(size(anSquare,1),2);
        
        factor1_means(:,1) = mean(squeeze(anSquare(:,1,:)),2) - grandMean;
        factor1_means(:,2) = mean(squeeze(anSquare(:,2,:)),2) - grandMean;
        factor2_means(:,1) = mean(squeeze(anSquare(:,:,1)),2) - grandMean;
        factor2_means(:,2) = mean(squeeze(anSquare(:,:,2)),2) - grandMean;
        
        intTerms = zeros(size(anSquare));
        for x=1:2
            for y=1:2
                intTerms(:,x,y) = anSquare(:,x,y) - (grandMean + factor1_means(:,x) + factor2_means(:,y));
            end
        end
        
        ssTable = zeros(3,1);
        ssTable(1) = 2*sum(factor1_means(:).^2);
        ssTable(2) = 2*sum(factor2_means(:).^2);
        ssTable(3) = sum(intTerms(:).^2);
        
        modDistance = zeros(10,1);
        modDistance(1) = norm(allMN(:,1)-allMN(:,2));
        modDistance(2) = norm(allMN(:,3)-allMN(:,4));
        
        modDistance(3) = norm(allMN(:,7)-allMN(:,5));
        modDistance(4) = norm(allMN(:,8)-allMN(:,6));
        
        modDistance(5) = norm(allMN(:,6)-allMN(:,5));
        modDistance(6) = norm(allMN(:,8)-allMN(:,7));
        
        modDistance(7) = mean(modDistance(3:4))/modDistance(1);
        modDistance(8) = mean(modDistance(5:6))/modDistance(2);
        
        %interaction size
        allMN_mg = allMN - mean(allMN,2);
        modDistance(9) = 0.5*norm((allMN(:,7)-allMN(:,5)) - (allMN(:,8)-allMN(:,6)));
        modDistance(10) = 0.5*norm((allMN(:,8)-allMN(:,7)) - (allMN(:,6)-allMN(:,5)));
        
        singleAx_eff1 = (allMN(:,2)-allMN(:,1))/norm(allMN(:,2)-allMN(:,1));
        singleAx_eff2 = (allMN(:,4)-allMN(:,3))/norm(allMN(:,4)-allMN(:,3));
        
        dualAx_eff1_a = (allMN(:,7)-allMN(:,5))/norm(allMN(:,7)-allMN(:,5));
        dualAx_eff1_b = (allMN(:,8)-allMN(:,6))/norm(allMN(:,8)-allMN(:,6));
        
        dualAx_eff2_a = (allMN(:,6)-allMN(:,5))/norm(allMN(:,6)-allMN(:,5));
        dualAx_eff2_b = (allMN(:,8)-allMN(:,7))/norm(allMN(:,8)-allMN(:,7));
        
        allAxes = [singleAx_eff1, dualAx_eff1_a, dualAx_eff1_b, singleAx_eff2, dualAx_eff2_a, dualAx_eff2_b];
        
        cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);
        
        figure
        imagesc(corr(allAxes),[-1,1]);
        colorbar;
        colormap(cMap);
        set(gca,'YDir','normal');
        
        [ meanDiff_eff1, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,1,:))', squeeze(stData(:,2,:))' );
        [ meanDiff_eff2, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,3,:))', squeeze(stData(:,4,:))' );
        
        [ meanDiff_dual1, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( [squeeze(stData(:,5,:))'; squeeze(stData(:,6,:))'], ...
            [squeeze(stData(:,7,:))'; squeeze(stData(:,8,:))']);
        [ meanDiff_dual2, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( [squeeze(stData(:,5,:))'; squeeze(stData(:,7,:))'], ...
            [squeeze(stData(:,6,:))'; squeeze(stData(:,8,:))']);
        
        [ meanDiff_dual1_a, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,7,:))', squeeze(stData(:,5,:))' );
        [ meanDiff_dual1_b, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,8,:))', squeeze(stData(:,6,:))' );
        
        [ meanDiff_dual2_a, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,6,:))', squeeze(stData(:,5,:))' );
        [ meanDiff_dual2_b, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,8,:))', squeeze(stData(:,7,:))' );
        
        [ meanDiff_int, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( [squeeze(stData(:,5,:))'; squeeze(stData(:,8,:))'], ...
            [squeeze(stData(:,6,:))'; squeeze(stData(:,7,:))'] );
        
        gamma = allMN(:,5:8)*[1; -1; -1; 1]*0.25;
        beta = allMN(:,5:8)*[1; 1; -1; -1]*0.25;
        alpha = allMN(:,5:8)*[1; -1; 1; -1]*0.25;
        mu = allMN(:,5:8)*[1; 1; 1; 1]*0.25;
        
        cMinusA = allMN(:,7)-allMN(:,5);
        cMinusA_r = -2*(beta + gamma);
        
        nTrials = size(stData,3);
        allP = [];
        allSS = [];
        for n=1:size(stData,1)
            tmp = squeeze(stData(n,5:end,:))';
            codes = [repmat([0,0],nTrials,1);
                repmat([1,0],nTrials,1);
                repmat([0,1],nTrials,1);
                repmat([1,1],nTrials,1)];

            [P,T,STATS,TERMS] = anovan(tmp(:), codes, 'model', 'interaction', 'display', 'off');

            allP = [allP; P'];
            allSS = [allSS; vertcat(T{2:end,2})'];
        end
        
        %%
        %resampling
        nResample = 1000;
        resampleModDistance = zeros(nResample,8);
        resampleCorr = zeros(nResample,6,6);
        
        for n=1:nResample
            %example single trial
            cWindow = (-timeWindow(1)/binMS) + (10:50);

            allResampleIdx = cell(4,1);
            nTrials = size(dPCA_single_set{1}.featureVals,4);
            for t=1:4
                allResampleIdx{t} = randi(nTrials, nTrials, 1);
            end
            
            stData = cat(2, squeeze(nanmean(dPCA_single_set{1}.featureVals(:,:,cWindow,allResampleIdx{1}),3)), ...
                squeeze(nanmean(dPCA_single_set{2}.featureVals(:,:,cWindow,allResampleIdx{2}),3)), ...
                squeeze(nanmean(dPCA_out_dual.featureVals(:,1,:,cWindow,allResampleIdx{3}),4)), ...
                squeeze(nanmean(dPCA_out_dual.featureVals(:,2,:,cWindow,allResampleIdx{4}),4)));
            
            allMN = squeeze(nanmean(stData,3));
            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allMN');

            modDistance = zeros(8,1);
            modDistance(1) = norm(allMN(:,1)-allMN(:,2));
            modDistance(2) = norm(allMN(:,3)-allMN(:,4));

            modDistance(3) = norm(allMN(:,7)-allMN(:,5));
            modDistance(4) = norm(allMN(:,8)-allMN(:,6));

            modDistance(5) = norm(allMN(:,6)-allMN(:,5));
            modDistance(6) = norm(allMN(:,8)-allMN(:,7));

            modDistance(7) = mean(modDistance(3:4))/modDistance(1);
            modDistance(8) = mean(modDistance(5:6))/modDistance(2);
            
            resampleModDistance(n,:) = modDistance;
            
            singleAx_eff1 = (allMN(:,2)-allMN(:,1))/norm(allMN(:,2)-allMN(:,1));
            singleAx_eff2 = (allMN(:,4)-allMN(:,3))/norm(allMN(:,4)-allMN(:,3));

            dualAx_eff1_a = (allMN(:,7)-allMN(:,5))/norm(allMN(:,7)-allMN(:,5));
            dualAx_eff1_b = (allMN(:,8)-allMN(:,6))/norm(allMN(:,8)-allMN(:,6));

            dualAx_eff2_a = (allMN(:,6)-allMN(:,5))/norm(allMN(:,6)-allMN(:,5));
            dualAx_eff2_b = (allMN(:,8)-allMN(:,7))/norm(allMN(:,8)-allMN(:,7));

            allAxes = [singleAx_eff1, dualAx_eff1_a, dualAx_eff1_b, singleAx_eff2, dualAx_eff2_a, dualAx_eff2_b];
            resampleCorr(n,:,:) = corr(allAxes);
        end
        
        %%
        %number of trials
        nTrialsToDo = 4:18;
        nResample = 1000;
        resampleModDistance = zeros(length(nTrialsToDo),nResample,8);
        resampleCorr = zeros(length(nTrialsToDo),nResample,6,6);
        resampleProjCV = zeros(length(nTrialsToDo),nResample,6);
        
        for resampleIdx=1:nResample
            disp(resampleIdx);
            for trlNumIdx=1:length(nTrialsToDo)

                currentTrialNum = nTrialsToDo(trlNumIdx);
                cWindow = (-timeWindow(1)/binMS) + (10:50);

                allResampleIdx = cell(4,1);
                nTrials = size(dPCA_single_set{1}.featureVals,4);
                for t=1:4
                    rp = randperm(nTrials);
                    allResampleIdx{t} = rp(1:currentTrialNum);
                end

                stData = cat(2, squeeze(nanmean(dPCA_single_set{1}.featureVals(:,:,cWindow,allResampleIdx{1}),3)), ...
                    squeeze(nanmean(dPCA_single_set{2}.featureVals(:,:,cWindow,allResampleIdx{2}),3)), ...
                    squeeze(nanmean(dPCA_out_dual.featureVals(:,1,:,cWindow,allResampleIdx{3}),4)), ...
                    squeeze(nanmean(dPCA_out_dual.featureVals(:,2,:,cWindow,allResampleIdx{4}),4)));

                allMN = squeeze(nanmean(stData,3));
                [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allMN');

                modDistance = zeros(8,1);
                modDistance(1) = norm(allMN(:,1)-allMN(:,2));
                modDistance(2) = norm(allMN(:,3)-allMN(:,4));

                modDistance(3) = norm(allMN(:,7)-allMN(:,5));
                modDistance(4) = norm(allMN(:,8)-allMN(:,6));

                modDistance(5) = norm(allMN(:,6)-allMN(:,5));
                modDistance(6) = norm(allMN(:,8)-allMN(:,7));

                modDistance(7) = mean(modDistance(3:4))/modDistance(1);
                modDistance(8) = mean(modDistance(5:6))/modDistance(2);

                resampleModDistance(trlNumIdx,resampleIdx,:) = modDistance;

                singleAx_eff1 = (allMN(:,2)-allMN(:,1))/norm(allMN(:,2)-allMN(:,1));
                singleAx_eff2 = (allMN(:,4)-allMN(:,3))/norm(allMN(:,4)-allMN(:,3));

                dualAx_eff1_a = (allMN(:,7)-allMN(:,5))/norm(allMN(:,7)-allMN(:,5));
                dualAx_eff1_b = (allMN(:,8)-allMN(:,6))/norm(allMN(:,8)-allMN(:,6));

                dualAx_eff2_a = (allMN(:,6)-allMN(:,5))/norm(allMN(:,6)-allMN(:,5));
                dualAx_eff2_b = (allMN(:,8)-allMN(:,7))/norm(allMN(:,8)-allMN(:,7));

                allAxes = [singleAx_eff1, dualAx_eff1_a, dualAx_eff1_b, singleAx_eff2, dualAx_eff2_a, dualAx_eff2_b];
                resampleCorr(trlNumIdx,resampleIdx,:,:) = corr(allAxes);
                
                projCV = zeros(6,1);
                meanDiffs = cell(6,1);
                [ meanDiffs{1}, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,1,:))', squeeze(stData(:,2,:))' );
                [ meanDiffs{2}, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,3,:))', squeeze(stData(:,4,:))' );
                [ meanDiffs{3}, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,7,:))', squeeze(stData(:,5,:))' );
                [ meanDiffs{4}, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,8,:))', squeeze(stData(:,6,:))' );
                [ meanDiffs{5}, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,6,:))', squeeze(stData(:,5,:))' );
                [ meanDiffs{6}, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( squeeze(stData(:,8,:))', squeeze(stData(:,7,:))' );
                for x=1:6
                    projCV(x) = norm(meanDiffs{x});
                end
                resampleProjCV(trlNumIdx,resampleIdx,:) = projCV;
            end
        end
        
        figure
        hold on;
        plot(nTrialsToDo,squeeze(mean(resampleModDistance(:,:,1:2),2)));
        plot(nTrialsToDo,squeeze(mean(resampleModDistance(:,:,3:4),2)),'--');
        ylim([0,14]);
        
        figure
        hold on;
        plot(nTrialsToDo,squeeze(mean(resampleProjCV(:,:,1:2),2)));
        plot(nTrialsToDo,squeeze(mean(resampleProjCV(:,:,3:4),2)),'--');
        ylim([0,14]);
        
        figure
        hold on;
        plot(nTrialsToDo,squeeze(mean(resampleCorr(:,:,1,3),2)));
        plot(nTrialsToDo,squeeze(mean(resampleCorr(:,:,4,6),2)));
        
        %%
        %example single trial, single mov
        cWindow = (-timeWindow(1)/binMS) + (10:50);
        allMN = [squeeze(nanmean(dPCA_single_set{1}.featureAverages(:,:,cWindow),3)), ...
            squeeze(nanmean(dPCA_single_set{2}.featureAverages(:,:,cWindow),3))];
            
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allMN');
        
        stData = cat(2, squeeze(nanmean(dPCA_single_set{1}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_single_set{2}.featureVals(:,:,cWindow,:),3)));
        
        colors = [0.8 0 0;
                 1.0 0.6 0.6;
                 0.0 0.0 0.8;
                 0.6 0.6 1.0;];
            
        markers = {'o','o','o','o'};
        
        figure
        hold on
        for c=1:size(stData,2)
            stProj = COEFF'*(squeeze(stData(:,c,:))-MU');
            plot3(stProj(1,:), stProj(2,:), stProj(3,:), markers{c}, 'Color', colors(c,:));
        end
        axis equal;
        
        %does cross-validation matter?
        unroll_stData = [];
        trlCodes = [];
        for c=1:size(stData,2)
            unroll_stData = [unroll_stData, squeeze(stData(:,c,:))];
            trlCodes = [trlCodes; repmat(c, size(stData,3), 1)];
        end
        
        stProj = zeros(3, size(unroll_stData,2));
        for t=1:length(trlCodes)
            trainIdx = setdiff(1:length(trlCodes), t);
            
            allMN = [];
            for c=1:size(stData,2)
                codeIdx = find(trlCodes(trainIdx)==c);
                allMN = [allMN, mean(unroll_stData(:,trainIdx(codeIdx)),2)];
            end
            
            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allMN');
            stProj(:,t) = COEFF'*(unroll_stData(:,t)-MU');
        end
        
        figure
        hold on
        for c=1:size(stData,2)
            tmp = stProj(:,trlCodes==c);
            plot3(tmp(1,:), tmp(2,:), tmp(3,:), markers{c}, 'Color', colors(c,:));
        end
        axis equal;
        
        
        %%
        %example single trial, dual mov
        cWindow = (-timeWindow(1)/binMS) + (10:50);
        allMN = [squeeze(nanmean(dPCA_out_dual.featureAverages(:,1,:,cWindow),4)), ...
            squeeze(nanmean(dPCA_out_dual.featureAverages(:,2,:,cWindow),4))];
            
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allMN');
        
        stData = cat(2, squeeze(nanmean(dPCA_out_dual.featureVals(:,1,:,cWindow,:),4)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,2,:,cWindow,:),4)));
        
        colors = [0.8 0.6 0.8;
                 0.8 0.6 0.8;
                 
                0.6 0.2 0.6;
                0.6 0.2 0.6];
            
        markers = {'o','x','o','x'};

        figure
        hold on
        for c=1:size(stData,2)
            stProj = COEFF'*(squeeze(stData(:,c,:))-MU');
            plot3(stProj(1,:), stProj(2,:), stProj(3,:), markers{c}, 'Color', colors(c,:));
        end
        axis equal;
 
        %%
        %effector & CI dimensions - what do these do during simultaneous
        %movement?
        effDim = find(dPCA_out_single.whichMarg==2);
        effDim = effDim(1);
        
        effDim_xval = find(dPCA_out_single.cval.whichMarg==2);
        effDim_xval = effDim_xval(1);
        
        ciDim = find(dPCA_out_single.whichMarg==3);
        ciDim = ciDim(1);
        
        ciDim_xval = find(dPCA_out_single.cval.whichMarg==3);
        ciDim_xval = ciDim_xval(1);
        
        timeAxis = ((timeWindow(1)/binMS):(timeWindow(2)/binMS))/50;
        colors = jet(nDirCon)*0.8;
        lsSingle = {'--','-'};
        
        marg_h = [0.3 0.03];
        marg_w = [0.15 0.03];
        dimProj = cell(2,2);
        dimProj{1,1} = zeros(length(timeAxis),nDirCon,nDirCon);
        dimProj{1,2} = zeros(length(timeAxis),nDirCon,nDirCon);
        dimProj{2,1} = zeros(length(timeAxis),nDirCon,nDirCon);
        dimProj{2,2} = zeros(length(timeAxis),nDirCon,nDirCon);
        
        dimProj_ci = cell(2,2);
        dimProj_ci{1,1} = zeros(length(timeAxis),nDirCon,nDirCon,2);
        dimProj_ci{1,2} = zeros(length(timeAxis),nDirCon,nDirCon,2);
        dimProj_ci{2,1} = zeros(length(timeAxis),nDirCon,nDirCon,2);
        dimProj_ci{2,2} = zeros(length(timeAxis),nDirCon,nDirCon,2);
        
        if nDirCon==2
            colors = [0.8 0.6 0.8;
                    0.6 0.2 0.6];
        else
            colors = jet(nDirCon)*0.8;
        end
        ls = {'-',':','--','-.'};
                
%         subtightplot(2,2,1,[],marg_h,marg_w);
%         hold on;
%         for c1=1:nDirCon
%             for c2=1:2
%                 plot(timeAxis, squeeze(dPCA_out_single.cval.Z(ciDim,c1,c2,:)),'Color',colors(c1,:),'LineWidth',2,'LineStyle',lsSingle{c2});
%                 errorPatch(timeAxis', squeeze(dPCA_out_single.cval.dimCI(ciDim_xval,c1,c2,:,:)), ...
%                     colors(c1,:), 0.2);
%                 dimProj{1,1}(:,c1,c2) = squeeze(dPCA_out_single.cval.Z(ciDim,c1,c2,:));
%                 dimProj_ci{1,1}(:,c1,c2,:) = squeeze(dPCA_out_single.cval.dimCI(ciDim_xval,c1,c2,:,:));
%             end
%         end
%         xlim([timeAxis(1), timeAxis(end)]);
%         ylim([-4, 8]);
%         set(gca,'XTickLabel',[],'YTick',-2:2:6);
%         set(gca,'FontSize',18);
%         ylabel('Rate (SD)');
%         plot([0 0],get(gca,'YLim'),'--k','LineWidth',2);
%         plot([1.5 1.5],get(gca,'YLim'),'--k','LineWidth',2);
%         
%         subtightplot(2,2,2,[],marg_h,marg_w);
%         hold on;
%         for c1=1:nDirCon
%             for c2=1:2
%                 plot(timeAxis, squeeze(dPCA_out_single.cval.Z(effDim,c1,c2,:)),'Color',colors(c1,:),'LineWidth',2,'LineStyle',lsSingle{c2});
%                 errorPatch(timeAxis', squeeze(dPCA_out_single.cval.dimCI(effDim_xval,c1,c2,:,:)), ...
%                     colors(c1,:), 0.2);
%                 dimProj{1,2}(:,c1,c2) = squeeze(dPCA_out_single.cval.Z(effDim,c1,c2,:));
%                 dimProj_ci{1,2}(:,c1,c2,:) = squeeze(dPCA_out_single.cval.dimCI(effDim_xval,c1,c2,:,:));
%             end
%         end
%         xlim([timeAxis(1), timeAxis(end)]);
%         ylim([-4, 8]);
%         set(gca,'XTickLabel',[]);
%         set(gca,'YTickLabel',[]);
%         set(gca,'FontSize',18);
%         plot([0 0],get(gca,'YLim'),'--k','LineWidth',2);
%         plot([1.5 1.5],get(gca,'YLim'),'--k','LineWidth',2);
        
        singleColors = {[0.8 0 0],[0.0 0.0 0.8];
            [1.0 0.6 0.6],[0.6 0.6 1.0]};
    
        figure('Position',[226   911   418   172]);
        subtightplot(1,2,1,[],marg_h,marg_w);
        hold on;
        
        if nDirCon==2
            axIdx = find(dPCA_out_single.cval.whichMarg==3);
            axIdx = axIdx(1);
            for c1=1:size(dPCA_out_single.cval.Z,2)
                for c2=1:size(dPCA_out_single.cval.Z,3)
                    plot(timeAxis,squeeze(dPCA_out_single.cval.Z(axIdx,c1,c2,:)),'-','LineWidth',2,'Color',singleColors{c1,c2});
                end
            end
        end
        
        for c1=1:nDirCon
            for c2=1:nDirCon
                fv = squeeze(dPCA_out_dual.featureVals(:,c1,c2,:,:));
                stProj = zeros(size(fv,2),size(fv,3));
                for trlIdx=1:size(stProj,2)
                    stProj(:,trlIdx) = squeeze(fv(:,:,trlIdx))'*dPCA_out_single.W(:,ciDim);
                end
                stProj(:,any(isnan(stProj)))=[];
                
                [mn,~,CI] = normfit(stProj');
                
                plot(timeAxis, mn, 'Color',colors(c1,:),'LineWidth',2,'LineStyle',ls{c2} );
                errorPatch(timeAxis', CI', colors(c1,:), 0.2);
                
                dimProj{2,1}(:,c1,c2) = mn;
                dimProj_ci{2,1}(:,c1,c2,:) = CI';
            end
        end
                
        xlim([timeAxis(1), timeAxis(end)]);
        ylim([-6, 6])
        set(gca,'FontSize',18,'YTick',[-5,0,5],'LineWidth',2);
        ylabel('Rate (SD)');
        plot([0 0],get(gca,'YLim'),'--k','LineWidth',2);
        plot([1.5 1.5],get(gca,'YLim'),'--k','LineWidth',2);
        xlabel('Time (s)');
        
        subtightplot(1,2,2,[],marg_h,marg_w);
        hold on;
        
        if nDirCon==2
            axIdx = find(dPCA_out_single.cval.whichMarg==2);
            axIdx = axIdx(1);
            for c1=1:size(dPCA_out_single.cval.Z,2)
                for c2=1:size(dPCA_out_single.cval.Z,3)
                    plot(timeAxis,squeeze(dPCA_out_single.cval.Z(axIdx,c1,c2,:)),'-','LineWidth',2,'Color',singleColors{c1,c2});
                end
            end
        end
        
        for c1=1:nDirCon
            for c2=1:nDirCon
                fv = squeeze(dPCA_out_dual.featureVals(:,c1,c2,:,:));
                stProj = zeros(size(fv,2),size(fv,3));
                for trlIdx=1:size(stProj,2)
                    stProj(:,trlIdx) = squeeze(fv(:,:,trlIdx))'*dPCA_out_single.W(:,effDim);
                end
                stProj(:,any(isnan(stProj)))=[];
                
                [mn,~,CI] = normfit(stProj');
                
                plot(timeAxis, mn, 'Color',colors(c1,:),'LineWidth',2,'LineStyle',ls{c2} );
                errorPatch(timeAxis', CI', colors(c1,:), 0.2);
                
                dimProj{2,2}(:,c1,c2) = mn;
                dimProj_ci{2,2}(:,c1,c2,:) = CI';
            end
        end
        xlim([timeAxis(1), timeAxis(end)]);
        ylim([-6, 6]);
        set(gca,'FontSize',18,'LineWidth',2,'YTick',[-5,0,5],'YTickLabel',[]);
        xlabel('Time (s)');
        plot([0 0],get(gca,'YLim'),'--k','LineWidth',2);
        plot([1.5 1.5],get(gca,'YLim'),'--k','LineWidth',2);
        
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'cross_CI_eff.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'cross_CI_eff.svg'],'svg');
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_effDimTransfer'],'dimProj','dimProj_ci');
        
        %%
        %variance table
        warning off;
        nReps = 200;
        allTables = cell(nReps,1);
        allTables_norm = cell(nReps,1);
        varSummaries = zeros(nReps,8);
        
        for repIdx=1:nReps

            %dual
            allSubIdx_dual = [];

            noSingleMovements = find(~ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
            dualCues = movCues(noSingleMovements);
            dualCueList = unique(dualCues);
            for x=1:length(dualCueList)
                tmp = find(dualCues==dualCueList(x));
                tmp = tmp(randi(length(tmp),length(tmp),1));
                allSubIdx_dual = [allSubIdx_dual, tmp'];
            end
            
            if repIdx==1
                allSubIdx_dual = 1:length(noSingleMovements);
            end

            dPCA_out_dual = apply_dPCA_PCAOnly( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements(allSubIdx_dual))), ...
                movFactors(noSingleMovements(allSubIdx_dual),:), movTimeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 30 );

            dPCA_out_dual_oneFactor = apply_dPCA_PCAOnly( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements(allSubIdx_dual))), ...
                movCues(noSingleMovements(allSubIdx_dual)), movTimeWindow/binMS, binMS/1000, {'CD','CI'}, 30 );

            %single
            movSets = {[187,188,189,190],[191,192,193,194]};
            dPCA_single_set = cell(length(movSets),1);
            allSubIdx = cell(length(movSets),1);
            singleMovements = cell(length(movSets),1);

            for setIdx=1:length(movSets)
                allSubIdx{setIdx} = [];

                singleMovements{setIdx} = find(ismember(movCues, movSets{setIdx}));
                singleCues = movCues(singleMovements{setIdx});
                singleCueList = unique(singleCues);
                for x=1:length(singleCueList)
                    tmp = find(singleCues==singleCueList(x));
                    tmp = tmp(randi(length(tmp),length(tmp),1));
                    allSubIdx{setIdx} = [allSubIdx{setIdx}, tmp'];
                end
                
                if repIdx==1
                    allSubIdx{setIdx} = 1:length(singleMovements{setIdx});
                end

                dPCA_single_set{setIdx} = apply_dPCA_PCAOnly( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements{setIdx}(allSubIdx{setIdx}))), ...
                    movFactors_single(singleMovements{setIdx}(allSubIdx{setIdx}),1), movTimeWindow/binMS, binMS/1000, {'Dir','CI'} );
            end

            close all;

            allMovCues = alignDat.currentMovement(alignDat.eventIdx);
            dualTrl = allIdx(noSingleMovements(allSubIdx_dual));
            singleTrl_1 = allIdx(singleMovements{1}(allSubIdx{1}));
            singleTrl_2 = allIdx(singleMovements{2}(allSubIdx{2}));

            trlSets = {singleTrl_1, dualTrl, singleTrl_2, dualTrl, dualTrl};
            movCueSets = {allMovCues(singleTrl_1), movFactors(noSingleMovements(allSubIdx_dual),1), ...
                allMovCues(singleTrl_2), movFactors(noSingleMovements(allSubIdx_dual),2), allMovCues(allIdx(noSingleMovements(allSubIdx_dual)))};

            nDim = nDirCon;

            axIdx = find(dPCA_single_set{1}.pca_result.whichMarg==1);
            axSingle1 = dPCA_single_set{1}.pca_result.W(:,axIdx(1:nDim));

            axIdx = find(dPCA_single_set{2}.pca_result.whichMarg==1);
            axSingle2 = dPCA_single_set{2}.pca_result.W(:,axIdx(1:nDim));

            axIdx = find(dPCA_out_dual.pca_result.whichMarg==1);
            axDual1 = dPCA_out_dual.pca_result.W(:,axIdx(1:nDim));

            axIdx = find(dPCA_out_dual.pca_result.whichMarg==2);
            axDual2 = dPCA_out_dual.pca_result.W(:,axIdx(1:nDim));

            axIdx = find(dPCA_out_dual_oneFactor.pca_result.whichMarg==1);
            axDual_both = dPCA_out_dual_oneFactor.pca_result.W(:,axIdx(1:(nDirCon*2)));

            axSets = {axSingle1, axDual1, axSingle2, axDual2, axDual_both};

            constraintSpaces = {{},{},{},{},{}};

            varTable = zeros(length(axSets), length(trlSets));
            for rowIdx=1:length(axSets)
                for colIdx=1:length(trlSets)
                    [ vsM, vsCI ] = getSimulVariance( alignDat.eventIdx(trlSets{colIdx}), movCueSets{colIdx}, ...
                        alignDat.zScoreSpikes, axSets{rowIdx}, 10:50, 1, constraintSpaces{colIdx} ); 
                    varTable(rowIdx, colIdx) = vsM;
                end
            end

            allTables{repIdx} = varTable;

            varTable_norm = varTable;
            for colIdx=1:size(varTable,2)
                varTable_norm(:,colIdx) = varTable_norm(:,colIdx)/varTable_norm(colIdx, colIdx);
            end

            allTables_norm{repIdx} = varTable_norm;
            
            varSummaries(repIdx,1:4) = diag(varTable(1:4,1:4));
            varSummaries(repIdx,5) = varTable_norm(1,2);
            varSummaries(repIdx,6) = varTable_norm(3,4);
            
            varSummaries(repIdx,7) = varSummaries(repIdx,2)/varSummaries(repIdx,1);
            varSummaries(repIdx,8) = varSummaries(repIdx,4)/varSummaries(repIdx,3);
        end
        
        mnVar_pca = varSummaries(1,:);
        ciVar_pca = prctile(varSummaries(2:end,:), [2.5, 97.5]);
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_varPCA'],'mnVar_pca','ciVar_pca');
        
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
        
        if nDirCon==2
            movDir = movDir(:,[1 3]);
        end

        %single movement encoding
        singleMovements = find(ismember(movCues, singleMovementCodes));

        epochsToUse = [alignDat.eventIdx(allIdx(singleMovements))+10, ...
            alignDat.eventIdx(allIdx(singleMovements))+60];
        singleTrlAvg = zeros(length(epochsToUse),size(alignDat.zScoreSpikes,2));
        singleTrlMoveDir = zeros(length(epochsToUse),size(movDir,2));

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
        dualMoveDir = zeros(length(epochsToUse),size(movDir,2));

        for t=1:length(epochsToUse)
            loopIdx = epochsToUse(t,1):epochsToUse(t,2);
            dualTrlAvg(t,:) = mean(alignDat.zScoreSpikes(loopIdx,:));
            dualMoveDir(t,:) = mean(movDir(loopIdx,:));
        end

        %see how subspace angle changes as a function of trial number
        numTrialsToTry = 2:18;
        numReps = 100;
        tStats = zeros(length(numTrialsToTry),numReps,10);
        for repIdx=1:numReps
            disp(repIdx);
            for trialNumIdx=1:length(numTrialsToTry)
                nTrials = numTrialsToTry(trialNumIdx);

                %resample single and dual trials
                allSubIdx_dual = [];
                dualCueList = unique(dualMoveDir,'rows');
                for x=1:length(dualCueList)
                    tmp = find(all(dualMoveDir==dualCueList(x,:),2));
                    tmp = tmp(randperm(length(tmp)));
                    allSubIdx_dual = [allSubIdx_dual, tmp(1:numTrialsToTry(trialNumIdx))'];
                end

                allSubIdx_single = [];
                singleCueList = unique(singleTrlMoveDir,'rows');
                for x=1:length(singleCueList)
                    tmp = find(all(singleTrlMoveDir==singleCueList(x,:),2));
                    tmp = tmp(randperm(length(tmp)));
                    allSubIdx_single = [allSubIdx_single, tmp(1:numTrialsToTry(trialNumIdx))'];
                end

                tStats(trialNumIdx,repIdx,:) = simulMovePDStat( singleTrlAvg(allSubIdx_single,:), singleTrlMoveDir(allSubIdx_single,:), ...
                    dualTrlAvg(allSubIdx_dual,:), dualMoveDir(allSubIdx_dual,:) );
            end
        end
        
        avgStats_byTrial = squeeze(mean(tStats,2));
        
        %[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca([singleTrlAvg; dualTrlAvg]);
        %singleTrlAvg_r = SCORE(1:size(singleTrlAvg,1),1:100);
        %dualTrlAvg_r = SCORE((size(singleTrlAvg,1)+1):end,1:100);
        singleTrlAvg_r = singleTrlAvg;
        dualTrlAvg_r = dualTrlAvg;
        
        meanStats = simulMovePDStat( singleTrlAvg_r, singleTrlMoveDir, dualTrlAvg_r, dualMoveDir );

        nResample = 1000;
        bootStats = zeros(nResample,length(meanStats));
        for n=1:nResample
            singleIdx = randi(size(singleTrlAvg,1), size(singleTrlAvg,1), 1);
            dualIdx = randi(size(dualTrlAvg,1), size(dualTrlAvg,1), 1);
            bootStats(n,:) = simulMovePDStat( singleTrlAvg_r(singleIdx,:), singleTrlMoveDir(singleIdx,:), dualTrlAvg_r(dualIdx,:), dualMoveDir(dualIdx,:) );
        end
        statCI = prctile(bootStats, [2.5, 50, 97.5]);
        
        %resample from single again, with suppressed means
        if nDirCon==2
            effCols = {1,2};
        else
            effCols = {1:2, 3:4};
        end
        
        singleTrlAvg_r_suppr = singleTrlAvg_r;
        for effIdx=1:2
            trlIdx = find(~all(singleTrlMoveDir(:,effCols{effIdx})==0,2));
            
            [mcList, ~, mcUniqueCodes] = unique(singleTrlMoveDir(trlIdx,effCols{effIdx}),'rows');
            overallMean = mean(singleTrlAvg_r(trlIdx,:));
            
            for c=1:length(mcList)
                trlIdxInner = find(mcUniqueCodes==c);
                deltaMeanActivity = mean(singleTrlAvg_r(trlIdx(trlIdxInner),:))-overallMean;
                
                suppressFactor = meanStats(effIdx);
                subtractionVector = deltaMeanActivity*(1-suppressFactor);
                singleTrlAvg_r_suppr(trlIdx(trlIdxInner),:) = singleTrlAvg_r(trlIdx(trlIdxInner),:) - subtractionVector;
            end
        end
                
        nResample = 1000;
        bootStats = zeros(nResample,length(meanStats));
        for n=1:nResample
            singleIdx = randi(size(singleTrlAvg,1), size(singleTrlAvg,1), 1);
            singleIdx_again = randi(size(singleTrlAvg,1), size(singleTrlAvg,1), 1);
            
            dualIdx = randi(size(dualTrlAvg,1), size(dualTrlAvg,1), 1);
            dualIdx_again = randi(size(dualTrlAvg,1), size(dualTrlAvg,1), 1);
            
            bootStats(n,:) = simulMovePDStat( singleTrlAvg_r(singleIdx,:), singleTrlMoveDir(singleIdx,:), singleTrlAvg_r_suppr(singleIdx_again,:), singleTrlMoveDir(singleIdx_again,:) );
            %bootStats(n,:) = simulMovePDStat( singleTrlAvg_r(singleIdx,:), singleTrlMoveDir(singleIdx,:), singleTrlAvg_r(singleIdx_again,:), singleTrlMoveDir(singleIdx_again,:) );
        end
        statCI_singleAgain = prctile(bootStats, [2.5, 50, 97.5]);
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_encModelStats'],'meanStats','statCI','statCI_singleAgain','avgStats_byTrial');

        %%
        continue;
        
        %%
        %cross variance dPCA number of trials. dual->single
        warning off;
        numTrials = 2:18;
        nReps = 100;
        allTables = cell(length(numTrials),nReps);
        allTables_norm = cell(length(numTrials),nReps);
        
        for trialNumIdx=1:length(numTrials)
            disp(trialNumIdx);
            for repIdx=1:nReps
                
                %dual
                allSubIdx_dual = [];

                noSingleMovements = find(~ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
                dualCues = movCues(noSingleMovements);
                dualCueList = unique(dualCues);
                for x=1:length(dualCueList)
                    tmp = find(dualCues==dualCueList(x));
                    tmp = tmp(randperm(length(tmp)));
                    allSubIdx_dual = [allSubIdx_dual, tmp(1:numTrials(trialNumIdx))'];
                end

                dPCA_out_dual = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements(allSubIdx_dual))), ...
                    movFactors(noSingleMovements(allSubIdx_dual),:), movTimeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 30 );

                %single
                movSets = {[187,188,189,190],[191,192,193,194]};
                dPCA_single_set = cell(length(movSets),1);
                allSubIdx = cell(length(movSets),1);
                singleMovements = cell(length(movSets),1);

                for setIdx=1:length(movSets)
                    allSubIdx{setIdx} = [];

                    singleMovements{setIdx} = find(ismember(movCues, movSets{setIdx}));
                    singleCues = movCues(singleMovements{setIdx});
                    singleCueList = unique(singleCues);
                    for x=1:length(singleCueList)
                        tmp = find(singleCues==singleCueList(x));
                        tmp = tmp(randperm(length(tmp)));
                        allSubIdx{setIdx} = [allSubIdx{setIdx}, tmp(1:numTrials(trialNumIdx))'];
                    end

                    dPCA_single_set{setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements{setIdx}(allSubIdx{setIdx}))), ...
                        movFactors_single(singleMovements{setIdx}(allSubIdx{setIdx}),1), movTimeWindow/binMS, binMS/1000, {'Dir','CI'} );
                end

                close all;

                allMovCues = alignDat.currentMovement(alignDat.eventIdx);
                dualTrl = allIdx(noSingleMovements(allSubIdx_dual));
                singleTrl_1 = allIdx(singleMovements{1}(allSubIdx{1}));
                singleTrl_2 = allIdx(singleMovements{2}(allSubIdx{2}));

                trlSets = {singleTrl_1, dualTrl, singleTrl_2, dualTrl};
                movCueSets = {allMovCues(singleTrl_1), movFactors(noSingleMovements(allSubIdx_dual),1), ...
                    allMovCues(singleTrl_2), movFactors(noSingleMovements(allSubIdx_dual),2)};

                nDim = nDirCon;

                axIdx = find(dPCA_single_set{1}.whichMarg==1);
                axSingle1 = dPCA_single_set{1}.W(:,axIdx(1:nDim));

                axIdx = find(dPCA_single_set{2}.whichMarg==1);
                axSingle2 = dPCA_single_set{2}.W(:,axIdx(1:nDim));

                axIdx = find(dPCA_out_dual.whichMarg==1);
                axDual1 = dPCA_out_dual.W(:,axIdx(1:nDim));

                axIdx = find(dPCA_out_dual.whichMarg==2);
                axDual2 = dPCA_out_dual.W(:,axIdx(1:nDim));

                axSets = {axSingle1, axDual1, axSingle2, axDual2};

                constraintSpaces = {{},{},{},{}};

                varTable = zeros(length(axSets), length(trlSets));
                for rowIdx=1:length(axSets)
                    for colIdx=1:length(trlSets)
                        [ vsM, vsCI ] = getSimulVariance( alignDat.eventIdx(trlSets{colIdx}), movCueSets{colIdx}, ...
                            alignDat.zScoreSpikes, axSets{rowIdx}, 10:50, 1, constraintSpaces{colIdx} ); 
                        varTable(rowIdx, colIdx) = vsM;
                    end
                end

                allTables{trialNumIdx, repIdx} = varTable;
                
                varTable_norm = varTable;
                for colIdx=1:size(varTable,2)
                    varTable_norm(:,colIdx) = varTable_norm(:,colIdx)/varTable_norm(colIdx, colIdx);
                end

                allTables_norm{trialNumIdx,repIdx} = varTable_norm;
            end
        end
        
        crossValue = zeros(size(allTables_norm,1),nReps,2);
        for c=1:size(crossValue,1)
            for repIdx=1:nReps
                crossValue(c,repIdx,1) = allTables_norm{c,repIdx}(2,1);
                crossValue(c,repIdx,2) = allTables_norm{c,repIdx}(4,3);
            end
        end
        
        figure; 
        plot(squeeze(mean(crossValue,2)));
        ylim([0 1]);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_varNumTrials_dpca.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_varNumTrials_dpca.fig'],'fig');
        
        %%
        %2D dPC trajectories
        axHandles = zeros(6,1);
        colors = jet(nDirCon)*0.8;
        ls = {'-',':','--','-.'};
        
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
                %if setIdx==1
                %    plot(xTraj(plotWindow), yTraj(plotWindow), 'Color', colors(conIdx,:), 'LineWidth', 4);
                %else
                %    plot(xTraj(plotWindow), yTraj(plotWindow), 'Color', 'k', 'LineWidth', 2, 'LineStyle',ls{conIdx});
                %end
            end
            axis tight;
        end
    
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
        epochsToUse = [alignDat.eventIdx(allIdx(singleMovements))+10, ...
            alignDat.eventIdx(allIdx(singleMovements))+60];
        loopIdxToTrain = expandEpochIdx(epochsToUse);
        coef_single = buildLinFilts(alignDat.zScoreSpikes(loopIdxToTrain,:), [ones(length(loopIdxToTrain),1), movDir(loopIdxToTrain,:)], 'standard')';

        pValSingle = zeros(size(alignDat.zScoreSpikes,2),1);
        for x=1:size(alignDat.zScoreSpikes,2)
            trlAvgRates = zeros(length(epochsToUse),1);
            trlAvgDir = zeros(length(epochsToUse),size(movDir,2));
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
            trlAvgDir = zeros(length(epochsToUse),size(movDir,2));
            for t=1:length(epochsToUse)
                loopIdx = epochsToUse(t,1):epochsToUse(t,2);
                trlAvgRates(t) = mean(alignDat.zScoreSpikes(loopIdx,x));
                trlAvgDir(t,:) = mean(movDir(loopIdx,:));
            end

            tmpMS = trlAvgRates - mean(trlAvgRates);
            [B,BINT,R,RINT,STATS] = regress(tmpMS,trlAvgDir);
            pValDual(x) = STATS(3);
        end
                
        %summarize with scatter
        sigUnits = find(pValSingle<0.001 & pValDual<0.001);
        
        if nDirCon==2
            pairs = {[2 3]};
        else
            pairs = {[2 4],[3 5]};
        end

        for pairIdx=1:length(pairs)
            x1 = coef_single(sigUnits,pairs{pairIdx}(1));
            x2 = coef_single(sigUnits,pairs{pairIdx}(2));
            y1 = coef_dual(sigUnits,pairs{pairIdx}(1));
            y2 = coef_dual(sigUnits,pairs{pairIdx}(2));
            
            input = [x1; x2];
            condition = [zeros(length(sigUnits),1); ones(length(sigUnits),1)];
            lm_full = fitlm([input, condition], [y1; y2], 'y ~ x1 + x2 + x1*x2', 'VarNames',{'x1','x2','y'});

            allX = [x1; x2];
            xAxis = linspace(min(allX), max(allX), 100)';

            [y1_p,y1ci] = lm_full.predict([xAxis, zeros(length(xAxis),1)]);
            [y2_p,y2ci] = lm_full.predict([xAxis, ones(length(xAxis),1)]);

            figure('Position',[680   842   366   256]);
            hold on;
            plot(x1, y1, 'bo');
            plot(x2, y2, 'ro');
            plot(xAxis, y1_p, 'b','LineWidth',2);
            plot(xAxis, y1ci, ':b','LineWidth',2);
            plot(xAxis, y2_p, 'r','LineWidth',2);
            plot(xAxis, y2ci, ':r','LineWidth',2);
            axis equal;
            set(gca,'LineWidth',2,'FontSize',16);
            xlabel('Single Movement Coef');
            ylabel('Dual Movement Coef');
            
            saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_pdScatter_' num2str(pairIdx) '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_pdScatter_' num2str(pairIdx) '.svg'],'svg');
        end
        
        %summarize
%         sigUnits = find(pValSingle<0.001 & pValDual<0.001);
% 
%         input = [coef_single(sigUnits,2); coef_single(sigUnits,3)];
%         input_condition = [zeros(length(sigUnits),1); coef_single(sigUnits,3)];
%         condition = [zeros(length(sigUnits),1); ones(length(sigUnits),1)];
%         
%         lm_full = fitlm([input, input_condition, condition], [coef_dual(sigUnits,2); coef_dual(sigUnits,3)]);
%         lm_full_2 = fitlm([input, [zeros(length(sigUnits),1); ones(length(sigUnits),1)]], [coef_dual(sigUnits,2); coef_dual(sigUnits,3)], 'y ~ x1 + x2 + x1*x2', 'VarNames',{'x1','x2','y'});
% 
%         lm1 = fitlm(coef_single(sigUnits,2), coef_dual(sigUnits,2));
%         lm2 = fitlm(coef_single(sigUnits,3), coef_dual(sigUnits,3));
%         lm3 = fitlm([coef_single(sigUnits,2); coef_single(sigUnits,3)], [coef_dual(sigUnits,2); coef_dual(sigUnits,3)]);
%         slopeDiffMean = lm1.Coefficients(2,1).Estimate - lm2.Coefficients(2,1).Estimate;
%         slopeRatioMean = lm1.Coefficients(2,1).Estimate/lm2.Coefficients(2,1).Estimate;
%         
%         allDataX = [coef_single(sigUnits,2); coef_single(sigUnits,3)];
%         allDataY = [coef_dual(sigUnits,2); coef_dual(sigUnits,3)];
%         
%         allSlopeDiff = zeros(10000,1);
%         for n=1:10000
%             disp(n);
%             
%             shuffIdx = randperm(length(allDataX));
%             shuffX = allDataX(shuffIdx);
%             shuffY = allDataY(shuffIdx);
%             
%             lm1 = fitlm(shuffX(1:60), shuffY(1:60));
%             lm2 = fitlm(shuffX(61:end), shuffY(61:end));
%             allSlopeDiff(n,1) = lm1.Coefficients(2,1).Estimate - lm2.Coefficients(2,1).Estimate;
%             allSlopeDiff(n,2) = lm1.Coefficients(2,1).Estimate/lm2.Coefficients(2,1).Estimate;
%         end
    end %movement set
end %dataset
