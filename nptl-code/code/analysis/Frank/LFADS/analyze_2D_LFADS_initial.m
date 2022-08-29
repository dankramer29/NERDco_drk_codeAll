%%
%predata=load('/Users/frankwillett/Data/Derived/BCIDynamicsPredata/t5-2017-09-20.mat')

%%
paths = getFRWPaths();
addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));

preDir = [paths.dataPath filesep 'Derived' filesep 'pre_LFADS' filesep 't5-2017-09-20'];
postDir = [paths.dataPath filesep 'Derived' filesep 'post_LFADS' filesep 't5-2017-09-20'];
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep 't5.2017.09.20' filesep];

R = getSTanfordBG_RStruct( sessionPath, [5 6 9 10 11 12] );

opts.filter = false;
opts.useDecodeSpeed = true;
data = unrollR_1ms( R, opts );
data.outerTargCodes = [9 8 6 3 1 2 4 7];
data.isOuterReach = ismember(data.targCodes, [1 2 3 4 6 7 8 9]);

lfadsRates = load([postDir filesep 'concatResults_small.mat']);
lfadsInput = load([preDir filesep 'matlabDataset.mat']);

for lfadsRunIdx = 1:size(lfadsRates.smallResults,1)
    allRates = zeros(size(lfadsInput.all_data));
    allRatesOrdered = zeros(size(allRates));
    allRatesOrdered(:,:,lfadsInput.trainIdx) = lfadsRates.smallResults{lfadsRunIdx,1};
    allRatesOrdered(:,:,lfadsInput.validIdx) = lfadsRates.smallResults{lfadsRunIdx,2};

    trlIdx = find(data.isOuterReach);
    trlCodes = data.targCodes(trlIdx);
    newCodes = zeros(size(trlCodes));
    for d=1:length(data.outerTargCodes)
        newCodes(trlCodes==data.outerTargCodes(d)) = d;
    end
    codeList = unique(newCodes);

    allRatesOrdered = allRatesOrdered(:,:,data.isOuterReach);
    allRatesOrdered = permute(allRatesOrdered, [3 2 1]);
    lfadsPreData.alignTypes = {'Go'};
    lfadsPreData.allCon = {newCodes};
    lfadsPreData.allNeural = {allRatesOrdered};

    binnedKin = zeros(size(lfadsPreData.allNeural{1},1),size(lfadsPreData.allNeural{1},2),5);
    for t=1:size(binnedKin,1)
        loopIdx = (data.reachEvents(trlIdx(t),2)+4):5:(data.reachEvents(trlIdx(t),2)+1000);
        binnedKin(t,:,:) = [data.cursorPos(loopIdx,1:2), data.cursorVel(loopIdx,1:2), data.cursorSpeed(loopIdx)];
    end
    lfadsPreData.allKin = {binnedKin};

    neuralAvg = zeros(length(codeList),size(allRatesOrdered,2),size(allRatesOrdered,3));
    kinAvg = zeros(length(codeList),size(binnedKin,2),size(binnedKin,3));
    for c=1:length(codeList)
        trlIdx = find(newCodes==codeList(c));
        neuralAvg(c,:,:) = nanmean(squeeze(allRatesOrdered(trlIdx,:,:)),1);
        kinAvg(c,:,:) = nanmean(squeeze(binnedKin(trlIdx,:,:)),1);
    end

    lfadsPreData.kinAvg = {kinAvg};
    lfadsPreData.neuralAvg = {neuralAvg};
    lfadsPreData.timeAxis = {(5:5:1001)/1000};
    lfadsPreData.timeWindows = [0 1000];

    lfadsPreData.metaData.filename = 't5.2017.09.20';
    lfadsPreData.metaData.task = 'BG_2DCursor';
    lfadsPreData.metaData.subject = 'T5';
    lfadsPreData.metaData.savetags = [5 6 9 10 11 12];
    lfadsPreData.metaData.controlType = 'bci';
    lfadsPreData.metaData.arrayNames = {'M1'};

    lfadsPreData.neuralType = 'LFADS';
    lfadsPreData.binMS = 5;

    save([paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata' filesep 't5-2017-09-20-LFADS' num2str(lfadsRunIdx) '.mat'],'-struct','lfadsPreData');
    
    %%
    %try single-trial alignment
    
    
end