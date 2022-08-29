function [ paramVec ] = rnnDecMakeFullParamVec( defaultOpts, fieldCols, valueTable )
    nRuns = size(valueTable,1);
    paramVec = repmat(defaultOpts, nRuns, 1);
    
    for n=1:nRuns
        for c=1:length(fieldCols)
            paramVec(n).(fieldCols{c}) = valueTable{n,c};
        end
    end
end

