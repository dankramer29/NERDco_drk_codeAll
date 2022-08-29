function [input, target, globalIdx] = formatTrialsForRNN(reachEpochs, trlIdx, nBinsPerChunk, featureInput, targetValues)
    input = zeros(length(trlIdx),nBinsPerChunk,size(featureInput,2));
    target = zeros(length(trlIdx),nBinsPerChunk,2);
    globalIdx = [];
    for t=1:length(trlIdx)
        loopIdx = reachEpochs(trlIdx(t),1):reachEpochs(trlIdx(t),2);
        allIdx = (reachEpochs(trlIdx(t),1)-nBinsPerChunk+length(loopIdx)):reachEpochs(trlIdx(t),2);
        input(t,:,:) = featureInput(allIdx,:);
        target(t,:,:) = targetValues(allIdx,:);

        globalIdx = [globalIdx; loopIdx'];
    end
    
    input = single(input);
    target = single(target);
end