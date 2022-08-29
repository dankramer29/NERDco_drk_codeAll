%%
datasets = {
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 17 18 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
};

effNames = {{{'Head','Tongue'},{'LArm','RArm'},{'Head','RArm'},{'LLeg','RLeg'},{'LLeg','RArm'}};
    {{'Head','RArm'},{'RLeg','RArm'}};
    {{'Head','RLeg'},{'Head','LLeg'},{'Head','LArm'},{'LArm','RLeg'},{'LArm','LLeg'},{'LLeg','RLeg'},{'LLeg','RArm'},{'RLeg','RArm'}};};

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
    tooLow = meanRate < 1.0;
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
            movFactors(noSingleMovements,:), timeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 10, 'xval','marg' );
        
        dPCA_dual_movWindow = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements)), ...
            movFactors(noSingleMovements,:), movTimeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 10, 'xval','marg' );

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
        
        %cross
        timeAxis = ((timeWindow(1)/binMS):(timeWindow(2)/binMS))/50;
        [yAxesFinal, allHandles, axFromDualMovements] = general_dPCA_plot( dPCA_out_dual_c, timeAxis, lineArgs_dual, ...
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
            movFactors_single(singleMovements,:), timeWindow/binMS, binMS/1000, {'Dir', 'Eff', 'CI', 'Dir x Eff'}, 10, 'xval', 'marg' );
        
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
                movFactors_single(singleMovements,1), timeWindow/binMS, binMS/1000, {'Dir','CI'}, 10, 'xval', 'marg' );
            
            dPCA_single_set_movWindow{setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
                movFactors_single(singleMovements,1), movTimeWindow/binMS, binMS/1000, {'Dir','CI'}, 10, 'xval', 'marg' );
            
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
        %cross
        dPCA_out_dual_c = dPCA_out_dual;
        for f1=1:2
            for f2=1:2
                tmpFA = dPCA_out_dual_c.featureAverages(:,f1,f2,:)-dPCA_out_dual_c.featureMeansFromTrlAvg';
                tmpFA = squeeze(tmpFA);
                
                axIdx = find(dPCA_single_set{1}.whichMarg==1);
                axIdx = axIdx(1);
                dPCA_out_dual_c.Z(1,f1,f2,:) = dPCA_single_set{1}.W(:,axIdx)' * tmpFA;
                
                axIdx = find(dPCA_single_set{2}.whichMarg==1);
                axIdx = axIdx(1);
                dPCA_out_dual_c.Z(2,f1,f2,:) = dPCA_single_set{2}.W(:,axIdx)' * tmpFA;
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
        dPCA_out_dual_c.whichMarg(1) = 1;
        dPCA_out_dual_c.whichMarg(2) = 2;
        [yAxesFinal, allHandles, axFromDualMovements] = general_dPCA_plot( dPCA_out_dual_c, timeAxis, lineArgs_dual, ...
            labels, 'sameAxes', [], [-6,6], [], colors, layoutInfo );
    
        axes(allHandles{1});
        ylabel('Dimension 1 (SD)');
        
        %%
        cWindow = (-timeWindow(1)/binMS) + (10:50);
        stData = cat(2, squeeze(nanmean(dPCA_single_set{1}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_single_set{2}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,1,:,cWindow,:),4)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,2,:,cWindow,:),4)));
        
        stData_norm = stData;
        stData_norm(:,1:2,:) = stData_norm(:,1:2,:) - nanmean(nanmean(stData_norm(:,1:2,:),3),2);
        stData_norm(:,3:4,:) = stData_norm(:,3:4,:) - nanmean(nanmean(stData_norm(:,3:4,:),3),2);
        stData_norm(:,5:8,:) = stData_norm(:,5:8,:) - nanmean(nanmean(stData_norm(:,5:8,:),3),2);
        
        trlAvg = squeeze(nanmean(stData_norm(:,1:4,:),3));
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(trlAvg');
        
        colors = jet(8)*0.8;
        figure
        hold on
        for c=1:4
            tmp = (COEFF(:,1:3)'*squeeze(stData(:,c,:)))';
            plot3(tmp(:,1), tmp(:,2), tmp(:,3),  'o','Color', colors(c,:));
        end
        axis equal;
        xLim = get(gca,'XLim');
        yLim = get(gca,'YLim');
        
        trlAvg = squeeze(nanmean(stData_norm(:,5:8,:),3));
        [COEFF2, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(trlAvg');
        
        colors = jet(8)*0.8;
        figure
        hold on
        for c=5:8
            tmp = (COEFF2(:,1:3)'*squeeze(stData(:,c,:)))';
            plot3(tmp(:,1), tmp(:,2), tmp(:,3),  'o','Color', colors(c,:));
        end
        axis equal;
        xlim(xLim);
        ylim(yLim);
        
        %%
        %use cross-validation to compute modulation size for each effector
        %in dual case & single case
        cWindow = (-timeWindow(1)/binMS) + (10:50);
        stData = cat(2, squeeze(nanmean(dPCA_single_set{1}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_single_set{2}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,1,:,cWindow,:),4)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,2,:,cWindow,:),4)));
        
        pairings = {{1,2},{3,4},{[5 6],[7 8]},{[5 7],[6 8]}};
                
        modSizeTest = zeros(4,1);
        for pairIdx = 1:length(pairings)
            dat1 = squeeze(stData(:,pairings{pairIdx}{1},:));
            dat2 = squeeze(stData(:,pairings{pairIdx}{2},:));
            if length(pairings{pairIdx}{1})>1
                dat1 = dat1(:,:);
                dat2 = dat2(:,:);

                badIdx = any(isnan(dat1),1) | any(isnan(dat2),1);
                dat1(:,badIdx) = [];
                dat2(:,badIdx) = [];
            end

            dat1 = dat1';
            dat2 = dat2';

            modSizeTest(pairIdx) = lessBiasedDistance(dat1, dat2);
        end
        
        %use cross-validation to estimate correlation 
        pairList = {[3 4],[5 6],[7 8],[1 2],[5 7],[6 8]};
        corrMatTest = ones(6,6);
        for rowIdx=1:6
            for colIdx=1:6
                if rowIdx==colIdx
                    continue
                end
                p1 = pairList{rowIdx};
                p2 = pairList{colIdx};
                dat1 = permute(squeeze(stData(:,p1,:)), [1 3 2]);
                dat2 = permute(squeeze(stData(:,p2,:)), [1 3 2]);
                dat1 = dat1(:,:);
                dat2 = dat2(:,:);
                
                subtractMean = false;
                [ lessBiasedEstimate_1, meanOfSquares_1 ] = lessBiasedDistance(dat1(:,1:18)', dat1(:,19:end)', subtractMean);
                [ lessBiasedEstimate_2, meanOfSquares_2 ] = lessBiasedDistance(dat2(:,1:18)', dat2(:,19:end)', subtractMean);

                dv1 = mean(dat1(:,1:18)') - mean(dat1(:,19:end)');
                dv2 = mean(dat2(:,1:18)') - mean(dat2(:,19:end)');
                
                corrMatTest(rowIdx, colIdx) = dv1*dv2'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
                %corrMat(rowIdx, colIdx) = (dv1-mean(dv1))*(dv2-mean(dv2))'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
            end
        end
        
        %resample
        nResamples = 1000;
        modSize = zeros(nResamples,4);
        corrMat = ones(nResamples,6,6);
        
        for repIdx = 1:nResamples
            disp(repIdx);
            for pairIdx = 1:length(pairings)
                dat1 = squeeze(stData(:,pairings{pairIdx}{1},:));
                dat2 = squeeze(stData(:,pairings{pairIdx}{2},:));
                if length(pairings{pairIdx}{1})>1
                    dat1 = dat1(:,:);
                    dat2 = dat2(:,:);

                    badIdx = any(isnan(dat1),1) | any(isnan(dat2),1);
                    dat1(:,badIdx) = [];
                    dat2(:,badIdx) = [];
                end
                
                dat1 = dat1';
                dat2 = dat2';
                dat1 = dat1(randi(size(dat1,1),size(dat1,1),1),:);
                dat2 = dat2(randi(size(dat2,1),size(dat2,1),1),:);
                
                modSize(repIdx,pairIdx) = lessBiasedDistance(dat1, dat2);
            end
            
            pairList = {[3 4],[5 6],[7 8],[1 2],[5 7],[6 8]};
            for rowIdx=1:6
                for colIdx=1:6
                    if rowIdx==colIdx
                        continue
                    end
                    p1 = pairList{rowIdx};
                    p2 = pairList{colIdx};
                    dat1 = permute(squeeze(stData(:,p1,:)), [1 3 2]);
                    dat2 = permute(squeeze(stData(:,p2,:)), [1 3 2]);
                    
                    dat1(:,:,1) = dat1(:,randi(size(dat1,2),size(dat1,2),1),1);
                    dat1(:,:,2) = dat1(:,randi(size(dat1,2),size(dat1,2),1),2);   
                    
                    dat2(:,:,1) = dat2(:,randi(size(dat2,2),size(dat2,2),1),1);
                    dat2(:,:,2) = dat2(:,randi(size(dat2,2),size(dat2,2),1),2);
                
                    dat1 = dat1(:,:);
                    dat2 = dat2(:,:);

                    subtractMean = false;
                    [ lessBiasedEstimate_1, meanOfSquares_1 ] = lessBiasedDistance(dat1(:,1:18)', dat1(:,19:end)', subtractMean);
                    [ lessBiasedEstimate_2, meanOfSquares_2 ] = lessBiasedDistance(dat2(:,1:18)', dat2(:,19:end)', subtractMean);

                    dv1 = mean(dat1(:,1:18)') - mean(dat1(:,19:end)');
                    dv2 = mean(dat2(:,1:18)') - mean(dat2(:,19:end)');

                    corrMat(repIdx, rowIdx, colIdx) = dv1*dv2'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
                    %corrMat(rowIdx, colIdx) = (dv1-mean(dv1))*(dv2-mean(dv2))'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
                end
            end
        end
        
        figure
        imagesc(corrMatTest,[0,1]);
        set(gca,'YDir','normal');
        colorbar;
        
        figure
        hist(squeeze(corrMat(:,1,3)));
        
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
        nResample = 100;
        resampleModDistance = zeros(length(nTrialsToDo),nResample,4);
        resampleCMat = zeros(length(nTrialsToDo),nResample,6,6);
        resampleModDistance_sub = zeros(length(nTrialsToDo),nResample,4);
        
        resampleModDistance_naive = zeros(length(nTrialsToDo),nResample,4);
        resampleCMat_naive = zeros(length(nTrialsToDo),nResample,6,6);
        
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

                modSizeTest = zeros(4,1);
                for pairIdx = 1:length(pairings)
                    dat1 = squeeze(stData(:,pairings{pairIdx}{1},:));
                    dat2 = squeeze(stData(:,pairings{pairIdx}{2},:));
                    if length(pairings{pairIdx}{1})>1
                        dat1 = dat1(:,:);
                        dat2 = dat2(:,:);

                        badIdx = any(isnan(dat1),1) | any(isnan(dat2),1);
                        dat1(:,badIdx) = [];
                        dat2(:,badIdx) = [];
                    end

                    dat1 = dat1';
                    dat2 = dat2';

                    modSizeTest(pairIdx) = lessBiasedDistance(dat1, dat2);
                end
                resampleModDistance(trlNumIdx, resampleIdx,:) = modSizeTest;
                
                %use cross-validation to estimate correlation 
                pairList = {[3 4],[5 6],[7 8],[1 2],[5 7],[6 8]};
                corrMat = ones(6,6);
                for rowIdx=1:6
                    for colIdx=1:6
                        if rowIdx==colIdx
                            continue
                        end
                        p1 = pairList{rowIdx};
                        p2 = pairList{colIdx};
                        dat1 = permute(squeeze(stData(:,p1,:)), [1 3 2]);
                        dat2 = permute(squeeze(stData(:,p2,:)), [1 3 2]);
                        dat1 = dat1(:,:);
                        dat2 = dat2(:,:);
                        nTrl = size(dat1,2)/2;

                        subtractMean = true;
                        [ lessBiasedEstimate_1, meanOfSquares_1 ] = lessBiasedDistance(dat1(:,1:nTrl)', dat1(:,(nTrl+1):end)', subtractMean);
                        [ lessBiasedEstimate_2, meanOfSquares_2 ] = lessBiasedDistance(dat2(:,1:nTrl)', dat2(:,(nTrl+1):end)', subtractMean);

                        dv1 = mean(dat1(:,1:nTrl)') - mean(dat1(:,(nTrl+1):end)');
                        dv2 = mean(dat2(:,1:nTrl)') - mean(dat2(:,(nTrl+1):end)');

                        corrMat(rowIdx, colIdx) = (dv1-mean(dv1))*(dv2-mean(dv2))'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
                    end
                end
                
                resampleCMat(trlNumIdx, resampleIdx, :, :) = corrMat;
                
                %--naive metrics--
                modSizeTest = zeros(4,2);
                for pairIdx = 1:length(pairings)
                    dat1 = squeeze(stData(:,pairings{pairIdx}{1},:));
                    dat2 = squeeze(stData(:,pairings{pairIdx}{2},:));
                    if length(pairings{pairIdx}{1})>1
                        dat1 = dat1(:,:);
                        dat2 = dat2(:,:);

                        badIdx = any(isnan(dat1),1) | any(isnan(dat2),1);
                        dat1(:,badIdx) = [];
                        dat2(:,badIdx) = [];
                    end

                    dat1 = dat1';
                    dat2 = dat2';

                    modSizeTest(pairIdx,1) = norm(mean(dat1)-mean(dat2));
                    
                    mn = mean([dat1; dat2]);
                    dv = mean(dat1)-mean(dat2);
                    
                    nTrials = size(dat1,1);
                    modelValues = [repmat(mn+dv*0.5,nTrials,1); repmat(mn-dv*0.5,nTrials,1);];
                    dvErrVar = var(modelValues-[dat1; dat2]);
                    
                    sigma = sqrt(dvErrVar / (nTrials*2*0.5^2));
                    modSizeTest(pairIdx,2) = sign(dv*dv' - sum(sigma.^2))*sqrt(abs(dv*dv' - sum(sigma.^2)));
                end
                resampleModDistance_naive(trlNumIdx, resampleIdx,:) = modSizeTest(:,1);
                resampleModDistance_sub(trlNumIdx, resampleIdx,:) = modSizeTest(:,2);
                
                pairList = {[3 4],[5 6],[7 8],[1 2],[5 7],[6 8]};
                corrMat = ones(6,6);
                for rowIdx=1:6
                    for colIdx=1:6
                        if rowIdx==colIdx
                            continue
                        end
                        p1 = pairList{rowIdx};
                        p2 = pairList{colIdx};
                        dat1 = permute(squeeze(stData(:,p1,:)), [1 3 2]);
                        dat2 = permute(squeeze(stData(:,p2,:)), [1 3 2]);
                        dat1 = dat1(:,:);
                        dat2 = dat2(:,:);
                        nTrl = size(dat1,2)/2;

                        dv1 = mean(dat1(:,1:nTrl)') - mean(dat1(:,(nTrl+1):end)');
                        dv2 = mean(dat2(:,1:nTrl)') - mean(dat2(:,(nTrl+1):end)');

                        corrMat(rowIdx, colIdx) = (dv1-mean(dv1))*(dv2-mean(dv2))'/(norm(dv1)*norm(dv2));
                    end
                end
                
                resampleCMat_naive(trlNumIdx, resampleIdx, :, :) = corrMat;
            end
        end
        
        figure
        hold on;
        plot(nTrialsToDo,squeeze(mean(resampleModDistance,2)),'LineWidth',2);
        plot(nTrialsToDo,squeeze(mean(resampleModDistance_naive,2)),'--','LineWidth',2);
        %plot(nTrialsToDo,squeeze(mean(resampleModDistance_sub,2)),':','LineWidth',2);
        
        figure
        hold on;
        plot(nTrialsToDo,squeeze(std(resampleModDistance,0,2)),'LineWidth',2);
        plot(nTrialsToDo,squeeze(std(resampleModDistance_naive,0,2)),'--','LineWidth',2);
        %plot(nTrialsToDo,squeeze(std(resampleModDistance_sub,0,2)),':','LineWidth',2);
        
        figure
        hold on;
        plot(nTrialsToDo,squeeze(mean(resampleCMat(:,:,1,3),2)),'LineWidth',2);
        plot(nTrialsToDo,squeeze(mean(resampleCMat(:,:,4,6),2)),'LineWidth',2);
        plot(nTrialsToDo,squeeze(mean(resampleCMat_naive(:,:,1,3),2)),'--','LineWidth',2);
        plot(nTrialsToDo,squeeze(mean(resampleCMat_naive(:,:,4,6),2)),'--','LineWidth',2);
        ylim([0,1]);
        
    end %movement set
end %dataset
