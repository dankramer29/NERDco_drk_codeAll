function [ data ] = speedThreshold( data, speedThresh )
    %determine movement start based on speed thresholding
    if isfield(data,'gainMovStart')
        data.moveStartIdx = data.gainMovStart;
        return;
    end
    
    data.moveStartIdx = nan(size(data.reachEvents,1),1);
    for t=1:size(data.reachEvents,1)
        loopIdx = data.reachEvents(t,2):(data.reachEvents(t,2)+200);
        loopIdx(loopIdx>length(data.cursorSpeed))=[];
        startIdx = find(data.cursorSpeed(loopIdx)>speedThresh,1,'first');
        if ~isempty(startIdx)
            data.moveStartIdx(t) = loopIdx(startIdx);
        end
    end
end

