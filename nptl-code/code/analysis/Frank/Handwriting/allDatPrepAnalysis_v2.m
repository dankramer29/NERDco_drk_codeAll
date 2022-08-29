%%
%single letter decoding
%word & sentence decoding

%%
sessionList = {'t5.2019.04.22',[6 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24],''; %alphabet & curves 1 (slow)
    't5.2019.04.24',[6 7 8 9 10 11 12 13 14 15 16 17 18 19 20],'';                    %alphabet & curves 2 (faster)
    't5.2019.04.29',[11 12 16 17 18 19 20 21 22],'';                                  %arm vs. head, letters of different speeds & sizes
    't5.2019.05.01',[4 6 8 10 13 15 19 21 22],'';                                     %many words
    't5.2019.05.06',[5 8 10 12 14 16 18],'_arm';                                      %bezier curves (arm)
    't5.2019.05.06',[4 6 9 11 13 15 17],'_head';                                      %bezier curves (head)
    't5.2019.05.08',[5 7 9 11 13 15 17 19 23],'';                                     %many sentences
    't5.2019.05.31',[6 8 10 12 14 17 19 21],'_arm';                                   %bezier curves 2 (arm)
    't5.2019.05.31',[4 7 9 11 13 15 18 20],'_head';                                   %bezier curves 2 (head)   
    't5.2019.06.17',[5 8 10 12 14 17 21 24 26 28],'_arm';                             %bezier curves 4 (arm)
    't5.2019.06.17',[3 6 9 11 13 16 18 22 25 27],'_head';                             %bezier curves 4 (head)
    't5.2019.06.19',[4 6 8 10 12 14 16 18 22 24],'_arm';                             %bezier curves 5 (arm)
    't5.2019.06.19',[2 5 7 9 11 13 15 17 19 23],'_head';                             %bezier curves 5 (head)
    't5.2019.06.24',[5 7 9 11 13 15 17 19 21 23],'_arm';                             %bezier curves 6 (arm)
    't5.2019.06.24',[3 6 8 10 12 14 16 18 20 22],'_head';                             %bezier curves 6 (head)
    };                                                         

