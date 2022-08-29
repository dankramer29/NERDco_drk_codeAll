function T = applySoftNormToT(T,isnv)
    for nn = 1:length(T)
        T(nn).Z = bsxfun(@times,T(nn).Z,isnv);
    end
    