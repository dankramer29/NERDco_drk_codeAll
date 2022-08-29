function [ paramValues ] = lfadsUniformParamSample( valuePossibilities, nPoints )
    paramValues = zeros(nPoints, length(valuePossibilities));
    for n=1:nPoints
        for p=1:length(valuePossibilities)
            paramValues(n,p) = valuePossibilities{p}(randi(length(valuePossibilities{p}),1));
        end
    end
end

