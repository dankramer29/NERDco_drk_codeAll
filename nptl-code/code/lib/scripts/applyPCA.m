function T = applyPCA(T,lowDModel)
    for nn = 1:length(T)
        neural = bsxfun(@minus,T(nn).Z,lowDModel.pcaMeans);
        T(nn).ZPCA = lowDModel.projector' * neural;
    end
    