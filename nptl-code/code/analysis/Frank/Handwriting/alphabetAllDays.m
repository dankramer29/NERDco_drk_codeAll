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
            simMatrix = plotCorrMat_cv( mPCA_out{setIdx}.featureVals  , [1,50], movLabelSets{setIdx} );
            saveas(gcf,[outDir filesep 'simMatrix_' num2str(setIdx) '.png'],'png');
            
            X = squeeze(mean(mPCA_out{setIdx}.featureAverages(:,:,1:50),3))';
            D = pdist(X,'correlation');
            Z = linkage(D);
            T = cluster(Z,'maxclust',8);
            
            orderIdx = [];
            for cIdx = 1:8
                orderIdx = [orderIdx; find(T==cIdx)];
            end
            
            simMatrix = plotCorrMat_cv( mPCA_out{setIdx}.featureVals(:,orderIdx,:,:)  , [1,50], movLabelSets{setIdx}(orderIdx) );
            saveas(gcf,[outDir filesep 'simMatrixOrder_' num2str(setIdx) '.png'],'png');
        end
    end
    
    %prep geometry
    if strcmp(sessionName,'t5.2019.05.06')
        setIdx = 6;
        prepVec = squeeze(nanmean(nanmean( mPCA_out{setIdx}.featureVals(:,:,1:50,:),4),3))';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

        SCORE = SCORE(:,4:6);
        
        figure
        hold on
        
        %for x=1:size(SCORE,1)
        %    text(SCORE(x,1), SCORE(x,2), SCORE(x,3), movLabelSets{setIdx}{x},'FontSize',16);
        %end

        colors = hsv(16)*0.8;
        rdIdx = 1:24;
        curveLaunchDir = [2 3 4 16 15 14, ...
            6 7 8 4 3 2, ...
            9 10 11 8 7 6, ...
            13 14 15 11 10 9];
        for c=1:length(rdIdx)
            colorIdx = curveLaunchDir(c);
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3),'s','MarkerFaceColor',colors(colorIdx,:),'Color',colors(colorIdx,:),'MarkerSize',14);
        end
        
        rdIdx = 25:40;
        for c=1:length(rdIdx)
            plot3(SCORE(rdIdx(c),1), SCORE(rdIdx(c),2), SCORE(rdIdx(c),3), 'o','MarkerFaceColor',colors(c,:),'Color',colors(c,:),'MarkerSize',14);
        end
        
        colors = hsv(16)*0.8;
        ringIdx = [25:40, 25];
        for c=1:(length(ringIdx)-1)
            plot3(SCORE(ringIdx(c:(c+1)),1), SCORE(ringIdx(c:(c+1)),2), SCORE(ringIdx(c:(c+1)),3), '-', 'LineWidth', 3, 'Color', colors(c,:));
        end

        axis tight;
        axis equal;
        %xlim([-2,2]);
        %ylim([-2,2]);
        %zlim([-2,2]);
    end

    %decode curvature from prep?
%     curveCodes = zeros(40,2);
%     curveCodes(1:3,2) = 1:3;
%     curveCodes(4:6,2) = -(1:3);
%     curveCodes(7:9,1) = -(1:3);
%     curveCodes(10:12,1) = 1:3;
%     curveCodes(13:15,2) = -(1:3);
%     curveCodes(16:18,2) = 1:3;
%     curveCodes(19:21,1) = 1:3;
%     curveCodes(22:24,1) = -(1:3);
%     
%     allY = [];
%     loopIdx = [];
%     allConIdx = [];
%     for t=1:length(trlCodes)
%         conIdx = find(trlCodes(t)==uniqueCodes_noNothing);
%         allY = [allY; repmat(curveCodes(conIdx,:),50,1)];
%         loopIdx = [loopIdx, (alignDat.eventIdx(t)-49):(alignDat.eventIdx(t))];
%         allConIdx = [allConIdx, repmat(conIdx,1,50)]; 
%     end
%     neuralDat = alignDat.zScoreSpikes_blockMean(loopIdx,:);
%     
%     filts = buildLinFilts(allY, [ones(size(neuralDat,1),1), neuralDat], 'standard');
%     predVals = [ones(size(neuralDat,1),1), neuralDat] * filts;
%     
%     mnVals = zeros(40,2);
%     for t=1:40
%         tmpIdx = find(allConIdx==t);
%         mnVals(t,:) = mean(predVals(tmpIdx,:));
%     end
    
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
    
    %if strcmp(sessionName,'t5.2019.05.06')
    %    in.fixTemplateSize = false;
    %    in.timeWindows(:,1) = -25;
    %    in.timeWindows(:,2) = 60;
    %    in.smoothSpikes_align = smoothSpikes_blockMean;
    %end
    
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
        timeStep = binMS/1000;
        timeAxis = (tw_use{setIdx}(1):tw_use{setIdx}(2))*timeStep;
        nDimToShow = 5;

        bias = [0,0,0];
            
        figure('Position',[680 218 1024 880]);
        for c=1:length(codeList{setIdx})
            if ~isempty(decVel_Z)
                concatDat = triggeredAvg( [out.cvVel(:,1:2), decVel_Z(:,3)], alignDat.eventIdx(trlCodes==codeList{setIdx}(c)), tw_use{setIdx} );
            else
                concatDat = triggeredAvg( out.cvVel, alignDat.eventIdx(trlCodes==codeList{setIdx}(c)), tw_use{setIdx} );
            end
            
            if isempty(concatDat)
                continue;
            end
            lenIdx = find(in.uniqueCodes_noNothing==codeList{setIdx}(c));
            lenEnd = out.conLen(lenIdx)+50;
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
            
            for t=1:(size(traj,1)-1)
                colorIdx = round(size(depthColors,1)*(mn(t,3)/0.2));
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