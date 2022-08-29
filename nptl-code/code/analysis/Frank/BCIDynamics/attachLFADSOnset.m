datasets = {'R_2016-02-02_1', ...
    'J_2015-04-14', ...
    'L_2015-06-05', ...
    'J_2015-01-20', ...
    'L_2015-01-14', ...
    'J_2014-09-10', ...
    't5-2017-09-20', ...
    'R_2017-10-04_1_bci', ...
    'R_2017-10-04_1_arm'};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
lfadsResultDir = [paths.dataPath filesep 'Derived' filesep 'post_LFADS' filesep 'BCIDynamics' filesep 'collatedMatFiles'];
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
for d=1:length(datasets)
    fileName = [dataDir filesep datasets{d} '.mat'];
    predata = load(fileName);
        
    %%
    lfadsData = load([lfadsResultDir filesep datasets{d} '_Go.mat']);

    lfadsNeural1 = zeros(size(predata.allNeural{1,1}));
    lfadsNeural2 = zeros(size(predata.allNeural{1,2}));
    
    lfadsNeural1(lfadsData.matInput.trainIdx,:,:) = permute(squeeze(lfadsData.allResults{1,1}(1:96,:,:)),[3 2 1]);
    lfadsNeural1(lfadsData.matInput.validIdx,:,:) = permute(squeeze(lfadsData.allResults{1,2}(1:96,:,:)),[3 2 1]);

    lfadsNeural2(lfadsData.matInput.trainIdx,:,:) = permute(squeeze(lfadsData.allResults{1,1}(97:end,:,:)),[3 2 1]);
    lfadsNeural2(lfadsData.matInput.validIdx,:,:) = permute(squeeze(lfadsData.allResults{1,2}(97:end,:,:)),[3 2 1]);
    
    lfadsNeural = cat(3, lfadsNeural1, lfadsNeural2);
    
    %%
    %try getting CIS to detect neural onset
    tmp = lfadsNeural;
    alignIdx = 1;

    %stack
    eventIdx = [];
    [~,eventOffset] = min(abs(predata.timeAxis{alignIdx}));

    stackIdx = 1:size(tmp,2);
    neuralStack = zeros(size(tmp,1)*size(tmp,2),size(tmp,3));
    for t = 1:size(tmp,1)
        neuralStack(stackIdx,:) = tmp(t,:,:);
        eventIdx = [eventIdx; stackIdx(1)+eventOffset-1];
        stackIdx = stackIdx + size(tmp,2);
    end

    %normalize
    neuralStack = zscore(neuralStack);

    %information needed for unrolling functions
    timeWindow = [-eventOffset+1, length(predata.timeAxis{alignIdx})-eventOffset];
    trialCodes = predata.allCon{alignIdx};
    timeStep = predata.binMS/1000;
    margNames = {'CD', 'CI'};

    %simple dPCA
    dPCA_out = apply_dPCA_simple( neuralStack(:,1:96), eventIdx, trialCodes, timeWindow, timeStep, margNames );
    
    binIdx = 1:size(lfadsNeural,2);
    lfadsCIS = zeros(size(lfadsNeural,1), size(lfadsNeural,2));
    for t=1:size(lfadsNeural,1)
        lfadsCIS(t,:) = neuralStack(binIdx,1:96) * dPCA_out.W(:,1);
        binIdx = binIdx + size(lfadsNeural,2);
    end
    
    %%
