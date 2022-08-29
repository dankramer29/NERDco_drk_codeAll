datasets = {'t5.2018.01.31'};

for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
    datDir = [paths.dataPath filesep 'BG Processed' filesep datasets{d,1} filesep];

    outDir = [paths.dataPath filesep 'Derived' filesep 'MentalRehearsal' filesep datasets{d,1}];
    mkdir(outDir);
    
    %VMR
    bNums = [18 23];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end
    
    for blockIdx = 1:length(bNums)
        R = allDat{blockIdx}.R;
        trlLen{blockIdx} = nan(length(R),1);
        errAngle{blockIdx} = nan(length(R),1);
        speedProfile{blockIdx} = nan(length(R),3000);
        for t=1:length(R)
            if all(R(t).posTarget==0)
                continue;
            end

            targVec = R(t).posTarget(1:2)/norm(R(t).posTarget(1:2));
            targDist = norm(R(t).posTarget(1:2));
            cursorProgress = targVec'*R(t).cursorPosition(1:2,:);

            halfwayIdx = find(cursorProgress>(targDist/2),1,'first');
            if isempty(halfwayIdx)
                continue;
            end

            cursVec = R(t).cursorPosition(1:2,halfwayIdx) / norm(R(t).cursorPosition(1:2,halfwayIdx));
            errAngle{blockIdx}(t) = abs(acosd(targVec'*cursVec));
            trlLen{blockIdx}(t) = R(t).trialLength;
            
            headVel = [0 0; diff(R(t).cursorPosition(1:2,:)')];
            [B,A] = butter(4, 10/500);
            headVel = filtfilt(B,A,double(headVel));
            headSpeed = matVecMag(headVel,2)*1000;
            speedProfile{blockIdx}(t,1:length(headSpeed)) = headSpeed;
        end
    end
    
    %%
    figure
    hold on;
    plot(errAngle{1},'bo');
    plot(errAngle{2},'ro');
    ylabel('Error Angle at Halfway');
    legend({'Unrehearsed','Rehearsed'});

    [h,p]=ttest2(errAngle{1}, errAngle{2});
    
    %%
    figure
    hold on;
    plot(trlLen{1},'bo');
    plot(trlLen{2},'ro');
    ylabel('Trial Length');
    legend({'Unrehearsed','Rehearsed'});

    [h,p]=ttest2(trlLen{1}, trlLen{2})
    
    %%
    figure
    hold on;
    plot(nanmean(speedProfile{1}),'-b');
    plot(nanmean(speedProfile{2}),'-r');
    ylabel('Speed');
    legend({'Unrehearsed','Rehearsed'});
    
    %%
    %symbol task
    bNums = [25 26];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end
    
    urTimes = [];
    rTimes = [];
    
    figure
    hold on
    for b=1:length(allDat)
        unrehearsedIdx = find(allDat{b}.stream.discrete.numSetsComplete==0 & ~allDat{b}.stream.discrete.isCenterTarget & ...
            allDat{b}.stream.discrete.state==4);
        rehearsedIdx = find(allDat{b}.stream.discrete.numSetsComplete==1 & ~allDat{b}.stream.discrete.isCenterTarget & ...
            allDat{b}.stream.discrete.state==4);
        
        plot(allDat{b}.stream.discrete.acqTime(unrehearsedIdx),'bo');
        plot(allDat{b}.stream.discrete.acqTime(rehearsedIdx),'ro');
        
        urTimes = [urTimes; allDat{b}.stream.discrete.acqTime(unrehearsedIdx)];
        rTimes = [rTimes; allDat{b}.stream.discrete.acqTime(rehearsedIdx)];
    end
    legend({'Unrehearsed','Rehearsed'});
    
    [h,p]=ttest2(double(urTimes), double(rTimes))
    
    %%
    %imagined decoding, different distances
    movSets = {[3],[0],'overt_P','P';
        [3],[0],'overt_M','M';
        [7],[2],'imag_P','P';
        [7],[2],'imag_M','M';
        [10 11],[1],'WIA-W_P','P';
        [10 11],[1],'WIA-W_M','M';
        [10,11],[2],'WIA-I_P','P';
        [10,11],[2],'WIA-I_M','M';
        [10,11],[3],'WIA-A_P','P';
        [10,11],[3],'WIA-A_M','M'};
    
    packagedDat = cell(size(movSets,1),4);
    
    for setIdx = 1:size(movSets,1)
        disp(['--' num2str(setIdx) '--']);
        
        bNums = movSets{setIdx,1};
        allDat = cell(length(bNums),1);
        for b=1:length(bNums)
            dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
            allDat{b} = load(dataPath);
        end
        
        allR = [];
        for x=1:length(allDat)
            allR = [allR, allDat{x}.R];
        end
        
        wiaCodes = zeros(length(allR),1);
        goCue = zeros(length(allR),1);
        for t=1:length(allR)
            wiaCodes(t) = allR(t).startTrialParams.wiaCode;
            allR(t).blockNum=1;
            if ~isempty(allR(t).timeGoCue)
                goCue(t) = allR(t).timeGoCue;
            end
        end
        goCue = round(goCue/20);
        
        R = allR;
        rtIdxAll = zeros(length(R),1);
        for t=1:length(R)
            %RT
            headPos = double(R(t).windowsMousePosition');
            headVel = [0 0; diff(headPos)];
            [B,A] = butter(4, 10/500);
            headVel = filtfilt(B,A,headVel);
            headSpeed = matVecMag(headVel,2)*1000;
            R(t).headSpeed = headSpeed;
            R(t).maxSpeed = max(headSpeed);
        end

        tPos = [R.posTarget]';
        tPos = tPos(:,1:2);
        [targList,~,targCodes] = unique(tPos,'rows');
        ms = [R.maxSpeed];
        avgMS = zeros(length(targList),1);
        for t=1:length(targList)
            avgMS(t) = mean(ms(targCodes==t));
        end

        for t=1:length(R)
            useThresh = max(avgMS(targCodes(t))*0.1,0.035);

            rtIdx = find(R(t).headSpeed>useThresh,1,'first');
            if isempty(rtIdx) || rtIdx<(goCue(t)+150)
                rtIdx = 21;
                rtIdxAll(t) = nan;
            else
                rtIdxAll(t) = rtIdx;
            end       
            R(t).rtTime = rtIdx;
        end
        rtAdjusted = rtIdxAll - goCue*20;

        smoothWidth = 0;
        datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
        binMS = 20;
        unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
        smoothSpikes = gaussSmooth_fast(unrollDat.zScoreSpikes, 6);

        intendedDir = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);
        intendedDir(isnan(intendedDir))=0;
        for t=1:length(allR)
            prepIdx = unrollDat.trialEpochs(t,1):(unrollDat.trialEpochs(t,1)+goCue(t));
            intendedDir(prepIdx,:) = repmat(unrollDat.currentTarget(prepIdx(end)+5,1:2) - unrollDat.cursorPosition(prepIdx(end),1:2),length(prepIdx),1);
        end

        useTrl = find(wiaCodes==movSets{setIdx,2} & [allR.isSuccessful]' & goCue>1);
        
        if strcmp(movSets{setIdx,3}(1:3),'WIA')
            loopIdx_mov = expandEpochIdx([unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+20, unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+50]);
            loopIdx_prep = expandEpochIdx([unrollDat.trialEpochs(useTrl,1)+25, unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)]);
        else
            loopIdx_mov = expandEpochIdx([unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+10, unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+50]);
            loopIdx_prep = expandEpochIdx([unrollDat.trialEpochs(useTrl,1)+10, unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)]);
        end
        
        packagedDat{setIdx,1} = smoothSpikes;
        packagedDat{setIdx,2} = intendedDir;
        if strcmp(movSets{setIdx,4},'M')
            packagedDat{setIdx,3} = loopIdx_mov;
        elseif strcmp(movSets{setIdx,4},'P')
            packagedDat{setIdx,3} = loopIdx_prep;
        end
        
        packagedDat{setIdx,4} = [unrollDat.trialEpochs(useTrl,1) + goCue(useTrl), ...
            round(unrollDat.currentTarget(unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+10,1:2))];
    end
    
    %single-channel fitting
    singleChan = cell(length(packagedDat),2);
    for setIdx = 1:size(movSets,1)
        trainFun = @(pred, resp)(buildLinFilts(resp, pred, 'standard'));
        decoderFun = @(dec, pred)(pred*dec);
        testFun = @(pred, truth)(diag(corr(pred, truth)));
        nFolds = 10;

        loopIdx = packagedDat{setIdx,3};
        [ perf decoder predVals respVals] = crossVal( packagedDat{setIdx,2}(loopIdx,:), packagedDat{setIdx,1}(loopIdx,:), ...
            trainFun, testFun, decoderFun, nFolds, []);
        singleChan{setIdx,1} = getDecoderPerformance(predVals, packagedDat{setIdx,1}(loopIdx,:) ,'R2');
        singleChan{setIdx,2} = trainFun(packagedDat{setIdx,2}(loopIdx,:), packagedDat{setIdx,1}(loopIdx,:));
    end
    
    %all R2
    comparisonPairs = {[1 9],[2 10],[3 7],[4 8]};
    
    figure
    for c=1:length(comparisonPairs)
        subplot(2,2,c);
        hold on
        
        Rx = singleChan{comparisonPairs{c}(1),1};
        Ry = singleChan{comparisonPairs{c}(2),1};
        Rx(Rx<0) = 0;
        Ry(Ry<0) = 0;
        
        plot(Rx, Ry,'o');
        xlabel(movSets{comparisonPairs{c}(1),3});
        ylabel(movSets{comparisonPairs{c}(2),3});
        
        ylim([0 0.4]);
        xlim([0 0.4]);
        plot([0 0.4],[0 0.4],'--k');
        set(gca,'FontSize',16);
    end
    
    %avg R2 plot
    avgR2 = zeros(length(singleChan),1);
    for setIdx=1:length(singleChan)
        R2 = singleChan{setIdx,1};
        R2(R2<0) = 0;
        avgR2(setIdx) = mean(R2);
    end
    
    figure
    bar(avgR2);
    set(gca,'XTick',1:length(singleChan),'XTickLabel',movSets(:,3),'XTickLabelRotation',45);
    set(gca,'FontSize',16);
    ylabel('Avg R2');
    saveas(gcf,[outDir filesep 'avgR2' '.png'],'png');
    saveas(gcf,[outDir filesep 'avgR2' '.fig'],'fig');
    
    %PD correlations
    crossPD = zeros(size(packagedDat,1));
    for rowIdx=1:size(packagedDat,1)
        for colIdx=1:size(packagedDat,1)
            if rowIdx==colIdx
                continue;
            end
            sigIdx = singleChan{rowIdx,1}>0.01 | singleChan{colIdx,1}>0.01;
            crossPD(rowIdx,colIdx) = mean(diag(corr(singleChan{rowIdx,2}(:,sigIdx)', singleChan{colIdx,2}(:,sigIdx)')));
        end
    end
    
    figure
    imagesc(crossPD);
    set(gca,'XTick',1:length(movSets),'XTickLabel',movSets(:,3),'XTickLabelRotation',45);
    set(gca,'YTick',1:length(movSets),'YTickLabel',movSets(:,3));
    set(gca,'FontSize',16);
    colorbar;
    saveas(gcf,[outDir filesep 'PDCorr' '.png'],'png');
    saveas(gcf,[outDir filesep 'PDCorr' '.fig'],'fig');
    
    %cross-decoding R
    crossPV = cell(size(packagedDat,1), size(packagedDat,1));
    crossAvg = cell(size(packagedDat,1));
    crossR = zeros(size(packagedDat,1));
    binIdx = -25:50;
    targList = [0, 409; 0, -409; 409 0; -409 0];
    dimIdx = [2 2 1 1];
                
    for rowIdx=1:size(packagedDat,1)
        for colIdx=1:size(packagedDat,1)
            if rowIdx==colIdx
                %cross-validate within condition
                trainFun = @(pred, resp)(buildTopNDecoder(pred, resp, 40, 'inverseLinear'));
                decoderFun = @applyTopNDecoder_unitGain;
                testFun = @(pred, truth)(diag(corr(pred, truth)));
                nFolds = 10;
                
                loopIdx = packagedDat{rowIdx,3};
                [ perf, decoder, predVals, respVals, foldTestIdx] = crossVal( packagedDat{rowIdx,1}(loopIdx,:), packagedDat{rowIdx,2}(loopIdx,:), ...
                    trainFun, testFun, decoderFun, nFolds, []);
                crossR(rowIdx, colIdx) = mean(diag(corr(predVals, packagedDat{rowIdx,2}(loopIdx,:))));
                
                allPV = zeros(size(packagedDat{rowIdx,1},1),2);
                allPV(loopIdx,:) = predVals;
                undoneIdx = setdiff(1:size(allPV,1), loopIdx);
                for x=1:length(undoneIdx)
                    [~,minIdx] = min(abs(undoneIdx(x)-loopIdx(foldTestIdx(:,1))));
                    allPV(undoneIdx(x),:) = applyTopNDecoder(decoder{foldTestIdx(minIdx,2)}, ...
                        packagedDat{rowIdx,1}(undoneIdx(x),:));
                end
                crossPV{rowIdx, colIdx} = allPV;
                
                crossAvg{rowIdx, colIdx} = zeros(length(binIdx),4);
                for t=1:size(targList,1)
                    trlIdx = find(ismember(packagedDat{rowIdx,4}(:,2:3), targList(t,:),'rows'));
                    tmp = triggeredAvg(allPV(:,dimIdx(t)), packagedDat{rowIdx,4}(trlIdx,1), [binIdx(1), binIdx(end)]);
                    crossAvg{rowIdx, colIdx}(:,t) = mean(tmp);
                end
            else
                %apply cross-condition
                loopIdx = packagedDat{rowIdx,3};
                dec = buildTopNDecoder(packagedDat{rowIdx,1}(loopIdx,:), packagedDat{rowIdx,2}(loopIdx,:), 40, 'inverseLinear');
                
                decVel = applyTopNDecoder_unitGain(dec, packagedDat{colIdx,1});
                testIdx = packagedDat{colIdx,3};
                crossR(rowIdx, colIdx) = mean(diag(corr(decVel(testIdx,:), packagedDat{colIdx,2}(testIdx,:))));
                
                crossAvg{rowIdx, colIdx} = zeros(length(binIdx),4);
                for t=1:size(targList,1)
                    trlIdx = find(ismember(packagedDat{colIdx,4}(:,2:3), targList(t,:),'rows'));
                    tmp = triggeredAvg(decVel(:,dimIdx(t)), packagedDat{colIdx,4}(trlIdx,1), [binIdx(1), binIdx(end)]);
                    crossAvg{rowIdx, colIdx}(:,t) = mean(tmp);
                end
            end
        end
    end
    
    plotSets = {[1:4],[1:2:10],[2:2:10],[1:10]};
    plotSetNames = {'Overt_vs_Imag','PrepOnly','OvertOnly','All'};
    
    for p=1:length(plotSets)
        figure
        imagesc(crossR(plotSets{p},plotSets{p}));
        set(gca,'XTick',1:length(plotSets{p}),'XTickLabel',movSets(plotSets{p},3),'XTickLabelRotation',45);
        set(gca,'YTick',1:length(plotSets{p}),'YTickLabel',movSets(plotSets{p},3));
        set(gca,'FontSize',16);
        colorbar;

        saveas(gcf,[outDir filesep 'XVal R' plotSetNames{p} '.png'],'png');
        saveas(gcf,[outDir filesep 'XVal R' plotSetNames{p} '.fig'],'fig');
    end
    
    dimToPlot = [1 2];
    for p=1:length(plotSets)
        allLims = cell(length(plotSets{p}));
        axHandles = zeros(length(plotSets{p}));
        
        figure('Position',[680   354   897   744]);
        for rowIdx=1:length(plotSets{p})
            for colIdx=1:length(plotSets{p})
                axHandles(rowIdx, colIdx) = subtightplot(length(plotSets{p}), length(plotSets{p}), (rowIdx-1)*length(plotSets{p}) + colIdx);
                hold on;
                
                plot(crossAvg{plotSets{p}(rowIdx), plotSets{p}(colIdx)}(:,dimToPlot),'LineWidth',2);
                set(gca,'XTick',[],'YTick',[]);
                axis tight;
                allLims{rowIdx, colIdx} = get(gca,'YLim');
                
                if rowIdx==length(plotSets{p})
                    xlabel(movSets{plotSets{p}(colIdx),3});
                end
                if colIdx==1
                    ylabel(movSets{plotSets{p}(rowIdx),3});
                end
                set(gca,'FontSize',16);
            end
        end
        
        cLims = vertcat(allLims{:});
        finalLims = [min(cLims(:,1)), max(cLims(:,2))];
        for rowIdx=1:length(plotSets{p})
            for colIdx=1:length(plotSets{p})
                set(axHandles(rowIdx, colIdx), 'YLim', finalLims);
                plot(axHandles(rowIdx, colIdx), [25 25], finalLims, '--k', 'LineWidth', 2);
            end
        end
        
        saveas(gcf,[outDir filesep 'XVal DecVel' plotSetNames{p} '.png'],'png');
        saveas(gcf,[outDir filesep 'XVal DecVel' plotSetNames{p} '.fig'],'fig');
    end

    %%
    %distance decoding
    bNums = [7];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end

    allR = [];
    for x=1:length(allDat)
        allR = [allR, allDat{x}.R];
    end

    eyePos = [allR.windowsPC1LeftEye]';
    
    wiaCodes = zeros(length(allR),1);
    goCue = zeros(length(allR),1);
    for t=1:length(allR)
        wiaCodes(t) = allR(t).startTrialParams.wiaCode;
        allR(t).blockNum=1;
        if ~isempty(allR(t).timeGoCue)
            goCue(t) = allR(t).timeGoCue;
        end
    end
    goCue = round(goCue/20);

    smoothWidth = 0;
    datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
    smoothSpikes = gaussSmooth_fast(unrollDat.zScoreSpikes, 6);

    intendedDir = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);
    intendedDir(isnan(intendedDir))=0;
    for t=1:length(allR)
        prepIdx = unrollDat.trialEpochs(t,1):(unrollDat.trialEpochs(t,1)+goCue(t));
        intendedDir(prepIdx,:) = repmat(unrollDat.currentTarget(prepIdx(end)+5,1:2) - unrollDat.cursorPosition(prepIdx(end),1:2),length(prepIdx),1);
        
        moveIdx = (unrollDat.trialEpochs(t,1)+goCue(t)):(unrollDat.trialEpochs(t,2));
        intendedDir(moveIdx,:) = repmat(unrollDat.currentTarget(moveIdx(1)+5,1:2) - unrollDat.cursorPosition(moveIdx(1),1:2),length(moveIdx),1);
    end

    useTrl = find(wiaCodes==2 & [allR.isSuccessful]' & goCue>1);
    loopIdx_mov = expandEpochIdx([unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+10, unrollDat.trialEpochs(useTrl,2)]);
        
    trainFun = @(pred, resp)(buildTopNDecoder(pred, resp, 40, 'inverseLinear'));
    decoderFun = @applyTopNDecoder;
    testFun = @(pred, truth)(diag(corr(pred, truth)));
    nFolds = 10;

    [ perf decoder predVals respVals] = crossVal( smoothSpikes(loopIdx_mov,:), intendedDir(loopIdx_mov,:), ...
        trainFun, testFun, decoderFun, nFolds, []);
                
    allPredVals = zeros(size(smoothSpikes,1),2);
    allPredVals(loopIdx_mov,:) = predVals;
    interIdx = setdiff(1:length(allPredVals), loopIdx_mov);
    allPredVals(interIdx,:) = applyTopNDecoder(decoder{1}, smoothSpikes(interIdx,:));
    
    endPos = zeros(length(useTrl),2);
    for t=1:length(useTrl)
        loopIdx = expandEpochIdx([unrollDat.trialEpochs(useTrl(t),1)+goCue(useTrl(t))+10, unrollDat.trialEpochs(useTrl(t),2)]);
        endPos(t,:) = sum(allPredVals(loopIdx,:));
    end
    
    targPosByTrial = round(unrollDat.currentTarget(unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+5,1:2));
    [distList,~,distCodes] = unique(matVecMag(targPosByTrial,2));
    [dirList, ~, dirCodes] = unique(atan2(targPosByTrial(:,2), targPosByTrial(:,1)),'rows');
    [tList,~,tCodes] = unique(targPosByTrial,'rows');
    
    colors = hsv(4)*0.8;
    cDat = cell(4,1);
    for codeIdx=1:4
        trlIdx = useTrl(dirCodes==codeIdx);
        cDat{codeIdx} = triggeredAvg(allPredVals, unrollDat.trialEpochs(trlIdx,1)+goCue(trlIdx), [-100 200]);
    end
    
    figure
    for dimIdx=1:2
        subplot(1,2,dimIdx);
        hold on;
        for codeIdx=1:4
            tmp = squeeze(nanmean(cDat{codeIdx},1));
            plot((-100:200)*0.02,tmp(:,dimIdx),'Color',colors(codeIdx,:),'LineWidth',2);
        end
        plot([0 0],[-500 500],'--k','LineWidth',2);
    end
    
    %%
    if length(distList)==2
        cList = hsv(4)*0.8;
        colors = [cList(3,:); cList(3,:); cList(4,:); cList(4,:); cList(2,:); cList(2,:); cList(1,:); cList(1,:)];
    else
        colors = hsv(4)*0.8;
    end
    endPos = zscore(endPos);
    
    figure
    hold on
    for t=1:length(endPos)
        codeIdx = tCodes(t);
        dist = norm(tList(codeIdx,:));
        if dist<200
            plot(endPos(t,1), endPos(t,2), 'Color', colors(codeIdx,:), 'Marker','o','MarkerSize',8);
        else
            plot(endPos(t,1), endPos(t,2), 'Color', colors(codeIdx,:), 'Marker','o','MarkerSize',8,'MarkerFaceColor',colors(codeIdx,:));
        end
    end
    
    saveas(gcf,[outDir filesep 'Imag_Dist_All.png'],'png');
    saveas(gcf,[outDir filesep 'Imag_Dist_All.fig'],'fig');
    
    anova1(matVecMag(endPos,2), distCodes);
    
    saveas(gcf,[outDir filesep 'Imag_Dist_Anova.png'],'png');
    saveas(gcf,[outDir filesep 'Imag_Dist_Anova.fig'],'fig');
    
    figure
    hold on
    for t=1:8
        codeIdx = tCodes==t;
        dist = norm(tList(t,:));
        if dist<200
            plot(mean(endPos(codeIdx,1)), mean(endPos(codeIdx,2)), 'Color', colors(t,:), 'Marker','o','MarkerSize',8);
        else
            plot(mean(endPos(codeIdx,1)), mean(endPos(codeIdx,2)), 'Color', colors(t,:), 'Marker','o','MarkerSize',8,'MarkerFaceColor',colors(t,:));
        end
    end
    
    saveas(gcf,[outDir filesep 'Imag_Dist_Mean.png'],'png');
    saveas(gcf,[outDir filesep 'Imag_Dist_Mean.fig'],'fig');
    
    farTargTrl = find(distCodes==2);
    
    figure
    hold on
    for t=1:length(farTargTrl)
        dirCode = dirCodes(farTargTrl(t));
        
        subplot(2,2,dirCode);
        hold on;
        loopIdx = (unrollDat.trialEpochs(useTrl(farTargTrl(t)),1)+goCue(useTrl(farTargTrl(t)))-50):unrollDat.trialEpochs(useTrl(farTargTrl(t)),2);
        timeAxis = (-50):(-50+length(loopIdx)-1);
        plot(timeAxis, unrollDat.windowsPC1LeftEye(loopIdx,1),'Color','b','LineWidth',2);
        plot(timeAxis, unrollDat.windowsPC1LeftEye(loopIdx,2),'Color','r','LineWidth',2);
        title(num2str(dirList(dirCode)));
    end
    
    arrows = [0, -1; 1, 0; 0, 1; -1, 0];
    colors = hsv(4)*0.8;
    figure
    hold on;
    for a=1:size(arrows,1)
        quiver(0,0,arrows(a,1),arrows(a,2),'LineWidth',2,'Color',colors(a,:));
    end
    
    %%
    %eye position for overt & imagined trials
    bNums = [3 7];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end

    allR = [];
    for x=1:length(allDat)
        allR = [allR, allDat{x}.R];
    end
    
    wiaCodes = zeros(length(allR),1);
    goCue = zeros(length(allR),1);
    for t=1:length(allR)
        wiaCodes(t) = allR(t).startTrialParams.wiaCode;
        allR(t).blockNum=1;
        if ~isempty(allR(t).timeGoCue)
            goCue(t) = allR(t).timeGoCue;
        end
    end
    goCue = round(goCue/20);

    smoothWidth = 0;
    datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
    
    useTrl = find([allR.isSuccessful]' & goCue>1);
    targPosByTrial = round(unrollDat.currentTarget(unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+5,1:2));
    [distList,~,distCodes] = unique(matVecMag(targPosByTrial,2));
    [dirList, ~, dirCodes] = unique(atan2(targPosByTrial(:,2), targPosByTrial(:,1)),'rows');
    [tList,~,tCodes] = unique(targPosByTrial,'rows');
    
    dimIdx = [2 1 2 1];
    for codeIdx=1:4
        realTrl = find((dirCodes==codeIdx) & (distCodes==2) & wiaCodes(useTrl)==0);
        imagTrl = find((dirCodes==codeIdx) & (distCodes==2) & wiaCodes(useTrl)==2);
    
        concatReal = triggeredAvg(unrollDat.windowsPC1LeftEye, unrollDat.trialEpochs(useTrl(realTrl),1)+goCue(useTrl(realTrl)), [-25, 75]);
        imagReal = triggeredAvg(unrollDat.windowsPC1LeftEye, unrollDat.trialEpochs(useTrl(imagTrl),1)+goCue(useTrl(imagTrl)), [-25, 75]);

        figure
        subplot(1,2,1);
        hold on
        plot((-25:75)*0.02, squeeze(mean(concatReal,1)),'b');
        plot((-25:75)*0.02, squeeze(mean(imagReal,1)),'r');

        subplot(1,2,2);
        hold on
        plot((-25:75)*0.02, squeeze(concatReal(:,:,dimIdx(codeIdx))),'b');
        plot((-25:75)*0.02, squeeze(imagReal(:,:,dimIdx(codeIdx))),'r');
    end
    
    %%
    %eye position for overt & imagined trials
    bNums = [10 11];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end

    allR = [];
    for x=1:length(allDat)
        allR = [allR, allDat{x}.R];
    end
    
    wiaCodes = zeros(length(allR),1);
    goCue = zeros(length(allR),1);
    for t=1:length(allR)
        wiaCodes(t) = allR(t).startTrialParams.wiaCode;
        allR(t).blockNum=1;
        if ~isempty(allR(t).timeGoCue)
            goCue(t) = allR(t).timeGoCue;
        end
    end
    goCue = round(goCue/20);

    smoothWidth = 0;
    datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
    
    useTrl = find([allR.isSuccessful]' & goCue>1);
    targPosByTrial = round(unrollDat.currentTarget(unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+5,1:2));
    [distList,~,distCodes] = unique(matVecMag(targPosByTrial,2));
    [dirList, ~, dirCodes] = unique(atan2(targPosByTrial(:,2), targPosByTrial(:,1)),'rows');
    [tList,~,tCodes] = unique(targPosByTrial,'rows');
    
    dimIdx = [2 1 2 1];
    for codeIdx=1:4
        realTrl = find((dirCodes==codeIdx) & wiaCodes(useTrl)==1);
        imagTrl = find((dirCodes==codeIdx) & wiaCodes(useTrl)==2);
        watchTrl = find((dirCodes==codeIdx) & wiaCodes(useTrl)==3); 
        
        concatReal = triggeredAvg(unrollDat.windowsPC1LeftEye, unrollDat.trialEpochs(useTrl(realTrl),1)+goCue(useTrl(realTrl)), [-25, 200]);
        concatImag = triggeredAvg(unrollDat.windowsPC1LeftEye, unrollDat.trialEpochs(useTrl(imagTrl),1)+goCue(useTrl(imagTrl)), [-25, 200]);
        concatWatch = triggeredAvg(unrollDat.windowsPC1LeftEye, unrollDat.trialEpochs(useTrl(watchTrl),1)+goCue(useTrl(watchTrl)), [-25, 200]);

        figure
        subplot(1,2,1);
        hold on
        plot((-25:200)*0.02, squeeze(mean(concatReal,1)),'b');
        plot((-25:200)*0.02, squeeze(mean(concatImag,1)),'r');
        plot((-25:200)*0.02, squeeze(mean(concatWatch,1)),'g');

        subplot(1,2,2);
        hold on
        plot((-25:200)*0.02, squeeze(concatReal(:,:,dimIdx(codeIdx))),'b');
        plot((-25:200)*0.02, squeeze(concatImag(:,:,dimIdx(codeIdx))),'r');
        plot((-25:200)*0.02, squeeze(concatWatch(:,:,dimIdx(codeIdx))),'g');
    end
    
    %%
    %can we recover structure of task with hmm?
    
    
    %%
    %sequence task
    
    %build direction decoder from imagined movement data
    bNums = [7];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end
    
    allR = [allDat{1}.R];
    wiaCodes = zeros(length(allR),1);
    goCue = zeros(length(allR),1);
    for t=1:length(allR)
        wiaCodes(t) = allR(t).startTrialParams.wiaCode;
        allR(t).blockNum=1;
        if ~isempty(allR(t).timeGoCue)
            goCue(t) = allR(t).timeGoCue;
        end
    end
    useTrl = find(wiaCodes==2 & [allR.isSuccessful]' & goCue>1);
    goCue = round(goCue/20);
    
    smoothWidth = 0;
    datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
    
    loopIdx = expandEpochIdx([unrollDat.trialEpochs(imaginedTrl,1)+goCue(imaginedTrl)+10, unrollDat.trialEpochs(imaginedTrl,1)+goCue(imaginedTrl)+50]);
    intendedDir = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);
    intendedDir = bsxfun(@times, intendedDir, 1./matVecMag(intendedDir,2));
    intendedDir(isnan(intendedDir))=0;
    
    decCoef = buildLinFilts(intendedDir(loopIdx,:), unrollDat.zScoreSpikes(loopIdx,:), 'inverseLinear');
    decVel = unrollDat.zScoreSpikes * decCoef;
    
    figure
    hold on
    plot(gaussSmooth_fast(decVel(loopIdx,1),6));
    plot(intendedDir(loopIdx,1),'LineWidth',2);
    
    [pxx,f] = periodogram(decVel,[],[],50);
    [B,A] = butter(3,0.1);
    smoothPxx = filtfilt(B,A,pxx);
    
    figure
    plot(f, smoothPxx);
    xlim([0 2]);
    
       
    decPos = cumsum(decVel);
    figure; 
    plot(decPos(:,1), decPos(:,2),'-o');
    
    lastIdx = 1:100;
    figure
    for x=1:length(decPos)
        clf
        hold on;
        plot(decPos(lastIdx,1), decPos(lastIdx,2));
        plot(decPos(lastIdx(end),1), decPos(lastIdx(end),2), 'o');
        lastIdx = lastIdx + 1;
        xlim([-500 100]);
        ylim([-200 200]);
        drawnow;
    end
    %%
    %apply decoder to VMR rehearsal time period
    bNums = [22];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end
    stream = allDat{1}.stream;
    
    nMS = 20;
    rawSpikes = [stream.spikeRaster, stream.spikeRaster2];
    nBins = floor(length(rawSpikes)/nMS);
    binSpikes = zeros(nBins, size(rawSpikes,2));
    binIdx = 1:nMS;
    for n=1:nBins
        binSpikes(n,:) = sum(rawSpikes(binIdx,:));
        binIdx = binIdx + nMS;
    end
    
    allSpikes = gaussSmooth_fast(binSpikes, 6);
    zSpikes = bsxfun(@plus, allSpikes, -mean(allSpikes));
    zSpikes = bsxfun(@times, zSpikes, 1./unrollDat.spikesStd);
    decVel = zSpikes * decCoef;
    
    figure
    plot(decVel);
    
    [pxx,f] = periodogram(decVel,[],[],50);
    [B,A] = butter(3,0.1);
    smoothPxx = filtfilt(B,A,pxx);
    
    figure
    plot(f, smoothPxx);
    xlim([0 2]);
    
    decPos = cumsum(decVel);
    figure; 
    plot(decPos(:,1), decPos(:,2),'-o');
    
    lastIdx = 1:100;
    figure
    for x=1:length(decPos)
        clf
        hold on;
        plot(decPos(lastIdx,1), decPos(lastIdx,2));
        plot(decPos(lastIdx(end),1), decPos(lastIdx(end),2), 'o');
        lastIdx = lastIdx + 1;
        xlim([-500 100]);
        ylim([-200 200]);
        drawnow;
    end
    
    %%
    figure; 
    plot(cumsum(decVel));
    
    theta = linspace(0,2*pi,9);
    theta = theta(1:8)';
    pattern = [cos(theta), sin(theta)];
    
    classDir = zeros(length(decVel),1);
    for t=1:length(decVel)
        dist = sqrt(sum(bsxfun(@plus, pattern, -decVel(t,:)).^2,2));
        [~,classDir(t)] = min(dist);
    end
    
    figure;
    imagesc(allSpikes');
    
    figure;
    imagesc(binSpikes');
    
    %%
    %apply decoder to rehearsal time period
    bNums = [29];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end
    stream = allDat{1}.stream;
    
    seq = squeeze(stream.discrete.targetSeq);
    seq = seq(1,1:2:16);
    rehearseIdx = find(stream.continuous.state==2);
    
    nMS = 20;
    rawSpikes = [stream.spikeRaster, stream.spikeRaster2];
    nBins = floor(length(rawSpikes)/nMS);
    for n=1:nBins
        
    end
    
    allSpikes = gaussSmooth_fast(,100);
    zSpikes = bsxfun(@plus, allSpikes, -mean(allSpikes));
    zSpikes = bsxfun(@times, zSpikes, 1./unrollDat.spikesStd);
    decVel = zSpikes * decCoef;
    
    figure
    plot(decVel(rehearseIdx,:));
    
    figure; 
    plot(cumsum(decVel(rehearseIdx,:)));
    
    theta = linspace(0,2*pi,9);
    theta = theta(1:8)';
    pattern = [cos(theta), sin(theta)];
    
    classDir = zeros(length(rehearseIdx),1);
    for t=1:length(rehearseIdx)
        dist = sqrt(sum(bsxfun(@plus, pattern, -decVel(t,:)).^2,2));
        [~,classDir(t)] = min(dist);
    end
    
end

%%
%todo:
%add eye position saver to symbol and sequence tasks
%fix no pause bug for WIA tasks
%fix speed cap for sequence tasks