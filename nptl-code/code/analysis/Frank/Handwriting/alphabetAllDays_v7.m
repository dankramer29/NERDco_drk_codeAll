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
    't5.2019.06.26',[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 21 23 24 25 26 27 28],''; %1000 words
    };                                                         

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
    binnedDataFileName = [outDir filesep 'binnedData.mat'];
    if exist(binnedDataFileName,'file')
        load(binnedDataFileName);
    else 
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

        clear R;

        alignFields = {'goCue'};
        smoothWidth = 0;
        datFields = {'rigidBodyPosXYZ','currentMovement','headVel'};
        if strcmp(sessionName,'t5.2019.06.26')
            timeWindow = [-1000,8000];
        else
            timeWindow = [-1000,4000];
        end
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

        trlCodes = alignDat.currentMovement(alignDat.eventIdx);
        nothingTrl = trlCodes==218;

        if strcmp(sessionName,'t5.2019.05.31')
            trlCodes = trlCodes+100;
        elseif strcmp(sessionName,'t5.2019.06.26')
            wordText = cell(length(alignDat.eventIdx),1);
            for t=1:length(wordText)
                wordText{t} = getMovementText(trlCodes(t));
                wordText{t} = deblank(wordText{t}(10:end));
            end

            firstLetter = zeros(length(wordText),1);
            for t=1:length(firstLetter)
                firstLetter(t) = wordText{t}(1);
            end
            letterList = unique(firstLetter);

            %remap codes to original alphabet & word codes
            wordCodes = [2092 2256 2272 2282 2291];
            originalAlphabet = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z'};
            originalCodes = [400:406, 412:432];

            for t=1:length(trlCodes)
                if ~ismember(trlCodes(t), wordCodes)
                    trlLetter = firstLetter(t);
                    tmpIdx = find(strcmp(originalAlphabet, char(trlLetter)));
                    trlCodes(t) = originalCodes(tmpIdx);
                end
            end
        end

        [uniqueCodes, ~, tcReorder] = unique(trlCodes);
        uniqueCodes_noNothing = uniqueCodes;
        uniqueCodes_noNothing(uniqueCodes_noNothing==218) = [];
        
        alignDat = rmfield(alignDat,{'meanSubtractSpikes','meanSubtractHLFP','zScoreHLFP'});
        save(binnedDataFileName);
    end
    
    %%
    wordCodes = [2092 2256 2272 2282 2291];
    [movLabelSets, codeSets, fullCodes, allLabels, allTemplates, allTemplateCodes, allTimeWindows] = allAlphabetCodePreamble();
    
    if strcmp(sessionName,'t5.2019.06.26')
        %he wrote slower on this day
        allTimeWindows(allTimeWindows(:,2)==150,2) = 200;
        allTimeWindows(allTimeWindows(:,2)==400,2) = 800;
    end
    
    %%
    %make data cubes for each condition & save
    cubeDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes'];
    fileName = [cubeDir filesep sessionName sessionSuffix '_unwarpedCube.mat'];
    
    if ~exist(fileName,'file')
        dat = struct();
        allFieldNames = {};
        for t=1:length(uniqueCodes_noNothing)
            tmpIdx = find(uniqueCodes_noNothing(t)==fullCodes);
            if isempty(tmpIdx)
                continue;
            end
            
            winToUse = allTimeWindows(tmpIdx,:);
            if ismember(uniqueCodes_noNothing(t), wordCodes)
                %for self-paced words, cut off the trial by replacing with nans
                %after T5 indicated he was done
                if strcmp(sessionName,'t5.2019.06.26')
                    wordCutoff = 800;
                else
                    wordCutoff = 400;
                end
                
                concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(trlCodes==fullCodes(tmpIdx)), winToUse );
                trlIdx = find(trlCodes==uniqueCodes_noNothing(t));
                endTime = endTrl(trlIdx) - startTrl(trlIdx);
                endTime = round(endTime/10);
                endTime(endTime>wordCutoff) = wordCutoff;

                for x=1:length(trlIdx)
                    concatDat(x,(51+endTime(x)):end,:)=nan;
                end
            else
                concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(trlCodes==fullCodes(tmpIdx)), winToUse );
            end

            %for cross-validation, record trial index
            if strcmp(sessionName,'t5.2019.06.26')
                trlIdx = find(trlCodes==fullCodes(tmpIdx));
                
                %number as if we are excluding the repeated word blocks (18
                %and 20)
                trlIdx(trlIdx>=625) = trlIdx(trlIdx>=625)-80;
            else
                trlIdx = find(trlCodes==fullCodes(tmpIdx));
            end
            dat.(allLabels{tmpIdx}) = concatDat;
            dat.([allLabels{tmpIdx} '_trlIdx']) = trlIdx;
            allFieldNames{end+1} = allLabels{tmpIdx};
        end

        dat.chanIdx = find(~tooLow);
        dat.blockMeans = alignDat.blockmeans;
        dat.featureSTD = alignDat.featureSTD;
        save(fileName,'-struct','dat');
        
        %%
        %split into cross-validated training sets for RNN decoding
        if strcmp(sessionName,'t5.2019.06.26')
            cvPart=load('/Users/frankwillett/Data/Derived/Handwriting/letterSequenceTrials/t5.2019.06.26_cvPartitions.mat');
            for valIdx=1:10
                cvDat = dat;
                for f=1:length(allFieldNames)
                    remIdx = ismember(dat.([allFieldNames{f} '_trlIdx']), cvPart.cvIdx{valIdx});
                    cvDat.([allFieldNames{f} '_trlIdx'])(remIdx)=[];
                    cvDat.(allFieldNames{f})(remIdx,:,:)=[];
                end
                save([cubeDir filesep sessionName sessionSuffix '_valFold' num2str(valIdx) '_unwarpedCube.mat'],'-struct','cvDat');
            end
        end
    end

    %%
    %substitute in aligned data
    lfadsMode = false;
    if lfadsMode
        alignedCube = load([cubeDir filesep sessionName sessionSuffix '_lfads_warpedCube.mat']);
        alignDat.zScoreSpikes_align = zeros(size(alignDat.zScoreSpikes,1),3);
    else
        alignedCube = load([cubeDir filesep sessionName sessionSuffix '_warpedCube.mat']);
        alignDat.zScoreSpikes_align = alignDat.zScoreSpikes;
    end

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
    smoothSpikes_blockMean = gaussSmooth_fast(alignDat.zScoreSpikes, 3);
    
    if strcmp(sessionName,'t5.2019.06.26')
        %slower writing
        tw = [-49, 199];
        twWords = [-49, 799];
    else
        tw = [-49, 149];
        twWords = [-49, 399];
    end

    margGroupings = {{1, [1 2]}, {2}};
    margNames = {'Condition-dependent', 'Condition-independent'};
    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 3;
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
    %make initial straight line decoder
    makePlot = true;
    if all(ismember(codeSets{2}([1 3 5 7]), uniqueCodes_noNothing))
        availableCodes = find(ismember(codeSets{2}(1:8), uniqueCodes_noNothing));
        straightLineCodes = codeSets{2}(availableCodes);
        [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot );
    elseif all(ismember(codeSets{6}, uniqueCodes_noNothing))
        straightLineCodes = codeSets{6}(25:40);
        [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot );        
    elseif all(ismember(codeSets{7}, uniqueCodes_noNothing))
        straightLineCodes = codeSets{7}(41:56);
        [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot );        
    elseif all(ismember(codeSets{8}, uniqueCodes_noNothing))
        straightLineCodes = codeSets{8}(25:40);
        [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot );        
    elseif all(ismember(codeSets{9}, uniqueCodes_noNothing))
        straightLineCodes = codeSets{9}(33:48);
        [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot );        
    elseif all(ismember(codeSets{10}, uniqueCodes_noNothing))
        straightLineCodes = codeSets{10}(41:56);
        [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot );        
    else
        decVel = [];
        filts_prep = zeros(size(smoothSpikes_align,2)+1,2);
    end
    
    if all(ismember([codeSets{2}([1 3 5 7]), codeSets{2}(29:32)], uniqueCodes_noNothing))
        straightLineCodes_Z = [codeSets{2}(1:8), codeSets{2}(29:32)];
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
    %in.smoothSpikes_align = mPCA_out{1}.readoutZ_unroll(:,1:2);
    in.curveCodes = codeSets{2};
    in.wordCodes = codeSets{3};
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
        if strcmp(sessionName,'t5.2019.05.08') || strcmp(sessionName,'t5.2019.06.26')
            loadDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'allAlphabets' filesep 't5.2019.05.01'];
        end
        
        warpTemp = load([loadDir 'warpedTemplates.mat']);
        
        in_pre = in;
        in_pre.initMode = 'useLoadedWarps';
        in_pre.preWarpTemp = warpTemp.out.warpedTemplates;
        if strcmp(sessionName,'t5.2019.06.26')
            %extra word
            in_pre.preWarpTemp = [in_pre.preWarpTemp; {[]}];
            in_pre.preWarpCodes = [codeSets{1}, codeSets{2}(1:8), codeSets{3}(1:5)];
        else
            in_pre.preWarpCodes = [codeSets{1}, codeSets{2}(1:8), codeSets{3}(1:4)];
        end
        
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
    
    letterCodes = [400:406, 412:432];
    curveCodes = [486:525]; 
    wordCodes = [2092 2256 2272 2282 2291];
    punctuationCodes = [580 581 582 583];
    letterCodesReorder = [1 2 3 4 8 9 10 11 12 13 14 15 6 16 7 17 18 19 20 5 21 22 23 24 25 26];

    codeList = {[letterCodes, punctuationCodes], curveCodes, letterCodes(letterIdxPage), wordCodes, letterCodes(letterCodesReorder)};
    movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','>',',','''','~','?'};
    movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
        'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
        'cv37','cv38','cv39','cv40'};
    movLabels3 = {'take','man','set','till','get'};
    movLabelSets = {movLabels1, movLabels2, movLabels1(letterIdxPage), movLabels3, movLabels1(letterCodesReorder)};
    
    if strcmp(sessionName,'t5.2019.06.26')
        tw_use = {[-49, 200],[-49, 200], [-49, 200], [-49, 800], [-49, 200]};
    else
        tw_use = {[-49, 150],[-49, 150], [-49, 150], [-49, 400], [-49, 200]};
    end
    
    if strcmp(sessionName,'t5.2019.06.26')
        manualLen = [151, 121, 95, 131, 121, 181, 121, 111, 171, 171, 111, 131, 91, 171, 51, 101, 121, ...
            171, 61, 131, 61, 51, 111, 111, 131, 121];
        pen_down = [141 211]; %take (word1)
        pen_up = [251 311]; %till (word4)
    elseif strcmp(sessionName,'t5.2019.05.08')
        manualLen = [99 91 70 104 110 132 84 98 125 110 104 79 92 127 68 90 113 104 74 86 86 83 110 103 115 100 ...
            82 77 116 71 110];
        i_up = [85, 150];
        question_down = [60,90]+60;
        comma_down = [50,77];
    end

    for setIdx=1:length(codeList)      
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
            %lenEnd = manualLen(lenIdx)+60;
            
            if setIdx==6
                lenEnd = 300;
            elseif setIdx==4
                if strcmp(sessionName,'t5.2019.06.26')
                    lenEnd = 800+50;
                else
                    lenEnd = 400+50;
                end
            end
            
            if setIdx==7
                subtightplot(7,7,c);
            elseif setIdx==4
                subtightplot(2,3,c);
            elseif setIdx==2
                subtightplot(7,6,c);
            elseif setIdx==1
                subtightplot(6,6,c,0.03,0.03,0.03);
            elseif setIdx==5
                subtightplot(6,6,c,0.05,0.05,0.03);
            else
                subtightplot(5,5,c);
            end
            hold on;

            mn = squeeze(mean(concatDat,1))+bias;
            mn = mn(61:lenEnd,:);
            traj = cumsum(mn);

            plot(traj(:,1),traj(:,2),'LineWidth',2);
            plot(traj(1,1),traj(1,2),'o');
            
            %for t=1:10:size(traj,1)
            %    text(traj(t,1),traj(t,2),num2str(t));
            %end
            
            %for t=1:(size(traj,1)-1)
            %    colorIdx = round(size(depthColors,1)*(mn(t,4)*0.1+0.5));
            %    colorIdx(colorIdx>size(depthColors,1)) = size(depthColors,1);
            %    colorIdx(colorIdx<=0) = 1;
            %    plot([traj(t,1), traj(t+1,1)], [traj(t,2), traj(t+1,2)], 'Color', depthColors(colorIdx,:), 'LineWidth',2);
            %end
            
            title(movLabelSets{setIdx}{c},'FontSize',30);
            axis off;
            axis equal;
        end
        
        saveas(gcf,[outDir filesep 'allTraj_page' num2str(setIdx) '.png'],'png');
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

            if setIdx==3
                setIdxToUse=1;
            else
                setIdxToUse=setIdx;
            end
            unalignedDim = gaussSmooth_fast(alignDat.zScoreSpikes, 3.0) * mPCA_out{setIdxToUse}.W(:,1:5);
            codeList = codeSets{setIdx};
            movLabels = movLabelSets{setIdx};

            tw_all = [-49, size(mPCA_out{setIdx}.featureVals,3)-50];
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
    r8 = find(ismember(uniqueCodes_noNothing, codeSets{2}(1:8)));
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
    rev = find(ismember(uniqueCodes_noNothing, codeSets{2}(9:12)));
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
    nineBend = find(ismember(uniqueCodes_noNothing, codeSets{2}(13:20)));
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
    bez = find(ismember(uniqueCodes_noNothing, codeSets{2}(21:28)));
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
        figure('Color','w');

        for minorIdx=1:length(minorSets)
            subtightplot(2,3,minorIdx);
            hold on;

            cs = minorSets{minorIdx};
            colors = hsv(length(cs))*0.8;

            for t=1:length(cs)
                plot(allTraj{cs(t)}(:,1), allTraj{cs(t)}(:,2),'-','Color',colors(t,:),'LineWidth',3);
                %text(allTraj{cs(t)}(end,1), allTraj{cs(t)}(end,2), betterBezierLabels{cs(t)});
            end

            axis equal;
            axis off;
        end
        
        saveas(gcf,[outDir filesep 'bezierCurves.png'],'png');
    end
    
    close all;
    
    %%
    %bezier day 2
    if strcmp(sessionName,'t5.2019.05.31')
        minorSets = {[1 2 3 6 7 8], [4 5 9 10], ...
            10+[1 2 3 6 7 8], 10+[4 5 9 10], ...
            20+[1 2 3 6 7 8], 20+[4 5 9 10], ...
            30+[1 2 3 6 7 8], 30+[4 5 9 10], ...
            41:56};
        figure

        for minorIdx=1:length(minorSets)
            subtightplot(3,3,minorIdx);
            hold on;

            cs = minorSets{minorIdx};
            colors = hsv(length(cs))*0.8;

            for t=1:length(cs)
                plot(allTraj{cs(t)}(:,1), allTraj{cs(t)}(:,2),'-','Color',colors(t,:),'LineWidth',2);
                text(allTraj{cs(t)}(end,1), allTraj{cs(t)}(end,2), movLabelSets{7}{cs(t)});
            end

            axis equal;
            axis off;
        end
        
        saveas(gcf,[outDir filesep 'bezierCurves.png'],'png');
    end
    
    close all;
    
    %%
    %bezier day 3
    if strcmp(sessionName,'t5.2019.06.17')
        minorSets = {[1 2 3 4 5 6], ...
            [7 8 9 10 11 12], ...
            [13 14 15 16 17 18], ...
            [19 20 21 22 23 24], ...
            25:40,...
            [41 42 49 50],...
            [43 44 51 52],...
            [45 46 53 54],...
            [47 48 55 56]};
        figure

        for minorIdx=1:length(minorSets)
            subtightplot(3,3,minorIdx);
            hold on;

            cs = minorSets{minorIdx};
            colors = hsv(length(cs))*0.8;

            for t=1:length(cs)
                plot(allTraj{cs(t)}(:,1), allTraj{cs(t)}(:,2),'-','Color',colors(t,:),'LineWidth',2);
                text(allTraj{cs(t)}(end,1), allTraj{cs(t)}(end,2), movLabelSets{8}{cs(t)});
            end

            axis equal;
            axis off;
        end
        
        saveas(gcf,[outDir filesep 'bezierCurves.png'],'png');
    end
    
    close all;
    
    %%
    %bezier day 4
    if strcmp(sessionName,'t5.2019.06.19')
        %minorSets = {1:4, 5:8, 9:12, 13:16, 17:20, 21:24, 25:28, 29:32, 33:48};
        minorSets = {[1 3 9 11 17 19 25 27],[5 7 13 15 21 23 29 31],[2 4 10 12 18 20 26 28],[6 8 14 16 22 24 30 32],33:48};
        figure

        for minorIdx=1:length(minorSets)
            subtightplot(2,3,minorIdx);
            hold on;

            cs = minorSets{minorIdx};
            
            if minorIdx==5
                colors = hsv(length(cs))*0.8;
            else
                colors = zeros(length(cs),3);
                tmp = hsv(length(cs)/2)*0.8;
                colors(1:2:end,:) = tmp;
                colors(2:2:end,:) = tmp;
            end

            for t=1:length(cs)
                plot(allTraj{cs(t)}(:,1), allTraj{cs(t)}(:,2),'-','Color',colors(t,:),'LineWidth',2);
                text(allTraj{cs(t)}(end,1), allTraj{cs(t)}(end,2), movLabelSets{9}{cs(t)});
            end

            axis equal;
            axis off;
        end
        
        saveas(gcf,[outDir filesep 'bezierCurves.png'],'png');
    end
    
    close all;
    
    %%
    %bezier day 5
    if strcmp(sessionName,'t5.2019.06.24')
        minorSets = {1:5, 6:10, 11:15, 16:20, 21:25, 26:30, 31:35, 36:40, 41:56};
        figure;
        
        for minorIdx=1:length(minorSets)
            subtightplot(3,3,minorIdx);
            hold on;

            cs = minorSets{minorIdx};
            colors = hsv(length(cs))*0.8;

            for t=1:length(cs)
                plot(allTraj{cs(t)}(:,1), allTraj{cs(t)}(:,2),'-','Color',colors(t,:),'LineWidth',2);
                text(allTraj{cs(t)}(end,1), allTraj{cs(t)}(end,2), movLabelSets{10}{cs(t)});
            end

            axis equal;
            axis off;
        end
        
        saveas(gcf,[outDir filesep 'bezierCurves.png'],'png');
    end
    
    close all;
    
    %%
    %load dynamical predictions
    %dynPred = load(['/Users/frankwillett/Data/Derived/Handwriting/prepDynamics/linearPredictions_' sessionName sessionSuffix '.mat']);
    %dynPred = load(['/Users/frankwillett/Data/Derived/Handwriting/prepDynamics/rnnPredictions_' sessionName sessionSuffix '.mat']);
    
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
    allModelTraj = cell(length(uniqueCodes_noNothing),1);

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
            
            %predNeural = squeeze(dynPred.pStatesNeuron(currIdx(plotConIdx),2:(end-1),:));
            
            for dimIdx = 1:3
                subplot(nPerPage,3,(plotConIdx-1)*3+dimIdx);
                hold on;
                if dimIdx==1 || dimIdx==2
                    plot(timeAxis, 1.6*[ones(size(avgNeural,1),1), avgNeural]*filts_prep(:,dimIdx),'LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, 1.6*[ones(size(avgNeural,1),1), avgNeural]*out.filts_mov(:,dimIdx),'LineWidth',2,'Color',color);
                    
                    plot(timeAxis, [ones(size(avgNeural,1),1), avgNeural]*out.filts_mov(:,4)*0.05,'-','LineWidth',2,'Color',[0 0.8 0]);
                    
                    %plot(timeAxis, allSimTraj{currIdx(plotConIdx)}(:,dimIdx),'--','LineWidth',2,'Color',color);
                    %plot(timeAxis, [ones(size(predNeural,1),1), predNeural]*filts_prep(:,dimIdx),'--','LineWidth',2,'Color',color*0.5);
                    %plot(timeAxis, [ones(size(predNeural,1),1), predNeural]*out.filts_mov(:,dimIdx),'--','LineWidth',2,'Color',color);
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
            
            prepVel = [ones(size(avgNeural,1),1), avgNeural]*filts_prep(:,1:2);
            outVel =  [ones(size(avgNeural,1),1), avgNeural]*out.filts_mov(:,1:2);
            CIS = avgNeural*ciDim;
            allModelTraj{currIdx(plotConIdx),1} = [prepVel, outVel, CIS];
            
            %dynTraj{currIdx(plotConIdx)} = [ones(size(predNeural,1),1), predNeural]*out.filts_mov(:,1:2);
        end

        saveas(gcf,[outDir filesep 'prepDynamicsPage_' num2str(pageIdx) '.png'],'png');
        currIdx = currIdx + nPerPage;
    end
    close all;
    
    concatModelTraj = cat(3, allModelTraj{:});
    concatModelTraj = permute(concatModelTraj, [3 1 2]);
    save(['/Users/frankwillett/Data/Derived/Handwriting/DynMat/dynDimMat_' sessionName sessionSuffix '.mat'],'concatModelTraj');
    
    %%
    if strcmp(sessionName,'t5.2019.05.06')
        %project to target direction to summarize
        theta = linspace(0,2*pi,17);
        theta = theta(1:16);
        dToUse = [1 1 1 1 1 1, ...
            5 5 5 5 5 5, ...
            9 9 9 9 9 9, ...
            13 13 13 13 13 13, ...
            1:16];

        rotTraj = cell(size(allModelTraj));
        for x=1:length(allModelTraj)
            t = -theta(dToUse(x));
            rotMat = [[cos(t), cos(t+pi/2)]; [sin(t), sin(t+pi/2)]];
            rotTraj{x} = [(rotMat * allModelTraj{x}(:,1:2)')', (rotMat * allModelTraj{x}(:,3:4)')'];
        end

        plotSets = {25:40, [1 2 3 7 8 9 13 14 15 19 20 21], [4 5 6 10 11 12 16 17 18 22 23 24]};

        for setIdx=1:length(plotSets)
            pIdx = plotSets{setIdx};
            timeAxis = (1:length(rotTraj{1}))*0.01 - 0.5;
    %         figure
    %         subplot(1,2,1);
    %         hold on
    %         
    %         for x=1:length(pIdx)
    %             plot(rotTraj{pIdx(x)}(:,1),'b');
    %             plot(rotTraj{pIdx(x)}(:,2),'r');
    %         end
    %         
    %         allConcat = cat(3,rotTraj{pIdx});
    %         plot(squeeze(mean(allConcat(:,1,:),3)),'b','LineWidth',3);
    %         plot(squeeze(mean(allConcat(:,2,:),3)),'r','LineWidth',3);
    % 
    %         subplot(1,2,2);
    %         hold on
    %         for x=1:length(pIdx)
    %             plot(rotTraj{pIdx(x)}(:,3),'b');
    %             plot(rotTraj{pIdx(x)}(:,4),'r');
    %         end
    %         
    %         allConcat = cat(3,rotTraj{pIdx});
    %         plot(squeeze(mean(allConcat(:,3,:),3)),'b','LineWidth',3);
    %         plot(squeeze(mean(allConcat(:,4,:),3)),'r','LineWidth',3);

            figure('Position',[680   849   693   249]);
            subplot(1,2,1);
            hold on

            allConcat = cat(3,rotTraj{pIdx});
            plot(timeAxis,squeeze(mean(allConcat(:,1,:),3)),'Color',[0.8 0 0],'LineWidth',3);
            plot(timeAxis,squeeze(mean(allConcat(:,3,:),3)),'Color',[0 0 0.8],'LineWidth',3);
            plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);

            title('X Dimension');
            xlabel('Time (s)');
            legend({'Prep','Velocity'});
            set(gca,'FontSize',16,'LineWidth',2);
            ylim([-0.6,1.0]);

            subplot(1,2,2);
            hold on

            allConcat = cat(3,rotTraj{pIdx});
            plot(timeAxis,squeeze(mean(allConcat(:,2,:),3)),'Color',[0.8 0 0],'LineWidth',3);
            plot(timeAxis,squeeze(mean(allConcat(:,4,:),3)),'Color',[0 0 0.8],'LineWidth',3);
            plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);
            title('Y Dimension');
            xlabel('Time (s)');
            legend({'Prep','Velocity'});
            set(gca,'FontSize',16,'LineWidth',2);
            ylim([-0.6,1.0]);
            
            saveas(gcf,[outDir filesep 'bezierPrepVsVelAvg_' num2str(setIdx) '.png'],'png');
        end
    end
    
    %%
    if strcmp(sessionName,'t5.2019.06.19')
        %project to target direction to summarize
        theta = linspace(0,2*pi,17);
        theta = theta(1:16);
        dToUse = [1 1 1 1,...
            3 3 3 3,...
            5 5 5 5,...
            7 7 7 7,...
            9 9 9 9,...
            11 11 11 11,...
            13 13 13 13,...
            15 15 15 15,...
            1:16];

        rotTraj = cell(size(allModelTraj));
        for x=1:length(allModelTraj)
            t = -theta(dToUse(x));
            rotMat = [[cos(t), cos(t+pi/2)]; [sin(t), sin(t+pi/2)]];
            rotTraj{x} = [(rotMat * allModelTraj{x}(:,1:2)')', (rotMat * allModelTraj{x}(:,3:4)')'];
        end

        plotSets = {33:48, 1:4:32, 2:4:32, 3:4:32, 4:4:32};

        for setIdx=1:length(plotSets)
            pIdx = plotSets{setIdx};
            timeAxis = (1:length(rotTraj{1}))*0.01 - 0.5;
    %         figure
    %         subplot(1,2,1);
    %         hold on
    %         
    %         for x=1:length(pIdx)
    %             plot(rotTraj{pIdx(x)}(:,1),'b');
    %             plot(rotTraj{pIdx(x)}(:,2),'r');
    %         end
    %         
    %         allConcat = cat(3,rotTraj{pIdx});
    %         plot(squeeze(mean(allConcat(:,1,:),3)),'b','LineWidth',3);
    %         plot(squeeze(mean(allConcat(:,2,:),3)),'r','LineWidth',3);
    % 
    %         subplot(1,2,2);
    %         hold on
    %         for x=1:length(pIdx)
    %             plot(rotTraj{pIdx(x)}(:,3),'b');
    %             plot(rotTraj{pIdx(x)}(:,4),'r');
    %         end
    %         
    %         allConcat = cat(3,rotTraj{pIdx});
    %         plot(squeeze(mean(allConcat(:,3,:),3)),'b','LineWidth',3);
    %         plot(squeeze(mean(allConcat(:,4,:),3)),'r','LineWidth',3);

            figure('Position',[680   849   693   249]);
            subplot(1,2,1);
            hold on

            allConcat = cat(3,rotTraj{pIdx});
            plot(timeAxis,squeeze(mean(allConcat(:,1,:),3)),'Color',[0.8 0 0],'LineWidth',3);
            plot(timeAxis,squeeze(mean(allConcat(:,3,:),3)),'Color',[0 0 0.8],'LineWidth',3);
            plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);

            title('X Dimension');
            xlabel('Time (s)');
            legend({'Prep','Velocity'});
            set(gca,'FontSize',16,'LineWidth',2);
            ylim([-0.6,1.0]);

            subplot(1,2,2);
            hold on

            allConcat = cat(3,rotTraj{pIdx});
            plot(timeAxis,squeeze(mean(allConcat(:,2,:),3)),'Color',[0.8 0 0],'LineWidth',3);
            plot(timeAxis,squeeze(mean(allConcat(:,4,:),3)),'Color',[0 0 0.8],'LineWidth',3);
            plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);
            title('Y Dimension');
            xlabel('Time (s)');
            legend({'Prep','Velocity'});
            set(gca,'FontSize',16,'LineWidth',2);
            ylim([-0.6,1.0]);
            
            saveas(gcf,[outDir filesep 'bezierPrepVsVelAvg_' num2str(setIdx) '.png'],'png');
        end
    end
    
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
                
                %mn = dynTraj{cs(t)};
                mn = allSimTraj{cs(t)};
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