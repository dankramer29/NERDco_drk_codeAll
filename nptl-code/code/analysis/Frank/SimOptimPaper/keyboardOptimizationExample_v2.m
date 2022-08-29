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

simOpts.control.fTargX  = [linspace(0,1,10) 1.1 1.2 1.3];
simOpts.control.fTargY = [0, 0.4, 0.6, 0.7, 0.78, 0.85, 0.9, 0.93, 0.96, 1, 1.02 1.03 1.03];

simOpts.trial.maxTrialTime = 12;

simOpts.forwardModel.delaySteps = 12;
simOpts.forwardModel.forwardSteps = 12;
simOpts.control.rtSteps = 10;

%%
%make keyboards
targetNumList = 2:10;
keyCenterList = cell(length(targetNumList),1);

for targNumIdx = 1:length(targetNumList)
    nTarg = targetNumList(targNumIdx);
    keyCenters = [];

    kbSize = 2;
    keyWidth = 2/nTarg;
    keyAxis = linspace(-1+keyWidth/2,1-keyWidth/2,nTarg);

    for x=1:nTarg
        for y=1:nTarg
            keyCenters = [keyCenters; [keyAxis(x), keyAxis(y)]];
        end
    end
    
    keyCenterList{targNumIdx} = keyCenters;
end
    
%%
%set up parameter sweeps
dwellTimeValues = 4:1:150;
noiseValues = logspace(log10(0.5.^2), log10(2.0.^2), 10);
optimalValues = zeros(length(noiseValues),4);

%generate keyboard targets
nTargs = 1200;
targetPos = zeros(nTargs, 2);
startPos = zeros(nTargs, 2);
targetIdx = zeros(nTargs,1);
for targIdx=1:nTargs
    startTargIdx = randi(length(keyCenterList{5}),1,1);
    endTargIdx = randi(length(keyCenterList{5}),1,1);

    targetPos(targIdx,:) = keyCenterList{5}(endTargIdx,:);
    startPos(targIdx,:) = keyCenterList{5}(startTargIdx,:);
    targetIdx(targIdx) = endTargIdx;
end

%sweep over noise values
for noiseIdx=1:length(noiseValues)
    disp(['Noise Value ' num2str(noiseIdx) ' / ' num2str(length(noiseValues))]);
    newNoiseModel = noiseModel;
    newNoiseModel.cov = zeros(2);
    newNoiseModel.cov(1,1) = noiseValues(noiseIdx);
    newNoiseModel.cov(2,2) = noiseValues(noiseIdx);
    newNoiseMatrix = genTimeSeriesFromARModel_multi( 1000000, newNoiseModel.coef, newNoiseModel.cov );
    
    newOpts = simOpts;
    newOpts.noiseMatrix = newNoiseMatrix;
    newOpts.trial.dwellTime = 22.0;
    newOpts.trial.maxTrialTime = 20.0;
            
    %optimize over alpha & beta with a pattern search
    %value range: [0.8, 0.2], [0.99,3.0], has been mapped for pattern
    %search to [0,1],[0,1]
    optFun = @(coef)(-innerObjFunction_kb( newOpts, targetPos, startPos, targetIdx, keyCenterList{5}, dwellTimeValues, ...
        [coef(1)*0.19 + 0.8, coef(2)*2.8 + 0.2] ));

    options = psoptimset('Display','iter','MaxFunEvals',2000,'TolMesh',10^-2);
    startValues = [(0.94-0.8)/0.19, (1.0-0.2)/2.8];
    [X, fval] = patternsearch(optFun,startValues,[],[],[],[],...
        [0, 0],[1,1],[],options); 
    
    X = [X(1)*0.19 + 0.8, X(2)*2.8 + 0.2];
    [finalBitRate, finalDwellTime] = innerObjFunction_kb( newOpts, targetPos, startPos, targetIdx, keyCenterList{5}, dwellTimeValues, X );
    optimalValues(noiseIdx,:) = [finalBitRate, X, finalDwellTime/50];
end 

save([figDir filesep 'optResults_kb6'],'optimalValues');

%%
%optimize over number of keys as well
dwellTimeValues = 4:1:150;
optimalValues = zeros(length(keyCenterList),length(noiseValues),4);
noiseValues = logspace(log10(0.5.^2), log10(2.0.^2), 10);

for noiseIdx=1:length(noiseValues)
    disp(['Noise Value ' num2str(noiseIdx) ' / ' num2str(length(noiseValues))]);
    
    for kbIdx=1:length(keyCenterList)
        disp(['Keyboard # ' num2str(kbIdx) ' / ' num2str(length(keyCenterList))]);
        
        %generate keyboard targets
        nTargs = 1200;
        targetPos = zeros(nTargs, 2);
        startPos = zeros(nTargs, 2);
        targetIdx = zeros(nTargs,1);
        for targIdx=1:nTargs
            startTargIdx = randi(length(keyCenterList{kbIdx}),1,1);
            endTargIdx = randi(length(keyCenterList{kbIdx}),1,1);

            targetPos(targIdx,:) = keyCenterList{kbIdx}(endTargIdx,:);
            startPos(targIdx,:) = keyCenterList{kbIdx}(startTargIdx,:);
            targetIdx(targIdx) = endTargIdx;
        end

        newNoiseModel = noiseModel;
        newNoiseModel.cov = zeros(2);
        newNoiseModel.cov(1,1) = noiseValues(noiseIdx);
        newNoiseModel.cov(2,2) = noiseValues(noiseIdx);
        newNoiseMatrix = genTimeSeriesFromARModel_multi( 100000, newNoiseModel.coef, newNoiseModel.cov );

        newOpts = simOpts;
        newOpts.noiseMatrix = newNoiseMatrix;
        newOpts.trial.dwellTime = 22.0;
        newOpts.trial.maxTrialTime = 20.0;

        %optimize over alpha & beta with a pattern search
        %value range: [0.8, 0.2], [0.99,3.0], has been mapped for pattern
        %search to [0,1],[0,1]
        optFun = @(coef)(-innerObjFunction_kb( newOpts, targetPos, startPos, targetIdx, keyCenterList{kbIdx}, dwellTimeValues, ...
            [coef(1)*0.19 + 0.8, coef(2)*2.8 + 0.2] ));

        options = psoptimset('Display','iter','MaxFunEvals',2000,'TolMesh',10^-3);
        startValues = [(0.94-0.8)/0.19, (1.0-0.2)/2.8];
        [X, fval] = patternsearch(optFun,startValues,[],[],[],[],...
            [0, 0],[1,1],[],options); 

        X = [X(1)*0.19 + 0.8, X(2)*2.8 + 0.2];
        [finalBitRate, finalDwellTime] = innerObjFunction_kb( newOpts, targetPos, startPos, targetIdx, keyCenters, dwellTimeValues, X );
        optimalValues(kbIdx,noiseIdx,:) = [finalBitRate, X, finalDwellTime/50];
    end 
end

save([figDir filesep 'optResults_allKb'],'optimalValues');

