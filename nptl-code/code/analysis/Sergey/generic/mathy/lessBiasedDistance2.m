function [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( class1, class2, subtractMean )
    % May 2019: This is Sergey's copy of Frank Willett's code. I've put it into my own repo so I can
    % assume it is static and also modify if needed.
    %
    %class1 and class2 are N x D matrices, where D is the number of
    %dimensions and N is the number of samples
    
    % If class 1 and class 2 are of differnet numbers of trials, it loops through all
    % combinations of trial_i (from class 1) and all trial
    
    %If subtractMean is true, this will center each vector
    %before computing the size of the difference (default is off).
    
    if nargin<3
        subtractMean = false;
    end

    if size( class1, 1 ) == size( class2, 1 )
        % Frank's original way. This is faster
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
    else
        
        squaredDistEstimates = nan( size(class1,1) * size(class2,1) ,1);
        
        iPtr = 0; % will increment through squaredDistEstimates
        for x = 1:size(class1,1)
            for y = 1:size(class2,1)
                iPtr = iPtr + 1;
                bigSetIdx_c1 = [1:(x-1),(x+1):size(class1,1)]; % class 1
                bigSetIdx_c2 = [1:(y-1),(y+1):size(class2,1)]; % class 1
                
                smallSetIdx_c1 = x;
                smallSetIdx_c2 = y;
                
                meanDiff_bigSet = mean(class1(bigSetIdx_c1,:),1) - mean( class2(bigSetIdx_c2,:),1);
                meanDiff_smallSet = class1(smallSetIdx_c1,:)-class2(smallSetIdx_c2,:);
                
                if subtractMean
                    squaredDistEstimates(iPtr) = (meanDiff_bigSet-mean(meanDiff_bigSet))*(meanDiff_smallSet-mean(meanDiff_smallSet))';
                else
                    squaredDistEstimates(iPtr) = meanDiff_bigSet*meanDiff_smallSet';
                end
            end
        end
    end
    
    meanOfSquares = mean(squaredDistEstimates);
    lessBiasedEstimate = sign(meanOfSquares)*sqrt(abs(meanOfSquares));
end

