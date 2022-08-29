function [ out ] = unrollR_dense( R, binMs, monkCode )
    
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
            
        tmp = globalIdx + [R(t).timeCueOn, R(t).timeTargetOn, nSteps];
        globalIdx = globalIdx + nSteps; 
        reachEvents = [reachEvents; tmp];
    end
    
    cueOn = vertcat(R.timeCueOn);
    targetOn = vertcat(R.timeTargetOn);
    delayTimes = vertcat(R.delayTime);
    if strcmp(monkCode,'Reggie')
        trlIdx = find(~isnan(targetOn));
        taskDim = 1;
    elseif strcmp(monkCode,'Jenkins')
        trlIdx = find(~isnan(delayTimes));
        taskDim = 2;
    end

    timeWindow = [-250, 750];
    
    %%
    colors = jet(12)*0.8;
    figure
    for plotIdx=1:12
        subplot(4,4,plotIdx);
        hold on
        for t=1:length(trlIdx)
            loopIdx = (reachEvents(trlIdx(t),2)+timeWindow(1)):(reachEvents(trlIdx(t),2)+timeWindow(2));
            codeIdx = round(abs(targetPos(reachEvents(trlIdx(t),2),taskDim))/10);
            if codeIdx==plotIdx
                plot(cursorSpeed(loopIdx),'Color',colors(codeIdx,:));
            end
        end
        xlim([0 1000]);
        ylim([-800 800]);
    end
        
    %%
    speedThresh = 25;
    if strcmp(monkCode,'Reggie')
        startWindow = [200 900];
    elseif strcmp(monkCode,'Jenkins')
        startWindow = [500 700];
    end
    startTimes = nan(length(trlIdx),1);
    startTimesGlobal = nan(length(trlIdx),1);
    peakSpeedTimes = nan(length(trlIdx),1);
    peakSpeedTimesGlobal = nan(length(trlIdx),1);
    peakSpeeds = zeros(length(trlIdx),1);
    distCodes = zeros(length(trlIdx),1);
    for t=1:length(trlIdx)
        loopIdx = (reachEvents(trlIdx(t),2)+timeWindow(1)):(reachEvents(trlIdx(t),2)+timeWindow(2));
        if loopIdx(1)<1
            continue;
        end
        startIdx = find(cursorSpeed(loopIdx)>speedThresh,1,'first');
        if ~isempty(startIdx) && startIdx>=startWindow(1) && startIdx<=startWindow(2)
            startTimes(t) = startIdx;
            startTimesGlobal(t) = startIdx + (reachEvents(trlIdx(t),2)+timeWindow(1)) - 1;
        end
        
        [peakSpeeds(t), maxIdx] = max(cursorSpeed(loopIdx));
        peakSpeedTimes(t) = maxIdx;
        peakSpeedTimesGlobal(t) = maxIdx + (reachEvents(trlIdx(t),2)+timeWindow(1)) - 1;
        codeIdx = round(targetPos(reachEvents(trlIdx(t),2),taskDim)/10);
        distCodes(t) = codeIdx;
    end
    
    %%
    posErr = zeros(length(trlIdx),2);
    for t=1:length(trlIdx)
        posErr(t,:) = targetPos(reachEvents(trlIdx(t),2),1:2) - cursorPos(reachEvents(trlIdx(t),2),1:2);
    end
    
    err = zeros(size(posErr,1),1);
    for t=1:length(trlIdx)
        loopIdx = (reachEvents(trlIdx(t),2)+timeWindow(1)):(reachEvents(trlIdx(t),2)+timeWindow(2));
        if loopIdx(1)<1
            continue;
        end
        
        [peakSpeed, maxIdx] = max(cursorSpeed(loopIdx));
        halfPoint = targetPos(loopIdx(maxIdx),1:2) - cursorPos(loopIdx(maxIdx),1:2);
        err(t) = sqrt(sum((halfPoint - posErr(t,:)/2).^2,2));
    end
    
    validIdx = ~isnan(startTimesGlobal);
    startDist = matVecMag(posErr,2);
    
    figure
    plot(startDist(validIdx), err(validIdx), '.');
    ylim([0 40]);
    
    hold on;
    cutoff = startDist*(10/40)+2.7;
    cutoffPoints = err>cutoff;
    plot(startDist(validIdx & cutoffPoints), err(validIdx & cutoffPoints), 'r.');
    validIdx = validIdx & ~cutoffPoints;
    
    nBins = 10;
    binEdges = linspace(10,120,nBins+1);
    meanErr = zeros(nBins,1);
    meanDist = zeros(nBins,1);
    [~,binIdx] = histc(startDist, binEdges);
    
    for b=1:nBins
        meanErr(b) = mean(err(binIdx==b & validIdx));
        meanDist(b) = mean(startDist(binIdx==b & validIdx));
    end
    
    figure
    hold on
    plot(meanDist, meanErr, '-o');
    ylim([0 15]);
    
    %%
    posErr = zeros(length(trlIdx),2);
    for t=1:length(trlIdx)
        posErr(t,:) = targetPos(reachEvents(trlIdx(t),2),1:2) - cursorPos(reachEvents(trlIdx(t),2),1:2);
    end
    
    [N,distCodes] = histc(posErr(:,taskDim),linspace(20,120,12));
    [N,distCodesNeg] = histc(posErr(:,taskDim),linspace(-120,-20,12));
    distCodes = distCodes + 11;
    trlCodes = zeros(length(trlIdx),1);
    trlCodes(posErr(:,taskDim)<0) = distCodesNeg(posErr(:,taskDim)<0);
    trlCodes(posErr(:,taskDim)>0) = distCodes(posErr(:,taskDim)>0);
    
    ampVar = zeros(11,1);
    for t=1:11
        tmpIdx = find(distCodesNeg==t & ~isnan(startTimes));
        ampVar(t,1) = mean(peakSpeeds(tmpIdx));
        
        distTraveled = zeros(length(tmpIdx),1);
        for x=1:length(tmpIdx)
            loopIdx = startTimesGlobal(tmpIdx(x)):peakSpeedTimesGlobal(tmpIdx(x));
            distTraveled(x) = sum(abs(cursorVel(loopIdx,2)))/1000;
        end
        ampVar(t,2) = std(distTraveled);
    end
    
    figure
    for t=1:11
        subplot(4,4,t);
        hold on
        tmpIdx = find(distCodesNeg==t & ~isnan(startTimes));

        for x=1:length(tmpIdx)
            loopIdx = (startTimesGlobal(tmpIdx(x))-400):(startTimesGlobal(tmpIdx(x))+400);
            plot(cursorVel(loopIdx,taskDim));
        end
        ylim([-800 0]);
    end
    
    %%
    targetPos_ds = targetPos(1:binMs:end,:);
    cursorPos_ds = cursorPos(1:binMs:end,:);
    startTimes_ds = round(startTimesGlobal/binMs);
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
    out.trlCodes = trlCodes;
    out.cursorVel_ds = cursorVel(1:binMs:end,:);
    out.validIdx = validIdx;
end

