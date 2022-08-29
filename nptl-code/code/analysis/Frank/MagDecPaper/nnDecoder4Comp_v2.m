function nnDecoder4Comp_v2(saveDir, in, targRad)

    nFolds = 6;
    in.modelType = 'FMP';
    C = cvpartition(size(in.reachEpochs,1),'KFold',nFolds);
    posErr = in.targetPos - in.cursorPos;
    
    alpha = 0.94;
    csWeight = linspace(0,1,10)';
    xValOutLin = cell(length(csWeight),1);
    xValOutClassify = cell(length(csWeight),1);
    for d=1:length(csWeight)
        xValOutLin{d} = zeros(size(posErr));
        xValOutClassify{d} = zeros(size(posErr,1),1);
    end
    
    distFromTarg = matVecMag(posErr,2);
    inTarg = distFromTarg<targRad;
    
    for wIdx=1:length(csWeight)
        for n=1:nFolds
            disp([' -- Fold ' num2str(n)]);
            inFold = in;
            inFold.reachEpochs = in.reachEpochs(C.training(n),:);
            
            foldModel = fitPhasicAndFB_6(inFold);
            out = applyPhasicAndFB(inFold, foldModel);
            dec = buildMagDec( inFold.reachEpochs, posErr/inFold.maxDist, alpha, out.popResponse(:,1:2), out.popResponse(:,3), csWeight(wIdx) );
            decVecFinal = applyMagDec( dec, alpha, out.popResponse(:,1:2), out.popResponse(:,3) );
            
            testEpochs = in.reachEpochs(C.test(n),:);
            testIdx = expandEpochIdx([testEpochs(:,1)+10, testEpochs(:,2)]);
            trainIdx = expandEpochIdx([inFold.reachEpochs(:,1)+10, inFold.reachEpochs(:,2)]);

            xValOutLin{wIdx}(testIdx,:) = decVecFinal(testIdx,:);
            
            decVecMag = matVecMag(decVecFinal,2);
            mvnModel = buildMvnClassifier(decVecMag(trainIdx), double(inTarg(trainIdx)), 'linear');
            xValOutClassify{wIdx}(testIdx) = double(applyMvnClassifier(mvnModel, decVecMag(testIdx)));
        end
    end
    
    acc = zeros(length(xValOutClassify),1);
    for a=1:length(xValOutClassify)
        acc(a) = mean(xValOutClassify{a}==inTarg);
    end
    figure
    plot(acc,'-o','LineWidth',2);
    set(gca,'FontSize',22);
    exportPNGFigure(gcf, [saveDir filesep 'xValSpeedLDA']);
    %%
    %single-trial example
    plotAlpha = 0.94;
    smoothMagDirect = filter(1-plotAlpha,[1,-plotAlpha],out.popResponse(:,3));
    smoothMagVector = matVecMag(filter(1-plotAlpha,[1,-plotAlpha],out.popResponse(:,1:2)),2);
    smoothMagDirect = zscore(smoothMagDirect);
    smoothMagVector = zscore(smoothMagVector);
    distFromTarg = zscore(matVecMag(posErr,2));
    timeAxis = (0:(length(smoothMagDirect)-1))*0.02;
    
    figure('Position',[560   739   671   209]);
    hold on;
    plot(timeAxis,smoothMagDirect,'LineWidth',2); 
    plot(timeAxis,smoothMagVector,'LineWidth',2);
    plot(timeAxis,distFromTarg,'LineWidth',2);
    axis tight;
    xlim([25 35]);
    set(gca,'FontSize',24);
    
    exportPNGFigure(gcf, [saveDir filesep 'xValSpeedDec']);
    
    %%
    nBoot = 1000;
    speedCohen = zeros(nBoot, length(csWeight));
    speed = cell(length(csWeight),1);
    for wIdx=1:length(csWeight)
        speed{wIdx} = matVecMag(xValOutLin{wIdx},2);
    end
    targDist = matVecMag(posErr,2);
    
    for n=1:nBoot
        disp(n);
        sampleIdx = randi(length(in.reachEpochs),length(in.reachEpochs),1);
        evalIdx = expandEpochIdx([in.reachEpochs(sampleIdx,1)+10, in.reachEpochs(sampleIdx,2)]);
        nearIdx = intersect(evalIdx, find(targDist<targRad));
        farIdx = setdiff(evalIdx, nearIdx);
        for wIdx=1:length(csWeight)
            mnNear = mean(speed{wIdx}(nearIdx));
            mnFar  = mean(speed{wIdx}(farIdx));
            stdNearFar = mean([std(speed{wIdx}(farIdx)), std(speed{wIdx}(nearIdx))]);
            speedCohen(n, wIdx) = (mnFar-mnNear)/stdNearFar;
        end
    end
    
    speedSummary = zeros(length(csWeight), 3);
    for wIdx=1:length(csWeight)
        speedSummary(wIdx,1) = mean(speedCohen(:,wIdx));
        speedSummary(wIdx,2:3) = prctile(speedCohen(:,wIdx),[2.5 97.5]);
    end
    
    figure
    hold on
    plot(csWeight, speedSummary(:,1), 'Color', [0.8 0 0], 'LineWidth', 1);
    errorPatch(csWeight, speedSummary(:,2:3), [0.8 0 0], 0.2);
    xlabel('||c|| Weight');
    ylabel('Near vs. Far Speed Separation');
    exportPNGFigure(gcf, [saveDir filesep 'xValSpeedDec']);
    
    save([saveDir filesep 'xValSpeedDec'],'csWeight','speedSummary');
    
    %%
