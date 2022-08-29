function [ R, rtAdjusted, goCue, wiaCodes, rtSimple ] = getSpeedAndRT( R, simpleThresh )
    wiaCodes = zeros(length(R),1);
    goCue = zeros(length(R),1);
    for t=1:length(R)
        wiaCodes(t) = R(t).startTrialParams.wiaCode;
        if ~isempty(R(t).timeGoCue)
            goCue(t) = R(t).timeGoCue;
        end
    end
    goCue = round(goCue/20);
        
    rtIdxAll = zeros(length(R),1);
    for t=1:length(R)
        %RT
        headPos = double(R(t).windowsMousePosition');
        headVel = [0 0; diff(headPos)];
        [B,A] = butter(4, 10/500);
        headVel = filtfilt(B,A,headVel);
        headSpeed = matVecMag(headVel,2)*1000;
        R(t).headSpeed = headSpeed;
        R(t).maxSpeed = max(headSpeed);
    end

    tPos = [R.posTarget]';
    tPos = tPos(:,1:2);
    [targList,~,targCodes] = unique(tPos,'rows');
    ms = [R.maxSpeed];
    avgMS = zeros(length(targList),1);
    for t=1:length(targList)
        avgMS(t) = mean(ms(targCodes==t));
    end

    for t=1:length(R)
        useThresh = max(avgMS(targCodes(t))*0.1,0.035);

        rtIdx = find(R(t).headSpeed>useThresh,1,'first');
        if isempty(rtIdx) || rtIdx<(goCue(t)+150)
            rtIdx = 21;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTime = rtIdx;
    end
    rtAdjusted = rtIdxAll - goCue*20;
    
    if isempty(simpleThresh)
        simpleThresh = 0.05;
    end
    for t=1:length(R)
        rtIdx = find(R(t).headSpeed>simpleThresh);
        rtIdx(rtIdx<goCue(t)+150)=[];
        if ~isempty(rtIdx)
            rtIdx = rtIdx(1);
        end
        if isempty(rtIdx) || rtIdx<(goCue(t)+150)
            rtIdx = 21;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTimeSimple = rtIdx;
    end
    rtSimple = rtIdxAll - goCue*20;
end

