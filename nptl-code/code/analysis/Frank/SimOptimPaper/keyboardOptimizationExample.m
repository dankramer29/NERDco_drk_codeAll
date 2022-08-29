%%
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));

bg2FileDir = '/Users/frankwillett/Data/BG Datasets/optimPaperDatasets';
figDir = '/Users/frankwillett/Data/Derived/nonlinearGainOptFigure/';
mkdir(figDir);

%%
load('/Users/frankwillett/Data/CaseDerived/testFiles/testCell_7_gsExplain.mat')
controlModel = testResultsCell{99}.fit.fitModel.bestMRule.piecewisePointModel;
noiseModel = testResultsCell{99}.fit.fitModel.bestARModel;
clear testResultsCell;

%%
%two optimizations:
%(1) For a fixed number of keys: optimize gain, smoothing & dwell time as a
%function of decoding noise to maximize achieved bit rate
%(2) Optimize number of keys, gain, smoothing & dwell time as a function of
%decoding noise to maximize achieved bit rate

simOpts = makeFastBciSimOptions( );

simOpts.control.fTargX  = [linspace(0,1,10) 1.1 1.2 1.3];
simOpts.control.fTargY = [0, 0.4, 0.6, 0.7, 0.78, 0.85, 0.9, 0.93, 0.96, 1, 1.02 1.03 1.03];

simOpts.trial.maxTrialTime = 12;

simOpts.forwardModel.delaySteps = 10;
simOpts.forwardModel.forwardSteps = 10;
simOpts.control.rtSteps = 10;

%%
%make keyboards
nTarg = 6;
keyCenters = [];

kbSize = 2;
keyWidth = 2/nTarg;
keyAxis = linspace(-1+keyWidth/2,1-keyWidth/2,nTarg);

for x=1:nTarg
    for y=1:nTarg
        keyCenters = [keyCenters; [keyAxis(x), keyAxis(y)]];
    end
end
    
%%
%simulate bit rates for different keyboards
betaValues = logspace(log10(0.10), log10(6.0), 30);
alphaValues = linspace(0.9,0.96,30);
alpha = 0.94; %set the smoothing to this value instead of sweeping
dwellTimeValues = 4:4:150;
allBitRates = zeros(length(noiseValues),length(betaValues),length(dwellTimeValues));
noiseValues = logspace(log10(0.5.^2), log10(2.0.^2), 10);
nThreads = 2;

disp('Starting (keyboard / gain / dwell time) sweep');

%sweep over gain values
for noiseIdx=1:length(noiseValues)
    newNoiseModel = noiseModel;
    newNoiseModel.cov = zeros(2);
    newNoiseModel.cov(1,1) = noiseValues(noiseIdx);
    newNoiseModel.cov(2,2) = noiseValues(noiseIdx);
    newNoiseMatrix = genTimeSeriesFromARModel_multi( 100000, newNoiseModel.coef, newNoiseModel.cov );
    
    %optimize over alpha & beta with a pattern search
    simOpts.noiseMatrix = genTimeSeriesFromARModel_multi( 100000, noiseModel.coef, noiseModel.cov );
    optFunStatic = @(coef)tttOptFunc(simOpts, gameOpts, fOpts, simOpts.plant.alpha, simOpts.control.fTargY, coef);

    noisyStart = simOpts.plant.fStaticY(1:end)+rand(1,length(simOpts.plant.fStaticY))-0.5;
    noisyStart(noisyStart<0)=0;
    [X, fval] = patternsearch(optFunStatic,noisyStart,[],[],[],[],...
        zeros(1,length(simOpts.plant.fStaticX)),...
        ones(1,length(simOpts.plant.fStaticX))*simOpts.plant.beta*4,[],optimOptions); 
    
    optFun = @(alpha, beta)(innerObjFunction_kb( simOpts, targetPos, startPos, keyCenters, dwellTimeValues )
    
    for a=1:length(alphaValues)
        disp(['Alpha value ' num2str(a) '/' num2str(length(alphaValues)) ' ...']);
        for b=1:length(betaValues)
            disp(['     Gain value ' num2str(b) '/' num2str(length(betaValues)) ' ...']);

            %--simulate point-to-point movements all over the keyboard 
            newOpts = simOpts;
            newOpts.noiseMatrix = newNoiseMatrix;
            newOpts.plant.beta = betaValues(b);
            newOpts.plant.alpha = alphaValues(a);
            newOpts.trial.dwellTime = 22.0;
            newOpts.trial.maxTrialTime = 20.0;

            nTargs = 600;
            targetPos = zeros(nTargs, 2);
            startPos = zeros(nTargs, 2);
            targetIdx = zeros(nTargs,1);
            for targIdx=1:nTargs
                startTargIdx = randi(length(keyCenters),1,1);
                endTargIdx = randi(length(keyCenters),1,1);

                targetPos(targIdx,:) = keyCenters(endTargIdx,:);
                startPos(targIdx,:) = keyCenters(startTargIdx,:);
                targetIdx(targIdx) = endTargIdx;
            end
  
           out = simBatch( newOpts, targetPos, startPos );

            %for each time step, find the closest target
            closestTargetIdx = zeros(length(out.pos),1);
            for t=1:length(out.pos)
                targDist = matVecMag(out.pos(t,:) - keyCenters,2);
                [~,closestTargetIdx(t)] = min(targDist);
            end

            %--estimate bit rate as a function of dwell time
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
                allBitRates(noiseIdx,b,dwellIdx) = log2(N-1)*max(sum(trialResults(:,1))-sum(~trialResults(:,1)),0)/totalTime;
            end %dwell time
        end %beta
    end %alpha
end %noise values

optValues = zeros(length(noiseValues),3);
for noiseIdx=1:length(noiseValues)
    tmp = squeeze(allBitRates(noiseIdx,:,:));
    [maxBitRate,maxIdx] = max(tmp(:));
    [i,j]=ind2sub(size(tmp),maxIdx);
    
    optValues(noiseIdx,1)=maxBitRate;
    optValues(noiseIdx,2)=betaValues(i);
    optValues(noiseIdx,3)=dwellTimeValues(j)/50;
end

%%
save([figDir filesep 'optResults'],'finalResults','factorNames','factorValues','powValues','alphaOpt','betaOpt');

