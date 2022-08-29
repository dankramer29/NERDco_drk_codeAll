%%
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));

bg2FileDir = '/Users/frankwillett/Data/BG Datasets/optimPaperDatasets';
figDir = '/Users/frankwillett/Data/Derived/keyboardOptFigure/';
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

simOpts.control.fTargX  = [controlModel.distEdges, controlModel.distEdges(end)+0.01];
simOpts.control.fTargY = [controlModel.distCoef', controlModel.distCoef(end)];

simOpts.trial.maxTrialTime = 12;

simOpts.forwardModel.delaySteps = 12;
simOpts.forwardModel.forwardSteps = 12;
simOpts.control.rtSteps = 10;

%%
%make keyboard
nKeysPerSide = 6;
keyCenters = [];

kbSize = 2;
keyWidth = kbSize/nKeysPerSide;
keyAxis = linspace(-1+keyWidth/2,1-keyWidth/2,nKeysPerSide);

for x=1:nKeysPerSide
    for y=1:nKeysPerSide
        keyCenters = [keyCenters; [keyAxis(x), keyAxis(y)]];
    end
end

nTargs = 200;
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
    
%%
betaValues = logspace(log10(0.5), log10(2.0), 30);

maxAlpha = 0.97;
minAlpha = 0.84;
alphaValues = fliplr(maxAlpha-(logspace(log10(0.01),log10(1),30)-0.01)*(maxAlpha-minAlpha)/0.99);

dwellTimeValues = 25:5:100;
nReps = 50;
allBitRates = zeros(nReps,length(alphaValues),length(betaValues),length(dwellTimeValues));
allSuccRates = zeros(nReps,length(alphaValues),length(betaValues),length(dwellTimeValues));
allAcqTimes = zeros(nReps,length(alphaValues),length(betaValues),length(dwellTimeValues));

for repIdx=1:nReps
    disp(['Rep ' num2str(repIdx) '/' num2str(nReps) ' ...']);
    newNoiseMatrix = genTimeSeriesFromARModel_multi( 100000, noiseModel.coef, noiseModel.cov );
    for a=1:length(alphaValues)
        disp(['   Alpha value ' num2str(a) '/' num2str(length(alphaValues)) ' ...']);
        for b=1:length(betaValues)
            disp(['      Gain value ' num2str(b) '/' num2str(length(betaValues)) ' ...']);

            %--simulate point-to-point movements all over the keyboard 
            newOpts = simOpts;
            newOpts.noiseMatrix = newNoiseMatrix;
            newOpts.plant.beta = betaValues(b);
            newOpts.plant.alpha = alphaValues(a);
            newOpts.trial.dwellTime = 22.0;
            newOpts.trial.maxTrialTime = 20.0;

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
                
                allBitRates(repIdx,a,b,dwellIdx) = log2(N-1)*max(sum(trialResults(:,1))-sum(~trialResults(:,1)),0)/totalTime;
                allSuccRates(repIdx,a,b,dwellIdx) = sum(trialResults(:,1))/length(trialResults);
                allAcqTimes(repIdx,a,b,dwellIdx) = mean(trialResults(:,2))/50;
            end %dwell time
        end %beta
    end %alpha
end %reps

%%
optValues = zeros(nReps, length(dwellTimeValues), 5);
for repIdx=1:nReps
    for d=1:length(dwellTimeValues)
        tmp = squeeze(allBitRates(repIdx,:,:,d));
        [maxBitRate, maxIdx] = max(tmp(:));
        [i,j] = ind2sub(size(tmp),maxIdx);
        
        optValues(repIdx,d,:) = [maxBitRate, alphaValues(i), betaValues(j), ...
            allAcqTimes(repIdx,i,j,d), allSuccRates(repIdx,i,j,d)];
    end  
end

figure
plot(dwellTimeValues/50, squeeze(mean(optValues(1:end,:,:),1)), '-o', 'LineWidth',2);


resultsDir = '/Users/frankwillett/Data/CaseDerived/';
save([resultsDir filesep 'figures' filesep 'optiPaper' filesep 'kbSim_3']);


%%
load([resultsDir filesep 'figures' filesep 'optiPaper' filesep 'kbSim_3']);

figure
plot(dwellTimeValues/50, squeeze(mean(optValues(1:end,:,:),1)), '-o', 'LineWidth',2);
legend({'Bit Rate','Alpha','Beta','Acquire Time','Succ Rate'});

figure('Position',[680   737   726   361]);
subplot(2,3,1);
hold on;
for r=1:6
    for c=1:6
        rectangle('Position',[c,r,1,1],'EdgeColor','k','FaceColor',[0.7 0.7 0.7],'LineWidth',1);
    end
end
axis equal;
axis off;

metricLabels = {'Bit Rate (bps)','Optimal Smoothing (\alpha)','Optimal Gain (\beta)','Selection Time (s)','Success Rate'};
dtAxis = dwellTimeValues/50;
for m=1:5
    subplot(2,3,1+m);
    hold on;
    
    [mn,~,CI] = normfit(squeeze(optValues(:,:,m)));
    plot(dtAxis, mn, '-k','LineWidth',1);
    errorPatch(dtAxis', CI', [0 0 0],0.2);
    %errorbar(dtAxis, mn, mn-CI(1,:), CI(2,:)-mn, 'k', 'LineWidth',2);
    set(gca,'FontSize',14,'LineWidth',1);
    xlabel('Dwell Time (s)');
    ylabel(metricLabels{m});
    axis tight;
end

resultsDir = '/Users/frankwillett/Data/CaseDerived/';
saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'keyboardExample'],'svg');
saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'keyboardExample'],'fig');

