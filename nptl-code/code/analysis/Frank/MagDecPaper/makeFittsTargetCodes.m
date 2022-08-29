function [ dirCodes, distCodes, muxCodes, distCenters ] = makeFittsTargetCodes( cursorPos, targetPos, ...
    trialEpochs, nDirCodes, nDistCodes, rectangleOption )

    posErr = targetPos - cursorPos;
    targDist = sqrt(sum(posErr.^2,2));
    
    theta = linspace(0,2*pi,nDirCodes+1);
    theta = theta(1:(end-1));
    dir = [cos(theta'), sin(theta')];
    dirCodes = zeros(size(trialEpochs,1),1);
    for t=1:size(trialEpochs,1)
        dirVec = posErr(trialEpochs(t,1)+3,:);
        dirVec = dirVec / norm(dirVec);
        dist = matVecMag(bsxfun(@plus, -dir, dirVec),2);
        [~,minIdx] = min(dist);
        dirCodes(t) = minIdx;
    end

    startDist = targDist(trialEpochs(:,1)+2);
    distEdges = linspace(0,prctile(startDist,90),nDistCodes+1);
    distCenters = distEdges(1:(end-1))+(distEdges(2)-distEdges(1))/2;
    distEdges(end) = distEdges(end)+1;
    [~,binIdx] = histc(targDist(trialEpochs(:,1)+2), distEdges);
    distCodes = binIdx;
    distCodes(distCodes==0) = nDistCodes;
    
    if nargin<6
        rectangleOption = false;
    end
    if ~rectangleOption
        [muxList,~,muxCodes] = unique([dirCodes, distCodes],'rows');
    else
        distEdges = [0,0.4,0.55,0.85];
        muxCodes = nan(size(dirCodes));
        for d=1:nDirCodes
            trlIdx = find(dirCodes==d);
            startDist = targDist(trialEpochs(trlIdx,1)+2);
            if d==2 || d==4
                distEdges = [0, prctile(startDist,48), prctile(startDist,52), prctile(startDist,100)];
            else
                distEdges = [0, prctile(startDist,30), prctile(startDist,52), prctile(startDist,90)];
            end
            [~,binIdx] = histc(startDist, distEdges);
            muxCodes(trlIdx(binIdx==1)) = (d-1)*2 + 1;
            muxCodes(trlIdx(binIdx==3)) = (d-1)*2 + 2;
        end
    end
end

