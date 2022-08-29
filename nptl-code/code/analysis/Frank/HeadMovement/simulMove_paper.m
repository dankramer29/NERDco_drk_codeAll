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
for d=3:length(datasets)
    
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
        
        dPCA_out_dual_oneFactor = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements)), ...
            movCues(noSingleMovements), timeWindow/binMS, binMS/1000, {'CD','CI'}, 30 );

        lineArgs_dual = cell(nDirCon,nDirCon);
        colors = jet(nDirCon)*0.8;
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
        [yAxesFinal, allHandles, axFromDualMovements] = twoFactor_dPCA_plot_pretty_2( dPCA_out_dual, timeAxis, lineArgs_dual, ...
            labels, 'sameAxes', [], [-6,6], dPCA_out_dual.dimCI, colors, layoutInfo );
    
        axes(allHandles{1});
        ylabel('Dimension 1 (SD)');
        
        %[~, allHandles, axFromDualMovements] = twoFactor_dPCA_plot( dPCA_out_dual,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
        %    lineArgs_dual, labels, 'sameAxes');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_2fac_2move_dPCA.svg'],'svg');

        %eff 1
        axIdx = find(dPCA_out_dual.cval.whichMarg==1);
        effDim = dPCA_out_dual.cval.resortW;
        for x=1:length(effDim)
            effDim{x} = effDim{x}(:,axIdx(1:min(4,length(axIdx))));
        end

        [ varianceSummary(1,1), varianceSummary(1,2:3) ] = getSimulVariance_xval( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, effDim, 10:50, 100 );
        
        %eff 2
        axIdx = find(dPCA_out_dual.cval.whichMarg==2);
        effDim = dPCA_out_dual.cval.resortW;
        for x=1:length(effDim)
            effDim{x} = effDim{x}(:,axIdx(1:min(4,length(axIdx))));
        end
        
        [ varianceSummary(2,1), varianceSummary(2,2:3) ] = getSimulVariance_xval( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, effDim, 10:50, 100 );
        
        %interaction variance
        axIdx = find(dPCA_out_dual.cval.whichMarg==4);
        interactionDim = dPCA_out_dual.cval.resortW;
        for x=1:length(effDim)
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
        colors = jet(nDirCon)*0.8;
        ls = {':','-'};
        for x=1:nDirCon
            for c=1:2
                lineArgs_single{x,c} = {'Color',colors(x,:),'LineWidth',2,'LineStyle',ls{c}};
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
        [yAxesFinal, allHandles, axFromSingle] = twoFactor_dPCA_plot_pretty_2( dPCA_out_single, timeAxis, lineArgs_single, ...
            labels, 'sameAxes', [], [-6,6], dPCA_out_single.dimCI, colors, layoutInfo );
        
        axes(allHandles{1});
        ylabel('Dimension 1 (SD)');
        
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
        trlSets_single = cell(length(movSets),1);
        lineArgs_singleSets = cell(2,1);
        for x=1:2
            lineArgs_singleSets{x} = {{'Color',colors(1,:),'LineWidth',2},...
                {'Color',colors(2,:),'LineWidth',2}};
        end
        
        for setIdx=1:length(movSets)
            singleMovements = find(ismember(movCues, movSets{setIdx}));
            dPCA_single_set{setIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
                movFactors_single(singleMovements,1), timeWindow/binMS, binMS/1000, {'Dir','CI'}, 20, 'xval' );
            
            axIdx = find(dPCA_single_set{setIdx}.cval.whichMarg==1);
            effDim = dPCA_single_set{setIdx}.cval.resortW;
            for x=1:length(effDim)
                effDim{x} = effDim{x}(:,axIdx(1:4));
            end

            movWindow = 10:50;
            [ varianceSummary(setIdx+2,1), varianceSummary(setIdx+2,2:3) ] = getSimulVariance_xval( eventIdx(singleMovements), movCues(singleMovements), ...
                alignDat.zScoreSpikes, effDim, 10:50, 100 );
            
            trlSets_single{setIdx} = allIdx(singleMovements);
            
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
            [yAxesFinal, allHandles, axFromSingle] = general_dPCA_plot( dPCA_single_set{setIdx}, timeAxis, lineArgs_singleSets{setIdx}, ...
                labels, 'sameAxes', [], [-6,6], dPCA_single_set{setIdx}.dimCI, colors, layoutInfo );

            axes(allHandles{1});
            ylabel('Dimension 1 (SD)');
        end
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_varSummary'],'varianceSummary');
                        
        %%
        %dual vs. single dimension
        cueList = unique(movCues);
        dualVsSingleFactor = ones(length(movCues),1);
        singleMovements = find(ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
        dualVsSingleFactor(singleMovements) = 0;
        dualVsSingleFactor = dualVsSingleFactor + 1;
        
        dPCA_dualVsSingle = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx), ...
            dualVsSingleFactor, timeWindow/binMS, binMS/1000, {'CI','CD'}, 20, 'xval');
                
        plotDim = find(dPCA_dualVsSingle.cval.whichMarg==1);
        plotDim = plotDim(1);
        cueList = unique(movCues);
        timeAxis = (timeWindow(1):binMS:timeWindow(2))/1000;
        meanResponse = zeros(length(cueList),3);
        allResponse = cell(length(cueList),2);
        
        figure
        hold on
        for c=1:length(cueList)
            trlIdx = find(movCues==cueList(c));
            tmp = squeeze(dPCA_dualVsSingle.cval.Z_trialOrder(trlIdx,plotDim,:));
            tmp(any(isnan(tmp),2),:)=[];
            [mn,~,CI] = normfit(tmp);
            
            isSingle = ismember(cueList(c), [187, 188, 189, 190, 191, 192, 193, 194]);
            if isSingle
                color = [0.8 0 0];
            else
                color = [0 0 0.8];
            end
            %errorPatch(timeAxis', CI', color, 0.2);
            plot(timeAxis,mn,'Color',color,'LineWidth',2);
            
            mWindow = -(timeWindow(1)/binMS) + 30;
            meanResponse(c,1) = mn(mWindow);
            meanResponse(c,2:3) = CI(:,mWindow);
            
            allResponse{c,1} = mn;
            allResponse{c,2} = CI;
        end
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_contextDim'],'meanResponse','allResponse');
        
        %%
        singleMovements = find(ismember(movCues, [187, 188, 189, 190, 191, 192, 193, 194]));
        dPCA_out_sAll = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements)), ...
            movCues(singleMovements), timeWindow/binMS, binMS/1000, {'CI','CD'}, 20);
        
        cWindow = 10:50;
        if nDirCon==4
            idxSets = {1:4,5:8}; 
        else
            idxSets = {1:2,3:4}; 
        end
        simMatrix = plotCorrMat( dPCA_out_sAll.featureAverages, cWindow, [], idxSets, idxSets);
    
        saveas(gcf, [outDir filesep datasets{d,3}{outerMovSetIdx} '_CorrMat.png'],'png');

        dirMap = [187, -1, 0;
            188, 1, 0;
            189, 0, 1;
            190, 0, -1;
            191, -1, 0;
            192, 1, 0;
            193, 0, 1;
            194, 0, -1];

        movSets = {[187,188,189,190],[191,192,193,194]};
        allPD = cell(length(movSets),1);
        allPVal = cell(length(movSets),1);
        
        for movSetIdx = 1:length(movSets)
            trlIdx = find(ismember(movCues, movSets{movSetIdx}));
            
            allDat = [];
            allTargPos = [];
            for innerIdx=1:length(trlIdx)
                loopIdx = cWindow + alignDat.eventIdx(allIdx(trlIdx(innerIdx)));
                allDat = [allDat; mean(alignDat.zScoreSpikes(loopIdx,:))];
                
                mapIdx = find(dirMap(:,1)==movCues(trlIdx(innerIdx)));
                targPos = dirMap(mapIdx,2:3);
                
                allTargPos = [allTargPos; targPos];
            end
            if nDirCon==2
                allTargPos = allTargPos(:,1);
                nCoef = 2;
            else
                nCoef = 3;
            end

            nUnits = size(allDat,2);
            pVals = zeros(nUnits,1);
            E = zeros(nUnits,nCoef);
            for featIdx=1:nUnits
                [B,BINT,R,RINT,STATS] = regress(allDat(:,featIdx), [ones(length(allTargPos),1), allTargPos]);
                pVals(featIdx) = STATS(3);
                E(featIdx,:) = B;
            end

            allPD{movSetIdx} = E(:,2:end);
            allPVal{movSetIdx} = pVals;
        end
        
        %plots
        R2 = zeros(length(allPD));
        rotMat = cell(length(allPD), length(allPD));
        for x=1:length(allPD)
            for y=1:length(allPD)
               rotMat{x,y} = allPD{x}\allPD{y};
               [B,BINT,R,RINT,STATS1] = regress(allPD{y}(:,1),allPD{x});
               if nDirCon==4
                   [B,BINT,R,RINT,STATS2] = regress(allPD{y}(:,2),allPD{x});
                   R2(x,y) = mean([STATS1(1), STATS2(1)]);
               else
                   R2(x,y) = STATS1(1);
               end
            end
        end
        for x=1:size(R2,1)
            R2(x,x) = 0;
        end

        eNames = effNames{d}{outerMovSetIdx};
        
        figure
        imagesc(R2,[0,max(abs(R2(:)))]);
        colorbar;
        set(gca,'XTick',1:4,'XTickLabel',eNames,'XTickLabelRotation',45);
        set(gca,'YTick',1:4,'YTickLabel',eNames);
        set(gca,'FontSize',14);
        if nDirCon==2
            rm = vertcat(rotMat{:});
            title(num2str(rm(2:3)));
        end
        saveas(gcf, [outDir filesep 'R2Mat_' datasets{d,3}{outerMovSetIdx} '.png'],'png');

        if nDirCon==4
            nCon = length(allPD);
            figure('Position',[154   367   859   738]);
            hold on
            for x=1:nCon
                for y=1:nCon
                    subplot(nCon,nCon,(x-1)*nCon+y);
                    hold on;
                    plot([0, rotMat{x,y}(1,1)], [0,rotMat{x,y}(2,1)],'-o','LineWidth',2);
                    plot([0, rotMat{x,y}(1,2)], [0,rotMat{x,y}(2,2)],'-o','LineWidth',2);
                    plot([0,0],[-1,1],'-k');
                    plot([-1,1],[0,0],'-k');
                    xlim([-1,1]);
                    ylim([-1,1]);
                    axis equal;

                    if y==1
                        ylabel(eNames{x});
                    end
                    if x==nCon
                        xlabel(eNames{y});
                    end
                    set(gca,'FontSize',14,'XTick',[],'YTick',[]);
                end
            end
            saveas(gcf, [outDir filesep 'PDRotMat_' datasets{d,3}{outerMovSetIdx} '.png'],'png');
        end
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_pdSummary'],'rotMat','allPD','allPVal','R2');
        close all;
                     
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
        
        marg_h = [0.12 0.03];
        marg_w = [0.1 0.03];
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
        
        colors = jet(nDirCon)*0.8;
        ls = {'-',':','--','-.'};
        
        figure
        subtightplot(2,2,1,[],marg_h,marg_w);
        hold on;
        for c1=1:nDirCon
            for c2=1:2
                plot(timeAxis, squeeze(dPCA_out_single.cval.Z(ciDim,c1,c2,:)),'Color',colors(c1,:),'LineWidth',2,'LineStyle',lsSingle{c2});
                errorPatch(timeAxis', squeeze(dPCA_out_single.cval.dimCI(ciDim_xval,c1,c2,:,:)), ...
                    colors(c1,:), 0.2);
                dimProj{1,1}(:,c1,c2) = squeeze(dPCA_out_single.cval.Z(ciDim,c1,c2,:));
                dimProj_ci{1,1}(:,c1,c2,:) = squeeze(dPCA_out_single.cval.dimCI(ciDim_xval,c1,c2,:,:));
            end
        end
        xlim([timeAxis(1), timeAxis(end)]);
        ylim([-4, 8]);
        set(gca,'XTickLabel',[],'YTick',-2:2:6);
        set(gca,'FontSize',18);
        ylabel('Modulation (SD)');
        plot([0 0],get(gca,'YLim'),'--k','LineWidth',2);
        plot([1.5 1.5],get(gca,'YLim'),'--k','LineWidth',2);
        
        subtightplot(2,2,2,[],marg_h,marg_w);
        hold on;
        for c1=1:nDirCon
            for c2=1:2
                plot(timeAxis, squeeze(dPCA_out_single.cval.Z(effDim,c1,c2,:)),'Color',colors(c1,:),'LineWidth',2,'LineStyle',lsSingle{c2});
                errorPatch(timeAxis', squeeze(dPCA_out_single.cval.dimCI(effDim_xval,c1,c2,:,:)), ...
                    colors(c1,:), 0.2);
                dimProj{1,2}(:,c1,c2) = squeeze(dPCA_out_single.cval.Z(effDim,c1,c2,:));
                dimProj_ci{1,2}(:,c1,c2,:) = squeeze(dPCA_out_single.cval.dimCI(effDim_xval,c1,c2,:,:));
            end
        end
        xlim([timeAxis(1), timeAxis(end)]);
        ylim([-4, 8]);
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
        set(gca,'FontSize',18);
        plot([0 0],get(gca,'YLim'),'--k','LineWidth',2);
        plot([1.5 1.5],get(gca,'YLim'),'--k','LineWidth',2);
        
        subtightplot(2,2,3,[],marg_h,marg_w);
        hold on;
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
        ylim([-4, 8]);
        set(gca,'FontSize',18,'YTick',-2:2:6);
        xlabel('Time (s)');
        ylabel('Modulation (SD)');
        plot([0 0],get(gca,'YLim'),'--k','LineWidth',2);
        plot([1.5 1.5],get(gca,'YLim'),'--k','LineWidth',2);
        
        subtightplot(2,2,4,[],marg_h,marg_w);
        hold on;
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
        ylim([-4, 8]);
        set(gca,'YTickLabel',[]);
        set(gca,'FontSize',18);
        xlabel('Time (s)');
        plot([0 0],get(gca,'YLim'),'--k','LineWidth',2);
        plot([1.5 1.5],get(gca,'YLim'),'--k','LineWidth',2);
        
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'cross_CI_eff.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'cross_CI_eff.svg'],'svg');
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_effDimTransfer'],'dimProj','dimProj_ci');
        
        %%
        %variance table
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

                dPCA_out_dual = apply_dPCA_PCAOnly( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements(allSubIdx_dual))), ...
                    movFactors(noSingleMovements(allSubIdx_dual),:), timeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'}, 30 );

                dPCA_out_dual_oneFactor = apply_dPCA_PCAOnly( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements(allSubIdx_dual))), ...
                    movCues(noSingleMovements(allSubIdx_dual)), timeWindow/binMS, binMS/1000, {'CD','CI'}, 30 );

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

                    dPCA_single_set{setIdx} = apply_dPCA_PCAOnly( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(singleMovements{setIdx}(allSubIdx{setIdx}))), ...
                        movFactors_single(singleMovements{setIdx}(allSubIdx{setIdx}),1), timeWindow/binMS, binMS/1000, {'Dir','CI'} );
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

                allTables{trialNumIdx, repIdx} = varTable;
                
                varTable_norm = varTable;
                for colIdx=1:size(varTable,2)
                    varTable_norm(:,colIdx) = varTable_norm(:,colIdx)/varTable_norm(colIdx, colIdx);
                end

                allTables_norm{trialNumIdx,repIdx} = varTable_norm;
            end
        end
        
        crossValue = zeros(size(allTables_norm,1),nReps,4);
        for c=1:size(crossValue,1)
            for repIdx=1:nReps
                crossValue(c,repIdx,1) = allTables_norm{c,repIdx}(1,2);
                crossValue(c,repIdx,2) = allTables_norm{c,repIdx}(2,1);
                
                crossValue(c,repIdx,3) = allTables_norm{c,repIdx}(3,4);
                crossValue(c,repIdx,4) = allTables_norm{c,repIdx}(4,3);
            end
        end
        
        figure; 
        plot(squeeze(mean(crossValue,2)));
        ylim([0 1]);
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_varNumTrials.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_varNumTrials.fig'],'fig');
        
        varTable = allTables{end,1};
        varTable_norm = allTables_norm{end,1};
        
        tickLabels = {'Single Eff 1','Dual Eff 1','Single Eff 2','Dual Eff 2','Dual'};
        
        figure('Position',[428         748        1162         350]);
        subplot(1,2,1);
        imagesc(varTable);
        colorbar;
        set(gca,'XTick',1:length(tickLabels),'XTickLabel',tickLabels,'XTickLabelRotation',45,'YTick',1:length(tickLabels),'YTickLabel',tickLabels,'FontSize',16);
        set(gca,'YDir','normal');
        for rowIdx=1:size(varTable,1)
            for colIdx=1:size(varTable,2)
                text(colIdx,rowIdx,num2str(varTable(rowIdx,colIdx),2),'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
            end
        end
        title('Raw');

        subplot(1,2,2);
        imagesc(varTable_norm);
        colorbar;
        set(gca,'XTick',1:length(tickLabels),'XTickLabel',tickLabels,'XTickLabelRotation',45,'YTick',1:length(tickLabels),'YTickLabel',tickLabels,'FontSize',16);
        set(gca,'YDir','normal');
        for rowIdx=1:size(varTable,1)
            for colIdx=1:size(varTable,2)
                text(colIdx,rowIdx,num2str(varTable_norm(rowIdx,colIdx),2),'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
            end
        end
        title('Normalized');
        
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_varTable.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_varTable.svg'],'svg');
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_varTable'],'varTable','varTable_norm');
        
        %%
        continue;
        
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
        %linear models of neural activity as a function of single movement
        %activity
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
        
        dmc = unique(movCues(ismember(movCues, dirFactorMap(9:end,1))));
        smc = unique(movCues(ismember(movCues, singleMovementCodes)));
        movSets = cell(length(dmc),1);
        for m=1:length(movSets)
            mov1 = dirFactorMap(dirFactorMap(:,1)==dmc(m),2);
            mov2 = dirFactorMap(dirFactorMap(:,1)==dmc(m),3);
            movCode1 = singleMovementCodes(mov1);
            movCode2 = singleMovementCodes(mov2+4);
            movSets{m} = [movCode1, movCode2, dmc(m)];
        end
        
        dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx), ...
            movCues, timeWindow/binMS, binMS/1000, {'CD','CI'}, 20, 'standard' );
        close(gcf);

        cdIdx = find(dPCA_out.whichMarg==1);
        cdIdx = cdIdx(1:6);

        cueList = unique(movCues);
        allCoef = zeros(length(movSets),3);
        allVar = zeros(length(movSets),3);
        allR2 = zeros(length(movSets),3);

        for setIdx=1:length(movSets)
            [~,conIdx] = ismember(movSets{setIdx}, cueList);
            rScore = squeeze(dPCA_out.Z(cdIdx,conIdx,:));

            for x=1:3
                tmp = squeeze(rScore(:,x,:));
                %allVar(setIdx,x) = sum(tmp(:).^2);
                allVar(setIdx,x) = var(tmp(:).^2);
            end

            Y = squeeze(rScore(:,3,:))';
            X = squeeze(rScore(:,1:2,:));
            X = permute(X,[3 1 2]);
            X_unroll = reshape(X,[size(X,1)*size(X,2), size(X,3)]);
            Y_unroll = reshape(Y,[size(Y,1)*size(Y,2), 1]);

            [B,BINT,R,RINT,STATS] = regress(Y_unroll, [ones(size(X_unroll,1),1), X_unroll]);
            allCoef(setIdx,:) = B;
            allR2(setIdx,1) = STATS(1);

            %sum
            pred = sum(X_unroll,2);
            err = Y_unroll-pred;
            R2 = 1 - (sum(err(:).^2)/sum(Y_unroll(:).^2));
            allR2(setIdx,2) = R2;

            %mean
            pred = mean(X_unroll,2);
            err = Y_unroll-pred;
            R2 = 1 - (sum(err(:).^2)/sum(Y_unroll(:).^2));
            allR2(setIdx,3) = R2;
        end
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_linModelStats'],'allCoef','allR2','allVar');
        
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
        
        %single plot
