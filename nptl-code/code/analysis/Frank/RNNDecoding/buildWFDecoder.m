function [ dec ] = buildWFDecoder( features, targetValues, trainLoopIdx )
    %Weiner filter
    predVal = zeros(length(trainLoopIdx),size(targetValues,2));
    learnDecay = 0.7;
    ep = 1e-9;
    curW = zeros(size(targetValues,2),9601);
    nBatch = 10;
    batchErr = zeros(nBatch,1);
    for batchIdx=1:nBatch
        disp(batchIdx);
        for t=1:length(trainLoopIdx)
            feat = features((trainLoopIdx(t)-49):trainLoopIdx(t),:);
            feat = [1; feat(:)];
            grd = -feat*(targetValues(trainLoopIdx(t),:)-(curW*feat)');
            curW = curW - grd'*ep;

            predVal(t,:) = curW*feat;
        end
        batchErr(batchIdx) = mean(mean((predVal - targetValues(trainLoopIdx,:)).^2));
        ep = ep * learnDecay;
    end
    
    dec.curW = curW;
end

