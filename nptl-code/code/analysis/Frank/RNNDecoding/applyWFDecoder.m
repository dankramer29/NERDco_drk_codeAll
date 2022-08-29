function [ predVal ] = applyWFDecoder( dec, features, testLoopIdx )
    %Weiner filter
    predVal = zeros(length(testLoopIdx),size(dec.curW,1));

    for t=1:length(testLoopIdx)
        feat = features((testLoopIdx(t)-49):testLoopIdx(t),:);
        feat = [1; feat(:)];
        predVal(t,:) = dec.curW*feat;
    end
end

