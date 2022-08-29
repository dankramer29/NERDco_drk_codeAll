function [ output_args ] = lessBiasedCorrOfOLS( predictors, response, nFolds )
    %
    estPD = [ones(size(targLocs,1),1), targLocs]\neuralData';
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
        testIdx = x:nTrials:size(targLocs,1);
        trainIdx = setdiff(1:size(targLocs,1), testIdx);

        estPD_train = [ones(length(trainIdx),1), targLocs(trainIdx,:)]\neuralData(:,trainIdx)';
        estPD_train = estPD_train';
        
        estPD_test = [ones(length(testIdx),1), targLocs(testIdx,:)]\neuralData(:,testIdx)';
        estPD_test = estPD_test';
        
        allCVEst(x,1) = (estPD_train(:,2)-mean(estPD_train(:,2)))'*(estPD_test(:,2)-mean(estPD_test(:,2)));
        allCVEst(x,2) = (estPD_train(:,3)-mean(estPD_train(:,3)))'*(estPD_test(:,3)-mean(estPD_test(:,3)));
    end
    cvEstMag = sign(mean(allCVEst)).*sqrt(abs(mean(allCVEst)));
   
    finalEstimates(outerRepIdx,2) = (estPD(:,2)-mean(estPD(:,2)))'*(estPD(:,3)-mean(estPD(:,3)))/(cvEstMag(1)*cvEstMag(2));
end

