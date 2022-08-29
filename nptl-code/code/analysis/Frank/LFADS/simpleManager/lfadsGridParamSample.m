function [ paramValues ] = lfadsGridParamSample( valuePossibilities, nReps )
    valLengths = zeros(length(valuePossibilities),1);
    for p=1:length(valuePossibilities)
        valLengths(p) = length(valuePossibilities{p});
    end
    nPoints = prod(valLengths);
    nTotalPoints = nPoints * nReps;
    
    paramValues = zeros(nTotalPoints, length(valuePossibilities));
    pointIdx = 1;
    for repIdx=1:nReps
        for n=1:nPoints
            subIdx{:} = ind2sub(valLengths, n);
            for p=1:length(valuePossibilities)
                paramValues(pointIdx,p) = valuePossibilities{p}(subIdx{p});
            end
            pointIdx = pointIdx+1;
        end
    end
end

