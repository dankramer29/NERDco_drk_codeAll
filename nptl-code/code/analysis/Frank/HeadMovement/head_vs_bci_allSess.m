%%
%see movementTypes.m for code definitions
allMovTypes = {
    {[1 2],'head'
    [3],'bci_ol'
    [4 5 6],'bci_cl'}
    
    {[1 2],'head'
    [6],'bci_ol_1'
    [8],'bci_cl_1'
    [10],'bci_ol_2'
    [11],'bci_cl_2'
    [12],'bci_cl_3'
    [13],'bci_cl_4'
    [14],'bci_cl_5'
    }

    {[2 3],'head'
    [4],'bci_ol_1'
    [5],'bci_ol_2'
    [6],'bci_ol_3'
    [7],'bci_cl_1'
    [8],'bci_cl_free'
    [11],'bci_cl_2'
    [12],'bci_cl_3'
    [14],'bci_cl_4'
    }
    
    {[10],'head'
    [11],'eye'
    [12],'bci_ol'
    [15],'bci_cl_1'
    [16],'bci_cl_2'
    [17],'bci_cl_3'
    }
    
    {[7],'head'
    [8],'bci_ol'
    [9],'bci_cl_1'
    [10],'bci_cl_2'
    [12],'bci_cl_iFix'
    }
    
    {[2],'head'
    [18],'bci_ol'
    [22],'bci_cl_1'
    }
    
    {[18],'head'
    [10],'bci_ol'
    [11],'bci_cl_1'
    [12],'bci_cl_2'
    [13],'bci_cl_3'
    [14],'bci_cl_4'
    [15],'bci_cl_5'
    [16],'bci_cl_6'
    [17],'bci_cl_7'
    }
    
    };

allFilterNames = {'011-blocks013_014-thresh-4.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'008-blocks013_014-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'009-blocks011_012_014-thresh-3.5-ch80-bin15ms-smooth25ms-delay0ms.mat'
'008-blocks016_017-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'003-blocks010-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'003-blocks022-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'002-blocks010_011_012_013_014-thresh-3.5-ch80-bin15ms-smooth25ms-delay0ms.mat'
};

allSessionNames = {'t5.2017.12.27','t5.2018.01.08','t5.2018.01.17','t5.2018.01.19','t5.2018.01.22','t5.2018.01.24','t5.2018.03.09'};

allCrossCon = {[1 2 3],[1 2 4 5 8],[1 4 9],[1 2 3 4 5 6],[1 2 3 4 5],[1 2 3],1:9};
allCrossPostfix = {{'_within','_crossHead','_crossOL','_crossCL'},
    {'_within','_crossHead','_crossOL1','_crossOL2','_crossCL2','_crossCL5'};
    {'_within','_crossHead','_crossOL3','_crossCL4'}
    {'_within','_crossHea','_crossEye','_crossOL','_crossCL1','_crossCL2','_crossCL3'}
    {'_within','_crossHead','_crossOL','_crossCL1','_crossCL2','_crossCLiF'}
    {'_within','_crossHead','_crossOL','_crossCL'}
    {'_within','_crossHead','_crossOL','_crossCL1','_crossCL2','_crossCL3','_crossCL4','_crossCL5','_crossCL6','_crossCL7'}};
allMoveTypeText = {{'Head','OL','CL'},{'Head','OL 1','CL 1','OL 2','CL 2','CL 3','CL 4','CL 5'},...
    {'Head','OL 1','OL 2','OL 3','CL 1','CL F','CL 2','CL 3','CL 4'},...
    {'Head','Eye','OL','CL 1','CL 2','CL 3'},...
    {'Head','OL','CL 1','CL 2','CL iF'},...
    {'Head','OL','CL 1'},...
    {'Head','OL','CL 1','CL 2','CL 3','CL 4','CL 5','CL 6','CL 7'}};

