function out = fitPhasicAndFB_6(in)
    %cursorPos
    %targPos
    %reachEpochs
    %gameType
    %features (should be z-scored)
    %blockNum

    featuresWithOnes = [ones(size(in.features,1),1), in.features];
    reachIdx_cVec = expandEpochIdx([in.reachEpochs(:,1)+in.rtSteps, in.reachEpochs(:,2)]);
    tOffsets = -100:400;
    
    %%
    %first estimate the direction, distance, and time signals        
    decoderForDirSignal = buildLinFilts(in.kin.posErrForFit(reachIdx_cVec,:), featuresWithOnes(reachIdx_cVec,:), 'standard');
    decodedDirSignal = featuresWithOnes * decoderForDirSignal;
    
    noNegative = true;
    nKnots = 10;
    targDist = matVecMag(in.targetPos - in.cursorPos,2);
    maxDist = prctile(targDist(in.reachEpochs(:,1)), 90)*0.95;
    fTargModel = fitFTarg(in.kin.posErrForFit(reachIdx_cVec,:), decodedDirSignal(reachIdx_cVec,:), maxDist, nKnots, noNegative);
    fTargModel(:,2) = fTargModel(:,2)/fTargModel(end,2);
    
    %%
    %fit time signal to residuals
    tKnots = [0:100 120:50:min(300,max(in.kin.timePostGo(:,1)))];
    %tKnots = [0:150 170:50:min(300,max(in.kin.timePostGo(:,1)))];
    reachIdx = expandEpochIdx(in.reachEpochs);
    targDistWeight = interp1([fTargModel(:,1); fTargModel(end,1)+1], [fTargModel(:,2); fTargModel(end,2)], in.kin.targDist, 'linear', 'extrap');
    
    predictors = [];
    if strcmp(in.modelType,'FMP') || strcmp(in.modelType,'FM')
        predictors = [bsxfun(@times, in.kin.unitVec, targDistWeight), targDistWeight];
    elseif strcmp(in.modelType,'FP') || strcmp(in.modelType,'F')        
        predictors = bsxfun(@times, in.kin.unitVec, targDistWeight);
    elseif strcmp(in.modelType,'MP') || strcmp(in.modelType,'M')
        predictors = targDistWeight;
    end
    predictors = [ones(size(targDistWeight,1),1), predictors];
    pdCoef = buildLinFilts(in.features(reachIdx,:), predictors(reachIdx,:), 'standard');
    predVals = predictors*pdCoef;
    
    %before computing the residuals, adjust timing optimally for each
    %feature, so the residual doesn't contain substantial variance due to
    %features turning on at slightly different times
%     nFeat = size(predVals,2);
%     timingJitter = -4:4;
%     timeShiftedPred = zeros(length(in.features)-20, nFeat);
%     optimalShift = zeros(nFeat,1);
%     for f = 1:nFeat
%         tmp = zeros(length(timingJitter),1);
%         for t=1:length(timingJitter)
%             input = predVals((timingJitter(t)+11):(end-10+timingJitter(t)), f);
%             feat = in.features(11:(end-10),f);
%             tmp(t) = corr(input,feat);
%         end
%         [~,optIdx] = max(tmp);
%         optimalShift(f) = timingJitter(optIdx);
%         timeShiftedPred(:,f) = predVals((optimalShift(f)+11):(end-10+optimalShift(f)), f);
%     end
%     residuals = in.features - [zeros(10,nFeat); timeShiftedPred; zeros(10,nFeat)];

    residuals = in.features - predVals;
    if isfield(in, 'outlierRemoveForCIS') && in.outlierRemoveForCIS
        totalNorm = matVecMag(in.features,2);
        totalNorm = zscore(totalNorm);
        outlierIdx = abs(totalNorm)>5;
        residuals(outlierIdx,:) = repmat(mean(residuals(~outlierIdx,:)), sum(outlierIdx), 1);
    end
    
    c = triggeredAvg( residuals, in.reachEpochs, [tOffsets(1) tOffsets(end)] );
    cMean = squeeze(nanmean(c));
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(cMean, 'Centered', 'off') ;
    weightsTime = SCORE(tKnots + 100, 1);
    weightsTime = weightsTime/max(abs(weightsTime));
    
    %%
    out.fTarg = fTargModel;
    out.fTime = [tKnots'*0.02, weightsTime];
    out.tOffsets = tOffsets;
    
    if strcmp(in.gameType, 'speedDelay') && isfield(in,'speedCode')
        speedMultipliers = ones(size(in.kin.timePostGo,1),1);
        for t=1:length(in.speedCode)
            loopIdx = in.reachEpochs(t,1):in.reachEpochs(t,2);
            speedMultipliers(loopIdx) = in.speedCode(t);
        end
    else
        speedMultipliers = ones(size(in.kin.timePostGo,1),1);
    end
    
    timeWeight = interp1([out.fTime(:,1); out.fTime(end,1)+1], [out.fTime(:,2); out.fTime(end,2)], in.kin.timePostGo(:,2), 'linear', 'extrap');
    predVectors = [ones(length(timeWeight),1), bsxfun(@times, in.kin.unitVec, targDistWeight), targDistWeight, timeWeight];
    predVectors(:,[2 3 4]) = bsxfun(@times, predVectors(:,[2 3 4]), speedMultipliers);
    
    %%
    %adjust sign of time weights
    modelTypes = {'FMP','FP','FM','MP','F','P','M'};
    popIdx = {[1:4],[1:2 4],[1:3],[3:4],[1:2],[4],3};
    timeIdx = {[4],[3],[],[2],[],[1],[]};  
    modelIdx = strcmp(modelTypes, in.modelType);
    
    predVectors = predVectors(:, [1, popIdx{modelIdx}+1]);
    pdCoef = predVectors(reachIdx,:) \ in.features(reachIdx,:);
    reconFeatures = predVectors * pdCoef;
    
    SSERR = sum((reconFeatures(reachIdx,:) - in.features(reachIdx,:)).^2);
    SSTOT = sum((in.features(reachIdx,:)-repmat(mean(in.features(reachIdx,:)),size(in.features(reachIdx,:),1),1)).^2);
    R2Vals = 1 - SSERR./SSTOT;
    
    %return model
    out.tuningCoef = pdCoef;
    out.expCoef = zeros(5, size(pdCoef,2));
    out.expCoef([1, popIdx{modelIdx}+1], :) = pdCoef;
    out.modelType = in.modelType;
    out.R2Vals = R2Vals;
    out.modelVectors = predVectors;
    out.popIdx = popIdx{modelIdx};
    out.timeIdx = timeIdx{modelIdx};

    out.featureMeans = mean(in.features(reachIdx,:));
    centeredFeatures = bsxfun(@plus, in.features(reachIdx,:), -out.featureMeans);
    out.zModelVectors = zscore(double(predVectors(reachIdx,2:end)));
    
    out.filts = buildLinFilts(out.zModelVectors, centeredFeatures, 'inverseLinear');

end
