function [ decoder ] = buildTopNDecoder( features, targetVals, topN, decType )
    if nargin<4
        decType = 'inverseLinear';
    end
    featureMeans = mean(features);
    featureStd = std(features);
    featureStd(featureStd==0) = 1;
    normFeatures = bsxfun(@times, bsxfun(@plus, features, -featureMeans), 1./featureStd);
    
    %x-val
%     data.targetVals = targetVals;
%     [linModels] = fitLinModels(normFeatures, data, {'targetVals'}, 1, 'standard');
%     tmp = mean(horzcat(linModels{1}.cVal.R2{:}));
    
    %simple correlation
    %tmp = normFeatures \ targetVals;
    %tmp = matVecMag(tmp,2);
    
     tmp = corr(normFeatures, targetVals);
     tmp(isnan(tmp)) = 0;
     tmp = sum(abs(tmp),2);
    
    [bestVals, best] = sort(tmp, 'descend');
    notNanIdx = find(~isnan(bestVals));
    bestN = best(notNanIdx(1:topN));
    
    useCols = var(targetVals)~=0;
    rankOfTV = rank(targetVals(:,useCols));
    
    %this is a pain: if the target values contain linearly dependent
    %columns, the kalman filter in buildLinFilts can break. In this case,
    %build the filter to decode the reduced dimensionality PC scores, and then expand the
    %filter coefficients back out. 
    if rankOfTV<sum(useCols)
        [COEFF, SCORE] = pca(targetVals(:,useCols));
        useTV = SCORE(:,1:rankOfTV);
    else
        useTV = targetVals(:,useCols);
    end
    
    badCols = all(bsxfun(@eq, normFeatures(:,bestN), mean(normFeatures(:,bestN)))) | (sum(features(:,bestN)~=0)/size(features(:,bestN),1)<0.03);    
    filts = buildLinFilts( useTV, normFeatures(:,bestN(~badCols)), decType );
    
    if rankOfTV<sum(useCols)
        filts =  filts * COEFF(:,1:rankOfTV)';
    end
    fullFilts = zeros(size(normFeatures,2), size(targetVals,2));
    fullFilts(bestN(~badCols),useCols) = filts;
    
    decoder.matrix = fullFilts;
    decoder.featureMeans = featureMeans;
    decoder.featureStd = featureStd;
end

