function [ meanMagnitude, meanSquaredMagnitude, B ] = cvStatsForOLS( predictors, response, nFolds, subtractMeans, transposeB )
    %predictors is an N x D matrix of N samples and D dimensions
    
    %response is an N x R matrix of N samples and R dimensions
    
    %nFolds specifies how many cross-validation folds to use. each fold
    %must be big enough and the data must be ordered in a way such that
    %both the training set and the held out set for each fold contain
    %enough data to properly estimate the regression coefficients.
    
    %if subtractMeans is specified and is true, the function will subtract
    %the means of the coefficient vectors before estimating the squared
    %magnitude (this is useful for computing correlation coefficients)
    
    %if transposeB is specified and is true, the regression coefficients
    %will be transposed before computing the vector magnitudes. This is
    %useful if the rows of the coefficient matrix B are the vectors whose
    %size is of interest as opposed to the columns (default).
    
    %default no transpose
    if nargin<5
        transposeB = false;
    end
    if nargin<4
        subtractMeans = false;
    end
    
    %full sample estimate
    B = predictors\response;
    if transposeB
        B = B';
    end
        
    %cross-validation to get estimate of squared magnitude
    nSamplesPerFold = ceil(size(predictors,1)/nFolds);
    heldOutIdx = 1:nSamplesPerFold;
    
    allCVEst = zeros(nFolds,size(B,2),size(B,2));
    for foldIdx=1:nFolds
        %if we're on the last fold, chop off the reamining idx
        heldOutIdx(heldOutIdx>size(predictors,1)) = [];
        trainIdx = setdiff(1:size(predictors,1), heldOutIdx);

        B_train = predictors(trainIdx,:)\response(trainIdx,:);     
        B_heldOut = predictors(heldOutIdx,:)\response(heldOutIdx,:); 
        if transposeB
            B_train = B_train';
            B_heldOut = B_heldOut';
        end
        if subtractMeans
            B_train = B_train - mean(B_train);
            B_heldOut = B_heldOut - mean(B_heldOut);
        end
        
        allCVEst(foldIdx,:,:) = B_train'*B_heldOut;
        heldOutIdx = heldOutIdx + nSamplesPerFold;
    end
    
    meanSquaredMagnitude = squeeze(mean(allCVEst,1));
    meanMagnitude = sign(meanSquaredMagnitude).*sqrt(abs(meanSquaredMagnitude));
end

