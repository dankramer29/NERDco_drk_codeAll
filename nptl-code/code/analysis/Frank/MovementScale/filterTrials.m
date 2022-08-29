function [ useTrials ] = filterTrials( data, saveTagsToUse, datasetType, speedMax )
    %return indices of trials to use in the analysis
    useTrials = true(length(data.targCodes),1);
    useTrials = useTrials & data.isOuterReach;
    useTrials = useTrials & data.isSuccessful;
    useTrials = useTrials & ~isnan(data.moveStartIdx);
    
    badSpeed = false(length(data.targCodes),1);
    for t=1:length(badSpeed)
        loopIdx = (data.moveStartIdx-60):(data.moveStartIdx+200);
        loopIdx(loopIdx<1) = [];
        loopIdx(loopIdx>length(data.cursorSpeed))=[];
        if isnan(loopIdx)
            continue;
        end
        badSpeed(t) = any(data.cursorSpeed(loopIdx)>speedMax);
    end
    useTrials = useTrials & ~badSpeed;
    
    if strcmp(datasetType,'gain')
        useTrials = useTrials & data.isConstantGain;
    else
        useTrials = useTrials & ismember(data.saveTag, saveTagsToUse);
        useTrials = useTrials & data.delayTrl;
    end
end

