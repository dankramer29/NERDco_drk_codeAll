%apply same analysis to Sergey gain data, Nir & Saurab 3-ring and vert/horz
%dense data
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/PSTH'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/Utility'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/dPCA'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/utilities/'));
dataDir = '/Users/frankwillett/Data/Monk/';
outDir = '/Users/frankwillett/Data/Derived/rnnDecoding_monk/';
mkdir(outDir);
datasets = {'JenkinsData','R_2016-02-02_1.mat','Jenkins','3ring',[1],'J_2016-02-02'
        'ReggieData','R_2017-01-19_1.mat','Reggie','3ring',[1,4,6,8,10],'R_2017-01-19'
        
        'JenkinsData','R_2015-10-01_1.mat','Jenkins','denseVert',[1,2],'J_2015-10-01'
        'JenkinsData','R_2015-09-24_1.mat','Jenkins','denseHorz',[2,3,5],'J_2015-09-24'
        'ReggieData','R_2017-01-15_1.mat','Reggie','denseVert',[3,5,7],'R_2017-01-15'
    };

speedThresh = 25;
speedMax = 1500;
timeWindow = [-500, 1500]/5;

%%
for d=3:5
    %%
    %format data and produce simple PSTH
    saveDir = [dataDir 'PSTH' filesep datasets{d,2}];
    mkdir(saveDir);
    
    load([dataDir filesep datasets{d,1} filesep datasets{d,2}]);
    opts.filter = true;
    data = unrollR_generic(R, 20, opts);
    
    if strcmp(datasets{d,4},'3ring')
        data = format3ring( data );
    elseif any(strcmp(datasets{d,4},{'denseVert','denseHorz'}))
        data = formatDense( data, datasets{d,4} );
        data.dirGroups = {2:11, 13:22};
    end
    
    %data = speedThreshold(data, speedThresh);
    data.moveStartIdx = data.reachEvents(:,2); 

    useTrials = true(length(data.targCodes),1);
    useTrials = useTrials & data.isSuccessful;
    useTrials = useTrials & ~isnan(data.moveStartIdx);
    useTrials = useTrials & ismember(data.saveTag, datasets{d,5});
    failedTrials = find(~data.isSuccessful);
    for x=1:length(failedTrials)
        badIdx = (failedTrials(x)):(failedTrials(x)+4);
        badIdx(badIdx>length(useTrials))=[];
        useTrials(badIdx) = false;
    end
    useTrials(1:10) = false; %not enough history for these
    
    for x=1:length(useTrials)
        loopIdx = data.reachEvents(:,2):data.reachEvents(:,3);
        if any(data.handSpeed(loopIdx)>speedMax)
            disp('bad');
            useTrials(x) = false;
        end
    end
    
    data.handVel = data.handVel/500;
    
    reachEpochs = [data.reachEvents(:,2), data.reachEvents(:,3)];
    reachEpochs = reachEpochs(useTrials,:);
    nBinsPerChunk = 510;
    
    nFolds = 6;
    C = cvpartition(size(reachEpochs,1),'KFold',nFolds);
    for n=1:nFolds
        trainIdx = find(C.training(n));
        testIdx = find(C.test(n));

        innerTrainIdx = trainIdx(1:(4*floor(length(trainIdx)/5)));
        innerTestIdx = setdiff(trainIdx, innerTrainIdx);

        [inputs, targets, globalIdx] = formatTrialsForRNN(reachEpochs, innerTrainIdx, nBinsPerChunk, data.spikes, data.handVel(:,1:2));
        [inputsVal, targetsVal, globalIdxVal] = formatTrialsForRNN(reachEpochs, innerTestIdx, nBinsPerChunk, data.spikes, data.handVel(:,1:2));
        [inputsFinal, targetsFinal, globalIdxFinal] = formatTrialsForRNN(reachEpochs, testIdx, nBinsPerChunk, data.spikes, data.handVel(:,1:2));

        errMask = zeros(size(inputs,1), size(inputs,2));
        errMask(:,101:end) = 1;

        errMaskVal = zeros(size(inputsVal,1), size(inputsVal,2));
        errMaskVal(:,101:end) = 1;

        errMaskFinal = zeros(size(inputsFinal,1), size(inputsFinal,2));
        errMaskFinal(:,101:end) = 1;

        saveDir = [outDir filesep 'Fold' num2str(n)];
        mkdir(saveDir);
        save([saveDir filesep datasets{d,6} '.mat'],'inputs','targets','inputsVal','targetsVal','inputsFinal','targetsFinal',...
            'globalIdx','globalIdxVal','globalIdxFinal','errMask','errMaskVal','errMaskFinal');
    end
    
    save([outDir datasets{d,6} '.mat'],'data','C','useTrials','reachEpochs');
end