%%
for sessionIdx=1:size(sessionList,1)
    
    sessionSuffix = sessionList{sessionIdx, 3};
    sessionName = sessionList{sessionIdx, 1};
    blockList = sessionList{sessionIdx, 2};
    clear allR R alignDat
    
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
 
    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'allAlphabets' filesep sessionName sessionSuffix];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

    %%       
    bNums = horzcat(blockList);
    movField = 'rigidBodyPosXYZ';
    filtOpts.filtFields = {'rigidBodyPosXYZ'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );

    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
        end
        allR = [allR, R{x}];
    end

    for t=1:length(allR)
        allR(t).headVel = [0 0 0; diff(allR(t).rigidBodyPosXYZ')]';
    end

    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'rigidBodyPosXYZ','currentMovement','headVel'};
    timeWindow = [-1000,4000];
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
    
    endTrl = [allR.holdCue];
    startTrl = [allR.goCue];
    clear allR;
    
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];

    alignDat.zScoreSpikes_allBlocks = zscore(alignDat.rawSpikes);
    alignDat.zScoreSpikes_blockMean = alignDat.zScoreSpikes;

    smoothSpikes_allBlocks = gaussSmooth_fast(zscore(alignDat.rawSpikes),3);
    smoothSpikes_blockMean = gaussSmooth_fast(alignDat.zScoreSpikes,3);

    trlCodes = alignDat.currentMovement(alignDat.eventIdx);
    nothingTrl = trlCodes==218;
    
    if strcmp(sessionName,'t5.2019.05.31')
        trlCodes = trlCodes+1000;
    end

    [uniqueCodes, ~, tcReorder] = unique(trlCodes);
    uniqueCodes_noNothing = uniqueCodes;
    uniqueCodes_noNothing(uniqueCodes_noNothing==218) = [];
    
    %%
    [movLabelSets, codeSets, fullCodes, allLabels, allTemplates, allTemplateCodes, allTimeWindows] = allAlphabetCodePreamble();
 
    %%
    %make data cubes for each condition & save
    cubeDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes'];
    fileName = [cubeDir filesep sessionName sessionSuffix '_unwarpedCube.mat'];
    
    if ~exist(fileName,'file')
        dat = struct();
        for t=1:length(uniqueCodes_noNothing)
            tmpIdx = find(uniqueCodes_noNothing(t)==fullCodes);
            if isempty(tmpIdx)
                continue;
            end
            
            winToUse = allTimeWindows(tmpIdx,:);
            if ismember(uniqueCodes_noNothing(t), codeSets{3}) %word codes
                %for self-paced words, cut off the trial by replacing with nans
                %after T5 indicated he was done
                concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(trlCodes==fullCodes(tmpIdx)), winToUse );
                trlIdx = find(trlCodes==uniqueCodes_noNothing(t));
                endTime = endTrl(trlIdx) - startTrl(trlIdx);
                endTime = round(endTime/10);
                endTime(endTime>400) = 400;

                for x=1:length(trlIdx)
                    concatDat(x,(51+endTime(x)):end,:)=nan;
                end
            else
                concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(trlCodes==fullCodes(tmpIdx)), winToUse );
            end

            dat.(allLabels{tmpIdx}) = concatDat;
        end

        save(fileName,'-struct','dat');
    end

    %%
    %substitute in aligned data
    alignedCube = load([cubeDir filesep sessionName sessionSuffix '_warpedCube.mat']);
    alignDat.zScoreSpikes_align = alignDat.zScoreSpikes_blockMean;

    for t=1:length(uniqueCodes_noNothing)
        trlIdx = find(trlCodes==uniqueCodes_noNothing(t));
        if isempty(trlIdx)
            continue;
        end
        labelIdx = find(fullCodes==uniqueCodes_noNothing(t));
        nBins = size(alignedCube.(allLabels{labelIdx}),2);
        %winToUse = allTimeWindows(trlIdx,:);
        
        for x=1:length(trlIdx)
            loopIdx = (alignDat.eventIdx(trlIdx(x))-49):(alignDat.eventIdx(trlIdx(x))+(nBins-50));
            alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(allLabels{labelIdx})(x,:,:);
        end
    end

    alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0;
    smoothSpikes_align = gaussSmooth_fast(alignDat.zScoreSpikes_align, 3);

    %%
    timeWindow_mpca = [-500,1500];
    tw =  timeWindow_mpca/binMS;
    tw(1) = tw(1) + 1;
    tw(2) = tw(2) - 1;
    
    twWords = [-49, 399];

    margGroupings = {{1, [1 2]}, {2}};
    margNames = {'Condition-dependent', 'Condition-independent'};
    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 5;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'singleTrial';
    opts_m.alignMode = 'rotation';
    opts_m.plotCI = true;
    opts_m.nResamples = 10;

    mPCA_out = cell(length(codeSets),1);
    for pIdx=1:length(codeSets) 
        trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
        if isempty(trlIdx)
            continue
        end
        
        mc = trlCodes(trlIdx)';
        [~,~,mc_oneStart] = unique(mc);

        if pIdx==3
            twUse = twWords;
        else
            twUse = tw;
        end
            
        mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_align, alignDat.eventIdx(trlIdx), ...
            mc_oneStart, twUse, binMS/1000, opts_m );
    end
    close all;
    
    %%
    %population rasters
    alignNames = {'aligned','unaligned'};
    for alignIdx=1:2
        for setIdx=1:length(codeSets)
            if isempty(mPCA_out{setIdx})
                continue;
            end

            unalignedDim = gaussSmooth_fast(alignDat.zScoreSpikes, 3.0) * mPCA_out{setIdx}.W(:,1:5);
            codeList = codeSets{setIdx};
            movLabels = movLabelSets{setIdx};

            tw_all = [-49, 150];
            timeStep = binMS/1000;
            timeAxis = (tw_all(1):tw_all(2))*timeStep;
            nDimToShow = 5;
            nPerPage = 10;
            currIdx = 1:10;

            for pageIdx=1:6
                figure('Position',[ 680   185   711   913]);
                for conIdx=1:length(currIdx)
                    c = currIdx(conIdx);
                    if c > length(codeList)
                        break;
                    end

                    if alignIdx==1
                        concatDat = triggeredAvg( mPCA_out{setIdx}.readoutZ_unroll(:,1:nDimToShow), alignDat.eventIdx(trlCodes==codeList(c)), tw_all );
                    else
                        concatDat = triggeredAvg( unalignedDim, alignDat.eventIdx(trlCodes==codeList(c)), tw_all );
                    end
                    
                    for dimIdx=1:nDimToShow
                        subtightplot(length(currIdx),nDimToShow,(conIdx-1)*nDimToShow + dimIdx);
                        hold on;

                        tmp = squeeze(concatDat(:,:,dimIdx));
                        tmp(isnan(tmp)) = [];
                        tmp(isinf(tmp)) = [];
                        %imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),prctile(tmp(:),[5 95]));
                        imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),[-1 1]);
                        axis tight;
                        plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
                        plot([1.5,1.5],get(gca,'YLim'),'-k','LineWidth',2);

                        cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
                        colormap(cMap);

                        %title(movLabels{c});
                        if dimIdx==1
                            ylabel(movLabels{c},'FontSize',16,'FontWeight','bold');
                        end
                        if c==1
                            title(['Dimension ' num2str(dimIdx)],'FontSize',12);
                        end

                        set(gca,'FontSize',16);
                        if c==length(codeList)
                            set(gca,'YTick',[]);
                            xlabel('Time (s)');
                        else
                            set(gca,'XTick',[],'YTick',[]);
                        end
                    end
                end
                currIdx = currIdx + length(currIdx);

                saveas(gcf,[outDir filesep 'popRaster_page' num2str(pageIdx) '_set_' num2str(setIdx) '_' alignNames{alignIdx} '.png'],'png');
            end
        end
    end
    
    %%
    %correlation matrix
    for setIdx = 1:length(codeSets)
        if ~isempty(mPCA_out{setIdx})
            hasNan = zeros(size(mPCA_out{setIdx}.featureVals,4),1);
            for t=1:size(mPCA_out{setIdx}.featureVals,4)
                tmp = mPCA_out{setIdx}.featureVals(:,:,:,t);
                hasNan(t) = any(isnan(tmp(:)));
            end
            
            useVals = mPCA_out{setIdx}.featureVals(:,:,:,~hasNan);
            useLabels = movLabelSets{setIdx};
            useAvg = mPCA_out{setIdx}.featureAverages(:,:,1:50);
            
            effSets = [];
            boxSets = [];
            
            if setIdx==2 && size(useVals,2)>4
                penOffPage = (29:36);
                useVals(:,penOffPage,:,:) = [];
                useLabels(penOffPage) = [];
                useAvg(:,penOffPage,:) = [];
                
                boxSets = {1:8, 9:12, 13:20, 21:28, 37:40};
            elseif setIdx==6
                useLabels = betterBezierLabels;
                boxSets = {1:6, 7:12, 13:18, 19:24, 25:40};
            elseif setIdx==8
                boxSets = {1:24, 25:40, 41:48,49:56};                
            end
            
            distMatrix = plotDistMat_cv( useVals  , [1,50],useLabels);
            saveas(gcf,[outDir filesep 'simMatrixDist_' num2str(setIdx) '.png'],'png');
            
            simMatrix = plotCorrMat_cv( useVals  , [1,50], useLabels, effSets, boxSets );
            title('Vector Correlation');
            saveas(gcf,[outDir filesep 'simMatrix_' num2str(setIdx) '.png'],'png');
            
            X = squeeze(mean(useAvg,3))';
            D = pdist(X,'correlation');
            Z = linkage(D);
            T = cluster(Z,'maxclust',8);
            
            orderIdx = [];
            for cIdx = 1:8
                orderIdx = [orderIdx; find(T==cIdx)];
            end
            
            simMatrix = plotCorrMat_cv( useVals(:,orderIdx,:,:)  , [1,50], useLabels(orderIdx) );
            title('Vector Correlation');
            saveas(gcf,[outDir filesep 'simMatrixOrder_' num2str(setIdx) '.png'],'png');
            saveas(gcf,[outDir filesep 'simMatrixOrder_' num2str(setIdx) '.fig'],'fig');
            
            %two way classifiers
            useSet = codeSets{setIdx};
            if setIdx==2
                useSet(penOffPage) = [];
            end
            trlIdx = find(ismember(trlCodes, useSet));

            mc = trlCodes(trlIdx)';
            mcList = unique(mc);
            accMat = zeros(length(mcList));
            nTrials = zeros(length(mcList));
            
            for x1=1:length(mcList)
                disp(x1);
                for x2=1:length(mcList)
                    subTrlIdx = trlIdx(ismember(trlCodes(trlIdx), mcList([x1 x2])));
                    [~,~,mc_oneStart] = unique(trlCodes(subTrlIdx)');
                    [ C, L ] = simpleClassify( alignDat.zScoreSpikes_blockMean, mc_oneStart, alignDat.eventIdx(subTrlIdx)-50, movLabelSets{pIdx}, 50, 1, 1, false );
                    accMat(x1, x2) = 1-L;
                    nTrials(x1, x2) = length(subTrlIdx)/2;
                end
            end
            
            for x1=1:length(mcList)
                for x2=1:length(mcList)
                    accMat(x1,x2) = accMat(x2,x1);
                end
            end

            if setIdx==2 || setIdx==7 || setIdx==8 || setIdx==9 || setIdx==5 || setIdx==4
                orderIdx = 1:length(accMat);
            end
            
            if setIdx==1
                figPos = [212   613   667   478];
            else
                figPos = [212   524   808   567];
            end
            
            figure('Position',figPos);
            hold on;
            imagesc(accMat(orderIdx, orderIdx),[0.5 1.0]);
            colormap(flipud(cool));
            set(gca,'XTick',(1:length(useLabels(orderIdx)))-0.25,'XTickLabel',useLabels(orderIdx),'XTickLabelRotation',45);
            set(gca,'YTick',1:length(useLabels(orderIdx)),'YTickLabel',useLabels(orderIdx));
            set(gca,'FontSize',16);
            set(gca,'LineWidth',2);
            colorbar;
            axis tight;
            title('Two-Way Classifier Accuracy');
            
            orderedMat = accMat(orderIdx, orderIdx);
            orderedTrials = nTrials(orderIdx, orderIdx);
            for x1=1:length(orderedMat)
                for x2=1:length(orderedMat)
                    [~, pci] = binofit(round(orderedMat(x1, x2)*orderedTrials(x1, x2)), round(orderedTrials(x1, x2)), 0.05);
                    if pci(1)<=0.5
                        plot(x1, x2, 'kx','MarkerSize',14);
                    end
                end
            end
            
            boxColors = [173,150,61;
            119,122,205;
            91,169,101;
            197,90,159;
            202,94,74]/255;

            currentIdx = 0;
            currentColor = 1;
            if ~isempty(boxSets)
                for c=1:length(boxSets)
                    newIdx = currentIdx + (1:length(boxSets{c}))';
                    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',boxColors(currentColor,:));
                    currentIdx = currentIdx + length(boxSets{c});
                    currentColor = currentColor + 1;
                end
            else
                for x1=1:length(orderedMat)
                    plot(get(gca,'XLim'),[x1 x1]-0.5,'k');
                    plot([x1 x1]-0.5, get(gca,'YLim'),'k');
                end
            end

            saveas(gcf,[outDir filesep 'twoWayClass_order_' num2str(setIdx) '.png'],'png');
            saveas(gcf,[outDir filesep 'twoWayClass_order_' num2str(setIdx) '.fig'],'fig');
        end
    end
    
    %%
    %classifier
    for pIdx=1:length(codeSets) 
        trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
        if isempty(trlIdx)
            continue
        end

        mc = trlCodes(trlIdx)';
        [~,~,mc_oneStart] = unique(mc);
        [ C, L ] = simpleClassify( smoothSpikes_blockMean, mc_oneStart, alignDat.eventIdx(trlIdx)-50, movLabelSets{pIdx}, 50, 1, 1 );
    
        saveas(gcf,[outDir filesep 'prepClassifier_' num2str(pIdx) '.png'],'png');
    end
    
    %%
    %recreate correlation matirx with curl + launch model
    launchDir = zeros(length(uniqueCodes_noNothing),2);
    curlDir = zeros(length(uniqueCodes_noNothing),1);
    oscillatorDir = zeros(length(uniqueCodes_noNothing),2);
    
    if strcmp(sessionName,'t5.2019.05.06')
        curveIdx = 1:24;
        curveRotDir = [1 1 1 2 2 2, ...
            1 1 1 2 2 2, ...
            1 1 1 2 2 2, ...
            1 1 1 2 2 2];    
        
        straightIdx = 25:40;
        straightTheta = linspace(0,2*pi,17);
        straightTheta = straightTheta(1:16);
        
        oscillatorDirY = [1 1 1 -1 -1 -1, ...
            0 0 0 0 0 0, ...
            -1 -1 -1 1 1 1, ...
            0 0 0 0 0 0];  
        
        oscillatorDirX = [0 0 0 0 0 0, ...
                1 1 1 -1 -1 -1, ...
                0 0 0 0 0 0, ...
                -1 -1 -1 1 1 1]; 
        setIdx = 6;
        boxSets = {1:6, 7:12, 13:18, 19:24, 25:40};
    elseif strcmp(sessionName,'t5.2019.06.24')
        curveIdx = 1:40;
        curveRotDir = [1 1 1 1 1, ...
            2 2 2 2 2, ...
            1 1 1 1 1, ...
            2 2 2 2 2, ...
            1 1 1 1 1, ...
            2 2 2 2 2, ...
            1 1 1 1 1, ...
            2 2 2 2 2]; 
        
        straightIdx = 41:56;
        straightTheta = linspace(0,2*pi,17);
        straightTheta = straightTheta(1:16);
        
        oscillatorDirY = [1,1,1,1,1, ...
            -1,-1,-1,-1,-1, ...
            0, 0, 0, 0, 0, ...
            0, 0, 0, 0, 0, ...
            -1,-1,-1,-1,-1,...
            1,1,1,1,1,...
            0, 0, 0, 0, 0,...
            0, 0, 0, 0, 0];  
        oscillatorDirX = [0,0,0,0,0,...
            0,0,0,0,0,...
            1,1,1,1,1,...
            -1,-1,-1,-1,-1,...
            0,0,0,0,0,...
            0,0,0,0,0,...
            -1,-1,-1,-1,-1,...
            1,1,1,1,1];

        setIdx = 10;
        boxSets = {};
    end
    
    curlDir(curveIdx(curveRotDir==1)) = 1;
    curlDir(curveIdx(curveRotDir==2)) = -1;
    
    oscillatorDir(curveIdx,:) = [oscillatorDirX', oscillatorDirY'];
    
    for x=1:length(uniqueCodes_noNothing)
        codeIdx = find(allTemplateCodes==uniqueCodes_noNothing(x));
        template = allTemplates{codeIdx};
        launchVel = mean(template(30:40,1:2));
        launchDir(x,:) = launchVel/norm(launchVel);
    end
    launchTheta = atan2(launchDir(:,2), launchDir(:,1));
    
    prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
    [COEFF, straightManifold, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(straightIdx,:));
    launchDir3d = interp1([straightTheta'; 2*pi]-pi, [straightManifold(:,1:3); straightManifold(1,1:3)], launchTheta);
    
    %coef = buildLinFilts(prepVec, [ones(size(prepVec,1),1), launchDir3d, curlDir], 'standard');
    %modelAct  = [ones(size(prepVec,1),1), launchDir3d, curlDir]*coef;
    
    coef = buildLinFilts(prepVec, [ones(size(prepVec,1),1), launchDir, curlDir], 'standard');
    modelAct  = [ones(size(prepVec,1),1), launchDir, curlDir]*coef;
  
    %coef = buildLinFilts(prepVec, [ones(size(prepVec,1),1), launchDir3d, oscillatorDir], 'standard');
    %modelAct  = [ones(size(prepVec,1),1), launchDir3d, oscillatorDir]*coef;
  
    %coef = buildLinFilts(prepVec, [ones(size(prepVec,1),1), launchDir3d], 'standard');
    %modelAct  = [ones(size(prepVec,1),1), launchDir3d]*coef;
    
    fullMat = zeros(size(modelAct,2), size(modelAct,1), 1, 20);
    for x=1:20
        fullMat(:,:,1,x) = modelAct';
    end
    
    effSets = [];
    
    simMatrix = plotCorrMat_cv( fullMat  , [1,1], movLabelSets{setIdx}, effSets, boxSets );
    set(gcf,'Position',[234   453   681   537]);
    saveas(gcf,[outDir filesep 'curlModelDir.png'],'png');
    
    R2 = getDecoderPerformance(modelAct(:), prepVec(:), 'R2');
    disp(R2);
    
    %%
    %bezier set 5
    if strcmp(sessionName,'t5.2019.06.24')
        setIdx = 10;
        prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
        
        %%
        %get radial subspace
        straightIdx = 41:56;
        curveIdx = setdiff(1:56, straightIdx);
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(straightIdx,:));
        SCORE = (prepVec-MU)*COEFF;
        
        %get non-radial subspace
        [COEFF, SCORE_nonRadial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec - SCORE(:,1:3)*COEFF(:,1:3)');
        SCORE_nonRadial_forStraight = (prepVec(straightIdx,:)-MU)*COEFF;
        
        %get full space
        [COEFF, SCORE_full, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);
        
        %%
        %get launch dir for each template
        theta = linspace(0,2*pi,17);
        theta = theta(1:16);
        possibleDir = [cos(theta)', sin(theta)'];
        
        launchDir = zeros(length(uniqueCodes_noNothing),2);
        curveLaunchDir = zeros(length(uniqueCodes_noNothing),1);
        for x=1:length(uniqueCodes_noNothing)
            codeIdx = find(allTemplateCodes==uniqueCodes_noNothing(x));
            template = allTemplates{codeIdx};
            launchVel = mean(template(30:40,1:2));
            
            launchDir(x,:) = launchVel/norm(launchVel);
            
            [~,closestIdx] = min(matVecMag(possibleDir-launchDir(x,:),2));
            curveLaunchDir(x) = closestIdx;
        end
        
        figure
        hold on
        colors = hsv(16)*0.8;
        rdIdx = curveIdx;
        mSizes = [8, 14 ,22];
        for c=1:length(rdIdx)
           colorIdx = curveLaunchDir(rdIdx(c));
           plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s',...
               'MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
           text(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),movLabelSets{setIdx}{rdIdx(c)},'FontSize',16);
        end
        
        colors = hsv(16)*0.8;
        rdIdx = straightIdx;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        ringIdx = [straightIdx, straightIdx(1)];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        
        saveas(gcf,[outDir filesep 'launchAnglePrepState.fig'],'fig');
        
        %%
        rdIdx = curveIdx;
        colors = hsv(2)*0.8;
        colors = [colors; 0.7 0.7 0.7];
                
        curveRotDir = [1 1 1 1 1, ...
            2 2 2 2 2, ...
            1 1 1 1 1, ...
            2 2 2 2 2, ...
            1 1 1 1 1, ...
            2 2 2 2 2, ...
            1 1 1 1 1, ...
            2 2 2 2 2];
        
        figure
        hold on
        for c=1:length(rdIdx)
            colorIdx = curveRotDir(c);
            plot3(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',18);
            text(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),movLabelSets{setIdx}{rdIdx(c)},'FontSize',16);
        end
        %colors = hsv(16)*0.8;
        %for c=1:16
        %    plot3(SCORE_nonRadial_forStraight(rdIdx(c),1), SCORE_nonRadial_forStraight(rdIdx(c),2), ...
        %        SCORE_nonRadial_forStraight(rdIdx(c),3),'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        %end
        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'curlPrepState.fig'],'fig');
    end
    
    %%
    %bezier set 4
    if strcmp(sessionName,'t5.2019.06.19')
        setIdx = 9;
        prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
        
        %%
        %get radial subspace
        straightIdx = 33:48;
        curveIdx = setdiff(1:48, straightIdx);
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(straightIdx,:));
        SCORE = (prepVec-MU)*COEFF;
        
        %get non-radial subspace
        [COEFF, SCORE_nonRadial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec - SCORE(:,1:3)*COEFF(:,1:3)');
        SCORE_nonRadial_forStraight = (prepVec(straightIdx,:)-MU)*COEFF;
        
        %%
        %get launch dir for each template
        theta = linspace(0,2*pi,17);
        theta = theta(1:16);
        possibleDir = [cos(theta)', sin(theta)'];
        
        launchDir = zeros(length(uniqueCodes_noNothing),2);
        curveLaunchDir = zeros(length(uniqueCodes_noNothing),1);
        for x=1:length(uniqueCodes_noNothing)
            codeIdx = find(allTemplateCodes==uniqueCodes_noNothing(x));
            template = allTemplates{codeIdx};
            launchVel = mean(template(30:40,1:2));
            
            launchDir(x,:) = launchVel/norm(launchVel);
            
            [~,closestIdx] = min(matVecMag(possibleDir-launchDir(x,:),2));
            curveLaunchDir(x) = closestIdx;
        end
        
        figure
        hold on
        colors = hsv(16)*0.8;
        rdIdx = curveIdx;
        mSizes = [8, 14 ,22];
        for c=1:length(rdIdx)
           colorIdx = curveLaunchDir(rdIdx(c));
           plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s',...
               'MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
           text(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),movLabelSets{setIdx}{rdIdx(c)},'FontSize',16);
        end
        
        colors = hsv(16)*0.8;
        rdIdx = straightIdx;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        ringIdx = [straightIdx, straightIdx(1)];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        
        saveas(gcf,[outDir filesep 'launchAnglePrepState.fig'],'fig');
        
        %%
        rdIdx = curveIdx;
        colors = hsv(2)*0.8;

        curveRotDir = [1 2 2 1, ...
            1 2 2 1, ...
            1 2 2 1, ...
            1 2 2 1, ...
            1 2 2 1, ...
            1 2 2 1, ...
            1 2 2 1, ...
            1 2 2 1];
        
        figure
        hold on
        for c=1:length(rdIdx)
            colorIdx = curveRotDir(c);
            plot3(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',18);
            text(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),movLabelSets{setIdx}{rdIdx(c)},'FontSize',16);
        end
        %colors = hsv(16)*0.8;
        %for c=1:16
        %    plot3(SCORE_nonRadial_forStraight(rdIdx(c),1), SCORE_nonRadial_forStraight(rdIdx(c),2), ...
        %        SCORE_nonRadial_forStraight(rdIdx(c),3),'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        %end
        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'curlPrepState.fig'],'fig');
    end

    %%
    %bezier set 3
    if strcmp(sessionName,'t5.2019.06.17')
        setIdx = 8;
        prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
        
        %%
        %get radial subspace
        straightIdx = 25:40;
        curveIdx = setdiff(1:56, straightIdx);
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(straightIdx,:));
        SCORE = (prepVec-MU)*COEFF;
        
        %get non-radial subspace
        [COEFF, SCORE_nonRadial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec - SCORE(:,1:3)*COEFF(:,1:3)');
        SCORE_nonRadial_forStraight = (prepVec(straightIdx,:)-MU)*COEFF;
        
        %%
        %get launch dir for each template
        theta = linspace(0,2*pi,17);
        theta = theta(1:16);
        possibleDir = [cos(theta)', sin(theta)'];
        
        launchDir = zeros(length(uniqueCodes_noNothing),2);
        curveLaunchDir = zeros(length(uniqueCodes_noNothing),1);
        for x=1:length(uniqueCodes_noNothing)
            codeIdx = find(allTemplateCodes==uniqueCodes_noNothing(x));
            template = allTemplates{codeIdx};
            launchVel = mean(template(30:40,1:2));
            
            launchDir(x,:) = launchVel/norm(launchVel);
            
            [~,closestIdx] = min(matVecMag(possibleDir-launchDir(x,:),2));
            curveLaunchDir(x) = closestIdx;
        end
        
        figure
        hold on
        colors = hsv(16)*0.8;
        rdIdx = curveIdx;
        mSizes = [8, 14 ,22];
        for c=1:length(rdIdx)
           colorIdx = curveLaunchDir(rdIdx(c));
           plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s',...
               'MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
           text(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),movLabelSets{8}{rdIdx(c)},'FontSize',16);
        end
        
        colors = hsv(16)*0.8;
        rdIdx = straightIdx;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        ringIdx = [straightIdx, straightIdx(1)];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        
        saveas(gcf,[outDir filesep 'launchAnglePrepState.fig'],'fig');
        
        %%
        rdIdx = curveIdx;
        colors = hsv(2)*0.8;
        colors = [colors; 0.7 0.7 0.7];
        
        curveRotDir = [1 1 1 2 2 2, ...
           1 1 1 2 2 2, ...
           1 1 1 2 2 2, ...
           1 1 1 2 2 2, ...
           1 2 1 2 1 2 1 2, ...
           1 2 1 2 1 2 1 2];     
