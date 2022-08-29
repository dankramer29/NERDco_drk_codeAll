%%
sessionList = {
    't5.2019.06.26',{[2 3 4 5 6 7 8 9 10], [11 12 13 14 15 16 17 21], [23 24 25 26 27 28]}}; %many balanced words (1000)   

for sessionIdx=1:size(sessionList,1)
    
    sessionName = sessionList{sessionIdx, 1};
    blockLists = sessionList{sessionIdx, 2};
    
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
 
    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceFormat' filesep sessionName];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

    %%      
    allAlignDat = cell(length(blockLists),1);
    allTrialTimes = cell(length(blockLists),1);
    allMovementCode = cell(length(blockLists),1);
    for listIdx=1:length(blockLists)
        clear allR R alignDat;
        blockList = blockLists{listIdx};
        
        bNums = horzcat(blockList);
        movField = 'rigidBodyPosXYZ';
        filtOpts.filtFields = {'rigidBodyPosXYZ'};
        filtOpts.filtCutoff = 10/500;

        %use the first block only for setting thresholds, to match synthetic
        %data
        R = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );

        allR = []; 
        for x=1:length(R)
            for t=1:length(R{x})
                R{x}(t).blockNum=bNums(x);
                R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
            end
            allR = [allR, R{x}];
        end

        for t=1:length(allR)
            allR(t).headVel = [0 0 0; diff(allR(t).rigidBodyPosXYZ')]';
        end

        trialTimes = zeros(length(allR),1);
        for t=1:length(trialTimes)
            trialTimes(t) = allR(t).restCue-allR(t).goCue;
        end
        maxTime = max(trialTimes);

        alignFields = {'goCue'};
        smoothWidth = 0;
        datFields = {'rigidBodyPosXYZ','currentMovement','headVel'};
        timeWindow = [0, round(maxTime/10)*10];

        binMS = 10;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
        alignDat.eventIdx(end) = [];
        
        allAlignDat{listIdx} = alignDat;
        allTrialTimes{listIdx} = trialTimes;
        
        cm = zeros(length(allR),1);
        for x=1:length(cm)
            cm(x) = allR(x).currentMovement(1);
        end
        
        allMovementCode{listIdx} = cm;
    end
    clear allR R alignDat;
    
    %%
    %put all alignDat together
    allSpikes = [allAlignDat{1}.rawSpikes; allAlignDat{2}.rawSpikes; allAlignDat{3}.rawSpikes];
    allEventIdx = [allAlignDat{1}.eventIdx; allAlignDat{2}.eventIdx+size(allAlignDat{1}.rawSpikes,1); ...
        allAlignDat{3}.eventIdx+size(allAlignDat{1}.rawSpikes,1)+size(allAlignDat{2}.rawSpikes,1)];
    allBlockNums = [allAlignDat{1}.bNumPerTrial; allAlignDat{2}.bNumPerTrial; allAlignDat{3}.bNumPerTrial];
    allEventIdx(allEventIdx==0)=1;
    allCodes = vertcat(allMovementCode{:});
    
    allTimes = round(vertcat(allTrialTimes{:})/10);
    maxTime = max(allTimes);
    
    highRateIdx = find(mean(allSpikes)*100>1);
    allSpikes = allSpikes(:,highRateIdx);
    
    bList = unique(allBlockNums);
    bMeans = zeros(length(bList),size(allSpikes,2));
    for b=1:length(bList)
        trlIdx = find(allBlockNums==bList(b));
        if trlIdx(end)>=length(allEventIdx)
            loopIdx = allEventIdx(trlIdx(1)):size(allSpikes,1);
        else
            loopIdx = allEventIdx(trlIdx(1)):(allEventIdx(trlIdx(end)+1)-1);
        end
        
        bMeans(b,:) = mean(allSpikes(loopIdx,:));
        allSpikes(loopIdx,:) = allSpikes(loopIdx,:)-bMeans(b,:);
    end
    
    sd = std(allSpikes);
    zScoreSpikes = allSpikes./sd;
    
    %%
    %get repeated words blocks
    repWordBlocks = [18 20];
    R = getStanfordRAndStream( sessionPath, repWordBlocks, 4.5, repWordBlocks(1), filtOpts );
    
    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
        end
        allR = [allR, R{x}];
    end
    
    wordRepCode = zeros(length(allR),1);
    for x=1:length(wordRepCode)
        wordRepCode(x) = allR(x).currentMovement(1);
    end
    
    wordRepCodeList = unique(wordRepCode);
    wordRepWords = cell(length(wordRepCodeList),1);
    for x=1:length(wordRepCodeList)
        wordRepWords{x} = getMovementText(wordRepCodeList(x));
        wordRepWords{x} = deblank(wordRepWords{x}(10:end));
    end
    
    trialTimes = zeros(length(allR),1);
    for t=1:length(trialTimes)
        trialTimes(t) = allR(t).restCue-allR(t).goCue;
    end

    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'rigidBodyPosXYZ','currentMovement'};
    timeWindow = [0, round(max(trialTimes)/10)*10];

    binMS = 10;
    alignDat_rep = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
    alignDat_rep.eventIdx(end) = [];
      
    %process repeated words data in the same way
    alignDat_rep.zScoreSpikes = (alignDat_rep.rawSpikes(:,highRateIdx)-bMeans(16,:)) ./ sd;

    %%
    %make data cube for alignment
    cubeDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes'];
    fileName = [cubeDir filesep sessionName '_unwarpedCube.mat'];
    
    dat = struct();
    for t=1:length(conLabels)
        winToUse = [-50, 200];
        concatDat = triggeredAvg( zScoreSpikes, allEventIdx(firstLetter==letterList(t)), winToUse );

        dat.(conLabels{t}) = concatDat;
    end

    %for self-paced words, cut off the trial by replacing with nans
    %after T5 indicated he was done
    winToUse = [-50, 900];
    for t=1:length(wordRepWords)
        trlIdx = find(wordRepCode==wordRepCodeList(t));
        concatDat = triggeredAvg( alignDat_rep.zScoreSpikes, alignDat_rep.eventIdx(trlIdx), winToUse );
        
        endTime = round(trialTimes(trlIdx)/10);
        for x=1:length(trlIdx)
            concatDat(x,(51+endTime(x)):end,:)=nan;
        end
        
        dat.(wordRepWords{t}) = concatDat;
    end

    dat.chanIdx = highRateIdx;
    dat.blockMeans = bMeans;
    dat.featureSTD = sd;
    save(fileName,'-struct','dat');
    
    %%
    %put it all into a big matrix
    nTrials = length(allTimes);
    nChan = size(allSpikes,2);
    fullData = zeros(nTrials, maxTime, nChan);
    
    currIdx = 1;
    for t=1:nTrials
        loopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
        fullData(t,1:length(loopIdx),:) = gaussSmooth_fast(zScoreSpikes(loopIdx,:),5.0);
    end

    %%
    %get word text
    mappedText = cell(length(allEventIdx),1);
    for t=1:length(mappedText)
        mappedText{t} = getMovementText(allCodes(t));
        mappedText{t} = deblank(mappedText{t}(10:end));
    end
    
    %%
    %check decodability
    firstLetter = zeros(length(mappedText),1);
    for t=1:length(firstLetter)
        firstLetter(t) = mappedText{t}(1);
    end
    letterList = unique(firstLetter);
    
    conLabels = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};
    binWidth = 30;
    nDecodeBins = 5;
    [ C, L, obj ] = simpleClassify( zScoreSpikes, firstLetter, allEventIdx, conLabels, binWidth, nDecodeBins, 10, true );
    
    %%
    %estimate character length
    designMat = zeros(length(allTimes), 26);
    for x=1:length(allTimes)
        for t=1:length(conLabels)
            tmpIdx = find(mappedText{x}==conLabels{t});
            if ~isempty(tmpIdx)
                designMat(x,t) = length(tmpIdx);
            end
        end
    end
    
    [B,BINT,R,RINT,STATS] = regress(allTimes/100,[ones(size(designMat,1),1), designMat]);
    
    figure;
    hold on;
    plot(B,'o');
    set(gca,'XTick',1:27,'XTickLabel',[{'RT'},conLabels],'FontSize',16);
        
    %%
    %save in shareable format
    numBinsPerTrial = allTimes;
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '.mat'],'fullData','mappedText','numBinsPerTrial');
    
    allTrials = single(fullData);
    wordPerTrial = mappedText;
    nTimeStepsPerTrial = allTimes;
    dataFormat = 'allTrials is an NxTxC matrix, where N is the number of trials, T is the number of 10 ms time steps, and M is the number of channels. nTimeStepsPerTrial indicates the number of time steps for each trial (time steps after this have zeroed values). wordPerTrial indicates the cued word on that trial';
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_share.mat'],'allTrials','wordPerTrial','nTimeStepsPerTrial','dataFormat');
    
end %all sessions