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

nTargs = 500;
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
nReps = 10;
allBitRates = zeros(nReps,length(dwellTimeValues));
allSuccRates = zeros(nReps,length(dwellTimeValues));
allAcqTimes = zeros(nReps,length(dwellTimeValues));
optimalValues = zeros(nReps,length(dwellTimeValues),2);

for dIdx = 1:length(dwellTimeValues)
    disp(['Dwel lTime: ' num2str(dIdx) '/' num2str(length(dwellTimeValues))]);
    for repIdx=1:nReps
        disp(num2str(repIdx));
        
        newNoiseMatrix = genTimeSeriesFromARModel_multi( 100000, noiseModel.coef, noiseModel.cov );
        newOpts = simOpts;
        newOpts.noiseMatrix = newNoiseMatrix;
        newOpts.trial.dwellTime = 22.0;
        newOpts.trial.maxTrialTime = 20.0;
        
        %optimize over alpha & beta with a pattern search
        %value range: [0.8, 0.2], [0.99,3.0], has been mapped for pattern
        %search to [0,1],[0,1]
        optFun = @(coef)(innerObjFunction_kb_2( newOpts, targetPos, startPos, targetIdx, keyCenters, dwellTimeValues(dIdx), ...
            [coef(1)*0.19 + 0.8, coef(2)*2.8 + 0.2] ));

        options = psoptimset('Display','off','MaxFunEvals',2000,'TolMesh',10^-2);
        startValues = [(0.94-0.8)/0.19, (1.0-0.2)/2.8];
        [X, fval] = patternsearch(optFun,startValues,[],[],[],[],...
            [0, 0],[1,1],[],options); 

        [negBitRate, succRate, meanAcqTime] = optFun(X);
        optimalValues(repIdx, dIdx, :) = [X(1)*0.19 + 0.8, X(2)*2.8 + 0.2];
        allBitRates(repIdx, dIdx) = -negBitRate;
        allAcqTimes(repIdx, dIdx) = meanAcqTime;
        allSuccRates(repIdx, dIdx) = succRate;
    end %reps
end

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
save([resultsDir filesep 'figures' filesep 'optiPaper' filesep 'kbSim_2']);

%%
load('/Users/frankwillett/Data/CaseDerived/kbSim.mat');

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

metricLabels = {'Bit Rate (bps)','Smoothing (\alpha)','Gain (\beta)','Acquire Time (s)','Success Rate'};
dtAxis = dwellTimeValues/50;
for m=1:5
    subplot(2,3,1+m);
    hold on;
    
    [mn,~,CI] = normfit(squeeze(optValues(:,:,m)));
    plot(dtAxis, mn, '-k');
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

