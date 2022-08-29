function [ decVals ] = applyTopNDecoder( decoder, features )
    normFeatures = bsxfun(@times, bsxfun(@plus, features, -decoder.featureMeans), 1./decoder.featureStd);
    decVals = normFeatures * decoder.matrix;
end

