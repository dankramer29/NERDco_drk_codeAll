function [ stdVal, carChans ] = getCarChansAndRMS( fileName, nCarChans )

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

    %compute RMS
    stdVal = std(allData);
    
    %CAR
    carChans = [];
    if ~isempty(nCarChans) && nCarChans>0
        [~,sortIdx] = sort(stdVal,'ascend');
        carChans = sortIdx(1:nCarChans);
    
        carSignal = mean(allData(:, carChans),2);
        for n=1:size(allData,2)
            allData(:,n) = allData(:,n) - carSignal;
        end
        stdVal = std(allData);
    end
end

