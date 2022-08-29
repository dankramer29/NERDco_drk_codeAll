function [ txEvents, timeAxis, tOffset, metaTags ] = getTXFromNS5_rawThresh( fileName, threshValue, carChans )
%comment from DRY: It appears this function computes ncTX, but not binned
%in any matter. Just returns raw times.

    %opens all the data - be careful with RAM
    rawData = openNSx_v620(fileName, 'read', 'c:1:96');
    if iscell(rawData.Data)
        allData = double(rawData.Data{end}')*0.25;
    else
        allData = double(rawData.Data')*0.25;
    end
    metaTags = rawData.MetaTags;
    
    lowData = zeros(ceil(length(allData)/2),size(allData,2));
    for c=1:size(allData,2)
        lowData(:,c) = decimate(allData(:,c),2);
    end
    allData = lowData;
    
    newSR = 15000;
    [B,A] = butter(6,2*[250 5000]/newSR);
    for n=1:size(allData,2)
        allData(:,n) = filtfilt(B,A,allData(:,n));
    end
    
    %CAR
    if ~isempty(carChans)
        carSignal = mean(allData(:, carChans),2);
        for n=1:size(allData,2)
            allData(:,n) = allData(:,n) - carSignal;
        end
    end

    %necessary for proper alignment across the two NSPs
    timeAxis = (0:(size(allData,1)-1)) * (1/newSR);
    %tOffset = (rawData.MetaTags.Timestamp(end)-1)/newSR;
    tOffset = 0;
    txEvents = cell(size(allData,2),length(threshValue));

    for t=1:length(threshValue)
        for n=1:size(allData,2)
            threshold = threshValue{t}(n);
            txEvents{n,t} = txEventsFromRawVoltage( allData(:,n), timeAxis, threshold ) + tOffset;
        end
    end
end

