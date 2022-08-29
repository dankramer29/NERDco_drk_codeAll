function [ dec ] = buildFODecoder( predictors, response, optimizeThresh, nChan, nTXPerChan, hasTX, hasSP, topN )
    if optimizeThresh
        featIdx = 1:nTXPerChan;
        bestFeat = zeros(nChan,1);
        for n=1:nChan
            coef = buildLinFilts(predictors(:,featIdx), [ones(length(response),1), response], 'standard');
            pred = [ones(length(response),1), response] * coef;
            R2 = 1 - sum((predictors(:,featIdx) - pred).^2)./sum(predictors(:,featIdx).^2);
            
            [~,maxIdx] = max(R2);
            bestFeat(n) = featIdx(maxIdx);
            featIdx = featIdx + nTXPerChan;
        end
        
        useFeatIdx = bestFeat;
        if hasSP
            useFeatIdx = [useFeatIdx; ((size(predictors,2)-nChan+1):size(predictors,2))'];
        end
    else
        useFeatIdx = 1:size(predictors,2);
    end
    
    if hasTX && hasSP
        txInd = 1:(size(predictors,2)-nChan);
    elseif hasTX
        txInd = 1:size(predictors,2);
    else
        txInd = [];
    end
    if ~isempty(txInd)
        badTX = mean(predictors(:,txInd)==0)>0.90;
        useFeatIdx = setdiff(useFeatIdx, txInd(badTX));
    end
    
    if ~isempty(topN) && length(useFeatIdx)>topN
        coef = buildLinFilts(predictors(:,useFeatIdx), [ones(length(response),1), response], 'standard');
        pred = [ones(length(response),1), response] * coef;
        R2 = 1 - sum((predictors(:,useFeatIdx) - pred).^2)./sum(predictors(:,useFeatIdx).^2);
        [~,sortIdx] = sort(R2,'descend');
        topIdx = sortIdx(1:topN);
        useFeatIdx = useFeatIdx(topIdx);
    end
    
    fMean = mean(predictors);
    fStd = std(predictors);
    normPred = zscore(predictors);
    filts = buildLinFilts(response, normPred(:,useFeatIdx), 'standard');
    
    dec.fMean = fMean;
    dec.fStd = fStd;
    dec.filts = filts;
    dec.useFeatIdx = useFeatIdx;
end

