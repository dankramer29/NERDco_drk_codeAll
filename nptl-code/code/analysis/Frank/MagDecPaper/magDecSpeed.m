fileDir = '/Users/frankwillett/Data/BG Datasets/';
resultsDir = '/Users/frankwillett/Data/magDecSpeed';
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/'));

sessionList = {'t8.2016.03.30_Speed_Obstacle_Bias_tests',[3 5],[6 7 8];
    't8.2016.04.04_Obstacle_and_Speed_tests',[3 4 6],[11 13 14];
    't9.2016.09.20 Intention Estimator Comparison',[4],[5 6 7 8 9];
    't10.2016.10.03 Magnitude Decoder',[4],[4 5 6 7];
    't10.2016.10.04 Magnitude Decoder',[5],[5 6 7 8]};
phasicSigns = [1, 1, 1, 1, 1];

for s=1:size(sessionList,1)

    mkdir([resultsDir filesep sessionList{s,1}]);

    %generate cross-validated population responses and single feature
    %predictions
    cal = LoadSLC(sessionList{s,3}, [fileDir filesep sessionList{s,1}]);

    sBLOCKS(1).sGInt.Name = 'BG2D';
    sBLOCKS(1).sGInt.GameName = 'Twigs';
    P = slcDataToPFile(cal, sBLOCKS);

    %create input structure for model fitting function
    reachPlusDelay = [P.trl.reaches(:,1)-50, P.trl.reaches(:,2)];
    in.reachEpochs = reachPlusDelay;
    rIdx = expandEpochIdx(P.trl.reaches);

    in.cursorPos = P.loopMat.cursorPos;
    in.targetPos = P.loopMat.targetPos;
    in.gameType = 'speedDelay';
    in.speedCode = P.loopMat.speedCue(P.trl.reaches(:,1)+4)+1;
    
    if any(strcmp(sessionList{s,1},{'t10.2016.10.03 Magnitude Decoder', 't10.2016.10.04 Magnitude Decoder'}))
        in.features = double([cal.ncTX.values(:,97:end), cal.spikePower.values(:,97:end)]);
    else
        in.features = double([cal.ncTX.values, cal.spikePower.values]);
    end
    
    in.maxDist = 0.55;
    in.rtSteps = 10;
    in.plot = false;

    %%
    %apply dPCA
    normFeatures = zscore(in.features);
    normFeatures = gaussSmooth_fast(normFeatures, 3);
    
    tPos = in.targetPos(P.trl.reaches(:,1),:);
    [tList,~,tCodes] = unique(tPos,'rows');
    tCodes(tCodes==5)=-1;
    tCodes(tCodes>=5) = tCodes(tCodes>=5)-1;
    fastCode = find(in.speedCode==2);
    tCodes(fastCode) = tCodes(fastCode)+8;
    
    useTrl = find(tCodes~=-1);
    out = apply_dPCA_simple( normFeatures, P.trl.reaches(useTrl,1), tCodes(useTrl), [-50 100], 0.02, {'Condition-dependent','Condition-independent'} );
     
    colors = [hsv(8)*0.8; hsv(8)*0.8];
    newLineArgs = cell(16,1);
    for c=1:16
        if c<=8
            newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle','--'};
        else
            newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle','-'};
        end
    end
    oneFactor_dPCA_plot( out, (-50:100)*0.02, newLineArgs, {'CD','CI'}, 'zoomedAxes' );
    
    modScales = oneFactor_dPCA_plot_mag( out, (-50:100)*0.02, newLineArgs, {'CD','CI'} );
    %%
    %normalize features
    blockList = unique(P.loopMat.relativeBlockNums);
    badCols = sum(in.features~=0)/length(in.features) < 0.05;
    in.features(in.features>600)=600;
    in.features(:,badCols) = [];
    blockStd = zeros(length(blockList),size(in.features,2));
    for b=1:length(blockList)
        blockIdx = find(P.loopMat.relativeBlockNums==blockList(b));
        in.features(blockIdx,:) = bsxfun(@plus, in.features(blockIdx,:), -mean(in.features(blockIdx,:)));
        blockStd(b,:) = std(in.features(blockIdx,:));
    end

    divisor = mean(blockStd);
    badCols = divisor==0;
    blockStd(badCols) = [];
    in.features(:,badCols)=[];
    in.features = bsxfun(@times, in.features, 1./mean(blockStd));
    in.features(abs(in.features)>10)=0;

    %kinematics
    [ in.kin.posErrForFit, in.kin.unitVec, in.kin.targDist, in.kin.timePostGo ] = prepKinForPhasicAndFB( in );

    %fit model
    %first fit full
    modelTypes = {'FMP','FM'};
    fullModels = cell(length(modelTypes),1);
    sfResponse = cell(length(modelTypes),1);
    popResponse = cell(length(modelTypes),1);

    for mType = 1:length(modelTypes)
        in.modelType = modelTypes{mType};

        fullModels{mType} = fitPhasicAndFB_speed(in);
        out = applyPhasicAndFB(in, fullModels{mType} );
        R2Vals = getDecoderPerformance(out.all(rIdx,:),in.features(rIdx,:),'R2')';

        sfResponse{mType} = zeros(size(in.features));
        popResponse{mType} = zeros(size(in.features,1),size(out.popResponse,2));

        nFolds = 6;
        C = cvpartition(size(in.reachEpochs,1),'KFold',nFolds);
        for n=1:nFolds
            disp(n);
            inFold = in;
            inFold.reachEpochs = in.reachEpochs(C.training(n),:);
            if strcmp(in.gameType,'speedDelay')
                inFold.speedCode = in.speedCode(C.training(n));
            end

            foldModel = fitPhasicAndFB_speed(inFold);
            inFold.reachEpochs = reachPlusDelay(C.test(n),:);
            out = applyPhasicAndFB(inFold, foldModel);

            testIdx = expandEpochIdx(reachPlusDelay(C.test(n),:));
            sfResponse{mType}(testIdx,:) = out.all(testIdx,:);
            popResponse{mType}(testIdx,:) = out.popResponse(testIdx,:);
        end
    end
    %save([resultsDir filesep 'tuning' filesep 'phasicResponse' filesep sessionList{s,1} filesep 'speed models'],'fullModels','badCols','R2Vals');
    
    %%
    code = P.loopMat.speedCue(P.trl.reaches(:,1)+4)+1;
    if strcmp(sessionList{s,1}(1:2),'t9')
        smoothWidth = 3;
    else
        smoothWidth = 1.5;
    end
    
    %median acquire times for slow vs. fast
    acqTimes = 0.02*(P.trl.reaches(:,2)-P.trl.reaches(:,1));
    medAcqTimes(1) = median(acqTimes(code==1));
    medAcqTimes(2) = median(acqTimes(code==2));
    medAcqTimes = round(medAcqTimes*50);
    
    for mType = 1:length(modelTypes)
        if strcmp(modelTypes{mType},'FMP')
            tmpTimeMag = [];
            for x=1:size(P.trl.reaches,1)
                loopIdx = (P.trl.reaches(x,1)-50):(P.trl.reaches(x,1)+100);
                if loopIdx(end)>size(popResponse{mType},1)
                    continue;
                end
                tmpTimeMag = [tmpTimeMag; popResponse{mType}(loopIdx,4)'];
            end
            meanSignal = mean(tmpTimeMag);
            [~,maxIdx] = max(abs(meanSignal));
            %if meanSignal(maxIdx)<0
                popResponse{mType}(:,4) = phasicSigns(s)*popResponse{mType}(:,4);
            %end
        end

        decDirRot = rotateToTargetFrame( P.loopMat.cursorPos, P.loopMat.targetPos, ...
            popResponse{mType}(:,1:2) );
        decDirRot(isnan(decDirRot)) = 0;
        decDirRot(isinf(decDirRot)) = 0;

        %slow = 1, fast = 2
        timeAxis = (-50:100)*0.02;
        colors = [0 0 0.8; 0.8 0 0];
        concatSeries = cell(4,2);
        for c=1:4
            concatSeries{c,1} = zeros(length(timeAxis),2);
            concatSeries{c,2} = zeros(4,length(timeAxis));
        end

        for c=1:2
            trlIdx = find(code==c); 
            tmpTimeMag = [];
            tmpFeedbackMag = [];
            tmpFeedbackXY = [];
            for t=1:length(trlIdx)
                loopIdx = (P.trl.reaches(trlIdx(t),1)-50):(P.trl.reaches(trlIdx(t),1)+100);
                if loopIdx(end)>length(popResponse{mType})
                    continue;
                end
                if strcmp(modelTypes{mType},'FMP')
                    tmpTimeMag = [tmpTimeMag; popResponse{mType}(loopIdx,4)'];
                end
                tmpFeedbackMag = [tmpFeedbackMag; popResponse{mType}(loopIdx,3)'];
                tmpFeedbackXY = [tmpFeedbackXY; decDirRot(loopIdx,1)'];                
            end

            if strcmp(modelTypes{mType},'FMP')
                concatSeries{3,1}(:,c)=mean(gaussSmooth_fast(tmpTimeMag', smoothWidth)');
                [~,~,concatSeries{3,2}((1:2)+(c-1)*2,:)]=normfit(gaussSmooth_fast(tmpTimeMag', smoothWidth)');
            end

            concatSeries{2,1}(:,c)=mean(gaussSmooth_fast(tmpFeedbackMag', smoothWidth)');
            concatSeries{1,1}(:,c)=mean(gaussSmooth_fast(tmpFeedbackXY', smoothWidth)');
            [~,~,concatSeries{2,2}((1:2)+(c-1)*2,:)]=normfit(gaussSmooth_fast(tmpFeedbackMag', smoothWidth)');
            [~,~,concatSeries{1,2}((1:2)+(c-1)*2,:)]=normfit(gaussSmooth_fast(tmpFeedbackXY', smoothWidth)');
        end

        figure('Position',[252   269   275   715]);
        titles = {'c(t)·UnitErr', '||c(t)||','CIS'};
        for t=1:3
            if t==1 && ~strcmp(modelTypes{mType},'FMP')
                continue;
            end
            subplot(3,1,t);
            hold on;
            for c=1:2
                plotIdx = 1:(medAcqTimes(c)+50);
                plotIdx(plotIdx>length(timeAxis))=[];
                
                lHandles(c)=plot(timeAxis(plotIdx), concatSeries{t,1}(plotIdx,c), 'Color',colors(c,:));

                rowIdx = (1:2)+(c-1)*2;
                tmp = concatSeries{t,2}(rowIdx,plotIdx);
                errorPatch(timeAxis(plotIdx)', tmp', colors(c,:), 0.2);
            end
            axis tight;
            set(gca,'YTick',[]);
            plot([0 0],get(gca,'YLim'),'--k');
            %title(titles{t});
            xlabel('Time (s)');
            ylabel(titles{t});

            set(gca,'FontName','Trade Gothic Next LT Pro');
            set(gca,'LineWidth',1);
            set(gca,'FontSize',11);
            if t==1
                legend(lHandles,{'Slow','Fast'},'Location','Best');
            end
        end

        exportPNGFigure(gcf,[resultsDir filesep 'tuning' filesep 'phasicResponse' filesep sessionList{s,1} filesep 'speed population response' modelTypes{mType}]);
    end
    close all;
    %%
    %single feature responses
    cursorSpeed = matVecMag([0 0; diff(P.loopMat.cursorPos)],2);
    cursorSpeed(cursorSpeed>0.1) = 0;
    cursorSpeed = cursorSpeed*50*2;
    [B,A] = butter(3, 7/25);
    cursorSpeed = filtfilt(B,A,cursorSpeed);
    
    code = P.loopMat.speedCue(P.trl.reaches(:,1)+4)+1;
    [ speedMean_slow, speedCI_slow, timeAxis ] = avgTimeSeries( cursorSpeed, P.trl.reaches(code==1,1), [-50 100], 0 );
    [ speedMean_fast, speedCI_fast ] = avgTimeSeries( cursorSpeed, P.trl.reaches(code==2,1), [-50 100], 0 );

    plotIdxSlow = 1:(medAcqTimes(1)+50);
    plotIdxFast = 1:(medAcqTimes(2)+50);
    plotIdxSlow(plotIdxSlow>length(timeAxis))=[];
    plotIdxFast(plotIdxFast>length(timeAxis))=[];
     
    timeAxis = timeAxis*0.02;
    colors  = [0 0 0.8; 0.8 0 0];
    figure('Position',[252   269   275   715]);
    subplot(3,1,1);
    hold on 
    plot(timeAxis(plotIdxSlow), speedMean_slow(plotIdxSlow), 'Color', colors(1,:));
    errorPatch(timeAxis(plotIdxSlow), speedCI_slow(plotIdxSlow,:), colors(1,:), 0.2);
    plot(timeAxis(plotIdxFast), speedMean_fast(plotIdxFast), 'Color', colors(2,:));
    errorPatch(timeAxis(plotIdxFast), speedCI_fast(plotIdxFast,:), colors(2,:), 0.2);
    
    axis tight;
    yLimits = get(gca,'YLim');
    yLimits(1) = 0;
    plot([0 0],yLimits,'--k','LineWidth',1.5);
    ylim(yLimits);
    xlabel('Time (s)');
    ylabel('Cursor Speed (TD/s)');
    set(gca,'FontSize',16,'LineWidth',1.5);
    xlim([-0.8 2]);
    
    mkdir([resultsDir filesep 'tuning' filesep 'phasicResponse' filesep sessionList{s,1}]);
     exportPNGFigure(gcf,[resultsDir filesep 'tuning' filesep 'phasicResponse' filesep sessionList{s,1} filesep 'decoded speed profile']);
% 
%     for t=1:20
%         [ meanOut_slow, CI_slow ] = avgTimeSeries( in.features(:,sortIdx(t)), P.trl.reaches(code==1,1), [-50 100], gaussWidth );
%         [ meanOut_fast, CI_fast ] = avgTimeSeries( in.features(:,sortIdx(t)), P.trl.reaches(code==2,1), [-50 100], gaussWidth );
% 
%         figure('Position',[624   578   665   400]);
%         hold on
%         plot(timeAxis, meanOut_slow, 'Color', colors(1,:));
%         errorPatch(timeAxis, CI_slow, colors(1,:), 0.2);
%         plot(timeAxis, meanOut_fast, 'Color', colors(2,:));
%         errorPatch(timeAxis, CI_fast, colors(2,:), 0.2);
%         yLimits = get(gca,'YLim');
%         plot([0 0],yLimits,'--k');
% 
%         totalRange = range([speedMean_slow; speedMean_fast]);
%         normCurveSlow = (speedMean_slow-min(speedMean_slow))/totalRange;
%         normCurveFast = (speedMean_fast-min(speedMean_fast))/totalRange;
%         yRange = diff(yLimits);
%         plot(timeAxis, (yRange*normCurveSlow+yLimits(1)), '-', 'Color', [0 0 0], 'LineWidth', 2);
%         plot(timeAxis, (yRange*normCurveFast+yLimits(1)), '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 2);
%         ylim(yLimits);
%         xlabel('Time (s)');
%         ylabel('Neural Response');
% 
%         exportPNGFigure(gcf,[resultsDir filesep 'tuning' filesep 'phasicResponse' filesep sessionList{s,1} filesep 'speed feature ' num2str(sortIdx(t))]);
%     end
%     close all;
end %session