%%
%preliminaries
nReps = 4000;
nNeurons = 100;

trueCorr = 1.0;
sigmaX = 1;
sigmaY = 1;
covMatrix = [sigmaX^2, trueCorr*sigmaX*sigmaY;
    trueCorr*sigmaX*sigmaY, sigmaY^2];

theta = linspace(0,2*pi,9);
theta = theta(1:(end-1));
targLocs = [cos(theta)', sin(theta)'];
nTrials = 10;
targLocs = repmat(targLocs, nTrials, 1);

targLocsExp = zeros(size(targLocs,1)*2,1);
targLocsExp(1:size(targLocs,1),1) = targLocs(:,1);
targLocsExp((size(targLocs,1)+1):end,2) = targLocs(:,1);

%%
finalEstimates = zeros(nReps,2);
for outerRepIdx=1:nReps
    truePD = mvnrnd(zeros(nNeurons,2),covMatrix);
    
    neuralMeans = [ones(nNeurons,1), truePD]*[ones(size(targLocsExp,1),1), targLocsExp]';
    neuralData = neuralMeans + 2*randn(size(neuralMeans));
    
    estPD = [ones(size(targLocsExp,1),1), targLocsExp]\neuralData';
    estPD = estPD';
    
    %sample estimates
    cMat = corr(estPD(:,2:3));
    finalEstimates(outerRepIdx,1) = cMat(1,2);
    
    %tmp = 1-cMat(1,2)^2;
    %[z, y] = hypergeometric2F1ODE(1/2,1/2,(nNeurons-1)/2,[0, tmp, 1]);
    %finalEstimates(outerRepIdx,2) = cMat(1,2)*y(2);
    
    %cross-validation
    allCVEst = zeros(nTrials,2);
    for x=1:nTrials
        testIdx = x:nTrials:size(targLocsExp,1);
        trainIdx = setdiff(1:size(targLocsExp,1), testIdx);

        estPD_train = [ones(length(trainIdx),1), targLocsExp(trainIdx,:)]\neuralData(:,trainIdx)';
        estPD_train = estPD_train';
        
        estPD_test = [ones(length(testIdx),1), targLocsExp(testIdx,:)]\neuralData(:,testIdx)';
        estPD_test = estPD_test';
        
        allCVEst(x,1) = (estPD_train(:,2)-mean(estPD_train(:,2)))'*(estPD_test(:,2)-mean(estPD_test(:,2)));
        allCVEst(x,2) = (estPD_train(:,3)-mean(estPD_train(:,3)))'*(estPD_test(:,3)-mean(estPD_test(:,3)));
    end
    cvEstMag = sign(mean(allCVEst)).*sqrt(abs(mean(allCVEst)));
   
    finalEstimates(outerRepIdx,2) = (estPD(:,2)-mean(estPD(:,2)))'*(estPD(:,3)-mean(estPD(:,3)))/(cvEstMag(1)*cvEstMag(2));
end

%%
nReps = 10000;
nDim = 100;
finalEstimates = zeros(nReps,3);
for outerRepIdx=1:nReps
    data1 = randn(20,nDim);
    data2 = randn(20,nDim)+1.0;
    
    finalEstimates(outerRepIdx,1) = lessBiasedDistance( data1, data2 );
    
    Z = [ones(size(data1,1)*2,1), [-ones(size(data1,1),1); ones(size(data2,1),1)]];
    B = Z\[data1; data2];
    err = [data1; data2]-Z*B;
    errVar = sum(err.^2)/(40-2);
    
    B_var = errVar*(1/(Z(:,2)'*Z(:,2)));
    B_var = mean(B_var);
    
    sqEst = (B(2,:))*(B(2,:))'-nDim*B_var;
    finalEstimates(outerRepIdx,2) = sign(sqEst)*sqrt(abs(sqEst))*2;
    
    response = zeros(40,nDim);
    response(1:2:end,:) = data1;
    response(2:2:end,:) = data2;
    
    predictors = zeros(40,2);
    predictors(1:2:end,:) = repmat([1,1],20,1);
    predictors(2:2:end,:) = repmat([1,-1],20,1);
    [ meanMagnitude, meanSquaredMagnitude, B ] = cvStatsForOLS( predictors, response, 20, false, true );
end