%     for n=1:nFolds
%         disp([' -- Fold ' num2str(n)]);
%         inFold = in;
%         inFold.reachEpochs = in.reachEpochs(C.training(n),:);
%         foldModel = fitPhasicAndFB_6(inFold);
%         out = applyPhasicAndFB(inFold, foldModel);
%         
%         %standard magnitude decoder
%         rEpochs = [inFold.reachEpochs(:,1)+10, inFold.reachEpochs(:,2)];
%         rIdx = expandEpochIdx(rEpochs);
%         alpha = linspace(0.8,0.98,10);
%         err = zeros(length(alpha),1);
%         dec = cell(length(alpha),1);
%         for a=1:length(alpha)
%             dec{a} = buildMagDec( inFold.reachEpochs, posErr/inFold.maxDist, alpha(a), out.popResponse(:,1:2), out.popResponse(:,3) );
%             decVec = applyMagDec( dec{a}, alpha(a), out.popResponse(:,1:2), out.popResponse(:,3) );
%             err(a) = getFTargErr( decVec(rIdx,:), posErr(rIdx,:), inFold.maxDist );
%         end
%         [~,minIdx] = min(err);
%         
%         testEpochs = in.reachEpochs(C.training(n),:);
%         testIdx = expandEpochIdx([testEpochs(:,1)+10, testEpochs(:,2)]);
%         decVecFinal = applyMagDec( dec{minIdx}, alpha(minIdx), out.popResponse(:,1:2), out.popResponse(:,3) );
%         xValOutLin{1}(testIdx,:) = decVecFinal(testIdx,:);
%         
%         %linear decoder with exponential smoothing
%         for a=1:length(alpha)
%             decPop = filter(1-alpha(a),[1, -alpha(a)], out.popResponse(:,1:2));
%             err(a) = getFTargErr( decPop(rIdx,:), posErr(rIdx,:), inFold.maxDist );
%         end
%         [~,minIdx] = min(err);
%         
%         decVecFinal = filter(1-alpha(minIdx),[1, -alpha(minIdx)], out.popResponse(:,1:2));
%         xValOutLin{2}(testIdx,:) = decVecFinal(testIdx,:);
%     end
% 
%     allIdx = expandEpochIdx([in.reachEpochs(:,1)+10, in.reachEpochs(:,2)]);
%     nearIdx = intersect(allIdx, find(matVecMag(posErr,2)<in.maxDist*0.25));
%     farIdx = setdiff(allIdx, nearIdx);
%     
%     mae = zeros(2,1);
%     speedRatio = zeros(2,1);
%     for d=1:2
%         mae(d) = nanmean(abs(getAngularError(posErr(allIdx,:), xValOutLin{d}(allIdx,:))))*(180/pi);
%         speed = matVecMag(xValOutLin{d},2);
%         speedRatio(d) = mean(speed(nearIdx))/mean(speed(farIdx));
%     end
    
%     for n=1:nFolds
%         disp(['Fold: ' num2str(n)]);
%         trainIdx = setdiff(1:length(useTrlIdx), testIdx);
%         innerTrainIdx = trainIdx(1:(4*floor(length(trainIdx)/5)));
%         innerTestIdx = setdiff(trainIdx, innerTrainIdx);
%         
%         for p=1:length(popIdx)
%             [inputs, targets, globalIdx] = formatInput(reachEpochs, innerTrainIdx, nBinsPerChunk, popResponse{1}, in.kin.posErrForFit, popIdx{p});
%             [inputsVal, targetsVal, globalIdxVal] = formatInput(reachEpochs, innerTestIdx, nBinsPerChunk, popResponse{1}, in.kin.posErrForFit, popIdx{p});
%             [inputsFinal, targetsFinal, globalIdxFinal] = formatInput(reachEpochs, testIdx, nBinsPerChunk, popResponse{1}, in.kin.posErrForFit, popIdx{p});
% 
%             save('C:\Users\Frank\Documents\Big Data\frwSimulation\BCI Modeling Results\nn4Comp\rnnData.mat',...
%                 'inputs','targets','inputsVal','targetsVal','inputsFinal','targetsFinal');
%             tic;
%             system('python "C:\Users\Frank\Documents\Python Scripts\rnn4Comp.py"');
%             toc;
%             tmp = load('C:\Users\Frank\Documents\Big Data\frwSimulation\BCI Modeling Results\nn4Comp\rnnResults.mat');
%             
%             out = permute(tmp.outputsFinal,[2 1 3]);
%             out = reshape(out, size(out,1)*size(out,2), 2);
%             targ = permute(targetsFinal,[2 1 3]);
%             targ = reshape(targ, size(targ,1)*size(targ,2), 2);
%             goodIdx = find(all(~isnan(targ),2));
%             
%             xValOut{p}(globalIdxFinal,:) = out(goodIdx,:);
%             disp(diag(corr(out(goodIdx,:), targ(goodIdx,:))));
%         end
%         
%         testIdx = testIdx + nPerFold;
%     end
end

% function [input, target, globalIdx] = formatInput(reachEpochs, trlIdx, nBinsPerChunk, popResponse, posErr, popIdx)
%     input = zeros(length(trlIdx),nBinsPerChunk,length(popIdx));
%     target = nan(length(trlIdx),nBinsPerChunk,2);
%     globalIdx = [];
%     for t=1:length(trlIdx)
%         loopIdx = reachEpochs(trlIdx(t),1):reachEpochs(trlIdx(t),2);
%         allIdx = (reachEpochs(trlIdx(t),1)-nBinsPerChunk+length(loopIdx)):reachEpochs(trlIdx(t),2);
%         input(t,:,:) = popResponse(allIdx,popIdx);
%         target(t,(end-length(loopIdx)+1):end,:) = posErr(loopIdx,:);
% 
%         globalIdx = [globalIdx; loopIdx'];
%     end
% end