function [ paramValues ] = rnnUniformParamSample( valuePossibilities, nPoints )
    paramValues = cell(nPoints, length(valuePossibilities));
    for n=1:nPoints
        for p=1:length(valuePossibilities)
            if iscell(valuePossibilities{p})
                paramValues{n,p} = valuePossibilities{p}{randi(length(valuePossibilities{p}),1)};
            else
                paramValues{n,p} = valuePossibilities{p}(randi(length(valuePossibilities{p}),1));
            end
        end
    end
end

