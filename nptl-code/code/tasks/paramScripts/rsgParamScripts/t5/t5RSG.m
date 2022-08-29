setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  
setModelParam('taskType', uint32(cursorConstants.TASK_RSG));
setModelParam('numDisplayDims', uint8(2) );
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_HEAD_MOUSE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

setModelParam('holdTime', 300);
setModelParam('targetDiameter', 100);
setModelParam('cursorDiameter', 25);
setModelParam('rsgFixationRadius', 30);

setModelParam('pause', true);

%%
targetLoc = zeros(2,10);
targetLoc(:,1) = [200; 0];
targetLoc(:,2) = [-200; 0];

nTrials = 256;
targSeq = [zeros(1,nTrials/2), ones(1,nTrials/2)]+1;
targSeq = targSeq(randperm(length(targSeq)));

%possibleProdTimes = [500, 750, 1000, 1250, 1500, 1750, 2000];
possibleProdTimes = [500 583 667 750 833 917 1000];
prodTimes = zeros(1,nTrials);
preReadyTimes = zeros(1,nTrials);

expRandBinSize = 10;
expRandMin = 1000;
expRandMax = 3000;
expRandMu = 1500;
for t=1:nTrials
    prodIdx = randi(length(possibleProdTimes));
    prodTimes(t) = possibleProdTimes(prodIdx);
    
    thisTrialDelay = uint16(0);
    while double(thisTrialDelay) < expRandMin || double(thisTrialDelay) > expRandMax
        thisTrialDelay = uint16(expRandMu * -log(rand([1 1])));
    end
    preReadyTimes(t) = uint16(round(double(thisTrialDelay) / double(expRandBinSize))*expRandBinSize);
end

setModelParam('rsgTargetSeq', targSeq);
setModelParam('rsgProductionTimes', prodTimes);
setModelParam('rsgPreReadyTimes', preReadyTimes);
setModelParam('rsgTargetLoc', targetLoc);
setModelParam('rsgCueDisplayTime', 105);

setModelParam('workspaceY', double([-540 539]));
setModelParam('workspaceX', double([-960 959]));

doResetBK = false;
unpauseOnAny(doResetBK);
