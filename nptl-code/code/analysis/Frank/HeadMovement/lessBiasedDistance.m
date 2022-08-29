function [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( class1, class2, subtractMean )
    %class1 and class2 are N x D matrices, where D is the number of
    %dimensions and N is the number of samples
    
    %The way this is written, N must be the same for both class1 and
    %class2, but this could be written in a more complex way to avoid that.
    
    %If subtractMean is true, this will center each vector
    %before computing the size of the difference (default is off).
    
    if nargin<3
        subtractMean = false;
    end

    squaredDistEstimates = zeros(size(class1,1),1);
    for x=1:size(class1,1)
        bigSetIdx = [1:(x-1),(x+1):size(class1,1)];
        smallSetIdx = x;
        
        meanDiff_bigSet = mean(class1(bigSetIdx,:)-class2(bigSetIdx,:));
        meanDiff_smallSet = class1(smallSetIdx,:)-class2(smallSetIdx,:);
        if subtractMean
            squaredDistEstimates(x) = (meanDiff_bigSet-mean(meanDiff_bigSet))*(meanDiff_smallSet-mean(meanDiff_smallSet))';
        else
            squaredDistEstimates(x) = meanDiff_bigSet*meanDiff_smallSet';
        end
    end
    
    meanOfSquares = mean(squaredDistEstimates);
    lessBiasedEstimate = sign(meanOfSquares)*sqrt(abs(meanOfSquares));
end

