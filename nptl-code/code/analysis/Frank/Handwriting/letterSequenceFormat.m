%%
%single letter decoding
%word & sentence decoding

%%
sessionList = {
    't5.2019.05.01',[4 5 7 9 12 14 18 20];                %many words (350)
    't5.2019.05.08',[5 6 8 10 12 14 16 18 20 22 24];}      %many sentences

for sessionIdx=1:size(sessionList,1)
    
    sessionName = sessionList{sessionIdx, 1};
    blockList = sessionList{sessionIdx, 2};
    clear allR R alignDat
    
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
 
    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceFormat' filesep sessionName];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

    %%       
    bNums = horzcat(blockList);
    movField = 'rigidBodyPosXYZ';
    filtOpts.filtFields = {'rigidBodyPosXYZ'};
    filtOpts.filtCutoff = 10/500;
    
    %use the first block only for setting thresholds, to match synthetic
    %data
    R = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );
    
    R(1) = [];
    bNums(1) = [];
    
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
        trialTimes(t) = length(allR(t).clock);
    end
    maxTime = max(trialTimes);
    
    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'rigidBodyPosXYZ','currentMovement','headVel'};
    timeWindow = [0, round(maxTime/10)*10];
    
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
    alignDat.eventIdx(end) = [];
    
    %%
    cubeDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes'];
    fileName = [cubeDir filesep sessionName '_unwarpedCube.mat'];
    unalignedCube = load(fileName);
    
    %use means and standard deviations from synthetic alphabet data
    zScoreSpikes_cubeStats = alignDat.rawSpikes;
    bList = unique(alignDat.bNumPerTrial);
    allLoopIdx = [];
    for b=1:size(alignDat.blockmeans,1)
        bMeanIdx = b;
        if bMeanIdx>size(unalignedCube.blockMeans,1)
            bMeanIdx = size(unalignedCube.blockMeans,1);
        end
        
        trlIdx = find(alignDat.bNumPerTrial==bList(b));
        for t=1:length(trlIdx)
            loopIdx = alignDat.eventIdx(trlIdx(t)):(alignDat.eventIdx(trlIdx(t))+timeWindow(end)/10);
            loopIdx = loopIdx + 1;
            loopIdx(loopIdx>size(zScoreSpikes_cubeStats,1)) = [];
            
            zScoreSpikes_cubeStats(loopIdx,:) = zScoreSpikes_cubeStats(loopIdx,:) - unalignedCube.blockMeans(bMeanIdx,:);
            zScoreSpikes_cubeStats(loopIdx,:) = zScoreSpikes_cubeStats(loopIdx,:)./unalignedCube.featureSTD;
            
            allLoopIdx = [allLoopIdx, loopIdx];
        end
    end
    
    concatDat = triggeredAvg(zScoreSpikes_cubeStats(:,unalignedCube.chanIdx), alignDat.eventIdx, [0 timeWindow(end)/10]);
    concatDat(isnan(concatDat)) = 0;
    
    sentenceText = loadSentenceText();
    mappedText = cell(length(allR),1);
    for t=1:length(mappedText)
        if strcmp(sessionName,'t5.2019.05.01')
            mappedText{t} = getMovementText(allR(t).currentMovement(100));
            mappedText{t} = deblank(mappedText{t}(10:end));
        elseif strcmp(sessionName,'t5.2019.05.08')
            mappedText{t} = sentenceText{allR(t).currentMovement(100)-3000};
        end
    end
    
    numBinsPerTrial = round(trialTimes/10);
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '.mat'],'concatDat','mappedText','numBinsPerTrial');
    
    allTrials = concatDat;
    wordPerTrial = mappedText;
    nTimeStepsPerTrial = numBinsPerTrial;
    dataFormat = 'allTrials is a NxTxC matrix, where N is the number of trials, T is the number of 10 ms time steps, and M is the number of channels. nTimeStepsPerTrial indicates the number of time steps for each trial (time steps after this belong to the next trial). wordPerTrial indicates the cued word on that trial';
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_share.mat'],'allTrials','wordPerTrial','nTimeStepsPerTrial','dataFormat');
    
    %%
    sentenceText = loadSentenceText();
    trlIdx = 97;
    textDisplay = sentenceText{allR(trlIdx).currentMovement(100)-3000};
    disp(textDisplay);
    
end %all sessions