for outerSessIdx = 1:length(allSessionNames)
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    sessionName = allSessionNames{outerSessIdx};
    filterName = allFilterNames{outerSessIdx};
    movTypes = allMovTypes{outerSessIdx};
    
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'head_vs_bci_all' filesep allSessionNames{outerSessIdx}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

    %%
    %load cursor filter for threshold values, use these across all movement types
    model = load([paths.dataPath filesep 'BG Datasets' filesep sessionName filesep 'Data' filesep 'Filters' filesep ...
        filterName]);

    %%
    %load cued movement dataset
    R = getSTanfordBG_RStruct( sessionPath, horzcat(movTypes{:,1}), model.model );

    speedThresh = 0.15;
    rtIdxAll = zeros(length(R),1);
    for t=1:length(R)
        %RT
        headPos = double(R(t).windowsMousePosition');
        headVel = [0 0; diff(headPos)];
        [B,A] = butter(4, 10/500);
        headVel = filtfilt(B,A,headVel);
        headSpeed = matVecMag(headVel,2)*1000;
        R(t).headSpeed = headSpeed;
        
        rtIdx = find(headSpeed>speedThresh);
        rtIdx(rtIdx<200)=[];
        if ~isempty(rtIdx)
            rtIdx = rtIdx(1);
        end
        if isempty(rtIdx)
            rtIdx = 21;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        if ismember(R(t).blockNum,movTypes{1,1})
            R(t).rtTime = rtIdx;
        else
            R(t).rtTime = 200;
        end
    end
    
    smoothWidth = 0;
    if strcmp(allSessionNames{outerSessIdx},'t5.2018.03.09')
        datFields = {'windowsPC1GazePoint','windowsMousePosition','cursorPosition','currentTarget','xk'};
    elseif outerSessIdx>=4
        datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    else
        datFields = {'windowsMousePosition','cursorPosition','currentTarget','xk'};
    end
    binMS = 20;
    unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

    alignFields = {'timeGoCue'};
    smoothWidth = 30;
    if strcmp(allSessionNames{outerSessIdx},'t5.2018.03.09')
        datFields = {'windowsPC1GazePoint','windowsMousePosition','cursorPosition','currentTarget','xk'};
    elseif outerSessIdx>=4
        datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    else
        datFields = {'windowsMousePosition','cursorPosition','currentTarget','xk'};
    end
    timeWindow = [-200, 800];
    binMS = 20;
    alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 0.5;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
    
    alignFields = {'rtTime'};
    alignDat_rt = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );
    alignDat_rt.allZScoreSpikes = alignDat_rt.zScoreSpikes;
    alignDat_rt.rawSpikes(:,tooLow) = [];
    alignDat_rt.meanSubtractSpikes(:,tooLow) = [];
    alignDat_rt.zScoreSpikes(:,tooLow) = [];
    
    %%
    %correlation between head velocity and decoded velocity
    headPos = unrollDat.windowsMousePosition;
    headVel = [0 0; diff(headPos)];
    [B,A] = butter(4, 10/500);
    headVel = filtfilt(B,A,headVel);
    headVel(:,2) = -headVel(:,2);
    allCorr = zeros(size(movTypes,1),2);
    
    for x=1:size(movTypes,1)
        %cursorVel = unrollDat.xk(:,[2 4]);
        cursorVel = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);
        clBlocks = find(ismember(unrollDat.blockNum, movTypes{x,1}));

%         figure
%         ax1 = subplot(1,2,1);
%         hold on;
%         plot(zscore(headVel(clBlocks,1)));
%         plot(zscore(cursorVel(clBlocks,1)));
% 
%         ax2 = subplot(1,2,2);
%         hold on;
%         plot(zscore(headVel(clBlocks,2)));
%         plot(-zscore(cursorVel(clBlocks,2)));
% 
%         linkaxes([ax1, ax2],'x');
        
        for dimIdx=1:2
            [C,lags]=xcorr(headVel(clBlocks,dimIdx), cursorVel(clBlocks,dimIdx),'coeff');
            allCorr(x,dimIdx) = max(C);
        end
    end
    disp(allCorr);
    
    %%