%     baselineDelta = zeros(size(lfadsNeural,1), size(lfadsNeural,2));
%     tmpBaseline = squeeze(mean(mean(lfadsNeural,1),2))';
%     for t=1:size(lfadsNeural,1)
%         baselineDelta(t,:) = matVecMag(squeeze(lfadsNeural(t,:,:)) - tmpBaseline,2);
%     end
     
    lfadsCIS = lfadsCIS - mean(lfadsCIS(:));
    lfadsCIS = lfadsCIS/std(lfadsCIS(:));
    baselineDelta = lfadsCIS;

    figure
    plot(baselineDelta');
    
    sequences = cell(size(baselineDelta,1),1);
    for s=1:length(sequences)
        sequences{s} = baselineDelta(s,:);
    end
    
    avgSeq = DBA(sequences);

    neuralThreshold = mean(baselineDelta(:,1));
    
    startIdx = nan(size(baselineDelta,1),1);
    for t=1:length(startIdx)
        loopIdx = 30:size(baselineDelta,2);
        firstIdx = find(baselineDelta(t,loopIdx)>0.5,1,'first');
        if ~isempty(firstIdx)
            startIdx(t) = firstIdx + loopIdx(1) - 1;
        end
    end
    
    newTimeWindow = [-30, 80];
    badTrl = false(size(startIdx));
    badTrl(startIdx<50) = true;
    badTrl(startIdx>99) = true;
    badTrl = badTrl | isnan(startIdx);
    
    nBins = newTimeWindow(2) - newTimeWindow(1) + 1;
    newDelta = nan(size(baselineDelta,1), nBins);
    for t=1:size(baselineDelta,1)
        if badTrl(t) || isnan(startIdx(t))
            continue;
        end
        loopIdx = (startIdx(t)+newTimeWindow(1)):(startIdx(t)+newTimeWindow(2));
        newDelta(t,:) = baselineDelta(t, loopIdx);
    end
    
    mn = nanmean(newDelta(~badTrl,:));
    sd = nanstd(newDelta(~badTrl,:));
    
    %%
    figure
    hold on
    for t=1:size(baselineDelta,1)
        if badTrl(t)
            plot(newDelta(t,:),'r');
        else
            plot(newDelta(t,:),'b');
        end
    end
    plot(mn,'k','LineWidth',2);
    
    %%
    outlierIdx = false(size(newDelta,1),1);
    for t=1:size(newDelta,1)
        outlierIdx(t) = any(newDelta(t,:)<mn-3*sd | newDelta(t,:)>mn+3*sd);
    end
    
    figure
    hold on
    for t=1:size(baselineDelta,1)
        if badTrl(t) || outlierIdx(t)
            plot(newDelta(t,:),'r');
        else
            plot(newDelta(t,:),'b');
        end
    end
    plot(mn,'k','LineWidth',2);
    
    %%
    useTrlIdx = find(~outlierIdx & ~badTrl);
    nTrl = length(useTrlIdx);
    newNeural = zeros(nTrl, nBins, size(lfadsNeural,3));
    newKin = zeros(nTrl, nBins, 5);
    
    for t=1:nTrl
        trlIdx = useTrlIdx(t);
        loopIdx = (startIdx(trlIdx)+newTimeWindow(1)):(startIdx(trlIdx)+newTimeWindow(2));
        newNeural(t,:,:) = cat(3, predata.allNeural{1,1}(trlIdx,loopIdx,:), predata.allNeural{1,2}(trlIdx,loopIdx,:));
        newKin(t,:,:) = predata.allKin{1}(trlIdx,loopIdx,:);
    end
    
    conList = unique(predata.allCon{1});
    kinAvg = zeros(length(conList), nBins, size(predata.kinAvg{1},3));
    neuralAvg = zeros(length(conList), nBins, size(newNeural,3));
    for c=1:length(conList)
        trlIdx = find(predata.allCon{1}(useTrlIdx)==conList(c));
        kinAvg(c,:,:) = mean(squeeze(newKin(trlIdx,:,:)),1);
        neuralAvg(c,:,:) = mean(squeeze(newNeural(trlIdx,:,:)),1);
    end
    
    %%
    predata.alignTypes = {'Go','MovStart','TargEnter','NeuralStart'};
    predata.allCon{4} = predata.allCon{1}(useTrlIdx);
    predata.allKin{4} = newKin;
    predata.kinAvg{4} = kinAvg;
    
    predata.allNeural{4,1} = newNeural(:,:,1:96);
    predata.allNeural{4,2} = newNeural(:,:,97:end);
    predata.neuralAvg{4,1} = neuralAvg(:,:,1:96);
    predata.neuralAvg{4,2} = neuralAvg(:,:,97:end);
    
    predata.timeAxis{4} = (newTimeWindow(1):newTimeWindow(2))*predata.binMS;
    predata.timeWindows{4} = newTimeWindow*predata.binMS;
    
    save(fileName, '-struct', 'predata');
end