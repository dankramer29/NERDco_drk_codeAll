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
for d=1:size(datasets,1)
    
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
    smoothWidth = 0;
    if strcmp(datasets{d,1}(1:2),'t5')
        datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
    else
        datFields = {'glove','currentMovement','glove_speed'};
    end
    timeWindow = [-1500,3000];
    movTimeWindow = [0,1000];
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 6);
    
    if strcmp(datasets{d,1},'t5.2018.03.19')
        dualSetIdx = 2:5;
    elseif strcmp(datasets{d,1},'t5.2018.03.21')
        dualSetIdx = 1:2;
    elseif strcmp(datasets{d,1},'t5.2018.04.02')
        dualSetIdx = 1:8;
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
        dPCA_out_dual = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx(noSingleMovements))+1, ...
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
        [yAxesFinal, allHandles, axFromDualMovements] = general_dPCA_plot( dPCA_out_dual, timeAxis, lineArgs_dual, ...
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
            alignDat.zScoreSpikes, dualDim_eff1, 20:100, 100 );
        
        %eff 2
        axIdx = find(dPCA_dual_movWindow.cval.whichMarg==2);
        dualDim_eff2 = dPCA_dual_movWindow.cval.resortW;
        for x=1:length(dualDim_eff2)
            dualDim_eff2{x} = dualDim_eff2{x}(:,axIdx(1:min(4,length(axIdx))));
        end
        
        [ varianceSummary(2,1), varianceSummary(2,2:3) ] = getSimulVariance_xval( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, dualDim_eff2, 20:100, 100 );
        
        %interaction variance
        axIdx = find(dPCA_dual_movWindow.cval.whichMarg==4);
        interactionDim = dPCA_dual_movWindow.cval.resortW;
        for x=1:length(interactionDim)
            interactionDim{x} = interactionDim{x}(:,axIdx(1:min(4,length(axIdx))));
        end
        
        [ varianceSummary(5,1), varianceSummary(5,2:3) ] = getSimulVariance_xval( eventIdx(noSingleMovements), movCues(noSingleMovements), ...
            alignDat.zScoreSpikes, interactionDim, 20:100, 100 );
                
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

            movWindow = 20:100;
            [ varianceSummary(setIdx+2,1), varianceSummary(setIdx+2,2:3) ] = getSimulVariance_xval( eventIdx(singleMovements), movCues(singleMovements), ...
                alignDat.zScoreSpikes, singleEffDim{setIdx}, 20:100, 100 );
            
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
        close all;
        
        %%
        cWindow = (-timeWindow(1)/binMS) + (20:100);
        stData = cat(2, squeeze(nanmean(dPCA_single_set{1}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_single_set{2}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,1,:,cWindow,:),4)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,2,:,cWindow,:),4)));
        
        eff1 = effNames{d}{outerMovSetIdx}{1};
        eff2 = effNames{d}{outerMovSetIdx}{2};
        
        stData_norm = stData;
        stData_norm(:,1:2,:) = stData_norm(:,1:2,:) - nanmean(nanmean(stData_norm(:,1:2,:),3),2);
        stData_norm(:,3:4,:) = stData_norm(:,3:4,:) - nanmean(nanmean(stData_norm(:,3:4,:),3),2);
        stData_norm(:,5:8,:) = stData_norm(:,5:8,:) - nanmean(nanmean(stData_norm(:,5:8,:),3),2);
        
        singleColors = [0.8 0 0;
            1.0 0.6 0.6;
            0.0 0.0 0.8;
            0.6 0.6 1.0];
        
        dualColors = [0.5 0 0.5;
            0.87 0.6 0.87;
            0.5 0.5 0;
            0.87 0.87 0.6];
            
        tmp = stData_norm(:,1:4,:);
        tmp_unroll = permute(tmp,[1 3 2]);
        tmp_unroll = tmp_unroll(:,:)';
        classLabels = zeros(size(tmp_unroll,1),1);
        globalIdx = 1:size(stData_norm,3);
        for c=1:4
            classLabels(globalIdx) = c;
            globalIdx = globalIdx + 18;
        end
        
        [cvScore, COEFF] = cvPCA_class( tmp_unroll, classLabels, 'reflection' );
        cvScore_reshape = reshape(cvScore', [3 18 4]);
        
        dualLineColor = [0.6 0.6 0.6];
        allXLim = [];
        allYLim = [];
        
        figure('Position',[214   818   778   236]);
        axHandles(1)=subplot(1,3,1);
        hold on
        
        clusterCenters = squeeze(nanmean(cvScore_reshape,2));
        plot([clusterCenters(1,1), clusterCenters(1,2)], [clusterCenters(2,1), clusterCenters(2,2)], '-','Color', [0.9 0.3 0.3], 'LineWidth', 2);
        plot([clusterCenters(1,3), clusterCenters(1,4)], [clusterCenters(2,3), clusterCenters(2,4)], '-','Color', [0.3 0.3 0.9], 'LineWidth', 2);
        disp(norm(clusterCenters(:,1)-clusterCenters(:,2)));
        disp(norm(clusterCenters(:,3)-clusterCenters(:,4)));
       
        for c=1:4
            tmp = squeeze(cvScore_reshape(:,:,c))';
            lHandles(c)=plot(tmp(:,1), tmp(:,2), 'o','Color', singleColors(c,:), 'MarkerFaceColor', singleColors(c,:), 'MarkerSize', 4);
        end

        axis equal;
        axis tight;
        allXLim = [allXLim; get(gca,'XLim')];
        allYLim = [allYLim; get(gca,'YLim')];
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Single PC1');
        ylabel('Single PC2');
        legend(lHandles,{[eff1 ' Left'],[eff1 ' Right'],[eff2 ' Left'],[eff2 ' Right']});
        
        %%
        axHandles(2)=subplot(1,3,2);
        hold on
        
        trlAvg = squeeze(nanmean(stData(:,5:8,:),3));
        clusterCenters = COEFF(:,1:2)'*trlAvg;
        
        mnAll = mean(clusterCenters');
        mnBlueEff = ((clusterCenters(:,2)-clusterCenters(:,1))*0.5 + (clusterCenters(:,4)-clusterCenters(:,3))*0.5)';
        mnRedEff = ((clusterCenters(:,3)-clusterCenters(:,1))*0.5 + (clusterCenters(:,4)-clusterCenters(:,2))*0.5)';
        
        blueLine = [mnAll-mnBlueEff/2; mnAll+mnBlueEff/2];
        redLine = [mnAll-mnRedEff/2; mnAll+mnRedEff/2];
        
        plot(blueLine(:,1), blueLine(:,2), '-','Color', [0.3 0.3 0.9], 'LineWidth', 2);
        plot(redLine(:,1), redLine(:,2), '-','Color', [0.9 0.3 0.3], 'LineWidth', 2);

        m1 = mean(clusterCenters(:,[1 3]),2);
        m2 = mean(clusterCenters(:,[2 4]),2);
        disp(norm(m1-m2));
        
        m1 = mean(clusterCenters(:,[1 2]),2);
        m2 = mean(clusterCenters(:,[3 4]),2);
        disp(norm(m1-m2));
        
        for c=1:4
            tmp = (COEFF(:,1:3)'*squeeze(stData(:,c+4,:)))';
            lHandles(c)=plot(tmp(:,1), tmp(:,2), 'o','Color', dualColors(c,:), 'MarkerFaceColor', dualColors(c,:), 'MarkerSize', 4);
        end
        
        axis equal;
        axis tight;
        allXLim = [allXLim; get(gca,'XLim')];
        allYLim = [allYLim; get(gca,'YLim')];
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Single PC1');
        ylabel('Single PC2');
        legend(lHandles,{[eff2 ' Left, ' eff1 ' Left'],[eff2 ' Right, ' eff1 ' Left'],[eff2 ' Left, ' eff1 ' Right'],[eff2 ' Right, ' eff1 ' Right']});
        
        %%
        tmp = stData_norm(:,5:8,:);
        tmp_unroll = permute(tmp,[1 3 2]);
        tmp_unroll = tmp_unroll(:,:)';
                
        [cvScore_2, COEFF2] = cvPCA_class( tmp_unroll, classLabels, 'rotation' );
        cvScore_reshape_2 = reshape(cvScore_2', [3 18 4]);
        
        axHandles(3)=subplot(1,3,3);
        hold on
        
        clusterCenters = squeeze(nanmean(cvScore_reshape_2,2));
   
        mnAll = mean(clusterCenters');
        mnBlueEff = ((clusterCenters(:,2)-clusterCenters(:,1))*0.5 + (clusterCenters(:,4)-clusterCenters(:,3))*0.5)';
        mnRedEff = ((clusterCenters(:,3)-clusterCenters(:,1))*0.5 + (clusterCenters(:,4)-clusterCenters(:,2))*0.5)';
        
        blueLine = [mnAll-mnBlueEff/2; mnAll+mnBlueEff/2];
        redLine = [mnAll-mnRedEff/2; mnAll+mnRedEff/2];
        
        m1 = mean(clusterCenters(:,[1 3]),2);
        m2 = mean(clusterCenters(:,[2 4]),2);
        disp(norm(m1-m2));
        
        m1 = mean(clusterCenters(:,[1 2]),2);
        m2 = mean(clusterCenters(:,[3 4]),2);
        disp(norm(m1-m2));
        
        plot(blueLine(:,1), blueLine(:,2), '-','Color', [0.3 0.3 0.9], 'LineWidth', 2);
        plot(redLine(:,1), redLine(:,2), '-','Color', [0.9 0.3 0.3], 'LineWidth', 2);
        
        for c=1:4
            tmp = squeeze(cvScore_reshape_2(:,:,c))';
            plot(tmp(:,1), tmp(:,2), 'o','Color', dualColors(c,:), 'MarkerSize', 4, 'MarkerFaceColor', dualColors(c,:));
        end
        
        axis equal;
        axis tight;
        allXLim = [allXLim; get(gca,'XLim')];
        allYLim = [allYLim; get(gca,'YLim')];
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Dual PC1');
        ylabel('Dual PC2');
        
        finalXLim = [min(allXLim(:)), max(allXLim(:))];
        finalYLim = [min(allYLim(:)), max(allYLim(:))];
        for axIdx=1:length(axHandles)
            set(axHandles(axIdx),'XLim',finalXLim,'YLim',finalYLim);
        end
        
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'PCA_dots.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} 'PCA_dots.svg'],'svg');
        
        %%
        %use cross-validation to compute modulation size for each effector
        %in dual case & single case
        cWindow = (-timeWindow(1)/binMS) + (20:100);
        stData = cat(2, squeeze(nanmean(dPCA_single_set{1}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_single_set{2}.featureVals(:,:,cWindow,:),3)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,1,:,cWindow,:),4)), ...
            squeeze(nanmean(dPCA_out_dual.featureVals(:,2,:,cWindow,:),4)));
        
        %pairings = {{1,2},{3,4},{[5 6],[7 8]},{[5 7],[6 8]}};
        pairings = {{1,2},{5 7},{6 8},{3,4},{5 6},{7 8},{[5 6],[7 8]},{[5 7],[6 8]}};
          
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
        %pairList = {[3 4],[5 6],[7 8],[1 2],[5 7],[6 8]};
        pairList = {{3,4},{5 6},{7 8},{[5 7],[6 8]},{1 2},{5 7},{6 8},{[5 6],[7 8]}};
        corrMatTest = ones(length(pairList));
        for rowIdx=1:length(pairList)
            for colIdx=1:length(pairList)
                if rowIdx==colIdx
                    continue
                end
                p1 = pairList{rowIdx};
                p2 = pairList{colIdx};
                
                dat1_a = permute(squeeze(stData(:,p1{1},:)), [1 3 2]);
                dat1_b = permute(squeeze(stData(:,p1{2},:)), [1 3 2]);
                
                dat2_a = permute(squeeze(stData(:,p2{1},:)), [1 3 2]);
                dat2_b = permute(squeeze(stData(:,p2{2},:)), [1 3 2]);
                
                dat1_a = dat1_a(:,:);
                dat1_b = dat1_b(:,:);
                
                dat2_a = dat2_a(:,:);
                dat2_b = dat2_b(:,:);
                
                subtractMean = false;
                [ lessBiasedEstimate_1, meanOfSquares_1 ] = lessBiasedDistance(dat1_a', dat1_b', subtractMean);
                [ lessBiasedEstimate_2, meanOfSquares_2 ] = lessBiasedDistance(dat2_a', dat2_b', subtractMean);

                dv1 = mean(dat1_a') - mean(dat1_b');
                dv2 = mean(dat2_a') - mean(dat2_b');
                
                corrMatTest(rowIdx, colIdx) = dv1*dv2'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
                %corrMat(rowIdx, colIdx) = (dv1-mean(dv1))*(dv2-mean(dv2))'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
            end
        end
        
        %jackknife
        nTrials = size(stData,3);
        modSize = zeros(nTrials,length(modSizeTest));
        corrMat = ones(nTrials,6,6);
        
        for repIdx = 1:nTrials
            disp(repIdx);
            keepIdx = setdiff(1:nTrials, repIdx);
            
            for pairIdx = 1:length(pairings)
                dat1 = squeeze(stData(:,pairings{pairIdx}{1},:));
                dat2 = squeeze(stData(:,pairings{pairIdx}{2},:));
                if length(pairings{pairIdx}{1})>1
                    dat1 = dat1(:,:,keepIdx);
                    dat2 = dat2(:,:,keepIdx);
                
                    dat1 = dat1(:,:);
                    dat2 = dat2(:,:);

                    badIdx = any(isnan(dat1),1) | any(isnan(dat2),1);
                    dat1(:,badIdx) = [];
                    dat2(:,badIdx) = [];
                else
                    dat1 = dat1(:,keepIdx);
                    dat2 = dat2(:,keepIdx);
                end
                
                dat1 = dat1';
                dat2 = dat2';
                modSize(repIdx,pairIdx) = lessBiasedDistance(dat1, dat2);
            end
            
            for rowIdx=1:length(pairList)
                for colIdx=1:length(pairList)
                    if rowIdx==colIdx
                        continue
                    end
                    p1 = pairList{rowIdx};
                    p2 = pairList{colIdx};

                    dat1_a = permute(squeeze(stData(:,p1{1},:)), [1 3 2]);
                    dat1_b = permute(squeeze(stData(:,p1{2},:)), [1 3 2]);

                    dat2_a = permute(squeeze(stData(:,p2{1},:)), [1 3 2]);
                    dat2_b = permute(squeeze(stData(:,p2{2},:)), [1 3 2]);
                    
                    if size(dat1_a,3)>size(dat1_a,2)
                        dat1_a = dat1_a(:,:,keepIdx);
                        dat1_b = dat1_b(:,:,keepIdx);
                    else
                        dat1_a = dat1_a(:,keepIdx,:);
                        dat1_b = dat1_b(:,keepIdx,:);
                    end
                    
                    if size(dat2_a,3)>size(dat2_a,2)
                        dat2_a = dat2_a(:,:,keepIdx);
                        dat2_b = dat2_b(:,:,keepIdx);
                    else
                        dat2_a = dat2_a(:,keepIdx,:);
                        dat2_b = dat2_b(:,keepIdx,:);
                    end
                    
                    dat1_a = dat1_a(:,:);
                    dat1_b = dat1_b(:,:);

                    dat2_a = dat2_a(:,:);
                    dat2_b = dat2_b(:,:);

                    subtractMean = false;
                    [ lessBiasedEstimate_1, meanOfSquares_1 ] = lessBiasedDistance(dat1_a', dat1_b', subtractMean);
                    [ lessBiasedEstimate_2, meanOfSquares_2 ] = lessBiasedDistance(dat2_a', dat2_b', subtractMean);

                    dv1 = mean(dat1_a') - mean(dat1_b');
                    dv2 = mean(dat2_a') - mean(dat2_b');

                    corrMat(repIdx, rowIdx, colIdx) = dv1*dv2'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
                end
            end
        end
        
        CI_jack = jackCI( modSizeTest', modSize );
        CI_jack_r1 = jackCI( modSizeTest(7)/modSizeTest(1), modSize(:,7)./modSize(:,1) );
        CI_jack_r2 = jackCI( modSizeTest(8)/modSizeTest(4), modSize(:,8)./modSize(:,4) );
        CI_jack_cMag = jackCI( corrMatTest(:)', corrMat(:,:) );
        CI_jack_cMag = reshape(CI_jack_cMag', [8 8 2]);
                
        %resample
        nResamples = 1000;
        modSize = zeros(nResamples,length(modSizeTest));
        corrMat = ones(nResamples,6,6);
        nTrials = size(stData,3);
        
        for repIdx = 1:nResamples
            disp(repIdx);
            for pairIdx = 1:length(pairings)
                dat1 = squeeze(stData(:,pairings{pairIdx}{1},:));
                dat2 = squeeze(stData(:,pairings{pairIdx}{2},:));
                if length(pairings{pairIdx}{1})>1
                    dat1 = dat1(:,:,randi(nTrials,nTrials,1));
                    dat2 = dat2(:,:,randi(nTrials,nTrials,1));
                
                    dat1 = dat1(:,:);
                    dat2 = dat2(:,:);

                    badIdx = any(isnan(dat1),1) | any(isnan(dat2),1);
                    dat1(:,badIdx) = [];
                    dat2(:,badIdx) = [];
                else
                    dat1 = dat1(:,randi(nTrials,nTrials,1));
                    dat2 = dat2(:,randi(nTrials,nTrials,1));                   
                end
                
                dat1 = dat1';
                dat2 = dat2';

                modSize(repIdx,pairIdx) = lessBiasedDistance(dat1, dat2);
            end
            
            for rowIdx=1:length(pairList)
                for colIdx=1:length(pairList)
                    if rowIdx==colIdx
                        continue
                    end
                    p1 = pairList{rowIdx};
                    p2 = pairList{colIdx};

                    dat1_a = permute(squeeze(stData(:,p1{1},:)), [1 3 2]);
                    dat1_b = permute(squeeze(stData(:,p1{2},:)), [1 3 2]);

                    dat2_a = permute(squeeze(stData(:,p2{1},:)), [1 3 2]);
                    dat2_b = permute(squeeze(stData(:,p2{2},:)), [1 3 2]);
                    
                    if size(dat1_a,3)>size(dat1_a,2)
                        dat1_a = dat1_a(:,:,randi(size(dat1_a,3),size(dat1_a,3),1));
                        dat1_b = dat1_b(:,:,randi(size(dat1_b,3),size(dat1_b,3),1));
                    else
                        dat1_a = dat1_a(:,randi(size(dat1_a,2),size(dat1_a,2),1),:);
                        dat1_b = dat1_b(:,randi(size(dat1_b,2),size(dat1_b,2),1),:);
                    end
                    
                    if size(dat2_a,3)>size(dat2_a,2)
                        dat2_a = dat2_a(:,:,randi(size(dat2_a,3),size(dat2_a,3),1));
                        dat2_b = dat2_b(:,:,randi(size(dat2_b,3),size(dat2_b,3),1));
                    else
                        dat2_a = dat2_a(:,randi(size(dat2_a,2),size(dat2_a,2),1),:);
                        dat2_b = dat2_b(:,randi(size(dat2_b,2),size(dat2_b,2),1),:);
                    end
                    
                    dat1_a = dat1_a(:,:);
                    dat1_b = dat1_b(:,:);

                    dat2_a = dat2_a(:,:);
                    dat2_b = dat2_b(:,:);

                    subtractMean = false;
                    [ lessBiasedEstimate_1, meanOfSquares_1 ] = lessBiasedDistance(dat1_a', dat1_b', subtractMean);
                    [ lessBiasedEstimate_2, meanOfSquares_2 ] = lessBiasedDistance(dat2_a', dat2_b', subtractMean);

                    dv1 = mean(dat1_a') - mean(dat1_b');
                    dv2 = mean(dat2_a') - mean(dat2_b');

                    corrMat(repIdx, rowIdx, colIdx) = dv1*dv2'/(lessBiasedEstimate_1*lessBiasedEstimate_2);
                end
            end
        end

        varianceSummary(3,:) = [modSizeTest(1), prctile(modSize(:,1),[2.5 97.5])];
        varianceSummary(4,:) = [modSizeTest(4), prctile(modSize(:,4),[2.5 97.5])];
        
        varianceSummary(6,:) = [mean(modSizeTest(2:3))/modSizeTest(1), prctile(mean(modSize(:,[2 3]),2)./modSize(:,1),[2.5 97.5])];
        varianceSummary(7,:) = [mean(modSizeTest(5:6))/modSizeTest(4), prctile(mean(modSize(:,[5 6]),2)./modSize(:,4),[2.5 97.5])];
        
        varianceSummary(8,:) = [modSizeTest(7)/modSizeTest(1), prctile(modSize(:,7)./modSize(:,1),[2.5 97.5])];
        varianceSummary(9,:) = [modSizeTest(8)/modSizeTest(4), prctile(modSize(:,8)./modSize(:,4),[2.5 97.5])];
        
        corrMatCI = permute(prctile(corrMat,[2.5 97.5]),[2 3 1]);
        
        save([outDir filesep datasets{d,3}{outerMovSetIdx} '_varSummary'],'varianceSummary','corrMatTest','corrMatCI','CI_jack_cMag','CI_jack',...
            'CI_jack_r1','CI_jack_r2');
        
        %%
        close all;
    end %movement set
end %dataset
