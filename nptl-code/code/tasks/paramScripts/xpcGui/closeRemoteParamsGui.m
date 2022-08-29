function closeRemoteParamsGui()

    figNum = findobj('name','remoteParamsGui');
    if ~isempty(figNum)
        close(figNum);
    end

