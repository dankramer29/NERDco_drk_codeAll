function [ txEvents ] = getTXFromNS5( fileName, threshMultiplier )
%comment from DRY: It appears this function computes ncTX, but not binned
%in any matter. Just returns raw times.

    nChannels = 96;
    txEvents = cell(nChannels,length(threshMultiplier));
    for n=1:nChannels
        disp([num2str(n) ' / ' num2str(nChannels)]);
        rawVoltage = openNSx(fileName, 'read', ['c:' num2str(n)]);
        if iscell(rawVoltage.Data)
            rawVoltage.Data = rawVoltage.Data{end};
        end
        
        timeAxis = (0:(length(rawVoltage.Data)-1)) * (1/rawVoltage.MetaTags.SamplingFreq);
        dData = double(rawVoltage.Data);
        [B,A] = butter(2,2*[200 5000]/rawVoltage.MetaTags.SamplingFreq);
        dData = filtfilt(B,A,dData);
        
        %necessary for proper alignment across the two NSPs
        tOffset = (rawVoltage.MetaTags.Timestamp(end)-1)/30000;
        
        for t=1:length(threshMultiplier)
            threshold = -std(dData) * threshMultiplier(t);
            txEvents{n,t} = txEventsFromRawVoltage( dData, timeAxis, threshold ) + tOffset;
        end
    end
end

