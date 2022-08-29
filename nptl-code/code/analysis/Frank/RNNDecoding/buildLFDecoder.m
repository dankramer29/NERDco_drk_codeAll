function [ dec ] = buildLFDecoder( reachEpochs, fAlpha, lagSteps, features, targetValues )
    allCoef = cell(length(fAlpha),length(lagSteps));
    rIdx = expandEpochIdx(reachEpochs);
    err = zeros(length(fAlpha),length(lagSteps));
    
    for a=1:length(fAlpha)
        disp(a);
        smoothFeatures = [ones(length(features),1), filter(1-fAlpha(a),[1, -fAlpha(a)], features)];
        
        %sweep lags
        for l=1:length(lagSteps)
            coef = buildLinFilts(targetValues(rIdx,:), smoothFeatures(rIdx-lagSteps(l),:), 'standard');
            predVals = smoothFeatures * coef;
            err(a,l) = mean(mean((predVals(rIdx-lagSteps(l),:) - targetValues(rIdx,:)).^2));
            allCoef{a,l} = coef;
        end
    end

    [minErr,minIdx] = min(err(:));
    [i,j] = ind2sub(size(err), minIdx);
    dec.fAlpha = fAlpha(i);
    dec.lagSteps = lagSteps(j);
    dec.coef = allCoef{i,j};
end

