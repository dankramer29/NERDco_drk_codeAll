function [ normFactor, indFactors ] = normalizeDecoder_indDim(posErr, decVectors, farDistInterval)
    %project the decoded vectors onto a vector that points at the target,
    %then take the mean of this projection when the user is far from the
    %target to estimate decoder gain. 
    
    %"normFactor" is what you need to multiply your decoding matrix by in
    %order to normalize it so that the mean of its projected output is 1. 
    
    targDist = sqrt(sum(posErr.^2,2));
    unitErr = bsxfun(@times, posErr, 1./targDist);
    projDec = sum(unitErr.*decVectors,2);
    
    farIdx = (targDist > farDistInterval(1)) & (targDist < farDistInterval(2));
    normFactor = 1/mean(projDec(farIdx));
    
    indFactors = zeros(size(posErr,2),1);
    for dimIdx=1:size(posErr,2)
        indFactors(dimIdx) = regress(decVectors(farIdx,dimIdx), unitErr(farIdx,dimIdx));
    end
    indFactors = 1./indFactors;
end
