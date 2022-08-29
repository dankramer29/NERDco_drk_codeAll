%%
%ftarg plots for each distance
%dPCA within a single direction axis
%fit LDS to trial-averaged data, unroll, plot predicting population
%activity & predicted velocities

%%
datasets(1).filename = 'R_2017-10-11_1';
datasets(1).task = 'bci_vs_arm_3ring';
datasets(1).subject = 'Jenkins';
datasets(1).savetags = [10 12];
datasets(1).controlType = 'arm';
datasets(1).arrayNames = {'M1','PMd'};

datasets(2).filename = 'R_2017-10-11_1';
datasets(2).task = 'bci_vs_arm_3ring';
datasets(2).subject = 'Jenkins';
datasets(2).savetags = [7];
datasets(2).controlType = 'bci';
datasets(2).arrayNames = {'M1','PMd'};

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
speedMax = 1500;
binMS = 10;

%%
for d=1:length(datasets)
    saveableName = [strrep(datasets(d).filename,'.','-') '_' datasets(d).controlType];
    outDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
    
    %%
    %load dataset
    fileName = [paths.dataPath filesep 'Monk' filesep 'BCIvsArm' filesep datasets(d).filename '.mat'];
    load(fileName);
    
    %%
    %first remove all trials not belonging to appropriate blocks
    saveTag = zeros(size(R));
    for t=1:length(R)
        saveTag(t) = R(t).startTrialParams.saveTag;
    end
    R = R(ismember(saveTag, datasets(d).savetags));
    
    %%
    %initial formatting
    if strcmp(datasets(d).controlType, 'arm')
        opts.filter = true;
        opts.useDecodeSpeed = false;
    else
        opts.filter = false;
        opts.useDecodeSpeed = true;
    end
    data = unrollR_1ms( R, opts );
    
    data = format3ring( data );
    
    %%
    %20ms cVec analysis
    data20 = unrollR_generic(R, 20, opts);
    data20 = format3ring( data20 );
    
    %bin selection
    reachEpochs = [data20.reachEvents(:,2)+10, data20.reachEvents(:,end)];
    useTrials = ~isnan(data20.reachEvents(:,1)) & [R.isSuccessful]';
    loopIdx = expandEpochIdx(reachEpochs(useTrials,:));
    
    %get control vector decode
    posErr = data20.targetPos - data20.cursorPos;
    posErr = posErr(:,1:2);
    normFeatures = zscore(data20.spikes);
    featMean = mean(data20.spikes);
    featStd = std(data20.spikes);
    filts = buildLinFilts(posErr(loopIdx,:), normFeatures(loopIdx,:), 'inverseLinear');
    dec_cvec = normFeatures*filts;
    
    %normalize magnitude
    [~, betaIdx] = normalizeDecoder_indDim(posErr(loopIdx,:), dec_cvec(loopIdx,:), [60, 120]);
    dec_cvec = bsxfun(@times, dec_cvec, betaIdx');
    filts = bsxfun(@times, filts, betaIdx');
    
    %fit f_targ for each separate ring
    codeFields = {'innerRingCodes','middleRingCodes','outerRingCodes'};
    ringDist = data20.withinDirDist;
    fTarg = cell(3,1);
    for ringIdx=1:3
        innerTrlIdx = useTrials & ismember(data20.targCodes, data20.(codeFields{ringIdx}));
        loopIdx = expandEpochIdx(reachEpochs(innerTrlIdx,:));
        fTarg{ringIdx} = fitFTarg(posErr(loopIdx,:), dec_cvec(loopIdx,:), ringDist(ringIdx), 12, true);
    end
    
    figure
    hold on
    for ringIdx=1:3
        plot(fTarg{ringIdx}(:,1), fTarg{ringIdx}(:,2), '-o');
    end
    
    loopIdx = expandEpochIdx(reachEpochs(useTrials,:));
    fTarg_all = fitFTarg(posErr(loopIdx,:), dec_cvec(loopIdx,:), ringDist(end), 12, true);
    figure
    plot(fTarg_all(:,1), fTarg_all(:,2), '-o');
    
    %%
    %basic trial filtering
    nTrials = size(data.trialSeg,1);
    trialFilter = true(nTrials,1);
    trialFilter = trialFilter & data.isOuterReach & data.isSuccessful;
        
    if strcmp(datasets(d).task,'3ring') || strcmp(datasets(d).task,'bci_vs_arm')
        %this is a delay dataset, so use only trials with a delay (not
        %non-delay catch trials)
        trialFilter = trialFilter & ~isnan(data.reachEvents(:,1));
    end
    
    %align by: (1) go cue, (2) movement start (via speed threshold)
    alignTypes = {'Go','MovStart'};
    alignEvents = nan(size(data.reachEvents,1),length(alignTypes));
    alignEvents(:,1) = data.reachEvents(:,2);
    
    %%
    %get average peak speed per condition (for thresholding)
    nTargCodes = length(unique(data.targCodes));
    if any(data.targCodes==0)
        nTargCodes = nTargCodes - 1;
    end
    
    speedProfiles = cell(nTargCodes,1);
    maxSpeed = cell(nTargCodes,1);
    for t=1:size(data.reachEvents,1)
        loopIdx = data.reachEvents(t,2):data.trialSeg(t,2);
        if ~trialFilter(t) || any(loopIdx<0 | loopIdx>length(data.cursorSpeed)) || ...
                any(data.cursorSpeed(loopIdx)>speedMax)
            continue;
        end
        targIdx = data.targCodes(t);
        maxSpeed{targIdx} = [maxSpeed{targIdx}, max(data.cursorSpeed(loopIdx))];
        
        loopIdx = (data.reachEvents(t,2)):(data.reachEvents(t,2)+1000);
        if any(loopIdx<0 | loopIdx>length(data.cursorSpeed))
            continue;
        end
        speedProfiles{targIdx} = [speedProfiles{targIdx}; data.cursorSpeed(loopIdx)'];
    end
    
    meanPeakSpeed = zeros(nTargCodes,1);
    for t=1:nTargCodes
        meanPeakSpeed(t) = mean(maxSpeed{t});
    end
    
    baselineSpeed = zeros(1,2);
    sp = vertcat(speedProfiles{:});
    sp = sp(:,1:100);
    baselineSpeed(1) = mean(sp(:));
    baselineSpeed(2) = std(sp(:));
    
    %%
    %threshold based on *speedPCT peak speed
    if strcmp(datasets(d).controlType,'arm')
        speedPCT = 0.30;
    else
        speedPCT = 0.50;
    end
    for t=1:size(data.reachEvents,1)
        if  ~trialFilter(t)
            continue;
        end
        speedThresh = speedPCT * meanPeakSpeed(data.targCodes(t));
        
        loopIdx = data.reachEvents(t,2):data.trialSeg(t,2);
        startIdx = find(data.cursorSpeed(loopIdx)>speedThresh,1,'first');
        if ~isempty(startIdx)
            alignEvents(t,2) = loopIdx(startIdx);
        end
    end
    
    %reject trials that don't cross the speed threshold
    trialFilter = trialFilter & ~isnan(alignEvents(:,2));
    
    %reject trials that have an outlier speed profile
    speedOutlier = false(size(trialFilter));
    for t=1:length(speedOutlier)
        loopIdx = data.reachEvents(t,2):(data.reachEvents(t,2)+1000);
        if any(loopIdx>length(data.cursorSpeed)) || ~trialFilter(t)
            continue;
        end
        
        speedTraj = data.cursorSpeed(loopIdx)';
        mnSpeedTraj = mean(speedProfiles{data.targCodes(t)});
        stdSpeedTraj = std(speedProfiles{data.targCodes(t)});
        
        speedOutlier(t) = any(speedTraj < (mnSpeedTraj - stdSpeedTraj*5) | ...
            speedTraj > (mnSpeedTraj + stdSpeedTraj*5));
    end
    
    %%
    %pull correct set of conditions for this dataset
    conSet = 1:48;
    
    %%
    %confirm alignment
    plotCon = conSet(9);
    trlIdx = find(data.targCodes==plotCon);
    speedConcat = cell(3,1);
    
    figure('Position',[680   823   914   275]);
    for alignIdx=1:2
        subplot(1,2,alignIdx);
        hold on;
        for t=1:length(trlIdx)
            if ~trialFilter(trlIdx(t))
                continue;
            end
            loopIdx = (alignEvents(trlIdx(t), alignIdx)-200):(alignEvents(trlIdx(t), alignIdx)+1200);
            if loopIdx(1)<0 || loopIdx(end)>length(data.cursorSpeed)
                continue;
            end
            plot(data.cursorSpeed(loopIdx),'LineWidth',2);
            speedConcat{alignIdx} = [speedConcat{alignIdx}; data.cursorSpeed(loopIdx)'];
        end
        title(alignTypes{alignIdx});
        set(gca,'LineWidth',1.5,'FontSize',16);
    end
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    saveas(gcf,[outDir filesep saveableName '_speedAlign.png'],'png');
    saveas(gcf,[outDir filesep saveableName '_speedAlign.fig'],'fig');
    
    %%
    %get trial average speed profile
    avgSpeed = mean(speedConcat{2});
    plotIdx = 1:700;
    
    figure
    hold on
    for s=1:size(speedConcat{2},1)
        plot(plotIdx-1, speedConcat{2}(s,plotIdx));
    end
    plot(avgSpeed(plotIdx),'-k','LineWidth',2);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (ms)');
    ylabel('Speed (mm/s)');
    
    adjustSpeed = avgSpeed;
    adjustSpeed = adjustSpeed - 55;
    adjustSpeed(adjustSpeed<0) = 0;
    adjustSpeed = adjustSpeed*1.25;
    
    movTime = 360;
    tAxis = linspace(0,movTime,movTime);
    minJerk = 80*(10*(tAxis/movTime).^3-15*(tAxis/movTime).^4+6*(tAxis/movTime).^5);
    minJerk = minJerk';
    minJerkVel = [0; diff(minJerk)*1000];
    minJerkVel = [zeros(150,1); minJerkVel; zeros(200,1)];
    minJerkPos = cumsum(minJerkVel)/1000;
    timeAxisMS = 0:(length(minJerkVel)-1);
    
    figure
    hold on;
    plot(adjustSpeed(plotIdx),'LineWidth',2);
    plot(minJerkVel,'LineWidth',2);
    plot(avgSpeed(plotIdx),'-k','LineWidth',2);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (ms)');
    ylabel('Speed (mm/s)');
    
    figure
    hold on
    for s=1:size(speedConcat{2},1)
        plot(plotIdx-1, speedConcat{2}(s,plotIdx));
    end
    plot(minJerkVel,'-k','LineWidth',2);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (ms)');
    ylabel('Speed (mm/s)');
    %%
    acq = [R(trialFilter).timeFirstTargetAcquire]';
    rt = alignEvents(trialFilter,2)-data.trialSeg(trialFilter,1)+1;
    
    figure; 
    subplot(1,2,1);
    hist(acq-rt,100);
    title('Acq-rt');
    
    subplot(1,2,2);
    hist(rt,100);
    title('rt');
    saveas(gcf,[outDir filesep saveableName '_rtHist.png'],'png');
    saveas(gcf,[outDir filesep saveableName '_rtHist.fig'],'fig');
    
    %%
    %bin neural data and create a neural data and kinematics trial matrix
    timeWindows = {[-499, 1300],[-699, 1100]};
    
    allNeural = cell(length(alignTypes),2);
    allKin = cell(length(alignTypes),1);
    allCon = cell(length(alignTypes),1);
    
    for alignIdx = 1:length(alignTypes)
        allCon{alignIdx} = [];
        timeWindow = timeWindows{alignIdx};
        nBins = (timeWindow(2)-timeWindow(1)+1)/binMS;
        for c=1:length(conSet)
            trlIdx = find(data.targCodes==conSet(c) & trialFilter);
            nTrials = length(trlIdx);
            
            allCon{alignIdx} = [allCon{alignIdx}; repmat(c,nTrials,1)];
            newNeural = cell(2,1); 
            newNeural{1} = nan(nTrials, nBins, 96);
            newNeural{2} = nan(nTrials, nBins, 96);
            newKin = nan(nTrials, nBins, 7);
            for t=1:length(trlIdx)
                loopIdx = (alignEvents(trlIdx(t), alignIdx)+timeWindow(1)):(alignEvents(trlIdx(t), alignIdx)+timeWindow(2));
                if any(loopIdx<1 | loopIdx>length(data.cursorSpeed))
                    continue;
                end
                
                for arrayIdx=1:2
                    if ~isfield(data,['array' num2str(arrayIdx)])
                        continue;
                    end
                    tmp = data.(['array' num2str(arrayIdx)])(loopIdx,:);
                    tmpBinned = zeros(nBins, 96);
                    binIdx = 1:binMS;
                    for b=1:nBins
                        tmpBinned(b,:) = sum(tmp(binIdx,:))*(1000/binMS);
                        binIdx = binIdx + binMS;
                    end
                    
                    newNeural{arrayIdx}(t,:,:) = tmpBinned;
                end
                
                tmp = [data.cursorPos(loopIdx,1:2), data.cursorVel(loopIdx,1:2), data.cursorSpeed(loopIdx), data.targetPos(loopIdx,1:2)];
                tmpBinned = tmp(1:binMS:end,:);
                newKin(t,:,:) = tmpBinned;
            end %trials
            
            allNeural{alignIdx,1} = [allNeural{alignIdx,1}; newNeural{1}];
            allNeural{alignIdx,2} = [allNeural{alignIdx,2}; newNeural{2}];
            allKin{alignIdx} = [allKin{alignIdx}; newKin];
        end %conditions
    end %alignment types
    
    %remove NAN trials
    for alignIdx=1:length(alignTypes)
        hasNan = false(size(allKin{alignIdx},1),1);
        for t=1:size(allKin{alignIdx},1)
            hasNan(t) = any(any(isnan(allKin{alignIdx}(t,:,:))));
        end
        allKin{alignIdx}(hasNan,:,:) = [];
        allNeural{alignIdx,1}(hasNan,:,:) = [];
        allNeural{alignIdx,2}(hasNan,:,:) = [];
        allCon{alignIdx}(hasNan) = [];
    end
    
    neuralAvg = cell(length(alignTypes),2);
    kinAvg = cell(length(alignTypes),1);    
    for alignIdx = 1:length(alignTypes)
        neuralAvg{alignIdx,1} = zeros(length(conSet),nBins,96);
        neuralAvg{alignIdx,2} = zeros(length(conSet),nBins,96);
        kinAvg{alignIdx,1} = zeros(length(conSet),nBins,7);
        
        for c=1:length(conSet)
            trlIdx = find(allCon{alignIdx}==c);
            for arrayIdx=1:2
                neuralAvg{alignIdx,arrayIdx}(c,:,:) = squeeze(mean(allNeural{alignIdx,arrayIdx}(trlIdx,:,:)));
            end
            
            tmp = allKin{alignIdx}(trlIdx,:,:);
            tmp(tmp>speedMax) = NaN;
            kinAvg{alignIdx}(c,:,:) = squeeze(nanmean(tmp));
        end
    end
    
    %%
    %confirm neural alignment
    timeAxis = cell(size(timeWindows));
    for t=1:length(timeAxis)
        timeAxis{t} = timeWindows{t}(1):binMS:timeWindows{t}(2);
        timeAxis{t} = timeAxis{t} + (binMS/2);
        timeAxis{t} = timeAxis{t}/1000;
    end
    
    figure
    for alignIdx=1:length(alignTypes)
        for arrayIdx=1:2
            subplot(2,3,(arrayIdx-1)*length(alignTypes) + alignIdx)
            plot(timeAxis{alignIdx}, mean(squeeze(neuralAvg{alignIdx,arrayIdx}(1,:,:))'),'LineWidth',2);
            title(alignTypes{alignIdx});
            set(gca,'LineWidth',1.5,'FontSize',16);
            xlim([timeAxis{alignIdx}(1), timeAxis{alignIdx}(end)]);
        end
    end
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    saveas(gcf,[outDir filesep saveableName '_neuralAlign.png'],'png');
    
    %%
    %confirm target codes with velocity averages
    figure
    for alignIdx=1:length(alignTypes)
        subplot(1,3,alignIdx);
        hold on;
        for c=1:length(conSet)
            plot(timeAxis{alignIdx}, squeeze(kinAvg{alignIdx}(c,:,3))','LineWidth',2);
        end
        title(alignTypes{alignIdx});
        set(gca,'LineWidth',1.5,'FontSize',16);
        xlim([timeAxis{alignIdx}(1), timeAxis{alignIdx}(end)]);
    end
    legend({'1','2','3','4','5','6','7','8'});
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    saveas(gcf,[outDir filesep saveableName '_xVel.png'],'png');
    
    %%
    %save data
    metaData = datasets(d);
    outPath = [outDir filesep saveableName '.mat'];
    
    mkdir(outDir);
    save(outPath, 'allNeural','allKin','allCon','neuralAvg','kinAvg','binMS',...
        'timeWindows','timeAxis','metaData','speedMax','speedPCT','alignTypes','fTarg','fTarg_all','filts','featMean','featStd');
    
    close all;
end
