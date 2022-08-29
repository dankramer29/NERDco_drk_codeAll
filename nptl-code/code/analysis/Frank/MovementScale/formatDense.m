function [ data ] = formatDense( data, targType )
    
    data.isOuterReach = data.targCodes~=13;
    [~,taskDim] = max(var(data.targList(:,1:2))); 
    
    posErr = zeros(length(data.reachEvents),2);
    for t=1:size(posErr,1)
        posErr(t,:) = data.targetPos(data.reachEvents(t,2),1:2) - data.cursorPos(data.reachEvents(t,2),1:2);
    end
    
    nBins = 11;
    [N,distCodes] = histc(posErr(:,taskDim),linspace(20,120,nBins+1));
    [N,distCodesNeg] = histc(posErr(:,taskDim),linspace(-120,-20,nBins+1));
    
    distCodes(distCodes~=0) = distCodes(distCodes~=0) + 11;
    distCodesNeg(distCodesNeg~=0) = nBins + 1 - distCodesNeg(distCodesNeg~=0);
    
    targCodes = zeros(size(posErr,1),1);
    targCodes(posErr(:,taskDim)<0) = distCodesNeg(posErr(:,taskDim)<0);
    targCodes(posErr(:,taskDim)>0) = distCodes(posErr(:,taskDim)>0);
    
    data.targCodes = targCodes;
    data.targCodes(~data.isOuterReach) = 25;
    data.centerTargetCode = 25;
    
    data.dirGroups = {1:11, 12:22};
    if strcmp(targType,'denseVert')
        data.dirTheta = [270,90]*(pi/180);
    elseif strcmp(targType,'denseHorz')
        data.dirTheta = [180,0]*(pi/180);
    end
    
    data.withinDirDist = zeros(nBins,1);
    for d=1:length(data.withinDirDist)
        idx = distCodesNeg==d;
        data.withinDirDist(d) = abs(mean(posErr(idx, taskDim)));
    end
        
end

