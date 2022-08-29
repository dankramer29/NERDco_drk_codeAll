function [ thresholds ] = getThresholdsFromNS5( fileName, threshMultiplier, carChans, nSecPerChunk )

    initialReadData = openNSx_v620(fileName, 'read', 'c:1:1');
    if iscell(initialReadData.Data)
        nPoints = length(initialReadData.Data{end});
    else
        nPoints = initialReadData.Data;
    end
    
    timeIdx = 1:(nSecPerChunk*30000);
    timeIdx(timeIdx>nPoints) = [];

    allData = zeros(length(timeIdx),96);
    for c=1:96
        disp(c);
        tmpData = openNSx_v620(fileName, 'read', ['c:' num2str(c) ':' num2str(c)]);
        if iscell(tmpData.Data)
            tmpData = tmpData.Data{end};
        else
            tmpData = tmpData.Data;
        end
        allData(:,c) = tmpData(timeIdx);
    end

    [B,A] = butter(4,2*[250 5000]/30000);
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

    stdVal = std(allData);
    thresholds = stdVal * threshMultiplier;
end

