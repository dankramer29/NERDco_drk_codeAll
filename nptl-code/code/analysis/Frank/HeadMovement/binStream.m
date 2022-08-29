function [ out ] = binStream( stream, binMS, smoothWidth, datFields )

    %unroll and get alignment indices
    allSpikes = [[stream.spikeRaster], [stream.spikeRaster2]];
    allSpikes = allSpikes(stream.continuous.clock(1):end,:);
    if smoothWidth>0
        allSpikes = gaussSmooth_fast(allSpikes, smoothWidth);
    end

    if ~isfield(stream,'blockNum')
        stream.blockNum = zeros(size(stream.continuous.clock));
    end
    
    %%
    %bin data
    nBins = floor(size(allSpikes,1)/binMS)-1;
    
    datStruct = struct();
    for f=1:length(datFields)
        datStruct.(datFields{f}) = zeros(nBins, size(squeeze(stream.continuous.(datFields{f})),2));
    end
    snippetMatrix = zeros(nBins, size(allSpikes,2));
    
    blockNum = zeros(nBins, 1);
    
    binIdx = 1:binMS;
    for b=1:nBins
        snippetMatrix(b,:) = sum(allSpikes(binIdx,:));
        for f=1:length(datFields)
            tmp = squeeze(stream.continuous.(datFields{f})(binIdx,:,:));
            datStruct.(datFields{f})(b,:) = mean(tmp);
        end
        
        blockNum(b) = median(stream.blockNum(binIdx,:));
        binIdx = binIdx + binMS;
    end

    %%
    %mean subtract
    out.rawSpikes = snippetMatrix;
    
    blockList = unique(blockNum);
    for b=1:length(blockList)
        disp(b);
        blockIdx = find(blockNum==blockList(b));
        snippetMatrix(blockIdx,:) = bsxfun(@plus, snippetMatrix(blockIdx,:), -mean(snippetMatrix(blockIdx,:)));
    end
    
    out.meanSubtractSpikes = snippetMatrix;
    
    snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));
    out.zScoreSpikes = snippetMatrix;
    out.spikesStd = std(snippetMatrix);
    
    for f=1:length(datFields)
        out.(datFields{f}) = datStruct.(datFields{f});
    end
    out.blockNum = blockNum;
    
end

