function [ cVec, normFeatureMatrix, rawFeatureMatrix, decoder, fixedNorms ] = getCVecFromSLCandNCS( slc, ncs, featureFields, featureCaps )
    nRows = size(slc.task.decodedKin,1);
    rawFeatureMatrix = zeros(nRows, 0);
    decoder = [];
    fixedNorms = [];
    if nargin<4
        featureCaps = [];
    end
    
    relIdx = 1;
    for f=1:length(featureFields)
        featInds = ncs.singleBlock.sSLCsent.decoders.kalman.([featureFields{f} 'Inds']);
        tmpDec = zeros(10,size(slc.(featureFields{f}).values,2));
        tmpDec(:,featInds) = ncs.singleBlock.sSLCsent.decoders.kalman.K_pad(:,(relIdx):(relIdx+length(featInds)-1));
        relIdx = relIdx + length(featInds);

        decoder = [decoder, tmpDec];
        tmpFeatures = double(slc.(featureFields{f}).values);
        if ~isempty(featureCaps)
            tmpFeatures(tmpFeatures>featureCaps(f)) = featureCaps(f);
        end
        
        rawFeatureMatrix = [rawFeatureMatrix, tmpFeatures];

        normVals = double(ncs.singleBlock.sSLCsent.decoders.kalman.([featureFields{f} 'Norm']));
        if isrow(normVals)
            normVals = normVals';
        end
        fixedNorms = [fixedNorms; normVals];
    end
        
    decoder = decoder / (1-ncs.singleBlock.sFILT.Linear.lowPassAlpha);
    
    if ncs.singleBlock.sSLCsent.decoders.kalman.AFN_ENABLE && ...
            isfield(ncs.singleBlock.sSLCsent.decoders, 'preDeocode') && ncs.singleBlock.sSLCsent.decoders.preDecode.AFN.isVarianceDividing
        %roughly simulate adaptive means by zscoreing 
        normFeatureMatrix = zscoreOnIdx( rawFeatureMatrix, 1:size(rawFeatureMatrix,1) );
        fixedNorms = 1./std(rawFeatureMatrix);
    else
        %apply fixed means / norms
        normFeatureMatrix = bsxfun(@plus, rawFeatureMatrix, -mean(rawFeatureMatrix));
        normFeatureMatrix = bsxfun(@times, normFeatureMatrix, fixedNorms');
    end

    cVec = (decoder * normFeatureMatrix')';
end

