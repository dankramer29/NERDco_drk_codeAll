
function [ bandPow, timeAxis, metaTags ] = getBandPowerFromNS5( fileName, carChans, bands, binMS, decFactor )

    %opens all the data - be careful with RAM
    rawData = openNSx_v620(fileName, 'read', 'c:1:96');
    if iscell(rawData.Data)
        allData = double(rawData.Data{end}')*0.25;
    else
        allData = double(rawData.Data')*0.25;
    end
        
    %CAR
    nChan = size(allData,2);
    if ~isempty(carChans)
        carSignal = mean(allData(:, carChans),2);
        for n=1:nChan
            allData(:,n) = allData(:,n) - carSignal;
        end
    end
    
    originalDecSignal = zeros(round(size(allData,1)/decFactor), size(allData,2));
    for colIdx=1:size(allData,2)
        originalDecSignal(:,colIdx) = decimate(allData(:,colIdx), decFactor);
    end
    
    decSR = rawData.MetaTags.SamplingFreq/decFactor;
    clear allData
    
    bandPow = cell(size(bands,1),1);
    for b=1:size(bands,1)
        
        [B,A] = butter(4,2*bands(b,:)/decSR);
        decSignal = originalDecSignal;
        for n=1:size(decSignal,2)
            decSignal(:,n) = filtfilt(B,A,decSignal(:,n));
        end

        %compute power
        decSignal = decSignal.^2;

        %put into bins
        nSamples = (binMS/1000)*decSR;
        startIdx = rawData.MetaTags.Timestamp(end)+1;
        binIdx = startIdx:(startIdx+nSamples-1);
        nBins = floor((size(decSignal,1)-startIdx+1)/nSamples);

        bandPow{b} = zeros(nBins, size(decSignal,2));
        timeAxis = zeros(nBins, 1);
        %tOffset = (rawData.MetaTags.Timestamp(end)-1)/30000;
        for n=1:nBins
            binIdx(binIdx>length(decSignal))=[];
            bandPow{b}(n,:) = mean(decSignal(binIdx,:));
            timeAxis(n) = (binIdx(1)/decSR);
            binIdx = binIdx + nSamples;
        end
    end
    
    metaTags = rawData.MetaTags;
end


