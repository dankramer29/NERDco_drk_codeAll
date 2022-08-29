function [ txEvents ] = getTXFromNS5_all( fileName, threshMultiplier, carChans )
%comment from DRY: It appears this function computes ncTX, but not binned
%in any matter. Just returns raw times.

    %opens all the data - be careful with RAM
    rawData = openNSx_v620(fileName, 'read', 'c:1:96');
    if iscell(rawData.Data)
        allData = double(rawData.Data{end}')*0.25;
    else
        allData = double(rawData.Data')*0.25;
    end
        
    [B,A] = butter(4,2*[250 5000]/30000);
    for n=1:size(allData,2)
        allData(:,n) = filtfilt(B,A,allData(:,n));
    end
    
    %CAR
    if ~isempty(carChans)
        carSignal = mean(allData(:, carChans),2);
        for n=1:nChan
            allData(:,n) = allData(:,n) - carSignal;
        end
    end

    %necessary for proper alignment across the two NSPs
    timeAxis = (0:(size(allData,1)-1)) * (1/rawData.MetaTags.SamplingFreq);
    tOffset = (rawData.MetaTags.Timestamp(end)-1)/30000;
    txEvents = cell(size(allData,2),length(threshMultiplier));

    for n=1:size(allData,2)
        stdVal = -std(allData(:,n));
        for t=1:length(threshMultiplier)
            threshold = stdVal * threshMultiplier(t);
            txEvents{n,t} = txEventsFromRawVoltage( allData(:,n), timeAxis, threshold ) + tOffset;
        end
    end
end

