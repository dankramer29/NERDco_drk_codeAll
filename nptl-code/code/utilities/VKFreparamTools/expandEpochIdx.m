function [ idx ] = expandEpochIdx( epochs )
    idx = [];
    for e=1:size(epochs,1)
        idx = [idx, epochs(e,1):epochs(e,2)];
    end
end

