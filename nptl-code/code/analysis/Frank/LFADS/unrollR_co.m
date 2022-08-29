function [ out ] = unrollR_co( R, binMs, monkCode )
    
    cursorPos = horzcat(R.cursorPos)';
    targetPos = zeros(size(cursorPos));
    reachEvents = [];
    spikes = [horzcat(R.spikeRaster)', horzcat(R.spikeRaster2)'];
    
    [B,A] = butter(3,10/500,'low');
    cursorPos = filtfilt(B,A,cursorPos);
    cursorVel = [0 0 0; diff(cursorPos)*1000];
    cursorSpeed = matVecMag(cursorVel,2);
    
    globalIdx = 0;
    for t=1:length(R)
        nSteps = size(R(t).cursorPos,2);
        loopIdx = (globalIdx+1):(globalIdx+nSteps);
        targetPos(loopIdx,:) = repmat(R(t).startTrialParams.posTarget',nSteps,1);
            
        if isempty(R(t).timeCueOn)
            timeCueOn = NaN;
        else
            timeCueOn = R(t).timeCueOn;
        end
        tmp = globalIdx + [timeCueOn, R(t).timeTargetOn, nSteps];
        globalIdx = globalIdx + nSteps; 
        reachEvents = [reachEvents; tmp];
    end
    
    reachEvents(isnan(reachEvents(:,2)),2) = reachEvents(isnan(reachEvents(:,2)),1);
    [targList,~,targCodes] = unique(targetPos(reachEvents(:,3),:),'rows');
    targDist = matVecMag(targList(:,1:2),2);
    
    cueOn = vertcat(R.timeCueOn);
    targetOn = vertcat(R.timeTargetOn);
    delayTimes = vertcat(R.delayTime);
    timeWindow = [-250, 750];
    
    theta = linspace(0,2*pi,17);
    theta = theta(1:16);
    dirVectors = [cos(theta)', sin(theta)'];
    dirVectors = [dirVectors*120; dirVectors*80; dirVectors*40];
    orderedIdx = zeros(48,1);
    for d=1:size(dirVectors,1)
        [~,minIdx] = min(matVecMag(bsxfun(@plus, dirVectors(d,:), -targList(:,1:2)),2));
        orderedIdx(d) = minIdx;
    end
    outerRingCodes = orderedIdx(1:16);
    middleRingCodes = orderedIdx(17:32);
    innerRingCodes = orderedIdx(33:48);
    trlIdx = find(ismember(targCodes, outerRingCodes));
    
    %%
    figure
    for plotIdx=1:length(outerRingCodes)
        subplot(4,4,plotIdx);
        hold on
        for t=1:length(trlIdx)
            loopIdx = (reachEvents(trlIdx(t),2)+timeWindow(1)):(reachEvents(trlIdx(t),2)+timeWindow(2));
            codeIdx = targCodes(trlIdx(t));
            if codeIdx==outerRingCodes(plotIdx)
                plot(cursorVel(loopIdx,1),'r');
                plot(cursorVel(loopIdx,2),'b');
                plot(cursorSpeed(loopIdx),'k');
            end
        end
        xlim([0 1000]);
        ylim([-800 800]);
    end
    
    %%
    %determine movement start based on speed thresholding
    moveStartIdx = nan(size(reachEvents,1),1);
    for t=1:size(reachEvents,1)
        loopIdx = reachEvents(t,2):(reachEvents(t,2)+1000);
        loopIdx(loopIdx>length(cursorSpeed))=[];
        startIdx = find(cursorSpeed(loopIdx)>200,1,'first');
        if ~isempty(startIdx)
            moveStartIdx(t) = loopIdx(startIdx);
        end
    end
    
    %%
    figure
    for plotIdx=1:length(outerRingCodes)
        subplot(4,4,plotIdx);
        hold on
        for t=1:length(trlIdx)
            if isnan(moveStartIdx(trlIdx(t)))
                continue;
            end
            loopIdx = (moveStartIdx(trlIdx(t))+timeWindow(1)):(moveStartIdx(trlIdx(t))+timeWindow(2));
            if any(loopIdx>length(cursorVel))
                continue;
            end
            
            codeIdx = targCodes(trlIdx(t));
            if codeIdx==outerRingCodes(plotIdx)
                plot(cursorVel(loopIdx,1),'r');
                plot(cursorVel(loopIdx,2),'b');
                plot(cursorSpeed(loopIdx),'k');
            end
        end
        xlim([0 1000]);
        ylim([-800 800]);
    end
        
    %%
    targetPos_ds = targetPos(1:binMs:end,:);
    cursorPos_ds = cursorPos(1:binMs:end,:);
    startTimes_ds = round(reachEvents(:,2)/binMs);
    spikes_bin = zeros(size(targetPos_ds,1),size(spikes,2));
    binIdx = 1:binMs;
    for b=1:(size(spikes_bin,1)-1)
        spikes_bin(b,:) = sum(spikes(binIdx,:))*(1000/binMs);
        binIdx = binIdx + binMs;
    end
    
    out.targetPos = targetPos;
    out.cursorPos = cursorPos;
    out.reachEvents = reachEvents;
    out.spikes = spikes;
    out.targetPos_ds = targetPos_ds;
    out.cursorPos_ds = cursorPos_ds;
    out.reachEvents_ds = startTimes_ds;
    out.spikes_bin = spikes_bin;
    out.trlCodes = targCodes;
    out.cursorVel_ds = cursorVel(1:binMs:end,:);
    out.outerRingCodes = outerRingCodes;
    out.middleRingCodes = middleRingCodes;
    out.innerRingCodes = innerRingCodes;
    out.delayTrlIdx = find(~isnan(delayTimes));
    out.moveStartIdx_ds = round(moveStartIdx/binMs);
end

