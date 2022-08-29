%%
%todo: redo letters that start with circles
%single letter decoding
%word & sentence decoding

%%
sessionList = {'t5.2019.04.22',[6 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24],''; %alphabet & curves 1 (slow)
    't5.2019.04.24',[6 7 8 9 10 11 12 13 14 15 16 17 18 19 20],'';                    %alphabet & curves 2 (faster)
    't5.2019.04.29',[11 12 16 17 18 19 20 21 22],'';                                  %arm vs. head, letters of different speeds & sizes
    't5.2019.05.01',[4 6 8 10 13 15 19 21 22],'';                                     %many words
    't5.2019.05.06',[5 8 10 12 14 16 18],'_arm';                                      %bezier curves (arm)
    't5.2019.05.06',[4 6 9 11 13 15 17],'_head';                                      %bezier curves (head)
    't5.2019.05.08',[5 7 9 11 13 15 17 19 23],''};                                    %many sentences

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

    [uniqueCodes, ~, tcReorder] = unique(trlCodes);
    
    uniqueCodes_noNothing = uniqueCodes;
    uniqueCodes_noNothing(uniqueCodes_noNothing==218) = [];
    
    %%
    %define codes of interest and matching templates
    letterCodes = [400:406, 412:432];
    curveCodes = [486:525]; 
    wordCodes = [2256 2272 2282 2291];
    punctuationCodes = [580 581 582 583];
    bezierCodes = 540:579;
    prepArrowCodes = [526:537];
    speedSizeCodes = [439 441 445 447 448 450 454 456 457 459 463 464 465 467 471 473];
    
    letterLabels = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt'};
    curveLabels = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
        'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
        'cv37','cv38','cv39','cv40'};
    wordLabels = {'word1','word2','word3','word4'};
    punctuationLabels = {'comma','apos','tilde','question'};
    bezierLabels = {'right1a','right2a','right3a','right4a','right5a','right6a',...
        'up1a','up2a','up3a','up4a','up5a','up6a',...
        'left1a','left2a','left3a','left4a','left5a','left6a',...
        'down1a','down2a','down3a','down4a','down5a','down6a',...
        'rd1a','rd2a','rd3a','rd4a','rd5a','rd6a','rd7a','rd8a','rd9a','rd10a','rd11a','rd12a','rd13a','rd14a','rd15a','r1d6a'};
    speedSizeLabels = {'aSmallSlow','aBigSlow','aSmallFast','aBigFast',...
        'mSmallSlow','mBigSlow','mSmallFast','mBigFast',...
        'zSmallSlow','zBigSlow','zSmallFast','zBigFast',...
        'tSmallSlow','tBigSlow','tSmallFast','tBigFast'};
    prepArrowLabels = {'fastRight','fastRightDown','fastRightUp','fastRightUpLeft','fastRightUpRight','fastRightUpRightSlash', ...
        'slowRight','slowRightDown','slowRightUp','slowRightUpLeft','slowRightUpRight','slowRightUpRightSlash'};

    movLabelSets = {letterLabels, curveLabels, wordLabels, prepArrowLabels, speedSizeLabels, bezierLabels};
    codeSets = {letterCodes, curveCodes, wordCodes, prepArrowCodes, speedSizeCodes, bezierCodes};
    
    fullCodes = [letterCodes, curveCodes, wordCodes, punctuationCodes, bezierCodes, prepArrowCodes, speedSizeCodes];
    allLabels = [letterLabels, curveLabels, wordLabels, punctuationLabels, bezierLabels, prepArrowLabels, speedSizeLabels];
    
    tempAlphabetCurve = load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_sp.mat');
    tempPunctuation = load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_punctuation.mat');
    tempPrepArrow = load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_prepArrowSeries.mat');
    tempBezier = load('/Users/frankwillett/Data/Derived/Handwriting/BezierTemplates/templates.mat');
    tempAGQ = load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_fixedAGQ.mat');
    tempAlphabetCurve.templates([1 10 18]) = tempAGQ.templates;
    
    allTemplateCodes = [letterCodes, curveCodes, tempPunctuation.templateCodes, tempPrepArrow.templateCodes, bezierCodes, speedSizeCodes];
    
    %add zero Z to bezier templates
    for t=1:length(tempBezier.templates)
        tempBezier.templates{t} = [tempBezier.templates{t}, zeros(length(tempBezier.templates{t}),1)];
    end
    
    %fix template units
    for t=1:length(tempPunctuation.templates)
        tempPunctuation.templates{t} = tempPunctuation.templates{t}/1000;
    end
    for t=1:length(tempPrepArrow.templates)
        tempPrepArrow.templates{t} = tempPrepArrow.templates{t}/1000;
    end
    for t=1:length(tempBezier.templates)
        tempBezier.templates{t} = tempBezier.templates{t}/10;
    end

    %reorder punctuation template
    tempPunctuation.templates = tempPunctuation.templates([4 3 1 2]);
    
    speedSizeLetterIdx = [1 1 1 1 6 6 6 6 26 26 26 26 5 5 5 5];
    allTemplates = [tempAlphabetCurve.templates; tempPunctuation.templates; tempPrepArrow.templates; ...
        tempBezier.templates; tempAlphabetCurve.templates(speedSizeLetterIdx)];
    
    allTimeWindows = zeros(length(fullCodes),2);
    allTimeWindows(:,1) = -50;
    allTimeWindows(ismember(fullCodes, letterCodes),2) = 150; 
    allTimeWindows(ismember(fullCodes, curveCodes),2) = 150; 
    allTimeWindows(ismember(fullCodes, wordCodes),2) = 400; 
    allTimeWindows(ismember(fullCodes, punctuationCodes),2) = 150; 
    allTimeWindows(ismember(fullCodes, bezierCodes),2) = 150; 
    allTimeWindows(ismember(fullCodes, prepArrowCodes),2) = 250; 
    allTimeWindows(ismember(fullCodes, speedSizeCodes),2) = 250;
    
    %annotate curvature
    for t=1:length(allTemplates)
        allTemplates{t} = [allTemplates{t}, zeros(size(allTemplates{t},1),1)];
    end
    
    curveWindows = {'a',[1 50 -1; 66 81 -1];
        'b',[31 71 1];
        'c',[1 51 -1];
        'd',[1 41 -1];
        't',[11 26 -1];
        'm',[31 47 1; 61 81 1;];
        'o',[1 61 -1];
        'e',[11 66 -1];
        'f',[1 26 -1];
        'g',[1 41 -1; 66 86 1];
        'h',[36 56 1];
        'i',[];
        'j',[1 26 1];
        'k',[];
        'l',[];
        'n',[36 61 1];
        'p',[46 76 1]
        'q',[1 46 -1; 71 91 1];
        'r',[46 71 1];
        's',[1 31 -1; 31 56 1];
        'u',[1 31 -1];
        'v',[];
        'w',[];
        'x',[];
        'y',[];
        'z',[];
        'dash',[];
        'gt',[];
        'cv1',[];
        'cv2',[];
        'cv3',[];
        'cv4',[];
        'cv5',[];
        'cv6',[];
        'cv7',[];
        'cv8',[];
        'cv9',[];
        'cv10',[];
        'cv11',[];
        'cv12',[];
        'cv13',[1 41 1];
        'cv14',[1 41 -1];
        'cv15',[1 41 -1];
        'cv16',[1 41 1];
        'cv17',[1 41 -1];
        'cv18',[1 41 1];
        'cv19',[1 41 -1];
        'cv20',[1 41 1];
        'cv21',[1 36 1];
        'cv22',[1 36 -1];
        'cv23',[1 36 1];
        'cv24',[1 36 -1];
        'cv25',[1 36 -1];
        'cv26',[1 36 1];
        'cv27',[1 36 -1];
        'cv28',[1 36 1];
        'cv29',[];
        'cv30',[];
        'cv31',[];
        'cv32',[];
        'cv33',[];
        'cv34',[];
        'cv35',[];
        'cv36',[];
        'cv37',[26 46 1];
        'cv38',[26 46 -1];
        'cv39',[26 46 -1];
        'cv40',[26 46 1];
        'right1a',[1 70 1];
        'right2a',[1 70 1];
        'right3a',[1 70 1];
        'right4a',[1 70 -1];
        'right5a',[1 70 -1];
        'right6a',[1 70 -1];
        'up1a',[1 70 1];
        'up2a',[1 70 1];
        'up3a',[1 70 1];
        'up4a',[1 70 -1];
        'up5a',[1 70 -1];
        'up6a',[1 70 -1];
        'left1a',[1 70 1];
        'left2a',[1 70 1];
        'left3a',[1 70 1];
        'left4a',[1 70 -1];
        'left5a',[1 70 -1];
        'left6a',[1 70 -1];
        'down1a',[1 70 1];
        'down2a',[1 70 1];
        'down3a',[1 70 1];
        'down4a',[1 70 -1];
        'down5a',[1 70 -1];
        'down6a',[1 70 -1];
        'rd1a',[];
        'rd2a',[];
        'rd3a',[];
        'rd4a',[];
        'rd5a',[];
        'rd6a',[];
        'rd7a',[];
        'rd8a',[];
        'rd9a',[];
        'rd10a',[];
        'rd11a',[];
        'rd12a',[];
        'rd13a',[];
        'rd14a',[];
        'rd15a',[];
        'rd16a',[];
        };
    
    for t=1:length(fullCodes)
        tempIdx = find(allTemplateCodes==fullCodes(t));        
        curveIdx = find(strcmp(curveWindows(:,1),allLabels{t}));
        if isempty(tempIdx) || isempty(curveIdx)
            continue;
        end
        
        cWin = curveWindows{curveIdx,2};
        for x=1:size(cWin,1)
            loopIdx = cWin(x,1):cWin(x,2);
            allTemplates{tempIdx}(loopIdx,end) = cWin(x,3);
        end
    end
    
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
            if ismember(uniqueCodes_noNothing(t), wordCodes)
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
    %correlation matrix
    for setIdx = 1:length(codeSets)
        if ~isempty(mPCA_out{setIdx})
            hasNan = zeros(size(mPCA_out{setIdx}.featureVals,4),1);
            for t=1:size(mPCA_out{setIdx}.featureVals,4)
                tmp = mPCA_out{setIdx}.featureVals(:,:,:,t);
                hasNan(t) = any(isnan(tmp(:)));
            end
            
            useVals = mPCA_out{setIdx}.featureVals(:,:,:,~hasNan);
            
            simMatrix = plotDistMat_cv( useVals  , [1,50], movLabelSets{setIdx} );
            saveas(gcf,[outDir filesep 'simMatrixDist_' num2str(setIdx) '.png'],'png');
            
            simMatrix = plotCorrMat_cv( useVals  , [1,50], movLabelSets{setIdx} );
            saveas(gcf,[outDir filesep 'simMatrix_' num2str(setIdx) '.png'],'png');
            
            X = squeeze(mean(mPCA_out{setIdx}.featureAverages(:,:,1:50),3))';
            D = pdist(X,'correlation');
            Z = linkage(D);
            T = cluster(Z,'maxclust',8);
            
            orderIdx = [];
            for cIdx = 1:8
                orderIdx = [orderIdx; find(T==cIdx)];
            end
            
            simMatrix = plotCorrMat_cv( useVals(:,orderIdx,:,:)  , [1,50], movLabelSets{setIdx}(orderIdx) );
            saveas(gcf,[outDir filesep 'simMatrixOrder_' num2str(setIdx) '.png'],'png');
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
        [ C, L ] = simpleClassify( smoothSpikes_blockMean, mc_oneStart, alignDat.eventIdx(trlIdx), movLabelSets{pIdx}, 50, 1, 1 );
    
        saveas(gcf,[outDir filesep 'prepClassifier_' num2str(pIdx) '.png'],'png');
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

    %%
    %two-factor mpca on depth & direction if we have the conditions
    if all(ismember([curveCodes([1 3 5 7]), curveCodes(29:32)], uniqueCodes_noNothing))
        margGroupings = {{1, [1 3]}, {2, [2 3]}, {[1 2], [1 2 3]}, {3}};
        margNames = {'Direction','Depth','Int','Time'};
        opts_m.margNames = margNames;
        opts_m.margGroupings = margGroupings;
        opts_m.nCompsPerMarg = 5;
        opts_m.makePlots = true;
        opts_m.nFolds = 10;
        opts_m.readoutMode = 'singleTrial';
        opts_m.alignMode = 'rotation';
        opts_m.plotCI = true;
        opts_m.nResamples = 10;
        
        trlIdx = find(ismember(trlCodes, [curveCodes([1 3 5 7]), curveCodes([29 31 30 32])]));        
        mc = trlCodes(trlIdx)';
        [~,~,mc_oneStart] = unique(mc);
        
        factorList = [1 1 1;
            2 2 1;
            3 3 1;
            4 4 1;
            5 1 2;
            6 3 2;
            7 2 2;
            8 4 2];
        
        twoFactorCodes = zeros(length(mc_oneStart),2);
        for t=1:length(mc_oneStart)
            twoFactorCodes(t,:) = factorList(mc_oneStart(t),2:3);
        end

        mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_align, alignDat.eventIdx(trlIdx), ...
            twoFactorCodes, [-49, 200], binMS/1000, opts_m );
    end
    close all;

    %%
    %make initial straight line decoder
    makePlot = true;
    if all(ismember(curveCodes([1 3 5 7]), uniqueCodes_noNothing))
        availableCodes = find(ismember(curveCodes(1:8), uniqueCodes_noNothing));
        straightLineCodes = curveCodes(availableCodes);
        [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot );
    elseif all(ismember(bezierCodes, uniqueCodes_noNothing))
        straightLineCodes = bezierCodes(25:40);
        [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot );        
    else
        decVel = [];
        filts_prep = zeros(size(smoothSpikes_align,2)+1,2);
    end
    
    if all(ismember([curveCodes([1 3 5 7]), curveCodes(29:32)], uniqueCodes_noNothing))
        straightLineCodes_Z = [curveCodes(1:8), curveCodes(29:32)];
        otherCurveCodes = setdiff(curveCodes, straightLineCodes_Z);
        otherCurveCodes = [otherCurveCodes, letterCodes([1 2 3 4 6 7 8 10 11 15 16 17 18 19 20 22 23 26 27 28])];
        [ filts_mov_Z, filts_prep_Z, decVel_Z ] = makeDecoderOnStraightMovements_withZ( smoothSpikes_align, alignDat, trlCodes, ...
            straightLineCodes_Z, otherCurveCodes, makePlot );
    else
        decVel_Z = [];
    end
    
    %%
    %refine with a warped-template approach
    in.makePlot = true;
    in.initMode = 'warpToInitialDecode';
    in.allLabels = allLabels;
    in.uniqueCodes_noNothing = uniqueCodes_noNothing;
    in.fullCodes = fullCodes;
    in.alignDat = alignDat;
    in.smoothSpikes_align = smoothSpikes_align;
    in.curveCodes = curveCodes;
    in.wordCodes = wordCodes;
    in.velInit = decVel;
    in.trlCodes = trlCodes;
    in.sessionName = sessionName;
    in.templates = allTemplates;
    in.templateCodes = allTemplateCodes;
    in.timeWindows = [allTimeWindows(:,1)+1, allTimeWindows(:,2)-1];
    in.fixTemplateSize = false;
    
    if isempty(decVel)
        %if we don't have straight line movements we can use to make an
        %initial decoder, load warped templates from a previous day
        if strcmp(sessionName,'t5.2019.05.08')
            loadDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'allAlphabets' filesep 't5.2019.05.01'];
        end
        
        warpTemp = load([loadDir 'warpedTemplates.mat']);
        
        in_pre = in;
        in_pre.initMode = 'useLoadedWarps';
        in_pre.preWarpTemp = warpTemp.out.warpedTemplates;
        in_pre.preWarpCodes = [letterCodes, curveCodes(1:8), wordCodes(1:4)];
        out = makeTemplateDecoder( in_pre );
        
        in.velInit = out.decVel(:,1:2);
    end
        
    out = makeTemplateDecoder( in );
    close all;
    
    %iterate again for datasets that need it
    in.velInit = out.decVel(:,1:2);
    out = makeTemplateDecoder( in );
    
    save([outDir 'warpedTemplates.mat'],'out');
    close all;
    
    %%
    %letter trajectories
    letterIdxPage = [1 2 3 4 6 7 8 10 11 15 16 17 18 19 20 21 22 23 25 26 27 28];
    depthColors = jet(100);
    
    codeList = {[letterCodes, punctuationCodes], curveCodes, letterCodes(letterIdxPage), wordCodes, prepArrowCodes, speedSizeCodes, bezierCodes};
    movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','>',',','''','~','?'};
    movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
        'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
        'cv37','cv38','cv39','cv40'};
    movLabels3 = {'man','set','till','get'};
    movLabelSets = {movLabels1, movLabels2, movLabels1(letterIdxPage), movLabels3, prepArrowLabels, speedSizeLabels, bezierLabels};
    tw_use = {[-49, 150],[-49, 150], [-49, 150], [-49, 400], [-49, 250], [-49, 250], [-49, 150]};

    for setIdx=1:length(codeList)      
        manualLen = [99 91 70 104 110 132 84 98 125 110 104 79 92 127 68 90 113 104 74 86 86 83 110 103 115 100 ...
            82 77 116 71 110];
        i_up = [85, 150];
        question_down = [60,90]+60;
        comma_down = [50,77];
        %40-50 bins for full bottom->top
    
        timeStep = binMS/1000;
        timeAxis = (tw_use{setIdx}(1):tw_use{setIdx}(2))*timeStep;
        nDimToShow = 5;

        bias = [0,0,0,0];
            
        figure('Position',[680 218 1024 880]);
        for c=1:length(codeList{setIdx})
            if ~isempty(decVel_Z)
                concatDat = triggeredAvg( [out.cvVel(:,1:2), decVel_Z(:,3), out.cvVel(:,4)], alignDat.eventIdx(trlCodes==codeList{setIdx}(c)), tw_use{setIdx} );
            else
                concatDat = triggeredAvg( out.cvVel, alignDat.eventIdx(trlCodes==codeList{setIdx}(c)), tw_use{setIdx} );
            end
            
            if isempty(concatDat)
                continue;
            end
            lenIdx = find(in.uniqueCodes_noNothing==codeList{setIdx}(c));
            lenEnd = out.conLen(lenIdx)+50;
            %lenEnd = manualLen(lenIdx)+50;
            
            if setIdx==6
                lenEnd = 300;
            elseif setIdx==4
                lenEnd = 400+50;
            end
            
            if setIdx==7
                subtightplot(7,7,c);
            elseif setIdx==4
                subtightplot(2,2,c);
            elseif setIdx==2
                subtightplot(7,6,c);
            elseif setIdx==1
                subtightplot(6,6,c);
            else
                subtightplot(5,5,c);
            end
            hold on;

            mn = squeeze(mean(concatDat,1))+bias;
            mn = mn(61:lenEnd,:);
            traj = cumsum(mn);

            plot(traj(:,1),traj(:,2),'LineWidth',2);
            plot(traj(1,1),traj(1,2),'o');
            
            for t=1:10:size(traj,1)
                text(traj(t,1),traj(t,2),num2str(t));
            end
            
            for t=1:(size(traj,1)-1)
                colorIdx = round(size(depthColors,1)*(mn(t,4)*0.1+0.5));
                colorIdx(colorIdx>size(depthColors,1)) = size(depthColors,1);
                colorIdx(colorIdx<=0) = 1;
                plot([traj(t,1), traj(t+1,1)], [traj(t,2), traj(t+1,2)], 'Color', depthColors(colorIdx,:), 'LineWidth',2);
            end
            
            title(movLabelSets{setIdx}{c},'FontSize',20);
            axis off;
            axis equal;
        end
        
        saveas(gcf,[outDir filesep 'allTraj_page' num2str(setIdx) '.png'],'png');
    end
    
    close all;
    
    %%
    %special curve plotting
    allTraj = cell(length(uniqueCodes_noNothing),1);
    for t=1:length(uniqueCodes_noNothing)
        concatDat = triggeredAvg( out.cvVel, alignDat.eventIdx(trlCodes==uniqueCodes_noNothing(t)), [-49, 150] );
        if isempty(concatDat)
            continue;
        end
        lenEnd = out.conLen(t)+50;
        lenEnd = min(150, lenEnd);
        
        mn = squeeze(mean(concatDat,1));
        mn = mn(61:lenEnd,:);
        traj = cumsum(mn);
        
        allTraj{t} = traj;
    end
    
    %radial 8
    figure
    r8 = find(ismember(uniqueCodes_noNothing, curveCodes(1:8)));
    if ~isempty(r8)
        colors = hsv(8)*0.8;
        
        subplot(2,2,1);
        hold on;
        for t=1:length(r8)
            plot(allTraj{r8(t)}(:,1), allTraj{r8(t)}(:,2), 'LineWidth', 2, 'Color', colors(t,:));
        end
        axis equal;
        axis off;
    end
    
    %reverse
    rev = find(ismember(uniqueCodes_noNothing, curveCodes(9:12)));
    if ~isempty(rev)
        colors = hsv(4)*0.8;
        
        subplot(2,2,2);
        hold on;
        for t=1:length(rev)
            plot(allTraj{rev(t)}(:,1), allTraj{rev(t)}(:,2), 'LineWidth', 2, 'Color', colors(t,:));
        end
        axis equal;
        axis off;
    end
    
    %90-bend
    nineBend = find(ismember(uniqueCodes_noNothing, curveCodes(13:20)));
    if ~isempty(rev)
        tmp = hsv(4)*0.8;
        colors = [];
        for c=1:size(tmp,1)
            colors = [colors; repmat(tmp(c,:),2,1)];
        end
        
        subplot(2,2,3);
        hold on;
        for t=1:length(nineBend)
            plot(allTraj{nineBend(t)}(:,1), allTraj{nineBend(t)}(:,2), 'LineWidth', 2, 'Color', colors(t,:));
        end
        axis equal;
        axis off;
    end
    
    %bezier subset of curves
    bez = find(ismember(uniqueCodes_noNothing, curveCodes(21:28)));
    if ~isempty(rev)
        tmp = hsv(4)*0.8;
        colors = [];
        for c=1:size(tmp,1)
            colors = [colors; repmat(tmp(c,:),2,1)];
        end
        
        subplot(2,2,4);
        hold on;
        for t=1:length(bez)
            plot(allTraj{bez(t)}(:,1), allTraj{bez(t)}(:,2), 'LineWidth', 2, 'Color', colors(t,:));
        end
        axis equal;
        axis off;
    end
        
    saveas(gcf,[outDir filesep 'curveTrajSpecial.png'],'png');
    close all;
    
    %%
    %bezier day
    if strcmp(sessionName,'t5.2019.05.06')
        minorSets = {1:6, 7:12, 13:18, 19:24, 25:40};
        figure

        for minorIdx=1:length(minorSets)
            subtightplot(2,3,minorIdx);
            hold on;

            cs = minorSets{minorIdx};
            colors = hsv(length(cs))*0.8;

            for t=1:length(cs)
                plot(allTraj{cs(t)}(:,1), allTraj{cs(t)}(:,2),'-','Color',colors(t,:),'LineWidth',2);
                text(allTraj{cs(t)}(end,1), allTraj{cs(t)}(end,2), bezierLabels{cs(t)});
            end

            axis equal;
            axis off;
        end
        
        saveas(gcf,[outDir filesep 'bezierCurves.png'],'png');
    end
    
    close all;
    
    %%
    %load dynamical predictions
    dynPred = load(['/Users/frankwillett/Data/Derived/Handwriting/prepDynamics/linearPredictions_' sessionName sessionSuffix '.mat']);
    
    %%
    for x=1:length(mPCA_out)
        if ~isempty(mPCA_out{x})
            ciDim = mPCA_out{x}.readouts(:,6)*0.2;
            break;
        end
    end

    color = [1 0 0];
    nPerPage = 6;
    currIdx = 1:nPerPage;
    nPages = ceil(length(uniqueCodes_noNothing)/nPerPage);
    headings = {'X','Y','CIS'};
    dynTraj = cell(length(uniqueCodes_noNothing),1);

    for pageIdx=1:nPages
        figure('Position',[73          49         526        1053]);
        for plotConIdx=1:length(currIdx)
            if currIdx(plotConIdx) > length(uniqueCodes_noNothing)
                continue;
            end
            codeIdx = find(fullCodes==uniqueCodes_noNothing(currIdx(plotConIdx)));
            
            tWin = [allTimeWindows(codeIdx,1)+1, allTimeWindows(codeIdx,2)-1] ;
            concatDat = triggeredAvg( smoothSpikes_align, alignDat.eventIdx(trlCodes==uniqueCodes_noNothing(currIdx(plotConIdx))), tWin );
            avgNeural = squeeze(mean(concatDat,1));
            timeAxis = (tWin(1):tWin(2))/100;
            
            predNeural = squeeze(dynPred.pStatesNeuron(currIdx(plotConIdx),2:(end-1),:));
            
            for dimIdx = 1:3
                subplot(nPerPage,3,(plotConIdx-1)*3+dimIdx);
                hold on;
                if dimIdx==1 || dimIdx==2
                    plot(timeAxis, [ones(size(avgNeural,1),1), avgNeural]*filts_prep(:,dimIdx),'LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, [ones(size(avgNeural,1),1), avgNeural]*out.filts_mov(:,dimIdx),'LineWidth',2,'Color',color);
                    
                    plot(timeAxis, [ones(size(avgNeural,1),1), avgNeural]*out.filts_mov(:,4)*0.1,'-','LineWidth',2,'Color',[0 0.8 0]);
                    
                    plot(timeAxis, [ones(size(predNeural,1),1), predNeural]*filts_prep(:,dimIdx),'--','LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, [ones(size(predNeural,1),1), predNeural]*out.filts_mov(:,dimIdx),'--','LineWidth',2,'Color',color);
                else
                    plot(timeAxis, avgNeural*ciDim,'LineWidth',2,'Color',color*0.5);
                end

                plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);
                xlim([timeAxis(1), timeAxis(end)]);
                ylim([-1,1]); 
                plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
                set(gca,'FontSize',16,'LineWidth',2);

                if dimIdx==1
                    ylabel(allLabels{codeIdx});
                end

                if plotConIdx==1
                    title(headings{dimIdx});
                end
            end
            
            dynTraj{currIdx(plotConIdx)} = [ones(size(predNeural,1),1), predNeural]*out.filts_mov(:,1:2);
        end

        saveas(gcf,[outDir filesep 'prepDynamicsPage_' num2str(pageIdx) '.png'],'png');
        currIdx = currIdx + nPerPage;
    end
    
    close all;
    
    %%
    %bezier day
    if strcmp(sessionName,'t5.2019.05.06')
        minorSets = {1:6, 7:12, 13:18, 19:24, 25:40};
        figure

        for minorIdx=1:length(minorSets)
            subtightplot(2,3,minorIdx);
            hold on;

            cs = minorSets{minorIdx};
            colors = hsv(length(cs))*0.8;

            for t=1:length(cs)
                plot(allTraj{cs(t)}(:,1), allTraj{cs(t)}(:,2),'-','Color',colors(t,:),'LineWidth',2);
                
                mn = dynTraj{cs(t)};
                mn = mn(61:end,:);
                pos = cumsum(mn);
                plot(pos(:,1), pos(:,2),'--','Color',colors(t,:),'LineWidth',2);
            end

            axis equal;
            axis off;
        end
        
        saveas(gcf,[outDir filesep 'bezierCurves_dyn.png'],'png');
    end
    
    close all;
    
end %all sessions