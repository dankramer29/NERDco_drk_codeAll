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
for d=1:length(datasets)
    
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
        dPCA_out = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(useTrl), ...
            targCodes(useTrl), timeWindow/binMS, binMS/1000, {'CD','CI'} );
        
        codeList = unique(targCodes(useTrl));
        lineArgs = cell(length(codeList),1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end
        
        %legIdx = [2,5,6,8,10,13,14,15];
        %for l=1:length(legIdx)
        %    lineArgs{legIdx(l)}{end+1}='LineStyle';
        %    lineArgs{legIdx(l)}{end+1}=':';
        %end
        
        oneFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
            lineArgs, {'CD','CI'}, 'sameAxes');
        saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.svg'],'svg');

        %%
        %save neural cube
        windowIdx = -25:100;
        dataCube = zeros(length(useTrl),length(windowIdx),192);
        for t=1:length(useTrl)
            loopIdx = windowIdx+alignDat.eventIdx(useTrl(t));
            dataCube(t,:,:) = alignDat.zScoreSpikes(loopIdx,:);
        end
        
        %save('joystickDataCube_OL.mat','dataCube');
        
        %%
        tList = unique(targCodes(useTrl));
        figure
        hold on
        for x=1:length(tList)
            text(targList(tList(x),1), targList(tList(x),2), num2str(x));
        end
        xlim([-700,700]);
        ylim([-700,700]);
        
        %bin data
        sr = [[allR.spikeRaster]', [allR.spikeRaster2]'];
        nBins = ceil(size(sr,1)/binMS);
        binData = zeros(nBins, 192);
        loopIdx = 1:binMS;
        
        for binIdx=1:(nBins-1)
            binData(binIdx,:) = sum(sr(loopIdx,:));
            loopIdx = loopIdx + binMS;
        end
        
        binData = zscore(binData);
        
        %%
        %neural distance between each condition
        distanceMatrix = zeros(length(tList));
        for rowIdx=1:length(tList)
            for colIdx=1:length(tList)
                trlIdx_1 = find(targCodes==rowIdx);
                trlIdx_2 = find(targCodes==colIdx);
                
                dat_1 = triggeredAvg(smoothSpikes, alignDat.eventIdx(trlIdx_1), [10, 50]); 
                dat_2 = triggeredAvg(smoothSpikes, alignDat.eventIdx(trlIdx_2), [10, 50]);
                
                dat_1 = squeeze(mean(dat_1,2));
                dat_2 = squeeze(mean(dat_2,2));
                
                dat_1 = mean(dat_1);
                dat_2 = mean(dat_2);
                
                distanceMatrix(rowIdx, colIdx) = norm(dat_2 - dat_1);
            end
        end
        
        order = [2 6 10 14 16 13 9 5 18 22 26 29 32 30 25 21 1 4 8 12 15 11 7 3 17 20 24 28 31 27 23 29];
        figure;
        imagesc(distanceMatrix(order, order));
        colorbar;
        
        %%
        %HMM classifier
        nClass = 8 + 8*2 + 2;
        transmat = zeros(nClass);
        mu = zeros(192,nClass,1);
        sigma = zeros(192,192,nClass,1);
        mixmat = [];
        prior = zeros(nClass,1);
        prior(nClass-1) = 1;
        diagValue = 0.95;
                
        for x=1:size(sigma,3)
            sigma(:,:,x,1) = eye(192);
        end
        
        oppIdx = [8, 7, 6, 5, 4, 3, 2, 1];
               
        %forward movement stage
        for x=1:8
            transmat(x,x) = diagValue;
            transmat(x,x+8) = 1-diagValue;
            
            tCode = tList(x);
            allIdx = [];
            for t=1:length(useTrl)
                trlIdx = useTrl(t);
                if targCodes(trlIdx)==tCode
                    loopIdx = (alignDat.eventIdx(trlIdx)+15):(alignDat.eventIdx(trlIdx)+50);
                    allIdx = [allIdx; loopIdx'];
                end
            end
            
            mu(:,x,1) = mean(alignDat.zScoreSpikes(allIdx,:));
        end
        
        %reversal movement stage
        for x=1:8
            transmat(x+8,nClass) = (1-diagValue);
            transmat(x+8,x+8) = diagValue;
            
            mu(:,x+8,1) = mu(:,oppIdx(x),1);
        end       
        
        %single-stage forward
        for x=1:8
            transmat(x+16,nClass) = (1-diagValue);
            transmat(x+16,x+16) = diagValue;
            
            mu(:,x+16,1) = mu(:,x,1);
        end       
        
        %starting neutral state
        transmat(nClass-1,nClass-1) = diagValue;
        transmat(nClass-1,1:8) = (1-diagValue)/16;
        transmat(nClass-1,(17):24) = (1-diagValue)/16;
        mu(:,nClass-1,1) = 0;
        
        %ending neutral state
        transmat(nClass,nClass) = 1;
        mu(:,nClass,1) = 0;
        
        phi.mu = squeeze(mu);
        phi.Sigma = squeeze(sigma);
        
        cellDat = cell(length(useTrl),1);
        for x=1:length(useTrl)
            loopIdx = alignDat.eventIdx(useTrl(x))+(0:50);
            cellDat{x} = alignDat.zScoreSpikes(loopIdx,:);
        end
        
        [p_start, A, phi, loglik] = ChmmGauss(cellDat, nClass, 'p_start0', prior', 'A0', transmat, 'phi0', phi, 'cov_type', 'diag', 'cov_thresh', 1e-1);

        %[p_start, A, phi, loglik] = ChmmGauss({binData}, 17, 'p_start0', prior', 'A0', transmat, 'phi0', phi, 'cov_type', 'diag', 'cov_thresh', 1e-1);

        %logp_xn_given_zn = Gauss_logp_xn_given_zn(binData, phi);
        %[~,~, loglik] = LogForwardBackward(logp_xn_given_zn, p_start, A);
        %path = LogViterbiDecode(logp_xn_given_zn, p_start, A);
        
        logp_xn_given_zn = Gauss_logp_xn_given_zn(cellDat{1}, phi);
        [~,~, loglik] = LogForwardBackward(logp_xn_given_zn, prior', transmat);
        path = LogViterbiDecode(logp_xn_given_zn, prior', transmat);

        figure;
        plot(path);

        %decode
        figure
        hold on
        
        decCode = nan(length(cellDat),1);
        for x=1:length(cellDat)
            disp(x);
            
            logp_xn_given_zn = Gauss_logp_xn_given_zn(cellDat{x}, phi);
            [~,~, loglik] = LogForwardBackward(logp_xn_given_zn, prior', transmat);
            path = LogViterbiDecode(logp_xn_given_zn, prior', transmat);
            
            if any(ismember(path,17:24))
                [~,memLoc] = ismember(path,17:24);
                memLoc = memLoc(memLoc>0);
                decCode(x) = tList(memLoc(1));
            end
            if isnan(decCode(x))
                pathCut = path;
                pathCut(ismember(pathCut,[25,26]))=[];
                pathCut = mode(pathCut);
                if ismember(pathCut,1:8)
                    decCode(x) = tList(pathCut);
                else
                    decCode(x) = tList(oppIdx(pathCut-8));
                end
                
                plot(path+randn(size(path))*0.1,'-');
            end
        end
        
        mean(decCode==targCodes(useTrl))
        
        %%
        %HMM classifier
        nClass = 10;
        transmat = zeros(10);
        mu = zeros(192,nClass,1);
        sigma = zeros(192,192,nClass,1);
        mixmat = [];
        prior = zeros(nClass,1);
        prior(nClass-1) = 1;
        diagValue = 0.95;
        
        for x=1:size(sigma,3)
            sigma(:,:,x,1) = eye(192);
        end

        %bin data
        sr = [[allR.spikeRaster]', [allR.spikeRaster2]'];
        nBins = ceil(size(sr,1)/binMS);
        binData = zeros(nBins, 192);
        loopIdx = 1:binMS;
        
        for binIdx=1:(nBins-1)
            binData(binIdx,:) = sum(sr(loopIdx,:));
            loopIdx = loopIdx + binMS;
        end
        
        binData = zscore(binData);
        
        %forward movement stage
        for x=1:8
            transmat(x,x) = diagValue;
            transmat(x,10) = 1-diagValue;
            
            tCode = tList(x);
            allIdx = [];
            for t=1:length(useTrl)
                trlIdx = useTrl(t);
                if targCodes(trlIdx)==tCode
                    loopIdx = (alignDat.eventIdx(trlIdx)+15):(alignDat.eventIdx(trlIdx)+50);
                    allIdx = [allIdx; loopIdx'];
                end
            end
            
            mu(:,x,1) = mean(alignDat.zScoreSpikes(allIdx,:));
        end
        
        %starting neutral state
        transmat(9,9) = diagValue;
        transmat(9,1:8) = (1-diagValue)/8;
        mu(:,9,1) = 0;
        
        %ending neutral state
        transmat(10,10) = 1;
        mu(:,10,1) = 0;
        
        phi.mu = squeeze(mu);
        phi.Sigma = squeeze(sigma);
        
        cellDat = cell(length(useTrl),1);
        for x=1:length(useTrl)
            loopIdx = alignDat.eventIdx(useTrl(x))+(0:50);
            cellDat{x} = alignDat.zScoreSpikes(loopIdx,:);
        end
        
        [p_start, A, phi, loglik] = ChmmGauss(cellDat, nClass, 'p_start0', prior', 'A0', transmat, 'phi0', phi, 'cov_type', 'diag', 'cov_thresh', 1e-2);

        %[p_start, A, phi, loglik] = ChmmGauss({binData}, 17, 'p_start0', prior', 'A0', transmat, 'phi0', phi, 'cov_type', 'diag', 'cov_thresh', 1e-1);

        %logp_xn_given_zn = Gauss_logp_xn_given_zn(binData, phi);
        %[~,~, loglik] = LogForwardBackward(logp_xn_given_zn, p_start, A);
        %path = LogViterbiDecode(logp_xn_given_zn, p_start, A);
        
        logp_xn_given_zn = Gauss_logp_xn_given_zn(cellDat{1}, phi);
        [~,~, loglik] = LogForwardBackward(logp_xn_given_zn, prior', transmat);
        path = LogViterbiDecode(logp_xn_given_zn, prior', transmat);

        %decode
        figure
        hold on
        decCode = nan(length(cellDat),1);
        for x=1:length(cellDat)
            disp(x);
            
            logp_xn_given_zn = Gauss_logp_xn_given_zn(cellDat{x}, phi);
            [~,~, loglik] = LogForwardBackward(logp_xn_given_zn, prior', transmat);
            path = LogViterbiDecode(logp_xn_given_zn, prior', transmat);
            
            for y=1:8
                if any(ismember(path,y))
                    decCode(x) = tList(y);
                end
            end
            
            plot(path);
        end
        
        mean(decCode==targCodes(useTrl))
        
        %%  
        %single bin classifier
        trialLens = zeros(length(useTrl),1);
        for x=1:length(useTrl)
            trialLens(x) = allR(useTrl(x)).trialLength;
        end
        avgTrialLen = mean(trialLens)/1000;
        
        windowBinList = 5:5:50;
        skipBinList = 0:5:35;
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
                    loopIdx(loopIdx<1) = [];
                    
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
                bitrate(windowIdx, skipIdx) = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*(50)/50);
                %bitrate(windowIdx, skipIdx) = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*(nBins+skipBins)/50);
                %bitrate(windowIdx, skipIdx) = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*(nBins)/50);
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
        title(['Accuracy (max=' num2str(max(accuracy(:))) '), trialLen=' num2str(avgTrialLen]);
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
        bestBitrate = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*(nBins+skipBins)/50);

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
        %multibin
        allFeatures = [];
        allCodes = [];
        nSubBins = 1;
        %nSubSteps = 20;
        skipBins = 10;

        for outerIdx = 1:length(useTrl)
            trlIdx = useTrl(outerIdx);

            newData = [];
            for subBins=1:nSubBins
                if subBins==1
                    loopIdx = alignDat.eventIdx(trlIdx)+(10:50);
                else
                    loopIdx = alignDat.eventIdx(trlIdx)+(50:65);
                end
                
                newData = [newData, mean(alignDat.meanSubtractSpikes(loopIdx,:))];
            end
            
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
        title(num2str(1-L));

        %%
        %target legend
        useList = targList(setdiff(1:size(targList,1), centerCode),:);
        
        figure
        hold on
        for x=1:size(useList,1)
            text(useList(x,1), useList(x,2), num2str(x), 'FontSize', 12);
        end
        set(gca,'YDir','reverse')
        xlim([-700,700]);
        ylim([-700,700]);
        axis equal;
        
        saveas(gcf,[outDir filesep 'targetLegend_' datasets{d,3}{blockSetIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'targetLegend_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
        
        %%
        %target legend color cues
        figure
        hold on
        for x=1:size(useList,1)
            plot(useList(x,1), useList(x,2),'o', 'MarkerSize',20,'MarkerFaceColor',colors(x,:),'Color',colors(x,:));
        end
        set(gca,'YDir','reverse')
        xlim([-700,700]);
        ylim([-700,700]);
        axis equal;
        
        saveas(gcf,[outDir filesep 'targetLegendColor_' datasets{d,3}{blockSetIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'targetLegendColor_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
        
        close all;
    end
    
    %%classify across all sets
    acrossFeatures = [];
    acrossClasses = [];
    for blockSetIdx=1:length(datasets{d,2})
        disp(blockSetIdx);
        
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
        timeWindow = [-1000,3000];
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        %%
        %single bin classifier
        allFeatures = [];
        allCodes = [];
        nBins = 25;
        skipBins = -25;

        for outerIdx = 1:length(useTrl)
            trlIdx = useTrl(outerIdx);
            loopIdx = (alignDat.eventIdx(trlIdx)+skipBins):((alignDat.eventIdx(trlIdx)+skipBins+nBins));
            loopIdx(loopIdx<1) = [];

            newData = mean(alignDat.meanSubtractSpikes(loopIdx,:));

            allFeatures = [allFeatures; newData];
            allCodes = [allCodes; targCodes(trlIdx)];
        end

        acrossFeatures = [acrossFeatures; allFeatures];
        acrossClasses = [acrossClasses; allCodes+(blockSetIdx)*100];
    end
    
    obj = fitcdiscr(acrossFeatures,acrossClasses,'DiscrimType','diaglinear');
    cvmodel = crossval(obj);
    L = kfoldLoss(cvmodel);
    predLabels = kfoldPredict(cvmodel);

    C = confusionmat(acrossClasses, predLabels);
    
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
    
    %%  
%     %temporal classifier
%     allFeatures = [];
%     allCodes = [];
%     nPoints = 3;
%     nBinsPerPoint = 20;
%     skipBins = 10;
%     for outerIdx = 1:length(useTrl)
%         trlIdx = useTrl(outerIdx);
%         
%         newData = [];
%         datIdx = (alignDat.eventIdx(trlIdx)+skipBins):((alignDat.eventIdx(trlIdx)+skipBins+nBinsPerPoint));
%         for pointIdx=1:nPoints
%             newData = [newData, mean(alignDat.meanSubtractSpikes(datIdx,:))];
%             datIdx = datIdx + nBinsPerPoint;
%         end
%         
%         allFeatures = [allFeatures; newData];
%         allCodes = [allCodes; targCodes(trlIdx)];
%     end
%     
%     nClasses = length(unique(allCodes));
%     
%     obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
%     cvmodel = crossval(obj);
%     L = kfoldLoss(cvmodel);
%     predLabels = kfoldPredict(cvmodel);
% 
%     C = confusionmat(allCodes, predLabels);
%     
%     nTrials = length(allCodes);
%     bitrate = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*(nBins+skipBins)/50);
%    
%     movLabels = cell(size(C,1),1);
%     for m=1:size(C,1)
%         movLabels{m} = num2str(m);
%     end
%     
%     figure('Position',[680         275        1112         823]);
%     imagesc(C);
%     set(gca,'XTick',1:length(allCodes),'XTickLabel',movLabels,'XTickLabelRotation',45);
%     set(gca,'YTick',1:length(allCodes),'YTickLabel',movLabels);
%     set(gca,'FontSize',14);
%     colorbar;
%     title(['X-Validated Accuracy: ' num2str(1-L,3) ', bit rate: ' num2str(bitrate)]);
% 
%     saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
%     saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');
end