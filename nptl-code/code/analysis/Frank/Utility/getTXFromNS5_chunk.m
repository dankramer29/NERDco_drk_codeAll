function [ txEvents ] = getTXFromNS5_chunk( fileName, thresholds, carChans, nSecPerChunk )

    currentInterval = [0, nSecPerChunk];
    done = false;
    txEvents = cell(96,1);
    chunkIdx = 1;
    
    %do an initia l full read of a single channel
    initialReadData = openNSx_v620(fileName, 'read', 'c:1:1');
    if iscell(initialReadData.Data)
        nPoints = length(initialReadData.Data{end});
    else
        nPoints = initialReadData.Data;
    end
    
    while ~done
        disp(['---------- Chunk ' num2str(chunkIdx) ' ----------']);
        timeIdx = ((currentInterval(1))*30000 + 1):((currentInterval(2))*30000);
        timeIdx(timeIdx>nPoints) = [];
        if isempty(timeIdx)
            break;
        end
        
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
        
        %necessary for proper alignment across the two NSPs
        timeAxis = (0:(size(allData,1)-1)) * (1/30000);
        tOffset = (initialReadData.MetaTags.Timestamp(end)-1)/30000;

        for n=1:size(allData,2)
            txEvents{n} = [txEvents{n}, currentInterval(1) + txEventsFromRawVoltage( allData(:,n), timeAxis, thresholds(n) ) + tOffset];
        end
        
        %advance the chunk interval
        currentInterval = currentInterval + nSecPerChunk;
        chunkIdx = chunkIdx + 1;
    end
end

