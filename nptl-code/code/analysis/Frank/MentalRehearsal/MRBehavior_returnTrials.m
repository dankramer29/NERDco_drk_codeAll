datasets = {'t5.2018.02.09'};

for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
    datDir = [paths.dataPath filesep 'BG Processed' filesep datasets{d,1} filesep];

    outDir = [paths.dataPath filesep 'Derived' filesep 'MentalRehearsal' filesep datasets{d,1}];
    mkdir(outDir);
        
    %%
    %imagined decoding, different distances
    movSets = {[4 8],[0],'overt_P','P';
        [4 8],[0],'overt_M','M';
        [5 6 9],[2],'imag_P','P';
        [5 6 9],[2],'imag_M','M';
        [7 11],[1],'watch_P','P';
        [7 11],[1],'watch_M','M'};
    
    packagedDat = cell(size(movSets,1),5);
    spikeStats = cell(size(movSets,1),1);
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
        datFields = {'windowsPC1GazePoint','windowsPC1HeadRot','windowsMousePosition','cursorPosition','currentTarget','xk'};
        binMS = 20;
        unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
        smoothSpikes = gaussSmooth_fast(unrollDat.zScoreSpikes, 6);
        spikeStats{setIdx} = unrollDat.spikesStd;
        
        intendedDir = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);
        intendedDir(isnan(intendedDir))=0;
        for t=1:length(allR)
            prepIdx = unrollDat.trialEpochs(t,1):(unrollDat.trialEpochs(t,1)+goCue(t));
            intendedDir(prepIdx,:) = repmat(unrollDat.currentTarget(prepIdx(end)+5,1:2) - unrollDat.cursorPosition(prepIdx(end),1:2),length(prepIdx),1);
        end

        if strcmp(movSets{setIdx,3},'overt_M') || strcmp(movSets{setIdx,3},'overt_P')
            useTrl = find(wiaCodes==movSets{setIdx,2} & [allR.isSuccessful]' & goCue>1 & rtAdjusted<650 & rtAdjusted>200);
        else
            useTrl = find(wiaCodes==movSets{setIdx,2} & [allR.isSuccessful]' & goCue>1);
        end
        
        loopIdx_mov = expandEpochIdx([unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+10, unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+50]);
        loopIdx_prep = expandEpochIdx([unrollDat.trialEpochs(useTrl,1)+10, unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)]);
        
        packagedDat{setIdx,1} = smoothSpikes;
        packagedDat{setIdx,2} = intendedDir;
        if strcmp(movSets{setIdx,4},'M')
            packagedDat{setIdx,3} = loopIdx_mov;
        elseif strcmp(movSets{setIdx,4},'P')
            packagedDat{setIdx,3} = loopIdx_prep;
        end
        
        packagedDat{setIdx,4} = [unrollDat.trialEpochs(useTrl,1) + goCue(useTrl), ...
            round(unrollDat.currentTarget(unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+10,1:2))];
        
        [B,A] = butter(4, 6/25);
        packagedDat{setIdx,5} = filtfilt(B,A,[0 0; diff(unrollDat.windowsMousePosition)]);
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
    allDec = cell(size(packagedDat,1),1);
    binIdx = -25:50;
    theta = linspace(0,2*pi,9)';
    theta(end) = [];
    targList = round(409*[cos(theta), sin(theta)]);
                
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
                    allPV(undoneIdx(x),:) = applyTopNDecoder_unitGain(decoder{foldTestIdx(minIdx,2)}, ...
                        packagedDat{rowIdx,1}(undoneIdx(x),:));
                end
                crossPV{rowIdx, colIdx} = allPV;
                
                crossAvg{rowIdx, colIdx} = zeros(length(binIdx),size(targList,1),2);
                for t=1:size(targList,1)
                    trlIdx = find(ismember(packagedDat{rowIdx,4}(:,2:3), targList(t,:),'rows'));
                    tmp = triggeredAvg(allPV, packagedDat{rowIdx,4}(trlIdx,1), [binIdx(1), binIdx(end)]);
                    crossAvg{rowIdx, colIdx}(:,t,:) = squeeze(nanmean(tmp,1));
                end
            else
                %apply cross-condition
                loopIdx = packagedDat{rowIdx,3};
                dec = buildTopNDecoder(packagedDat{rowIdx,1}(loopIdx,:), packagedDat{rowIdx,2}(loopIdx,:), 40, 'inverseLinear');
                
                decVel = applyTopNDecoder_unitGain(dec, packagedDat{colIdx,1});
                testIdx = packagedDat{colIdx,3};
                crossR(rowIdx, colIdx) = mean(diag(corr(decVel(testIdx,:), packagedDat{colIdx,2}(testIdx,:))));
                
                crossAvg{rowIdx, colIdx} = zeros(length(binIdx),size(targList,1),2);
                for t=1:size(targList,1)
                    trlIdx = find(ismember(packagedDat{colIdx,4}(:,2:3), targList(t,:),'rows'));
                    tmp = triggeredAvg(decVel, packagedDat{colIdx,4}(trlIdx,1), [binIdx(1), binIdx(end)]);
                    crossAvg{rowIdx, colIdx}(:,t,:) = squeeze(nanmean(tmp,1));
                end
                
                allDec{rowIdx} = dec;
            end
        end
    end
    
    plotSets = {[1:6]};
    plotSetNames = {'All'};
    
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
   
    dimNames = {'X','Y'};
    for dimIdx=1:2
        colors = hsv(8)*0.8;
        for p=1:length(plotSets)
            allLims = cell(length(plotSets{p}));
            axHandles = zeros(length(plotSets{p}));

            figure('Position',[680   354   897   744]);
            for rowIdx=1:length(plotSets{p})
                for colIdx=1:length(plotSets{p})
                    axHandles(rowIdx, colIdx) = subtightplot(length(plotSets{p}), length(plotSets{p}), (rowIdx-1)*length(plotSets{p}) + colIdx);
                    hold on;

                    for c=1:size(colors,1)
                        plot(squeeze(crossAvg{plotSets{p}(rowIdx), plotSets{p}(colIdx)}(:,c,dimIdx)),'LineWidth',2,'Color',colors(c,:));
                    end
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

            saveas(gcf,[outDir filesep 'XVal DecVel ' dimNames{dimIdx} '.png'],'png');
            saveas(gcf,[outDir filesep 'XVal DecVell ' dimNames{dimIdx} '.fig'],'fig');
        end
    end
     
    %head movement control
    headAvgVel = cell(size(packagedDat,1),2);
    binIdx = -25:200;
    theta = linspace(0,2*pi,9)';
    theta(end) = [];
    targList = round(409*[cos(theta), sin(theta)]);
    for rowIdx=1:size(packagedDat,1)
 
        %apply cross-condition
        loopIdx = packagedDat{rowIdx,3};
        
        headAvgVel{rowIdx,1} = zeros(length(binIdx),size(targList,1),2);
        headAvgVel{rowIdx,2} = zeros(length(binIdx),size(targList,1),2,2);
        for t=1:size(targList,1)
            trlIdx = find(ismember(packagedDat{rowIdx,4}(:,2:3), targList(t,:),'rows'));
            tmp = triggeredAvg(packagedDat{rowIdx,5}, packagedDat{rowIdx,4}(trlIdx,1), [binIdx(1), binIdx(end)]);
            
            for x=1:size(tmp,2)
                singleBinDat = squeeze(tmp(:,x,:));
                singleBinDat(any(isnan(singleBinDat),2),:)=[];
                headAvgVel{rowIdx,1}(x,t,:) = mean(singleBinDat);
                [~,~,headAvgVel{rowIdx,2}(x,t,:,:)] = normfit(singleBinDat);
            end
        end
    end
    
    dimIdx=2;
    timeAxis = binIdx*0.02;
    colors = hsv(8)*0.8;
    figure
    for rowIdx=1:size(packagedDat,1)
        subplot(3,2,rowIdx);
        hold on;
        for t=1:size(targList,1)
            tmp = squeeze(headAvgVel{rowIdx,1}(:,t,:));
            plot(timeAxis,tmp(:,dimIdx),'Color',colors(t,:),'LineWidth',2);
            
            %tmp = squeeze(headAvgVel{rowIdx,2}(:,t,:,:));
            %errorPatch(timeAxis', squeeze(tmp(:,:,dimIdx)), colors(t,:), 0.4);
        end
        plot([0 0],get(gca,'YLim'),'--k');
    end

    colors = hsv(8)*0.8;
    figure
    for rowIdx=1:size(packagedDat,1)
        subplot(3,2,rowIdx);
        hold on;
        
        allEP = [];
        for t=1:size(targList,1)
            tmp = squeeze(headAvgVel{rowIdx,1}(:,t,:));
            endPoint = mean(tmp);
            %endPoint = tmp(26,:);
            allEP = [allEP; endPoint];
        end
        
        coef = buildLinFilts(targList, [ones(size(allEP,1),1), allEP], 'standard');
        correctedEP = [ones(size(allEP,1),1), allEP]*coef;
        
        for t=1:size(correctedEP,1)
            plot(correctedEP(t,1),correctedEP(t,2),'o','Color',colors(t,:),'MarkerFaceColor',colors(t,:),'LineWidth',2);
        end
    end
    
    figure
    for rowIdx=1:size(packagedDat,1)
        subplot(3,2,rowIdx);
        hold on
        for t=1:8
            mnPos = mean(squeeze(crossAvg{rowIdx,rowIdx}(:,t,:)));
            plot(mnPos(:,1), mnPos(:,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
        end
    end
end