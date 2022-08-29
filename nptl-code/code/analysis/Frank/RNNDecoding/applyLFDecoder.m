function [ out ] = applyLFDecoder( dec, features )
    smoothFeatures = [ones(length(features),1), filter(1-dec.fAlpha,[1, -dec.fAlpha], features)];
    lagFeatures = [zeros(50,size(smoothFeatures,2)); smoothFeatures];
    lagFeatures = lagFeatures((51-dec.lagSteps):(end-dec.lagSteps),:);
    out = lagFeatures * dec.coef;
end

