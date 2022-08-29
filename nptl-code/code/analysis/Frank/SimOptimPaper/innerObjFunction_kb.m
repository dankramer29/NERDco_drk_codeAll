function [ maxBitRate, bestDwellTime ] = innerObjFunction_kb( simOpts, targetPos, startPos, targetIdx, keyCenters, dwellTimeValues, coef )
    %evaluates performance for a given alpha/beta pair; finds optimal dwell
    %time by sweeping
    simOpts.plant.alpha = coef(1);
    simOpts.plant.beta = coef(2);
    out = simBatch( simOpts, targetPos, startPos );

    %for each time step, find the closest target
    closestTargetIdx = zeros(length(out.pos),1);
    for t=1:length(out.pos)
        targDist = matVecMag(out.pos(t,:) - keyCenters,2);
        [~,closestTargetIdx(t)] = min(targDist);
    end

    %--estimate bit rate as a function of dwell time
    nTargs = size(targetPos,1);
    allBitRates = zeros(length(dwellTimeValues),1);
    for dwellIdx=1:length(dwellTimeValues)
        dTime = dwellTimeValues(dwellIdx);
        trialResults = zeros(nTargs,2);

        %estimate success/failure and trial time for each trial
        for trlIdx=1:nTargs
            loopIdx = out.reachEpochs(trlIdx,1):out.reachEpochs(trlIdx,2);
            dwellCounter = 0;
            trialDone = false;
            dwellCounterVec = zeros(length(loopIdx),1);
            for lp=2:length(loopIdx)
                lpIdx = loopIdx(lp);
                if closestTargetIdx(lpIdx)==closestTargetIdx(lpIdx-1) && lp>10 %RT delay
                    dwellCounter = dwellCounter + 1;
                else
                    dwellCounter = 0;
                end
                dwellCounterVec(lp) = dwellCounter;

                if dwellCounter>=dTime
                    %target acquired
                    if closestTargetIdx(lpIdx)==targetIdx(trlIdx)
                        %success
                        trialResults(trlIdx,1) = 1;
                    else
                        %failure
                        trialResults(trlIdx,1) = 0;
                    end
                    trialResults(trlIdx,2) = lp;
                    trialDone = true;
                    break;
                end
            end
            if ~trialDone
                trialResults(trlIdx,:) = [0, length(loopIdx)];
            end %time step
        end %trials

        %compute achieved bit rate
        N = length(keyCenters);
        totalTime = sum(trialResults(:,2))/50;
        allBitRates(dwellIdx) = log2(N-1)*max(sum(trialResults(:,1))-sum(~trialResults(:,1)),0)/totalTime;
    end %dwell time
    
    [maxBitRate, maxIdx] = max(allBitRates);
    bestDwellTime = dwellTimeValues(maxIdx);
end

