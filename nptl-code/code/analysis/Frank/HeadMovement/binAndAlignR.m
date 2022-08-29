function [ out ] = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields )

    %unroll and get alignment indices
    if isfield(R,'spikeRaster2')
        allSpikes = full([[R.spikeRaster]', [R.spikeRaster2]']);
    elseif isfield(R,'spikeRaster')
        allSpikes = full([R.spikeRaster]');
    else
        allSpikes = zeros(length([R.clock]), 10);
    end
    if isfield(R,'HLFP')
        allHLFP = [R.HLFP]';
    else
        allHLFP = zeros(size(allSpikes));
    end
    if smoothWidth>0
        allSpikes = gaussSmooth_fast(allSpikes, smoothWidth);
    end
    
    allDat = struct();
    for f=1:length(datFields)
        allDat.(datFields{f}) = [R.(datFields{f})]';
    end
    
    globalIdx = 0;
    alignEvents = int64(zeros(length(R),length(alignFields)));
    allBlocks = zeros(size(allSpikes,1),1);
    for t=1:length(R)
        if isfield(R,'spikeRaster')
            nMS = size(R(t).spikeRaster,2);
        else
            nMS = length(R(t).clock);
        end
        
        loopIdx = (globalIdx+1):(globalIdx + nMS);
        allBlocks(loopIdx) = R(t).blockNum;
        for f=1:length(alignFields)
            alignEvents(t,f) = globalIdx + R(t).(alignFields{f});
        end
        globalIdx = globalIdx + nMS;
    end

    %%
    %bin data
    nBins = (timeWindow(2)-timeWindow(1))/binMS;
    nTrl = length(R);
    
    datStruct = struct();
    for f=1:length(datFields)
        datStruct.(datFields{f}) = zeros(nTrl*nBins, size(R(1).(datFields{f}),1));
    end
    snippetMatrix = zeros(nTrl*nBins, size(allSpikes,2));
    hlfpMatrix = zeros(nTrl*nBins, size(allSpikes,2));
    
    blockRows = zeros(nTrl*nBins, 1);
    validTrl = false(nTrl,1);
    globalIdx = 1;

    for t=1:nTrl
        disp(t);
        loopIdx = (alignEvents(t,1)+int64(timeWindow(1))):(alignEvents(t,1)+int64(timeWindow(2)));

        if loopIdx(1)<1 || loopIdx(end)>size(allSpikes,1)
            loopIdx(loopIdx<1)=[];
            loopIdx(loopIdx>size(allSpikes,1))=[];
            if isempty(loopIdx)
                loopIdx = size(allSpikes,1);
            end
        else
            validTrl(t) = true;
        end

        newRow = zeros(nBins, size(allSpikes,2));
        newRow_HLFP = zeros(nBins, size(allSpikes,2));
        newDatRow = struct();
        for f=1:length(datFields)
            newDatRow.(datFields{f}) = zeros(nBins, size(R(1).(datFields{f}),1));
        end
        
        binIdx = 1:binMS;
        for b=1:nBins
            if binIdx(end)>length(loopIdx)
                continue;
            end
            newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
            newRow_HLFP(b,:) = sum(allHLFP(loopIdx(binIdx),:).^2);
            for f=1:length(datFields)
                newDatRow.(datFields{f})(b,:) = mean(allDat.(datFields{f})(loopIdx(binIdx),:));
            end
            binIdx = binIdx + binMS;
        end

        newIdx = (globalIdx):(globalIdx+nBins-1);
        globalIdx = globalIdx+nBins;
        
        blockRows(newIdx) = repmat(allBlocks(loopIdx(1)), size(newRow,1), 1);
        for f=1:length(datFields)
            datStruct.(datFields{f})(newIdx,:) = newDatRow.(datFields{f});
        end
        snippetMatrix(newIdx,:) = newRow;
        hlfpMatrix(newIdx,:) = newRow_HLFP;
    end

    %%
    %mean subtract
    out.rawSpikes = snippetMatrix;
    
    bNumPerTrial = [R.blockNum];
    blockList = unique(bNumPerTrial);
    blockMeans = zeros(length(blockList), size(out.rawSpikes,2));
    
    for b=1:length(blockList)
        disp(b);
        binIdx = find(blockRows==blockList(b));
        
        blockMeans(b,:) = mean(snippetMatrix(binIdx,:));
        
        snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -blockMeans(b,:));
        hlfpMatrix(binIdx,:) = bsxfun(@plus, hlfpMatrix(binIdx,:), -mean(hlfpMatrix(binIdx,:)));
    end
    
    out.meanSubtractSpikes = snippetMatrix;
    out.meanSubtractHLFP = hlfpMatrix;
    
    out.featureSTD = std(snippetMatrix);
        
    snippetMatrix = bsxfun(@times, snippetMatrix, 1./out.featureSTD);
    out.zScoreSpikes = snippetMatrix;
    out.zScoreHLFP = bsxfun(@times, hlfpMatrix, 1./std(hlfpMatrix));
    
    for f=1:length(datFields)
        out.(datFields{f}) = datStruct.(datFields{f});
    end
    
    out.blockmeans = blockMeans;
    
    %%
    %event idx
    out.eventIdx = ((-timeWindow(1)/binMS):nBins:size(snippetMatrix,1))';
    out.bNumPerTrial = bNumPerTrial';
end