%         curveRotDir = [1 1 1 2 2 2, ...
%             1 1 1 2 2 2, ...
%             1 1 1 2 2 2, ...
%             1 1 1 2 2 2, ...
%             3 3 3 3 3 3 3 3, ...
%             3 3 3 3 3 3 3 3]; 
        
        figure
        hold on
        for c=1:length(rdIdx)
            colorIdx = curveRotDir(c);
            plot3(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',18);
            text(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),movLabelSets{8}{rdIdx(c)},'FontSize',16);
        end
        %colors = hsv(16)*0.8;
        %for c=1:16
        %    plot3(SCORE_nonRadial_forStraight(rdIdx(c),1), SCORE_nonRadial_forStraight(rdIdx(c),2), ...
        %        SCORE_nonRadial_forStraight(rdIdx(c),3),'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        %end
        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'curlPrepState.fig'],'fig');
    end
    
    %%
    %bezier set 2
    if strcmp(sessionName,'t5.2019.05.31')
        setIdx = 7;
        prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
        
        %%
        %get radial subspace
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(41:end,:));
        SCORE = (prepVec-MU)*COEFF;
        
        %get non-radial subspace
        [COEFF, SCORE_nonRadial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(1:40,:) - SCORE(1:40,1:3)*COEFF(:,1:3)');
        SCORE_nonRadial_forStraight = (prepVec(41:end,:)-MU)*COEFF;
        
        %%
        %get launch dir for each template
        theta = linspace(0,2*pi,17);
        theta = theta(1:16);
        possibleDir = [cos(theta)', sin(theta)'];
        
        launchDir = zeros(length(uniqueCodes_noNothing),2);
        curveLaunchDir = zeros(length(uniqueCodes_noNothing),1);
        curveSize = zeros(size(curveLaunchDir));
        for x=1:length(uniqueCodes_noNothing)
            codeIdx = find(allTemplateCodes==uniqueCodes_noNothing(x));
            template = allTemplates{codeIdx};
            launchVel = mean(template(30:40,1:2));
            
            launchDir(x,:) = launchVel/norm(launchVel);
            
            [~,closestIdx] = min(matVecMag(possibleDir-launchDir(x,:),2));
            curveLaunchDir(x) = closestIdx;
        end
        
        curveSize(1:10) = [1 2 3 1 3 1 2 3 1 3];
        curveSize(11:20) = [1 2 3 1 3 1 2 3 1 3];
        curveSize(21:30) = [1 2 3 1 3 1 2 3 1 3];
        curveSize(31:40) = [1 2 3 1 3 1 2 3 1 3];
        
        figure
        hold on
        colors = hsv(16)*0.8;
        rdIdx = 1:40;
        mSizes = [8, 14 ,22];
        for c=1:length(rdIdx)
           colorIdx = curveLaunchDir(c);
           plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s',...
               'MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',mSizes(curveSize(c)));
           text(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),bezierLabels2{rdIdx(c)},'FontSize',16);
        end
        
        colors = hsv(16)*0.8;
        rdIdx = 41:56;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        ringIdx = [41:56, 41];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        
        saveas(gcf,[outDir filesep 'launchAnglePrepState.fig'],'fig');
        
        %%
        rdIdx = 1:40;
        colors = hsv(2)*0.8;
        curveRotDir = [1 1 1 1 1 2 2 2 2 2, ...
            1 1 1 1 1 2 2 2 2 2, ...
            1 1 1 1 1 2 2 2 2 2, ...
            1 1 1 1 1 2 2 2 2 2];         
        figure
        hold on
        for c=1:length(rdIdx)
            colorIdx = curveRotDir(c);
            plot3(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
            text(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),bezierLabels2{rdIdx(c)},'FontSize',16);
        end
        %colors = hsv(16)*0.8;
        %for c=1:16
        %    plot3(SCORE_nonRadial_forStraight(rdIdx(c),1), SCORE_nonRadial_forStraight(rdIdx(c),2), ...
        %        SCORE_nonRadial_forStraight(rdIdx(c),3),'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        %end
        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'curlPrepState.fig'],'fig');
        
        rdIdx = 1:40;
        colors = hsv(3)*0.8;
        curveRotDir = [1 2 3 1 3 1 2 3 1 3, ...
           1 2 3 1 3 1 2 3 1 3, ...
           1 2 3 1 3 1 2 3 1 3, ...
           1 2 3 1 3 1 2 3 1 3];  
       
        figure
        hold on
        for c=1:length(rdIdx)
            colorIdx = curveRotDir(c);
            plot3(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
            text(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),bezierLabels{rdIdx(c)},'FontSize',16);
        end
        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'curveMagPrepState.fig'],'fig');
    end
    
    %%    
    if strcmp(sessionName,'t5.2019.04.24')
        %%
        %compute curvature
        movIdx = 1;
        
        acc = [0 0; diff(allTemplates{movIdx}(:,1:2))*100];
        dir = allTemplates{movIdx}(:,1:2)./matVecMag(allTemplates{movIdx}(:,1:2),2);
        dT = matVecMag(diff(dir)*100,2);
        dS = matVecMag(allTemplates{movIdx}(:,1:2),2);
        
        figure
        plot(cumsum(allTemplates{movIdx}(:,1)), cumsum(allTemplates{movIdx}(:,2)));
        axis equal;
        
        figure
        hold on
        plot(cumsum(allTemplates{movIdx}(:,1)));
        plot(cumsum(allTemplates{movIdx}(:,2)));
        
        C = (allTemplates{movIdx}(:,1).*acc(:,2)-allTemplates{movIdx}(:,2).*acc(:,1)) ./ ...
            dS.^3;
        
        figure;
        plot(C);
        
        %%
        prepVec = zeros(length(uniqueCodes_noNothing), size(smoothSpikes_blockMean,2));
        launcDir = zeros(length(uniqueCodes_noNothing), 2);
        curlDir = zeros(length(uniqueCodes_noNothing), 1);
        
        for t=1:length(uniqueCodes_noNothing)
            trlIdx = find(trlCodes==uniqueCodes_noNothing(t));
            cDat = triggeredAvg( smoothSpikes_blockMean, alignDat.eventIdx(trlIdx), [-50,0] );
            prepVec(t,:) = squeeze(mean(mean(cDat,1),2));
        end
        
        letterLaunchDir = [3 7 5 4 7 7, ...
            5 1 5 3 7 7, ...
            7 7 7 7 7 3, ...
            7 5 7 8 8 8, ...
            8 1 1 8];
        curveLaunchDir = [1 2 3 4 5 6 7 8, ...
            1 3 5 7, ...
            1 1 3 3 5 5 7 7, ...
            2 8 4 2 4 6 6 8, ...
            1 5 3 7, ...
            7 3 5 1, ...
            1 1 3 3];
        allLaunchDir = [letterLaunchDir, curveLaunchDir];
        
        letterCurlDir = [-1,0,-1,-1,-1,0,...
            -1,-1,-1,-1,0,0,...
            1,0,0,0,0,-1,...
            0,-1,-1,0,0,0,...
            0,0,0,0];
        curveCurlDir = [0,0,0,0,0,0,0,0,...
            0,0,0,0,...
            1,-1,-1,1,-1,1,-1,1,...
            1,-1,1,-1,-1,1,-1,1,...
            0,0,0,0,...
            0,0,0,0,...
            0,0,0,0];
        allCurlDir = [letterCurlDir, curveCurlDir];
        allCurlDir_cIdx = allCurlDir;
        allCurlDir_cIdx(allCurlDir==-1)=1;
        allCurlDir_cIdx(allCurlDir==0)=2;
        allCurlDir_cIdx(allCurlDir==1)=3;
        curlColors = [0.8 0 0; 0.7 0.7 0.7; 0 0 0.8];
        
        mlAll = [movLabelSets{1}, movLabelSets{2}];
        
        penOffPage = 28+(29:36);
        prepVec(penOffPage,:) = [];
        allLaunchDir(penOffPage) = [];
        allCurlDir_cIdx(penOffPage) = [];
        mlAll(penOffPage) = [];
        
        curlCon = find(ismember(allCurlDir_cIdx,[1 3]));
        
        %%
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);
        
        %get radial subspace
        [COEFF, SCORE_radial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(29:36,:));
        SCORE_radial = (prepVec-MU)*COEFF;
        
        %get non-radial subspace
        %[COEFF, SCORE_nonRadial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec - SCORE_radial(:,1:3)*COEFF(:,1:3)');
        [COEFF, SCORE_nonRadial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(curlCon,:) - SCORE_radial(curlCon,1:3)*COEFF(:,1:3)');
        SCORE_nonRadial = (prepVec-MU)*COEFF;
        
        figure
        hold on

        colors = hsv(8)*0.8;
        for c=1:size(SCORE,1)
            cIdx = allLaunchDir(c);
            %plot3(SCORE(c,1), SCORE(c,2), SCORE(c,3), 'o','MarkerFaceColor',colors(cIdx,:),'Color',colors(cIdx,:),'MarkerSize',14);
            text(SCORE(c,1), SCORE(c,2), SCORE(c,3),mlAll{c},'Color',colors(cIdx,:),'FontWeight','bold','FontSize',14);
        end
        
        ringIdx = [29:36, 29];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'launchAnglePrepState.fig'],'fig');
        
        %%
        figure
        hold on

        colors = curlColors;
        for c=1:size(SCORE_nonRadial,1)
            cIdx = allCurlDir_cIdx(c);
            text(SCORE_nonRadial(c,1), SCORE_nonRadial(c,2), SCORE_nonRadial(c,3),mlAll{c},'Color',colors(cIdx,:),'FontWeight','bold','FontSize',14);
        end
        
        %colors = hsv(8)*0.8;
        %ringIdx = [29:36, 29];
        %for c=1:(length(ringIdx)-1)
        %    plot3(SCORE_nonRadial(ringIdx(c:(c+1)),1), SCORE_nonRadial(ringIdx(c:(c+1)),2), SCORE_nonRadial(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        %end
        axis equal;
        xlim([-1,1]);
        ylim([-1,1]);
        zlim([-1,1]);
        saveas(gcf,[outDir filesep 'curlPrepState.fig'],'fig');
        
        %%
        setIdx = 2;
        prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

        SCORE = SCORE(:,1:3);
        
        figure
        hold on

        colors = hsv(8)*0.8;
        rdIdx = 13:28;
        curveLaunchDir = [1 1 3 3 5 5 7 7, ...
            2 8 4 2 4 6 6 8];
        for c=1:length(rdIdx)
           colorIdx = curveLaunchDir(c);
           plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
        end

        colors = hsv(8)*0.8;
        rdIdx = 1:8;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        ringIdx = [1:8, 1];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;

        %decode curvature from prep?
        curveLabels = zeros(40,1);
        curveLabels(13:20) = [1, -1, -1, 1, -1, 1, -1, 1];
        curveLabels(21:28) = [1, -1, -1, 1, -1, 1, -1, 1];

        allY = [];
        loopIdx = [];
        allConIdx = [];
        for t=1:length(trlCodes)
            conIdx = find(trlCodes(t)==codeSets{2});
            if isempty(conIdx)
                continue;
            end
            
            if ismember(conIdx,1:8)
                allY = [allY; zeros(100,1)];
                loopIdx = [loopIdx, (alignDat.eventIdx(t)-49):(alignDat.eventIdx(t)+50)];
                allConIdx = [allConIdx, repmat(conIdx,1,100)]; 
            else
                allY = [allY; repmat(curveLabels(conIdx,:),50,1)];
                loopIdx = [loopIdx, (alignDat.eventIdx(t)-49):(alignDat.eventIdx(t))];
                allConIdx = [allConIdx, repmat(conIdx,1,50)]; 
            end
        end
        neuralDat = alignDat.zScoreSpikes_blockMean(loopIdx,:);
        
        filts_curve = buildLinFilts(allY, [ones(size(neuralDat,1),1), neuralDat], 'standard');
        predVals = [ones(size(neuralDat,1),1), neuralDat] * filts_curve;

        mnVals = zeros(40,1);
        for t=1:40
            tmpIdx = find(allConIdx==t);
            mnVals(t,:) = mean(predVals(tmpIdx,:));
        end
        
        %apply to letters
        loopIdx = [];
        allConIdx = [];
        for t=1:length(trlCodes)
            conIdx = find(trlCodes(t)==codeSets{1});
            if isempty(conIdx)
                continue;
            end
            loopIdx = [loopIdx, (alignDat.eventIdx(t)-49):(alignDat.eventIdx(t))];
            allConIdx = [allConIdx, repmat(conIdx,1,50)]; 
        end
        neuralDat = alignDat.zScoreSpikes_blockMean(loopIdx,:);
        predVals = [ones(size(neuralDat,1),1), neuralDat] * filts_curve;
        
        mnVals = zeros(28,1);
        for t=1:28
            tmpIdx = find(allConIdx==t);
            mnVals(t,:) = mean(predVals(tmpIdx,:));
        end
        
        figure
        plot(mnVals,'-o');
        set(gca,'XTick',1:28,'XTickLabels',movLabelSets{1});
    end
    
    %manifold subtraction
    if strcmp(sessionName,'t5.2019.05.06')
        setIdx = 6;
        prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
        
        %%
        %get radial subspace
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(25:end,:));
        SCORE = (prepVec-MU)*COEFF;
        
        %get non-radial subspace
        [COEFF, SCORE_nonRadial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(1:24,:) - SCORE(1:24,1:3)*COEFF(:,1:3)');
        SCORE_nonRadial_forStraight = (prepVec(25:end,:)-MU)*COEFF;
        
        %%
        figure
        hold on
        colors = hsv(16)*0.8;
        rdIdx = 1:24;
        curveLaunchDir = [2 3 4 16 15 14, ...
           6 7 8 4 3 2, ...
           9 10 11 8 7 6, ...
           13 14 15 11 10 9];
        curveSize = [1 2 3 1 2 3, ...
           1 2 3 1 2 3, ...
           1 2 3 1 2 3, ...
           1 2 3 1 2 3];  
        mSizes = [8, 14 ,22];
        for c=1:length(rdIdx)
           colorIdx = curveLaunchDir(c);
           plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s',...
               'MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',mSizes(curveSize(c)));
           text(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),betterBezierLabels{rdIdx(c)},'FontSize',16);
        end
        
        colors = hsv(16)*0.8;
        rdIdx = 25:40;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        ringIdx = [25:40, 25];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        
        saveas(gcf,[outDir filesep 'launchAnglePrepState.fig'],'fig');
        
        %%
        rdIdx = 1:24;
        colors = hsv(2)*0.8;
        curveRotDir = [1 1 1 2 2 2, ...
            1 1 1 2 2 2, ...
            1 1 1 2 2 2, ...
            1 1 1 2 2 2];         
        figure
        hold on
        for c=1:length(rdIdx)
            colorIdx = curveRotDir(c);
            plot3(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
            text(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),bezierLabels{rdIdx(c)},'FontSize',16);
        end
        %colors = hsv(16)*0.8;
        %for c=1:16
        %    plot3(SCORE_nonRadial_forStraight(rdIdx(c),1), SCORE_nonRadial_forStraight(rdIdx(c),2), ...
        %        SCORE_nonRadial_forStraight(rdIdx(c),3),'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        %end
        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'curlPrepState.fig'],'fig');
        
        rdIdx = 1:24;
        colors = hsv(3)*0.8;
        curveRotDir = [1 2 3 1 2 3, ...
           1 2 3 1 2 3, ...
           1 2 3 1 2 3, ...
           1 2 3 1 2 3];  
       
        figure
        hold on
        for c=1:length(rdIdx)
            colorIdx = curveRotDir(c);
            plot3(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
            text(SCORE_nonRadial(rdIdx(c),1), SCORE_nonRadial(rdIdx(c),2), SCORE_nonRadial(rdIdx(c),3),bezierLabels{rdIdx(c)},'FontSize',16);
        end
        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'curveMagPrepState.fig'],'fig');
    end
    
    %prep geometry
    if strcmp(sessionName,'t5.2019.05.06')
        cGroups = {1:3, 4:6, 7:9, 10:12, 13:15, 16:18, 19:21, 22:24};
        launchDir = zeros(24,2);
        for x=1:24
            launchDir(x,:) = tempBezier.templates{x}(30,1:2)/norm(tempBezier.templates{x}(30,1:2));
        end

        figure; 
        for groupIdx=1:length(cGroups)
            subplot(3,3,groupIdx);
            hold on;
            for cIdx=1:3
                ld = launchDir(cGroups{groupIdx}(cIdx),:);
                theta = atan2(ld(2), ld(1));
                rotMat = [[cos(-theta), cos(-theta+pi/2)]; [sin(-theta), sin(-theta+pi/2)]];

                curve = tempBezier.templates{cGroups{groupIdx}(cIdx)}(:,1:2);
                curveRot = (rotMat*curve')';
                plot(curveRot(:,1), 'Color', [0.8 0 0], 'LineWidth', 2);
                plot(curveRot(:,2), 'Color', [0 0 0.8], 'LineWidth', 2);
            end
        end

        setIdx = 6;
        prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

        SCORE = SCORE(:,1:3);
        
        %color by launch angle
        figure
        hold on
        
        colors = hsv(16)*0.8;
        rdIdx = 1:24;
        curveLaunchDir = [2 3 4 16 15 14, ...
           6 7 8 4 3 2, ...
           9 10 11 8 7 6, ...
           13 14 15 11 10 9];
        for c=1:length(rdIdx)
           colorIdx = curveLaunchDir(c);
           plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
           text(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),betterBezierLabels{rdIdx(c)},'FontSize',16);
        end
                
        colors = hsv(16)*0.8;
        rdIdx = 25:40;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        ringIdx = [25:40, 25];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'rawPrepState_launch.fig'],'fig');
        
        %color by curl
        figure
        hold on
        
        rdIdx = 1:24;
        colors = hsv(2)*0.8;
        curveRotDir = [1 1 1 2 2 2, ...
            1 1 1 2 2 2, ...
            1 1 1 2 2 2, ...
            1 1 1 2 2 2];         
        for c=1:length(rdIdx)
           colorIdx = curveRotDir(c);
           plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
           text(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),bezierLabels{rdIdx(c)},'FontSize',16);
        end
                
        colors = hsv(16)*0.8;
        rdIdx = 25:40;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        ringIdx = [25:40, 25];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        saveas(gcf,[outDir filesep 'rawPrepState_curl.fig'],'fig');

        %decode curvature from prep?
        curveLabels = zeros(40,1);
        curveLabels(1:3,1) = 1:3;
        curveLabels(4:6,1) = -(1:3);
        curveLabels(7:9,1) = (1:3);
        curveLabels(10:12,1) = -(1:3);
        curveLabels(13:15,1) = (1:3);
        curveLabels(16:18,1) = -(1:3);
        curveLabels(19:21,1) = (1:3);
        curveLabels(22:24,1) = -(1:3);

        allY = [];
        loopIdx = [];
        allConIdx = [];
        weights = [];
        for t=1:length(trlCodes)
            conIdx = find(trlCodes(t)==uniqueCodes_noNothing);            
            if ismember(conIdx,25:40)
                allY = [allY; zeros(150,1)];
                loopIdx = [loopIdx, (alignDat.eventIdx(t)-49):(alignDat.eventIdx(t)+100)];
                allConIdx = [allConIdx, repmat(conIdx,1,150)]; 
                weights = [weights; ones(150,1)*3];
            else
                allY = [allY; repmat(curveLabels(conIdx,:),50,1)];
                loopIdx = [loopIdx, (alignDat.eventIdx(t)-49):(alignDat.eventIdx(t))];
                allConIdx = [allConIdx, repmat(conIdx,1,50)]; 
                weights = [weights; ones(50,1)];
            end
        end
        neuralDat = alignDat.zScoreSpikes_blockMean(loopIdx,:);

        filts_curve = buildLinFilts(allY, [ones(size(neuralDat,1),1), neuralDat], 'weight', [], weights );
        predVals = [ones(size(neuralDat,1),1), neuralDat] * filts_curve;

        mnVals = zeros(40,1);
        for t=1:40
            tmpIdx = find(allConIdx==t);
            mnVals(t,:) = mean(predVals(tmpIdx,:));
        end
    end
end %all sessions