%         [mcList, ~, mcUniqueCodes] = unique(singleTrlMoveDir,'rows');
%         colors = jet(size(mcList,1))*0.8;
%         
%         figure
%         hold on
%         for c=1:size(mcList,1)
%             trlIdx = find(mcUniqueCodes==c);
%             plot(singleTrlAvg_r(trlIdx,1), singleTrlAvg_r(trlIdx,2), 'o', 'Color', colors(c,:));
%         end
%         
%         figure
%         hold on
%         for c=1:size(mcList,1)
%             trlIdx = find(mcUniqueCodes==c);
%             plot(singleTrlAvg_r_suppr(trlIdx,1), singleTrlAvg_r_suppr(trlIdx,2), 'o', 'Color', colors(c,:));
%         end
        
        %dual plot
%         [mcList, ~, mcUniqueCodes] = unique(dualMoveDir,'rows');
%         colors = jet(size(mcList,1))*0.8;
%         
%         figure
%         hold on
%         for c=1:size(mcList,1)
%             trlIdx = find(mcUniqueCodes==c);
%             plot3(dualTrlAvg_r(trlIdx,1), dualTrlAvg_r(trlIdx,2), dualTrlAvg_r(trlIdx,3), 'o', 'Color', colors(c,:));
%         end
        
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
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_encModelStats'],'meanStats','statCI','statCI_singleAgain');

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
