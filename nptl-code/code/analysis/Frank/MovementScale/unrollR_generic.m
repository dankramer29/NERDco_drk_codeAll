function [ out ] = unrollR_generic( R, binMs, opts )
    
    if nargin<3
        opts.filter = false;
    end
    
    if isfield(R,'handPos')
        hpField = 'handPos';
        cpField = 'cursorPos';
    else
        hpField = 'cursorPosition';
        cpField = 'cursorPosition';
    end
        
    handPos = double(horzcat(R.(hpField))');
    cursorPos = double(horzcat(R.(cpField))');
    targetPos = zeros(size(cursorPos));
    reachEvents = [];
    if isfield(R,'spikeRaster2')
        spikes = [horzcat(R.spikeRaster)', horzcat(R.spikeRaster2)'];
    else
        spikes = horzcat(R.spikeRaster)';
    end
    
    if opts.filter
        [B,A] = butter(4,20/500,'low');
        handPos = filtfilt(B,A,handPos);
        cursorPos = filtfilt(B,A,cursorPos);
    end
    
    nDim = size(cursorPos,2);
    cursorVel = [zeros(1,nDim); diff(cursorPos)*1000];
    handVel = [zeros(1,nDim); diff(handPos)*1000];
    
    cursorSpeed = sqrt(sum(cursorVel.^2,2));
    handSpeed = sqrt(sum(handVel.^2,2));
    
    globalIdx = 0;
    for t=1:length(R)
        nSteps = length(R(t).state);
        loopIdx = (globalIdx+1):(globalIdx+nSteps);
        if isfield(R(t).startTrialParams,'posTarget')
            targetPos(loopIdx,:) = repmat(R(t).startTrialParams.posTarget',nSteps,1);
        else
            targetPos(loopIdx,:) = repmat(R(t).posTarget(1:size(targetPos,2))',nSteps,1);
        end
        
        if ~isfield(R(t),'timeCueOn') || isempty(R(t).timeCueOn)
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

    %%
    out.targetPos = targetPos(1:binMs:end,:);
    out.cursorPos = cursorPos(1:binMs:end,:);
    out.cursorVel = cursorVel(1:binMs:end,:);
    out.cursorSpeed = cursorSpeed(1:binMs:end);
    out.handPos = handPos(1:binMs:end,:);
    out.handVel = handVel(1:binMs:end,:);
    out.handSpeed = handSpeed(1:binMs:end);
    out.reachEvents = round(reachEvents/binMs);
    
    out.spikes = zeros(size(out.targetPos,1),size(spikes,2));
    binIdx = 1:binMs;
    for b=1:(size(out.spikes,1)-1)
        out.spikes(b,:) = sum(spikes(binIdx,:))*(1000/binMs);
        binIdx = binIdx + binMs;
    end

    out.targList = targList;
    out.targCodes = targCodes;
    out.isSuccessful = vertcat(R.isSuccessful);
    out.saveTag = zeros(length(out.isSuccessful),1);
    if isfield(R(1).startTrialParams,'saveTag')
        for t=1:length(out.saveTag)
            out.saveTag(t) = R(t).startTrialParams.saveTag;
        end
    end
    
    if isfield(R,'delayTime')
        delayTimes = vertcat(R.delayTime);
        out.delayTrl = ~isnan(delayTimes);
    end
end

