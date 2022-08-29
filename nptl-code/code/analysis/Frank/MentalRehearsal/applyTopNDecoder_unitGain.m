function [ decVals ] = applyTopNDecoder_unitGain( decoder, features )
    normFeatures = bsxfun(@times, bsxfun(@plus, features, -decoder.featureMeans), 1./decoder.featureStd);
    unitMatrix = bsxfun(@times, decoder.matrix, 1./matVecMag(decoder.matrix,1));
    decVals = normFeatures * unitMatrix;
end

