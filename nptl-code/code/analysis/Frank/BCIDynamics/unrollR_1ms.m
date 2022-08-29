function [ out ] = unrollR_1ms( R, opts )
        
    if nargin<2
        opts.filter = true;
        opts.useDecodeSpeed = false;
    end
    
    if isfield(R,'handPos')
        hpField = 'handPos';
        cpField = 'cursorPos';
    else
        hpField = 'cursorPosition';
        cpField = 'cursorPosition';
    end
        
    out.handPos = double(horzcat(R.(hpField))');
    out.cursorPos = double(horzcat(R.(cpField))');
    out.targetPos = zeros(size(out.cursorPos));
    out.reachEvents = [];
    out.array1 = horzcat(R.spikeRaster)';
    if isfield(R,'spikeRaster2')
        out.array2 = horzcat(R.spikeRaster2)';
    end
    
    if opts.filter
        [B,A] = butter(3,10/500,'low');
        out.handPos = filtfilt(B,A,out.handPos);
        out.cursorPos = filtfilt(B,A,out.cursorPos);
    end
    
    nDim = size(out.cursorPos,2);
    if opts.useDecodeSpeed
        if isfield(R,'decodeState')
            ds = horzcat(R.decodeState)';
            out.cursorVel = ds(:,4:(4+nDim-1));
        elseif isfield(R,'xk')
            ds = horzcat(R.xk)';
            out.cursorVel = ds(:,2:2:(nDim*2));            
        end
    else
        out.cursorVel = [zeros(1,nDim); diff(out.cursorPos)*1000];
    end
    out.handVel = [zeros(1,nDim); diff(out.cursorPos)*1000];
    
    out.cursorSpeed = sqrt(sum(out.cursorVel.^2,2));
    out.handSpeed = sqrt(sum(out.handVel.^2,2));
    
    out.trialSeg = [];
    out.reachEvents = [];
    globalIdx = 0;
    for t=1:length(R)
        nSteps = length(R(t).state);
        loopIdx = (globalIdx+1):(globalIdx+nSteps);
        if isfield(R(t).startTrialParams,'posTarget')
            out.targetPos(loopIdx,:) = repmat(R(t).startTrialParams.posTarget',nSteps,1);
        else
            out.targetPos(loopIdx,:) = repmat(R(t).posTarget(1:size(out.targetPos,2))',nSteps,1);
        end
        
        if ~isfield(R(t),'timeCueOn') || isempty(R(t).timeCueOn)
            timeCueOn = NaN;
        else
            timeCueOn = R(t).timeCueOn;
        end
        if ~isfield(R(t),'timeFirstTargetAcquire') || isempty(R(t).timeFirstTargetAcquire)
            timeFirstTargetAcquire = NaN;
        else
            timeFirstTargetAcquire = R(t).timeFirstTargetAcquire;
        end
        tmp = globalIdx + [timeCueOn, R(t).timeTargetOn, nSteps, timeFirstTargetAcquire, R(t).trialLength];
        out.reachEvents = [out.reachEvents; tmp];
        
        tmp = globalIdx + [1, nSteps];
        out.trialSeg = [out.trialSeg; tmp];
        
        globalIdx = globalIdx + nSteps; 
    end
    
    out.reachEvents(isnan(out.reachEvents(:,2)),2) = out.reachEvents(isnan(out.reachEvents(:,2)),1);
    [targList,~,targCodes] = unique(out.targetPos(out.reachEvents(:,3),:),'rows');

    %%
    out.targList = targList;
    out.targCodes = targCodes;
    out.isSuccessful = vertcat(R.isSuccessful);
    out.saveTag = zeros(length(out.isSuccessful),1);
    if isfield(R(1).startTrialParams,'saveTag')
        for t=1:length(out.saveTag)
            out.saveTag(t) = R(t).startTrialParams.saveTag;
        end
    end
end

