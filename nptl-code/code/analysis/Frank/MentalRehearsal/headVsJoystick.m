datasets = {'t5.2018.02.19'};
%'t5.2018.02.19',{[0 1 7],[2],[3],[8],[3 8],[4 9],[5 12],[6 13],[14 15],[16]},{'E','I1','I2','I3','I23','INC','W','Micro','Joy8','Joy1'}
for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
    datDir = [paths.dataPath filesep 'BG Processed' filesep datasets{d,1} filesep];

    outDir = [paths.dataPath filesep 'Derived' filesep 'MentalRehearsal' filesep datasets{d,1}];
    mkdir(outDir);
    
    %%
    %psths
    bNums = [0 1 7 14 15];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end

    allR = [];
    for x=1:length(allDat)
        for t=1:length(allDat{x}.R)
            allDat{x}.R(t).blockNum=bNums(x);
        end
        allR = [allR, allDat{x}.R];
    end

    [ allR, rtAdjusted, goCue, wiaCodes, rtSimple ] = getSpeedAndRT( allR, [] );

    smoothWidth = 0;
    datFields = {'windowsPC1GazePoint','windowsPC1HeadRot','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
    
    posErr = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);
    trlCodes = dirTrialBin( posErr(unrollDat.trialEpochs(:,1)+goCue+5,:), 8 );
    outerIdx = ~all(unrollDat.currentTarget(unrollDat.trialEpochs(:,1)+10,:)==0,2);
    blockNums = unrollDat.blockNum(unrollDat.trialEpochs(:,1));
    
    trlA = find(ismember(blockNums, [0 1 7]) & [allR.isSuccessful]' & goCue>1 & rtAdjusted<800 & rtAdjusted>200);
    trlJ = find(ismember(blockNums, [14 15]) & [allR.isSuccessful]' & goCue>1);
    allTrl = [trlA; trlJ];
    
    %PSTH            
    timeWindow = [-1500, 4000];
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 3;
    psthOpts.neuralData = {zscore(unrollDat.zScoreSpikes)};
    psthOpts.timeWindow = timeWindow/binMS;
    psthOpts.trialEvents = unrollDat.trialEpochs(allTrl,:)+goCue(allTrl);
    psthOpts.trialConditions = [trlCodes(trlA); trlCodes(trlJ)+8;];

    psthOpts.conditionGrouping = {1:8, 9:16};

    colors = hsv(8)*0.8;
    lineArgs = cell(8,1);
    for c=1:size(colors,1)
        lineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
    end
    lineArgs = [lineArgs; lineArgs; lineArgs; lineArgs];

    psthOpts.lineArgs = lineArgs;
    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = [outDir filesep 'PSTH' filesep];
    featLabels = cell(192,1);
    for f=1:192
        featLabels{f} = ['C' num2str(f)];
    end
    psthOpts.featLabels = featLabels;
    psthOpts.prefix = 'HJ';
    psthOpts.subtractConMean = false;
    psthOpts.timeStep = binMS/1000;

    pOut = makePSTH_simple(psthOpts);
    close all;
    
    trlTypes = {trlA,trlI};
    trlNames = {'H','J'};
    for x=1:length(trlTypes)
        psthOpts_i = psthOpts;
        psthOpts_i.trialEvents = unrollDat.trialEpochs(trlTypes{x},:)+goCue(trlTypes{x});
        psthOpts_i.trialConditions = trlCodes(trlTypes{x});
        psthOpts_i.conditionGrouping = {1:8};
        psthOpts_i.prefix = trlNames{x};
        pOut = makePSTH_simple(psthOpts_i);
        close all;
    end
    
    %%
    %imagined decoding, different distances
    movSets = {[0 1 7],[0],'head_P','P';
        [0 1 7],[0],'head_M','M';
        [14 15],[1],'joy_P','P';
        [14 15],[1],'joy_M','M';};
    
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
        elseif strcmp(movSets{setIdx,3},'VMR_M')
            useTrl = find(wiaCodes==movSets{setIdx,2} & [allR.isSuccessful]' & ~all([allR.posTarget]==0)');
        else
            useTrl = find(wiaCodes==movSets{setIdx,2} & [allR.isSuccessful]' & goCue>1);
        end
        
        loopIdx_mov = expandEpochIdx([unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+15, unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+40]);
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
        PDs = trainFun(packagedDat{setIdx,2}(loopIdx,:), packagedDat{setIdx,1}(loopIdx,:));
        
        PDs(:,2) = -PDs(:,2);
        if strcmp(movSets{setIdx,3},'VMR_M')
            theta = 25*(pi/180);
            rotMat = [[cos(theta); sin(theta)], [cos(theta+pi/2); sin(theta+pi/2)]];
            PDs = rotMat * PDs;
        end
        singleChan{setIdx,2} = PDs;
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
    crossPD = nan(size(packagedDat,1));
    for rowIdx=1:size(packagedDat,1)
        for colIdx=1:size(packagedDat,1)
            if rowIdx==colIdx
                crossPD(rowIdx,colIdx) = 1;
            end
            sigIdx = singleChan{rowIdx,1}>0.005 & singleChan{colIdx,1}>0.005;
            if sum(sigIdx)>4
                crossPD(rowIdx,colIdx) = mean(diag(corr(singleChan{rowIdx,2}(:,sigIdx)', singleChan{colIdx,2}(:,sigIdx)')));
            end
        end
    end
    
    figure
    imagesc(crossPD,[-1 1]);
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
%                 if strcmp(movSets{rowIdx,3},'VMR_M')
%                     theta = 45*(pi/180);
%                     rotMat = [[cos(theta); sin(theta)], [cos(theta+pi/2); sin(theta+pi/2)]];
%                     decVel = (rotMat * decVel')';
%                 end
                
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
    
    plotSets = {[1:4]};
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
        subplot(4,2,rowIdx);
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
        subplot(4,2,rowIdx);
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
        subplot(4,2,rowIdx);
        hold on
        for t=1:8
            sumTraj = cumsum(squeeze(crossAvg{rowIdx,rowIdx}(:,t,:)));
            plot(sumTraj(:,1), sumTraj(:,2), '-', 'Color', colors(t,:));
            plot(sumTraj(end,1), sumTraj(end,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
        end
    end
    
    %%
    %audio file, start/stop labeling for movement sequence task
    %nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.09/Data/_Lateral/NSP Data/22_sequenceTask_Complete_t5_bld(022)022.ns5';

    %analogData = openNSx_v620(nsFileName, 'read', 'c:98');
    %analogData = double(analogData.Data{end}');
    %analogData = analogData/2000;
    %audiowrite('sequenceRehearsal.wav',analogData,30000);
    
    startStop = [26.977, 35.971;
        41.257, 51.368;
        52.717, 64.857;
        66.666, 79.173;
        80.788, 90.278;
        91.350, 103.009;
        104.897, 116.233;
        117.289, 129.329;
        131.080, 142.743;
        144.456, 154.299;
        155.243, 166.947;
        168.065, 180.780;
        181.562, 202.840;
        203.577, 214.321;
        215.162, 225.865;
        226.610, 239.101;
        240.496, 252.304;
        252.855, 259.129;];
    startStop = startStop(1:12,:);
    timeIntervals = startStop(:,2)-startStop(:,1);
    startStopMS = int32(round(startStop*1000));
    
    ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.09/Data/_Medial/NSP Data/22_sequenceTask_Complete_t5_bld(022)022.ns5';
    siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
    offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);
    
    blockNum = 22;
    dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(blockNum) '.mat'];
    allDat = load(dataPath);
    stream = allDat.stream;
    
    startStopIdx = (-int32(stream.continuous.clock(1)) - int32(offset_ms(end)) + startStopMS);
    startStopIdx = double(startStopIdx);
    
    allNeural = gaussSmooth_fast(double([stream.spikeRaster(stream.continuous.clock(1):end,:), ...
        stream.spikeRaster2(stream.continuous.clock(1):end,:)]), 100);
    concatNeural = triggeredAvg( allNeural, startStopIdx(:,1), [-10000, 10000] );
    
    nPoints = 1000;
    concatNeural = zeros(length(startStop), nPoints, 192);
    for x=1:length(startStop)
        warpIdx = round(linspace(startStopIdx(x,1), startStopIdx(x,2), nPoints));
        %warpIdx = round(linspace(startStopIdx(x,2)-10000, startStopIdx(x,2), nPoints));
        concatNeural(x,:,:) = allNeural(warpIdx,:);
    end
    
    colors = hsv(2)*0.8;
    figure
    hold on
    for dimIdx=1:2
        tmp = [];
        for x=1:size(concatNeural,1)
            mn = bsxfun(@times, squeeze(concatNeural(x,:,:)), 1./spikeStats{4});
            dv = applyTopNDecoder_unitGain(allDec{4}, mn);
            tmp = [tmp; dv(:,dimIdx)'];
        end
        tmp = tmp - mean(tmp(:));
        [mn,~,mnCI] = normfit(tmp);
        
        plot(mn,'Color',colors(dimIdx,:));
        errorPatch( (1:length(mn))', mnCI', colors(dimIdx,:), 0.4 );
    end
    plot(get(gca,'XLim'),[0 0],'--k');
    
    meanNeural = squeeze(mean(concatNeural,1));
    meanNeural_norm = bsxfun(@times, meanNeural, 1./spikeStats{4});
    decVel = applyTopNDecoder_unitGain(allDec{4}, meanNeural_norm);
    decVel = zscore(decVel);
    
    figure
    plot(decVel);
    
    %%
    %average based on where the eye is
    blockNum = 22;
    dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(blockNum) '.mat'];
    allDat = load(dataPath);
    
    bStream = binStream( allDat.stream, 20, 0, {'windowsPC1GazePoint','clock'} );
    bStream.meanSubtractSpikes = gaussSmooth_fast(bStream.meanSubtractSpikes, 10);
    
    [B,A] = butter(4,6/25);
    filtGaze = filtfilt(B,A,bStream.windowsPC1GazePoint);
    filtGaze = bsxfun(@times, filtGaze, [1920, 1080]);
    filtGaze(:,2) = -filtGaze(:,2);
    
    gazeAOI = [0.49, -0.83;
        0.345, -0.73;
        0.65, -0.733;
        0.50, -0.15;
        0.30, -0.11];
    gazeAOI = bsxfun(@times, gazeAOI, [1920, 1080]);
    aoiRadius = 140;
     
    rehearseIdx = 1:(260*50);
    
    figure;
    hold on;
    plot(filtGaze(rehearseIdx,1), filtGaze(rehearseIdx,2), '.');
    for t=1:size(gazeAOI,1)
        rectangle('Position',[gazeAOI(t,1)-aoiRadius, gazeAOI(t,2)-aoiRadius, aoiRadius*2, aoiRadius*2],'Curvature',[1 1],'LineWidth',2);
        text(gazeAOI(t,1), gazeAOI(t,2), num2str(t), 'FontSize', 26, 'Color', 'k');
    end
    axis equal;
    
    gazeRegion = zeros(size(filtGaze,1),1);
    for t=1:size(filtGaze,1)
        for x=1:size(gazeAOI,1)
            if sqrt(sum((gazeAOI(x,:)-filtGaze(t,:)).^2))<aoiRadius
                gazeRegion(t) = x;
            end
        end
    end
    
    figure
    hold on;
    plot(gazeRegion);
    for t=1:size(startStopIdx,1)
        plot([startStopIdx(t,1)/20, startStopIdx(t,1)/20],[0 5],'--k','LineWidth',2);
        plot([startStopIdx(t,2)/20, startStopIdx(t,2)/20],[0 5],'--r','LineWidth',2);
    end
    
    mss = bsxfun(@times, bStream.meanSubtractSpikes, 1./spikeStats{4});
    decVel = applyTopNDecoder_unitGain(allDec{4}, mss);
    regionAvg = zeros(size(gazeAOI,1),2);
    for r=1:size(gazeAOI,1)
        validIdx = intersect(find(gazeRegion==r), 350:8708);      
        %validIdx = intersect(find(gazeRegion==r), 13000:23928);  
        regionAvg(r,:)=mean(decVel(validIdx,:));
    end
    
    figure
    hold on
    for r=1:size(gazeAOI)
        text(regionAvg(r,1), -regionAvg(r,2), num2str(r), 'FontSize', 16);
    end
    xlim([-1 1]);
    ylim([-1 1]);
    axis equal;
    
    centerPoints = [361, 463, 541, 660, 736, 845;
        1190, 1260, 1338, 1442, 1496, 1572;
        1892, 1987, 2068, 2179, 2250, 2313;
        2493, 2596, 2691, 2867, 2932, 3004;
        3256, 3433, 3517, 3599, 3673, 3762;
        3890, 3998, 4062, 4144, 4209, 4279;
        4409, 4550, 4655, 4767, 4843, 4924;
        5137, 5239, 5334, 5415, 5495, 5578;
        5760, 5906, 5988, 6116, 6175, 6255;
        6436, 6564, 6687, 6781, 6846, 6920;
        7068, 7098, 7224, 7287, 7332, 7428;
        7639, 7810, 7893, 7987, 8051, 8123;
        8281, 8386, 8471, 8584, 8635, 8701;];
    
    figure
    hold on
    for r=1:size(centerPoints,2)
        loopIdx = cell(size(centerPoints,1),1);
        for x=1:size(centerPoints,1)
            loopIdx{x} = (centerPoints(x,r)-15):(centerPoints(x,r)+15);
        end
        
        trlMeans = [];
        for x=1:size(centerPoints,1)
            trlMeans(x,:) = mean(decVel(loopIdx{x},:));
        end
        trlMeans(:,2) = -trlMeans(:,2);
        
        [regionAvg,~,mnCI] = normfit(trlMeans);
        text(regionAvg(1), regionAvg(2), num2str(r), 'FontSize', 16);
        plot([mnCI(1,1),mnCI(2,1)],[regionAvg(2), regionAvg(2)],'k-');
        plot([regionAvg(1), regionAvg(1)],[mnCI(1,2),mnCI(2,2)],'k-');
    end
    xlim([-1 1]);
    ylim([-1 1]);
    axis equal;
    
        
    %%
    %eye position for overt & imagined trials
    bNums = [4 6 7];
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
    datFields = {'windowsPC1GazePoint','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
    
    useTrl = find([allR.isSuccessful]' & goCue>1);
    targPosByTrial = round(unrollDat.currentTarget(unrollDat.trialEpochs(useTrl,1)+goCue(useTrl)+5,1:2));
    [dirList, ~, dirCodes] = unique(atan2(targPosByTrial(:,2), targPosByTrial(:,1)),'rows');
    [tList,~,tCodes] = unique(targPosByTrial,'rows');
    
    figure
    for codeIdx=1:8
        realTrl = find((dirCodes==codeIdx) & wiaCodes(useTrl)==0);
        watchTrl = find((dirCodes==codeIdx) & wiaCodes(useTrl)==1);
        imagTrl = find((dirCodes==codeIdx) & wiaCodes(useTrl)==2);
    
        concatWatch = triggeredAvg(unrollDat.windowsMousePosition, unrollDat.trialEpochs(useTrl(watchTrl),1)+goCue(useTrl(watchTrl)), [-25, 75]);
        concatReal = triggeredAvg(unrollDat.windowsMousePosition, unrollDat.trialEpochs(useTrl(realTrl),1)+goCue(useTrl(realTrl)), [-25, 75]);
        concatImag = triggeredAvg(unrollDat.windowsMousePosition, unrollDat.trialEpochs(useTrl(imagTrl),1)+goCue(useTrl(imagTrl)), [-25, 75]);

        subplot(3,3,codeIdx);
        hold on
        plot((-25:75)*0.02, squeeze(concatReal(:,:,2)),'b','LineWidth',2);
        %plot((-25:75)*0.02, squeeze(concatImag(:,:,2)),'r','LineWidth',2);
        plot((-25:75)*0.02, squeeze(concatWatch(:,:,2)),'r','LineWidth',2);
    end
    
    %%
    %VMR behavior
    bNums = [17 19];
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
    plot(errAngle{2},'bo');
    plot(errAngle{1},'ro');
    ylabel('Error Angle at Halfway');
    legend({'Unrehearsed','Rehearsed'});

    [h,p]=ttest2(errAngle{1}, errAngle{2})
    
    figure
    hold on;
    plot(trlLen{2},'bo');
    plot(trlLen{1},'ro');
    ylabel('Trial Length');
    legend({'Unrehearsed','Rehearsed'});

    [h,p]=ttest2(trlLen{1}, trlLen{2})
    
    figure
    hold on;
    plot(nanmean(speedProfile{2}),'-b');
    plot(nanmean(speedProfile{1}),'-r');
    ylabel('Speed');
    legend({'Unrehearsed','Rehearsed'});
    
    %%
    %VMR rehearsal
    bNums = [14 15];
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
    datFields = {'windowsPC1GazePoint','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );
    
    %%
    decVel = applyTopNDecoder_unitGain(allDec{4}, gaussSmooth_fast(unrollDat.zScoreSpikes,3));
    
    theta = linspace(0,2*pi,9)';
    theta(end) = [];
    targList = round(409*[cos(theta), sin(theta)]);
    
    headVel = [0 0; diff(unrollDat.windowsMousePosition)];
    [B,A] = butter(4, 10/500);
    headVel = filtfilt(B,A,headVel);
            
    binIdx = [0,150];
    headAvg = zeros(length(binIdx(1):binIdx(end)),size(targList,1),2);
    decAvg = zeros(length(binIdx(1):binIdx(end)),size(targList,1),2);
    for t=1:size(targList,1)
        trlIdx = find(ismember(unrollDat.currentTarget(unrollDat.trialEpochs(:,1)+10, 1:2), targList(t,:),'rows'));
        tmp = triggeredAvg(decVel, unrollDat.trialEpochs(trlIdx,1), [binIdx(1), binIdx(end)]);
        decAvg(:,t,:) = squeeze(mean(tmp,1));
        
        tmp = triggeredAvg(headVel, unrollDat.trialEpochs(trlIdx,1), [binIdx(1), binIdx(end)]);
        headAvg(:,t,:) = squeeze(mean(tmp,1));
    end
        
    colors = hsv(size(targList,1))*0.8;
    
    figure
    hold on
    for t=1:size(decAvg,2)
        mnPos = mean(squeeze(decAvg(:,t,:)));
        plot(mnPos(:,1), -mnPos(:,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
    end
    
    figure
    hold on
    for t=1:size(decAvg,2)
        traj = squeeze(decAvg(:,t,:));
        sumTraj = cumsum(traj);
        plot(sumTraj(:,1), -sumTraj(:,2), '-', 'Color',colors(t,:));
        plot(sumTraj(end,1), -sumTraj(end,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
    end
    
    figure
    hold on
    for t=1:length(targList)
        plot(targList(t,1), -targList(t,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
    end
    
    figure
    hold on
    for t=1:size(headAvg,2)
        mnPos = mean(squeeze(headAvg(:,t,:)));
        plot(mnPos(:,1), -mnPos(:,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
    end
    
    %%
    %normal imagine blocks
    figure
    hold on
    for t=1:8
        %mnPos = mean(squeeze(crossAvg{4,4}(:,t,:)));
        %plot(mnPos(:,1), -mnPos(:,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
        
        traj = squeeze(crossAvg{4,4}(:,t,:));
        sumTraj = cumsum(traj);
        plot(sumTraj(:,1), -sumTraj(:,2), '-', 'Color',colors(t,:));
        plot(sumTraj(end,1), -sumTraj(end,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
    end
    
    %%
    %cross
    figure
    for rowIdx=1:6
        for colIdx=1:6
            subtightplot(6,6,(rowIdx-1)*6+colIdx);
            hold on;
            
            allTraj = [];
            trajCell = cell(8,1);
            for t=1:8
                %mnPos = mean(squeeze(crossAvg{4,4}(:,t,:)));
                %plot(mnPos(:,1), -mnPos(:,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
                
                if strcmp(movSets{colIdx,4},'P')
                    useIdx = 1:25;
                else
                    useIdx = 35:76;
                end
                traj = squeeze(crossAvg{rowIdx,colIdx}(useIdx,t,:));
                allTraj = [allTraj; traj];
                trajCell{t} = traj;
            end
            
            bias = mean(allTraj);
            for t=1:8
                sumTraj = cumsum(trajCell{t}-bias);
                plot(sumTraj(:,1), -sumTraj(:,2), '-', 'Color',colors(t,:));
                plot(sumTraj(end,1), -sumTraj(end,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
            end
        end
    end
    
    colors = hsv(8)*0.8;
    for p=1:length(plotSets)
        allLimsX = cell(length(plotSets{p}));
        allLimsY = cell(length(plotSets{p}));
        axHandles = zeros(length(plotSets{p}));

        figure('Position',[680   354   897   744]);
        for rowIdx=1:length(plotSets{p})
            for colIdx=1:length(plotSets{p})
                axHandles(rowIdx, colIdx) = subtightplot(length(plotSets{p}), length(plotSets{p}), (rowIdx-1)*length(plotSets{p}) + colIdx);
                hold on;

                allTraj = [];
                trajCell = cell(8,1);
                for t=1:8
                    %mnPos = mean(squeeze(crossAvg{4,4}(:,t,:)));
                    %plot(mnPos(:,1), -mnPos(:,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));

                    if strcmp(movSets{plotSets{p}(colIdx),4},'P')
                        useIdx = 1:25;
                    elseif strcmp(movSets{plotSets{p}(colIdx),3},'watch_M')
                        useIdx = 35:50;
                    else
                        useIdx = 35:76;
                    end
                    traj = squeeze(crossAvg{plotSets{p}(rowIdx),plotSets{p}(colIdx)}(useIdx,t,:));
                    allTraj = [allTraj; traj];
                    trajCell{t} = traj;
                end

                bias = mean(allTraj);
                for t=1:8
                    sumTraj = cumsum(trajCell{t}-bias)/length(useIdx);
                    plot(sumTraj(:,1), -sumTraj(:,2), '-', 'Color',colors(t,:));
                    plot(sumTraj(end,1), -sumTraj(end,2), 'o', 'MarkerFaceColor', colors(t,:),'MarkerSize',8,'Color',colors(t,:));
                end
                
                set(gca,'XTick',[],'YTick',[]);
                axis tight;
                allLimsX{rowIdx, colIdx} = get(gca,'XLim');
                allLimsY{rowIdx, colIdx} = get(gca,'YLim');

                if rowIdx==length(plotSets{p})
                    xlabel(movSets{plotSets{p}(colIdx),3});
                end
                if colIdx==1
                    ylabel(movSets{plotSets{p}(rowIdx),3});
                end
                set(gca,'FontSize',16);
            end
        end

        for rowIdx=1:length(plotSets{p})
            cLimsX = vertcat(allLimsX{rowIdx, :});
            cLimsY = vertcat(allLimsY{rowIdx, :});
            finalLimsX = [min(cLimsX(:,1)), max(cLimsX(:,2))];
            finalLimsY = [min(cLimsY(:,1)), max(cLimsY(:,2))];
            
            for colIdx=1:length(plotSets{p})
                set(axHandles(rowIdx, colIdx), 'XLim', finalLimsX);
                set(axHandles(rowIdx, colIdx), 'YLim', finalLimsY);
                %plot(axHandles(rowIdx, colIdx), [25 25], finalLims, '--k', 'LineWidth', 2);
            end
        end

        saveas(gcf,[outDir filesep 'XVal DecTraj.png'],'png');
        saveas(gcf,[outDir filesep 'XVal DecTraj.fig'],'fig');
        saveas(gcf,[outDir filesep 'XVal DecTraj.svg'],'svg');
    end
    
    %%
    %angle vs. time
    angleErrTraj = zeros(length(binIdx(1):binIdx(end)),size(targList,1));
    for t=1:size(decAvg,2)
        traj = squeeze(decAvg(:,t,:));
        sumTraj = cumsum(traj);
        
        for x=1:size(angleErrTraj,1)
            u = [sumTraj(x,:),0];
            v = [targList(t,:),0];
            %angleErrTraj(x,t) = atan2d(norm(cross(u,v)),dot(u,v));
            x1 = sumTraj(x,1);
            y1 = sumTraj(x,2);
            x2 = targList(t,1);
            y2 = targList(t,2);
            angleErrTraj(x,t) = atan2d(x1*y2-y1*x2,x1*x2+y1*y2);
            %angleErrTraj(x,t) = subspace(sumTraj(x,:)', targList(t,:)');
        end
    end

    figure
    hold on
    for t=1:size(decAvg,2)
        plot(angleErrTraj(:,t),'Color',colors(t,:));
    end
    plot(get(gca,'XLim'),[0 0],'--k');
    %%
    %angle vs. time
    angleErrTraj = zeros(size(crossAvg{4,4},1),size(targList,1));
    for t=1:size(decAvg,2)
        traj = squeeze(crossAvg{4,4}(:,t,:));
        sumTraj = cumsum(traj);
        
        for x=1:size(angleErrTraj,1)
            u = [sumTraj(x,:),0];
            v = [targList(t,:),0];
            %angleErrTraj(x,t) = atan2d(norm(cross(u,v)),dot(u,v));
            x1 = sumTraj(x,1);
            y1 = sumTraj(x,2);
            x2 = targList(t,1);
            y2 = targList(t,2);
            angleErrTraj(x,t) = atan2d(x1*y2-y1*x2,x1*x2+y1*y2);
            %angleErrTraj(x,t) = subspace(sumTraj(x,:)', targList(t,:)');
        end
    end

    figure
    hold on
    for t=1:size(decAvg,2)
        plot(angleErrTraj(:,t),'Color',colors(t,:));
    end
    plot(get(gca,'XLim'),[0 0],'--k');
end

%%
%todo:
%add eye position saver to symbol and sequence tasks
%fix no pause bug for WIA tasks
%fix speed cap for sequence tasks