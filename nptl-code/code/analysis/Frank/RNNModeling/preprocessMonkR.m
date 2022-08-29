function [ R ] = preprocessMonkR( R, wantedSaveTags, nDim )
    for t=1:length(R)
        R(t).currentTarget = repmat(R(t).startTrialParams.posTarget(1:nDim),1,length(R(t).counter));
        R(t).saveTag = R(t).startTrialParams.saveTag;
        R(t).blockNum = R(t).saveTag;
        R(t).clock = R(t).counter;
    end
    
    R = R(ismember([R.saveTag], wantedSaveTags));
    
    rtIdxAll = zeros(length(R),1);
    [B,A] = butter(4, 5/500);
    for t=1:length(R)
        %RT
        pos = double(R(t).cursorPos(1:nDim,:)');
        pos(21:end,:) = filtfilt(B,A,pos(21:end,:)); %reseed
        vel = [zeros(1,nDim); diff(pos)];
        vel(1:21,:) = 0;
        speed = matVecMag(vel,2)*1000;
        R(t).speed = speed;
        R(t).maxSpeed = max(speed(30:end));
    end
    
    tPos = zeros(length(R),nDim);
    for t=1:length(R)
        tPos(t,:) = R(t).startTrialParams.posTarget(1:nDim);
    end
   
    [targList,~,targCodes] = unique(tPos,'rows');
    ms = [R.maxSpeed];
    avgMS = zeros(length(targList),1);
    for t=1:length(targList)
        tmp = ms(targCodes==t);
        tmp(tmp>2000) = nan;
        avgMS(t) = nanmean(tmp);
    end
    
    for t=1:length(R)
        useThresh = max(avgMS(targCodes(t))*0.3,30);
        
        rtIdx = find(R(t).speed>useThresh,1,'first');
        if isempty(rtIdx)
            rtIdx = 150;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTime = rtIdx;
    end
end

