function [ postfit ] = fitModelOnConditions_v6_sciRep( P, conditionNums, modelType, resultsDir )
    
    %remove outliers 
    outlierIdx = findOutlierReaches_con( P, conditionNums );    
    for c=1:length(conditionNums)
        P.conditions.trialNumbers{conditionNums(c)} = setdiff(P.conditions.trialNumbers{conditionNums(c)}, outlierIdx{c});
    end
    
    %compile simOpts for each condition
    simOpts_c = cell(length(conditionNums),1);
    reaches_c = cell(length(conditionNums),1);
    for c=1:length(conditionNums)
        %set up simulation
        simOpts_c{c} = prefitToSimOpts_con( P, conditionNums(c), 'matching', length(P.conditions.trialNumbers{conditionNums(c)}) );
        reaches_c{c} = P.trl.reaches(P.conditions.trialNumbers{conditionNums(c)},:);
    end
    
    %configure simulation options movement rules
    for c=1:length(simOpts_c{c})
        if strcmp(modelType.name, 'predictiveStopping')
            simOpts_c{c}.mRule.predictiveStop = true;
            simOpts_c{c}.mRule.type = simOpts_c{c}.mRule.type_piecewisePointModel;
            simOpts_c{c}.mRule.predictiveStopLookAhead = round(0.5 / simOpts_c{1}.loopTime);
        elseif strcmp(modelType.name, 'pointModel') || strcmp(modelType.name,'predictiveOptimalController')
            simOpts_c{c}.mRule.predictiveStopLookAhead = 0;
            simOpts_c{c}.mRule.type = simOpts_c{c}.mRule.type_piecewisePointModel;
        elseif strcmp(modelType.name, 'finiteLQG')
            simOpts_c{c}.mRule.type = simOpts_c{c}.mRule.type_finiteLQG;
        end
        
        if strcmp(modelType.stateEstimation,'fbDelay') || strcmp(modelType.stateEstimation,'infDelay')
            simOpts_c{c}.mRule.feedbackDelay = round(P.feedbackDelay / simOpts_c{1}.loopTime);
            %P.averageRT
            simOpts_c{c}.mRule.integrateBackSteps = 0;
        else
            simOpts_c{c}.mRule.feedbackDelay = 1;
            simOpts_c{c}.mRule.integrateBackSteps = 0;
        end
        
        if modelType.refitStop
            simOpts_c{c}.mRule.stopOnTarget = true;
            simOpts_c{c}.mRule.stopOnTargetRad = -1; %stop on actual target radius
        end
    end
        
    reactionTimeInterval = P.reactionTimeIntervalForFitting;
    
    %normalize command vector to calibration condition
    calConditionIdx = find(P.conditions.calCondition);
    succCalReaches = P.trl.reaches(intersect(find(P.trl.isSuccessful), P.conditions.trialNumbers{calConditionIdx}),:);
    succCalReaches = [succCalReaches(:,1) + round(reactionTimeInterval(1)/simOpts_c{c}.loopTime), succCalReaches(:,2)];
    succCalFP = limitReachesToFirstTargetPass( P.loopMat.positions, P.loopMat.targetPos, succCalReaches );    
    
    cVecNorm = zeros(size(P.loopMat.positions));
    alphaBeta = zeros(length(simOpts_c),2);
    for c=1:length(simOpts_c)
        %include delay periods before reaches here, so we have valid cVec
        %for those time periods
        rIdx = expandReachesBackwards( P.trl.reaches, reaches_c{c} );
        
        if P.conditions.calCondition(conditionNums(c))
            %use the test decoder coefficients, but the calibration
            %decoder's gain
            cVec = P.conditions.decoder{2}.decoderFun(P.conditions.decoder{2}, P.loopMat.featureMatrix, P.loopMat.blockNum);
            cVec = cVec(:,1:2);
            extraGainFactor = P.conditions.nativeGain(1) / P.conditions.nativeGain(2);
        else
            cVec = P.conditions.decoder{conditionNums(c)}.decoderFun(P.conditions.decoder{conditionNums(c)}, P.loopMat.featureMatrix, P.loopMat.blockNum);
            cVec = cVec(:,1:2);
            extraGainFactor = 1;
        end
        
        cVecNormFactor = normalizeCommandVectors( P.loopMat.positions, P.loopMat.targetPos, cVec, succCalFP, P.ffDistInterval);
        cVecNorm(rIdx,:) = cVec(rIdx,:) * cVecNormFactor;
        
        alphaBeta(c,1) = P.conditions.alphaBeta(conditionNums(c));
        alphaBeta(c,2) = extraGainFactor * (1/cVecNormFactor);
    end
        
    %fill in filters to simOpts
    for c=1:length(simOpts_c)
        simOpts_c{c}.filt.ln.B = (1-alphaBeta(c,1))*alphaBeta(c,2);
        simOpts_c{c}.filt.ln.A = [1, -alphaBeta(c,1)];
    end
    
    %compile reaches
    reachesNoRT = [];
    for c=1:length(simOpts_c)
        tmp = reaches_c{c};
        tmp(:,1) = tmp(:,1) + round(reactionTimeInterval(1)/simOpts_c{c}.loopTime);
        reachesNoRT = [reachesNoRT; tmp];
    end
    allReachIdx = expandEpochIdx(reachesNoRT);
        
    %cap cVec (counteract effect of large noise bursts)
    maxMagnitudes =  prctile(abs(cVecNorm(allReachIdx,:)),99.9);
    for dim=1:size(cVecNorm,2)
        largeValIdx = abs(cVecNorm(:,dim)) > maxMagnitudes(dim);
        cVecNorm(largeValIdx,dim) = sign(cVecNorm(largeValIdx,dim))*maxMagnitudes(dim);
    end

    opts = makeCartesianCVecModelOpts();
    opts.pos = double(P.loopMat.positions);
    opts.vel = double(P.loopMat.vel);
    opts.targPos = P.loopMat.targetPos;
    opts.cVec = cVecNorm;
    opts.targRad = P.loopMat.targetRad;
    opts.filtAlpha = alphaBeta(1,1);
    opts.filtBeta = alphaBeta(1,2);
    opts.reachEpochsToFit = reachesNoRT;
    opts.timeStep = simOpts_c{1}.loopTime;
    opts.fbDelayAndBackStep = simOpts_c{1}.loopTime*[simOpts_c{1}.mRule.feedbackDelay, simOpts_c{1}.mRule.integrateBackSteps];

    opts.modelOpts.iterativeNoiseModel = false;
    opts.modelOpts.useDelayedVel = false;
    opts.modelOpts.noVel = strcmp(modelType.modelMode,'noVel');
    opts.modelOpts.targetDeadzone = modelType.refitStop;
    if isfield(modelType,'reducedVariant')
        opts.modelOpts.reducedVariant = modelType.reducedVariant;
    end
    if strcmp(modelType.name, 'finiteLQG')
        opts.modelName = 'lqg';
        opts.modelOpts.timeOpt = 'maxTime';
        opts.maxMoveTime = P.conditions.tmOpts{c}.maxMoveTime;
    else
        opts.modelName = 'pointModel';
    end
    opts.modelOpts.doFTime = false;
    modelOut = fitCartesianCVecModel( opts );

    %put the model into the right field of simulation options
    for c=1:length(simOpts_c)
        if strcmp(modelType.name, 'finiteLQG')
            tmp = modelOut.bestControlModel.L;
            tmp(1,3,:) = tmp(1,3,:) * P.loopTime(1);
            tmp(2,4,:) = tmp(2,4,:) * P.loopTime(1);
            simOpts_c{c}.mRule.finiteLQGMat = tmp;
        else
            simOpts_c{c}.mRule.piecewisePointModel = modelOut.bestControlModel;
        end
    end
    if strcmp(modelType.noiseFitting,'point')
        opts.modelName = 'pointModel';
        opts.fbDelayAndBackStep = [P.feedbackDelay, 0];
        opts.modelOpts.reducedVariant = '';
        modelOut_point = fitCartesianCVecModel( opts );
        noiseTimeSeries = modelOut_point.noiseTimeSeries;
        pCommand = modelOut_point.bestControlModelCVec;
    else
        noiseTimeSeries = modelOut.noiseTimeSeries;
        pCommand = modelOut.bestControlModelCVec;
    end
    
    if strcmp(modelType.noiseModel,'autoregressive')
        arModel = fitARModelAtFarField( noiseTimeSeries, matVecMag(P.loopMat.positions - P.loopMat.targetPos,2), ...
            reachesNoRT, simOpts_c{1}.loopTime, 500, [0, P.ffDistInterval(2)],'multi');
    elseif strcmp(modelType.noiseModel,'white')
        arModel.coef = [];
        arModel.nLags = 0;
        arModel.sigma = std(noiseTimeSeries(allReachIdx,:));
        arModel.cov = cov(noiseTimeSeries(allReachIdx,:));
        arModel.corr = corr(noiseTimeSeries(allReachIdx,:));
    end
    
    if modelType.noiseSignalDependence
        %get noise power as a function of control vector magnitude
        cVecMag = matVecMag(pCommand,2);
        [ estFunc, estFunc_CInorm, estFuncStd, estFuncStd_CInorm ] = estimateBinnedFunction_range( [cVecMag(allReachIdx), noiseTimeSeries(allReachIdx,:)], 20, [0 1.5] );
        
        badPoints = false(size(estFuncStd,1),1);
        for d=1:(size(estFuncStd,2)-1)
            CIRange = diff(squeeze(estFuncStd_CInorm(:,d,:)),1,2);
            badPoints = badPoints | CIRange > 0.3*nanmean(estFuncStd(:,d+1));
        end
        if all(badPoints(~isnan(estFuncStd(:,2))))
            badPoints(:) = false;
        end
        estFuncStd(badPoints,2:3) = NaN;
        estFuncStd(any(estFuncStd(:,2:3)==0,2),2:3)=NaN;
        estFuncStd(:,2:3) = nanInterp(estFuncStd(:,2:3));
        stdSmoothed = filtfilt(ones(5,1)/5, 1, estFuncStd(:,2:3));
        
        ts = genTimeSeriesFromARModel_multi( 10000, arModel.coef, arModel.cov );
        avgStd = std(ts);
        for c=1:length(simOpts_c)
            simOpts_c{c}.noise.magPoints = estFuncStd(:,1);
            simOpts_c{c}.noise.noiseScale = mean(stdSmoothed,2) / mean(avgStd);
        end 
        
        [ estFunc, estFunc_CInorm, estFuncStd, estFuncStd_CInorm ] = estimateBinnedFunction_range( [cVecMag(allReachIdx), noiseTimeSeries(allReachIdx,:)], 20, [0 1.5] );
        rawSDN.magPoints = estFuncStd(:,1);
        rawSDN.noiseSigma = estFuncStd;
        rawSDN.noiseSigmaCI = estFuncStd_CInorm;
        rawSDN.avgStd = avgStd;
    else
        rawSDN = [];
    end
    
    %special control cases (average control model, average noise model,
    %slow block control model)
    if modelType.avgControlModel
        avgModelsFile = load([resultsDir filesep 'testFiles' filesep 'testCell_7_avgControlModels.mat']);
        sessionIdx = strcmp(P.session.name, vertcat(avgModelsFile.sessions.name));
        for c=1:length(simOpts_c)
            simOpts_c{c}.mRule.piecewisePointModel = avgModelsFile.avgModels{sessionIdx};
        end   
    end
    if modelType.sbControlModel
        avgModelsFile = load([resultsDir filesep 'testFiles' filesep 'testCell_7_sbControlModels.mat']);
        sessionIdx = strcmp(P.session.name, vertcat(avgModelsFile.sessions.name));
        for c=1:length(simOpts_c)
            simOpts_c{c}.mRule.piecewisePointModel = avgModelsFile.slowModels{sessionIdx};
        end   
    end
    if modelType.avgNoiseModel
        avgNoiseFile = load([resultsDir filesep 'testFiles' filesep 'testCell_7_avgNoiseModel.mat']);
        arModel = avgNoiseFile.avgModel;
    end    
    if strcmp(modelType.stateEstimation,'infDelay')
        for c=1:length(simOpts_c)
            simOpts_c{c}.mRule.feedbackDelay = 1000;
            simOpts_c{c}.mRule.integrateBackSteps = 0;
        end
    end
    
    %format struct for return
    postfit = makeResultsStruct(arModel, P.conditions.trialNumbers, conditionNums, simOpts_c, reaches_c, modelType, outlierIdx);
    postfit.errFiltered = noiseTimeSeries;
    postfit.pCommand = pCommand;
    postfit.allReachIdx = allReachIdx;
    postfit.rawSDN = rawSDN;
    postfit.cVecNorm = cVecNorm;
end

function postfit = makeResultsStruct(arModel, trialNumbers, conditionNums, simOpts_c, reaches_c, modelType, outlierIdx)
    postfit.fitModel.bestARModel = arModel;
    postfit.fitModel.bestMRule = simOpts_c{1}.mRule;
    
    postfit.outlierReachIdx = outlierIdx;
    postfit.fitTrlNumbers = trialNumbers;
    postfit.fitConditions = conditionNums;
    postfit.fitReaches = reaches_c;
    postfit.fitSimOpts = simOpts_c;
    postfit.modelType = modelType;
end