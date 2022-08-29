function [ out ] = binAndUnrollR( R, binMS, smoothWidth, datFields )

    %unroll and get alignment indices
    if isfield(R,'spikeRaster2')
        allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
    else
        allSpikes = [R.spikeRaster]';
    end

    if smoothWidth>0
        allSpikes = gaussSmooth_fast(allSpikes, smoothWidth);
    end
    
    datFields = [datFields, {'blockNum'}];
    
    currentIdx = 1;
    trialEpochs = zeros(length(R),2);
    for t=1:length(R)
        trialEpochs(t,:) = [currentIdx, currentIdx+length(R(t).clock)-1];
        currentIdx = currentIdx + length(R(t).clock);
    end
    
    allDat = struct();
    for f=1:length(datFields)
        if size(R(1).(datFields{f}),2) ~= size(R(1).spikeRaster,2)
            for t=1:length(R)
                R(t).([datFields{f} '_exp']) = repmat(R(t).(datFields{f}),1,size(R(t).spikeRaster,2));
            end  
            datFields{f} = [datFields{f} '_exp'];
        end   
        allDat.(datFields{f}) = [R.(datFields{f})]';
    end
    
    %%
    %bin data
    nBins = floor(size(allSpikes,1)/binMS);
    
    datStruct = struct();
    for f=1:(length(datFields)-1)
        datStruct.(datFields{f}) = zeros(nBins, size(R(1).(datFields{f}),1));
    end
    snippetMatrix = zeros(nBins, size(allSpikes,2));
    
    allBlock = allDat.(datFields{end});
    blockNum = zeros(nBins, 1);
    
    binIdx = 1:binMS;
    for b=1:nBins
        snippetMatrix(b,:) = sum(allSpikes(binIdx,:));
        for f=1:(length(datFields)-1)
            datStruct.(datFields{f})(b,:) = mean(allDat.(datFields{f})(binIdx,:));
        end
        
        blockNum(b) = median(allBlock(binIdx,:));
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
    
    for f=1:(length(datFields)-1)
        out.(datFields{f}) = datStruct.(datFields{f});
    end
    out.blockNum = blockNum;
    
    out.trialEpochs = round(trialEpochs/binMS);
    out.trialEpochs(out.trialEpochs==0) = 1;
    out.trialEpochs(out.trialEpochs>length(out.zScoreSpikes)) = length(out.zScoreSpikes);
end