%     %make movies
%     for x=1:size(movTypes,1)
%         trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{x,1}));
%         loopIdx = find(ismember(unrollDat.blockNum, movTypes{x,1}));
% 
%         theta = linspace(0,2*pi,9)';
%         theta(end) = [];
%         targList = 409*[cos(theta), sin(theta)];
%         targList = [targList; [0 0]];
% 
%         cursorXY = unrollDat.cursorPosition(loopIdx,1:2);
%         targXY = unrollDat.currentTarget(loopIdx,1:2);
%         cursorColor = [255,255,255]/255;
%         targColor = [108,108,108]/255;
%         targRad = repmat(R(trlIdx(end)).startTrialParams.targetDiameter/2,length(loopIdx),1);
%         cursorRad = repmat(45/2,length(loopIdx),1);
%         extraCursors = cell(2,3);
%         extraCursors{1,1} = unrollDat.windowsMousePosition(loopIdx,1:2)*1080;
%         extraCursors{1,1}(:,2) = -extraCursors{1,1}(:,2);
%         extraCursors{1,2} = 45/2;
%         extraCursors{1,3} = [0 208 108]/255;
%         if outerSessIdx>=4
%             extraCursors{2,1} = unrollDat.windowsPC1LeftEye(loopIdx,1:2)-[840 525];
%             extraCursors{2,1}(:,2) = -extraCursors{2,1}(:,2);
%             extraCursors{2,2} = 45/2;
%             extraCursors{2,3} = [208 108 108]/255;
%         else
%             extraCursors(2,:) = [];
%         end
%         playMovie = false;
%         fps = 50;
%         xLim = [-500, 500];
%         yLim = [-500, 500];
%         inTarget = false(length(loopIdx),1);
%         bgColor = [0 0 0];
% 
%          M = makeCursorMovie_v2( cursorXY, targXY, targList, cursorColor, ...
%             targColor, cursorRad, targRad, extraCursors, ...
%                 playMovie, fps, xLim, yLim, inTarget, bgColor );
%          writeMpegMovie( M, [outDir filesep 'movie_' movTypes{x,2}], 50 );
%     end

    %%
    %decoding accuracy
    timeStart = -20:50;
    decAcc = zeros(size(movTypes,1),length(timeStart),2);
    pdCoef = cell(size(movTypes,1),1);
    maxLags = zeros(size(movTypes,1),1);
    for x=1:size(movTypes,1)
        trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{x,1}));
        isSucc = [R(trlIdx).isSuccessful];
        trlIdx(~isSucc) = [];
        
        rtOffsets = round([R.rtTime]/20)';
        
        decVectors = zeros(size(unrollDat.cursorPosition,1),2);
        posErr = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);
        C = cvpartition(length(trlIdx),'KFold',6);
        for n=1:6
            trainTrials = trlIdx(C.training(n));
            loopIdx = expandEpochIdx([unrollDat.trialEpochs(trainTrials,1)-10+rtOffsets(trainTrials), unrollDat.trialEpochs(trainTrials,2)]);
            loopIdx(loopIdx<1) = [];
            coef = buildLinFilts(posErr(loopIdx,:), unrollDat.zScoreSpikes(loopIdx,:), 'inverseLinear');
            
            testTrials = trlIdx(C.test(n));
            loopIdx = expandEpochIdx([unrollDat.trialEpochs(testTrials,1), unrollDat.trialEpochs(testTrials,2)]);
            decVectors(loopIdx,:) = unrollDat.zScoreSpikes(loopIdx,:) * coef;
        end

        loopIdx = expandEpochIdx([unrollDat.trialEpochs(trlIdx,1)+10, unrollDat.trialEpochs(trlIdx,2)]);
        coef = buildLinFilts(posErr(loopIdx,:), unrollDat.zScoreSpikes(loopIdx,:), 'inverseLinear');
        pdCoef{x} = coef;
        
        tmpC = zeros(length(timeStart),1);
        for t=1:length(timeStart)
            %corr
            re = [unrollDat.trialEpochs(trlIdx,1)+timeStart(t)+rtOffsets(trlIdx), unrollDat.trialEpochs(trlIdx,1)+timeStart(t)+10+rtOffsets(trlIdx)];
            loopIdxBeginning = expandEpochIdx(re);
            loopIdxBeginning(loopIdxBeginning<1) = [];
 
            cMat = corr(decVectors(loopIdxBeginning,:), posErr(loopIdxBeginning,:));
            decAcc(x,t,1) = mean(diag(cMat));
            
            %SNR
            unitVec = bsxfun(@times, posErr(loopIdxBeginning,:), 1./matVecMag(posErr(loopIdxBeginning,:),2));
            [B_x,B_xint,~,~,STATS_x] = regress(decVectors(loopIdxBeginning,1), [ones(size(unitVec,1),1), unitVec(:,1)]);
            [B_y,B_yint,~,~,STATS_y] = regress(decVectors(loopIdxBeginning,2), [ones(size(unitVec,1),1), unitVec(:,2)]);
            SNR = [B_x(2)/sqrt(STATS_x(end)), B_y(2)/sqrt(STATS_y(end))];
            decAcc(x,t,2) = mean(SNR);
        end
    end
    
    figure('Position',[680   838   772   260]);
    subplot(1,2,1);
    bar(max(squeeze(decAcc(:,:,1))'),'LineWidth',2);
    set(gca,'XTickLabel',allMoveTypeText{outerSessIdx},'XTickLabelRotation',45,'FontSize',16);
    ylabel('R');
    
    subplot(1,2,2);
    bar(max(squeeze(decAcc(:,:,2))'),'LineWidth',2);
    set(gca,'XTickLabel',allMoveTypeText{outerSessIdx},'XTickLabelRotation',45,'FontSize',16);
    ylabel('SNR');
    
    saveas(gcf,[outDir filesep 'decAcc_bar.png'],'png');
    saveas(gcf,[outDir filesep 'decAcc_bar.svg'],'svg');
    
    figure('Position',[680   838   772   260]);
    subplot(1,2,1);
    plot(timeStart*0.02,squeeze(decAcc(:,:,1))','LineWidth',2);
    legend(allMoveTypeText{outerSessIdx},'Location','SouthEast');
    ylabel('R');
    
    subplot(1,2,2);
    plot(timeStart*0.02,squeeze(decAcc(:,:,2))','LineWidth',2);
    legend(allMoveTypeText{outerSessIdx},'Location','SouthEast');
    ylabel('SNR');
    
    saveas(gcf,[outDir filesep 'decAcc.png'],'png');
    saveas(gcf,[outDir filesep 'decAcc.svg'],'svg');
    
    pdCMat = zeros(size(movTypes,1));
    for x=1:size(movTypes,1)
        for y=1:size(movTypes,1)
            pdCMat(x,y) = mean(diag(corr(pdCoef{x}, pdCoef{y})));
        end
    end
    
    figure;
    imagesc(pdCMat,[-0.2 1.0]);
    colorbar;
    set(gca,'XTick',1:size(movTypes,1),'XTickLabel',allMoveTypeText{outerSessIdx});
    set(gca,'YTick',1:size(movTypes,1),'YTickLabel',allMoveTypeText{outerSessIdx},'FontSize',18,'XTickLabelRotation',45);

    saveas(gcf,[outDir filesep 'PD_corr.png'],'png');
    saveas(gcf,[outDir filesep 'PD_corr.svg'],'svg');
    
    mText = allMoveTypeText{outerSessIdx};
    save([outDir filesep 'decAcc_pd.mat'],'decAcc','pdCMat','mText');
    
    %%
    %cross decoding
    decVec = cell(size(movTypes,1),1);
    for x=1:size(movTypes,1)
        trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{x,1}));
        isSucc = [R(trlIdx).isSuccessful];
        trlIdx(~isSucc) = [];
        
        rtOffsets = round([R.rtTime]/20)';
        posErr = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);
        loopIdx = expandEpochIdx([unrollDat.trialEpochs(trlIdx,1)+rtOffsets(trlIdx)-10, unrollDat.trialEpochs(trlIdx,2)]);
        loopIdx(loopIdx<1) = [];

        coef = buildLinFilts(posErr(loopIdx,:), unrollDat.zScoreSpikes(loopIdx,:), 'inverseLinear');
        coef = bsxfun(@times, coef, 1./matVecMag(coef,1));
        decVec{x} = zeros(size(alignDat.cursorPosition,1),2);
        
        for y=1:size(movTypes,1)
            trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{y,1})); 
            loopIdx = expandEpochIdx([alignDat.eventIdx(trlIdx,1)+timeWindow(1)/binMS, ...
                alignDat.eventIdx(trlIdx,1)+timeWindow(2)/binMS]);
            loopIdx(loopIdx<1) = [];
            loopIdx(loopIdx>length(alignDat.allZScoreSpikes)) = [];
            decVec{x}(loopIdx,:) = alignDat.allZScoreSpikes(loopIdx,:) * coef;
        end
    end
    
    colors = hsv(8)*0.8;
    nCon = size(movTypes,1);
    yLimsAll = zeros(nCon, nCon, 2);
    axIdx = zeros(nCon,nCon);
    dimNames = {'X','Y'};
    
    for dimIdx = 1:2
        figure('Position',[46         116        1064         989]);
        for x=1:nCon
            yLims = [];
            for y=1:nCon
                axIdx(x,y) = subtightplot(nCon, nCon, (x-1)*nCon + y);
                hold on;
                
                trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{y,1}));      
                posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+2,1:2);
                dirCodes = dirTrialBin( posErr, 8 );
                
                for dirIdx=1:8
                    cDat = triggeredAvg(decVec{x}(:,dimIdx), alignDat.eventIdx(trlIdx(dirCodes==dirIdx)), timeWindow/binMS);
                    mn = mean(cDat);
                    plot(mn,'Color',colors(dirIdx,:),'LineWidth',2);
                end
                
                xlim([1 length(mn)]);
                set(gca,'XTick',[],'YTick',[],'FontSize',16);
                axis tight;
                yLims = [yLims; get(gca,'YLim')];
                if y==1
                    ylabel(allMoveTypeText{outerSessIdx}{x});
                end
                if x==nCon
                    xlabel(allMoveTypeText{outerSessIdx}{y});
                end
                yLimsAll(x,y,:) = get(gca,'YLim');
            end
            
            %for t=1:length(axIdx)
            %    set(axIdx(t),'YLim',yLims(x,:));
            %end
        end
        
        finalLims = zeros(1,2);
        finalLims(1) = min(yLimsAll(:));
        finalLims(2) = max(yLimsAll(:));
        for x=1:nCon
            for y=1:nCon
                set(axIdx(x,y),'YLim',finalLims);
            end
        end
        
        saveas(gcf,[outDir filesep 'CrossDec_' dimNames{dimIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'CrossDec_' dimNames{dimIdx} '.svg'],'svg');
    end

    %%
    %plot trajectories
    for pIdx = 1:size(movTypes,1)
        trlIdx = find(ismember(alignDat.bNumPerTrial, movTypes{pIdx,1}));        
        posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+2,1:2);
        dirCodes = dirTrialBin( posErr, 8 );
        centerRemap = [5 6 7 8 1 2 3 4];
        
        tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2);
        [targList, ~, targCodes] = unique(tPos,'rows');
        centerIdx = find(targCodes==5);
        dirCodes(centerIdx) = centerRemap(dirCodes(centerIdx));
        
        figure
        hold on
        for t=1:length(trlIdx)
            cp = R(trlIdx(t)).cursorPosition';
            plot(cp(:,1), cp(:,2), 'Color', colors(dirCodes(t),:), 'LineWidth', 2);
        end
        targRad = (R(trlIdx(end)).startTrialParams.targetDiameter)/2;
        for t=1:size(targList,1)
            rectangle('Position',[targList(t,1)-targRad, targList(t,2)-targRad, targRad*2, targRad*2],...
                'Curvature',[1 1],'LineWidth',2,'EdgeColor','k');
        end
        axis equal;
        
        saveas(gcf,[outDir filesep 'traj_' allMoveTypeText{outerSessIdx}{pIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'traj_' allMoveTypeText{outerSessIdx}{pIdx} '.svg'],'svg');
    end    
    
    %%
    %PSTH
    allTrlCodes = zeros(length(alignDat.eventIdx),1);
    codeSets = cell(size(movTypes,1),1);
    for pIdx = 1:size(movTypes,1)
        trlIdx = find(ismember(alignDat.bNumPerTrial, movTypes{pIdx,1}));
        posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+2,1:2);
        dirCodes = dirTrialBin( posErr, 8 );
        
        tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2);
        [targList, ~, targCodes] = unique(tPos,'rows');
        outerIdx = find(targCodes~=5);

        tc = targCodes(outerIdx);
        tc(tc>5) = tc(tc>5)-1;
        
        allTrlCodes(trlIdx(outerIdx)) = tc + (pIdx-1)*8;
        codeSets{pIdx} = unique( allTrlCodes(trlIdx(outerIdx)));
    end    
  
    colors = hsv(8)*0.8;
    lineArgs = cell(8,1);
    for c=1:length(lineArgs)
        lineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
    end
    allLineArgs = repmat(lineArgs,size(movTypes,1),1);
    
    codeList = unique(allTrlCodes);
    
    outerTrials = find(allTrlCodes~=0);
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 0;
    psthOpts.neuralData = {alignDat.rawSpikes};
    psthOpts.timeWindow = timeWindow/binMS;
    psthOpts.trialEvents = alignDat.eventIdx(outerTrials);
    psthOpts.trialConditions = allTrlCodes(outerTrials);
    psthOpts.conditionGrouping = codeSets;
    psthOpts.lineArgs = allLineArgs;

    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = outDir;

    featLabels = cell(192,1);
    chanIdx = find(~tooLow);
    for f=1:length(chanIdx)
        featLabels{f} = num2str(chanIdx(f));
    end
    psthOpts.featLabels = featLabels;

    psthOpts.prefix = allSessionNames{outerSessIdx};
    pOut = makePSTH_simple(psthOpts);
    close all;
    
    %%
    %PCA
    crossCon = allCrossCon{outerSessIdx};
    crossPostfix = allCrossPostfix{outerSessIdx};
    movTypeText = allMoveTypeText{outerSessIdx};

    movTypesPlot = movTypes;
    dPCA_out = cell(size(movTypesPlot,1),1);
    for pIdx = 1:size(movTypesPlot,1)
        trlIdx = find(ismember(alignDat.bNumPerTrial, movTypesPlot{pIdx,1}));
        posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+2,1:2);
        dirCodes = dirTrialBin( posErr, 8 );
        
        tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
        [targList, ~, targCodes] = unique(tPos,'rows');
        outerIdx = find(targCodes~=5);
        %outerIdx = true(size(targCodes));

        dPCA_out{pIdx} = apply_pcaMarg_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx((outerIdx))), ...
            dirCodes(outerIdx), timeWindow/binMS, binMS/1000, {'CI','CD'} );
        close(gcf);
    end    

    dPCA_cross = cell(length(crossCon),1);
    for crossIdx = 1:length(crossCon)
        dPCA_cross{crossIdx} = dPCA_out;
        for c=1:length(dPCA_out)
            dPCA_cross{crossIdx}{c}.pca_result.whichMarg = dPCA_out{crossCon(crossIdx)}.pca_result.whichMarg;
            for axIdx=1:20
                for conIdx=1:size(dPCA_cross{crossIdx}{c}.pca_result.Z,2)
                    dPCA_cross{crossIdx}{c}.pca_result.Z(axIdx,conIdx,:) = dPCA_out{crossCon(crossIdx)}.pca_result.W(:,axIdx)' * ...
                        squeeze(dPCA_cross{crossIdx}{c}.featureAverages(:,conIdx,:));
                end
            end
        end            
    end
    
    for plotCross = 1:length(crossPostfix)
        topN = 4;
        plotIdx = 1;

        timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
        yLims = [];
        axHandles=[];   

        figure('Position',[272          82         652        100+(115*length(movTypesPlot))],'Name',crossPostfix{plotCross});
        for pIdx=1:length(movTypesPlot)
            cdIdx = find(dPCA_out{pIdx}.pca_result.whichMarg==1);
            for c=1:topN
                axHandles(plotIdx) = subtightplot(length(movTypesPlot),topN,(pIdx-1)*topN+c);
                hold on

                colors = jet(size(dPCA_out{pIdx}.pca_result.Z,2))*0.8;
                for conIdx=1:size(dPCA_out{pIdx}.pca_result.Z,2)
                    if plotCross==1
                        plot(timeAxis, squeeze(dPCA_out{pIdx}.pca_result.Z(cdIdx(c),conIdx,:)),...
                            'LineWidth',2,'Color',colors(conIdx,:));
                    else
                        plot(timeAxis, squeeze(dPCA_cross{plotCross-1}{pIdx}.pca_result.Z(cdIdx(c),conIdx,:)),...
                            'LineWidth',2,'Color',colors(conIdx,:));
                    end
                end

                axis tight;
                yLims = [yLims; get(gca,'YLim')];
                plotIdx = plotIdx + 1;

                plot(get(gca,'XLim'),[0 0],'k');
                plot([0, 0],[-100, 100],'--k');
                set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

                if pIdx==length(movTypesPlot)
                    xlabel('Time (s)');
                else
                    set(gca,'XTickLabels',[]);
                end
                if pIdx==1
                    title(['Dim ' num2str(c)],'FontSize',11)
                end
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);

                if c==1
                    ylabel(movTypeText{pIdx});
                    %text(-0.05,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
                end
                set(gca,'FontSize',14);
                set(gca,'YLim',yLims(end,:));
            end
        end

        finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
        for p=1:length(axHandles)
           set(axHandles(p), 'YLim', finalLimits);
        end

        saveas(gcf,[outDir filesep 'pca_all' crossPostfix{plotCross} '.png'],'png');
        saveas(gcf,[outDir filesep 'pca_all' crossPostfix{plotCross} '.svg'],'svg');
    end

    %%
    %dPCA, head vs. bci
    crossCon = allCrossCon{outerSessIdx};
    crossPostfix = allCrossPostfix{outerSessIdx};
    movTypeText = allMoveTypeText{outerSessIdx};

    movTypesPlot = movTypes;
    dPCA_out = cell(size(movTypesPlot,1),1);
    for pIdx = 1:size(movTypesPlot,1)
        trlIdx = find(ismember(alignDat.bNumPerTrial, movTypesPlot{pIdx,1}));
        posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+2,1:2);
        dirCodes = dirTrialBin( posErr, 8 );
        
        tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
        [targList, ~, targCodes] = unique(tPos,'rows');
        outerIdx = find(targCodes~=5);
        %outerIdx = true(size(targCodes));
        %outerIdx = outerIdx(1:min(length(outerIdx),24));

        dPCA_out{pIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx((outerIdx))), ...
            dirCodes(outerIdx), timeWindow/binMS, binMS/1000, {'CI','CD'} );
        close(gcf);
    end    

    dPCA_cross = cell(length(crossCon),1);
    for crossIdx = 1:length(crossCon)
        dPCA_cross{crossIdx} = dPCA_out;
        for c=1:length(dPCA_out)
            dPCA_cross{crossIdx}{c}.whichMarg = dPCA_out{crossCon(crossIdx)}.whichMarg;
            for axIdx=1:20
                for conIdx=1:size(dPCA_cross{crossIdx}{c}.Z,2)
                    dPCA_cross{crossIdx}{c}.Z(axIdx,conIdx,:) = dPCA_out{crossCon(crossIdx)}.W(:,axIdx)' * squeeze(dPCA_cross{crossIdx}{c}.featureAverages(:,conIdx,:));
                end
            end
        end            
    end
    
    for plotCross = 1:length(crossPostfix)
        topN = 4;
        plotIdx = 1;

        timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
        yLims = [];
        axHandles=[];   

        figure('Position',[272          82         652        100+(115*length(movTypesPlot))],'Name',crossPostfix{plotCross});
        for pIdx=1:length(movTypesPlot)
            cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
            for c=1:topN
                axHandles(plotIdx) = subtightplot(length(movTypesPlot),topN,(pIdx-1)*topN+c);
                hold on

                colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
                for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                    if plotCross==1
                        plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                    else
                        plot(timeAxis, squeeze(dPCA_cross{plotCross-1}{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                    end
                end

                axis tight;
                yLims = [yLims; get(gca,'YLim')];
                plotIdx = plotIdx + 1;

                plot(get(gca,'XLim'),[0 0],'k');
                plot([0, 0],[-100, 100],'--k');
                set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

                if pIdx==length(movTypesPlot)
                    xlabel('Time (s)');
                else
                    set(gca,'XTickLabels',[]);
                end
                if pIdx==1
                    title(['Dim ' num2str(c)],'FontSize',11)
                end
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);

                if c==1
                    ylabel(movTypeText{pIdx});
                    %text(-0.05,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
                end
                set(gca,'FontSize',14);
                set(gca,'YLim',yLims(end,:));
            end
        end

        finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
        for p=1:length(axHandles)
           set(axHandles(p), 'YLim', finalLimits);
        end

        saveas(gcf,[outDir filesep 'dPCA_all' crossPostfix{plotCross} '.png'],'png');
        saveas(gcf,[outDir filesep 'dPCA_all' crossPostfix{plotCross} '.svg'],'svg');
    end
    
    close all;
end