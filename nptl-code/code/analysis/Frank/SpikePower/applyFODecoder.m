function [ response ] = applyFODecoder( dec, predictors )
    predictors = bsxfun(@plus, predictors, dec.fMean);
    predictors = bsxfun(@times, predictors, 1./dec.fStd);
    response = predictors(:,dec.useFeatIdx) * dec.filts;
end

