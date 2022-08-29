%%
%single letter decoding
%word & sentence decoding

%%
sessionList = {
    't5.2019.05.01',[4 6 8 10 13 15 19 21 22],[5 7 9 12 14 18 20];                %many words
    't5.2019.05.08',[5 7 9 11 13 15 17 19 23],[6 8 10 12 14 16 18 20 22 24]};     %many sentences

for sessionIdx=1:size(sessionList,1)
    
    sessionName = sessionList{sessionIdx, 1};
    blockList = sort([sessionList{sessionIdx, 2}, sessionList{sessionIdx, 3}]);
    clear allR R alignDat
    
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
 
    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'allAlphabets' filesep sessionName sessionSuffix];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

    %%       
    bNums = horzcat(blockList);
    movField = 'rigidBodyPosXYZ';
    filtOpts.filtFields = {'rigidBodyPosXYZ'};
    filtOpts.filtCutoff = 10/500;
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

    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'rigidBodyPosXYZ','currentMovement','headVel'};
    timeWindow = [-1000,10000];
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
    
    endTrl = [allR.holdCue];
    startTrl = [allR.goCue];
    clear allR R;
    
    alphabetBlocks = sessionList{sessionIdx,2};
    trl = find(ismember(alignDat.bNumPerTrial, alphabetBlocks));
    loopIdx = [];
    for t=1:length(trl)
        loopIdx = [loopIdx, (alignDat.eventIdx(trl(t))-99):(alignDat.eventIdx(trl(t))+400)];
    end
    
    meanRate = mean(alignDat.rawSpikes(loopIdx,:))*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];

    alignDat.zScoreSpikes_allBlocks = zscore(alignDat.rawSpikes);
    alignDat.zScoreSpikes_blockMean = alignDat.zScoreSpikes;

    smoothSpikes_allBlocks = gaussSmooth_fast(zscore(alignDat.rawSpikes),3);
    smoothSpikes_blockMean = gaussSmooth_fast(alignDat.zScoreSpikes,3);

    trlCodes = alignDat.currentMovement(alignDat.eventIdx);
    nothingTrl = trlCodes==218;

    [uniqueCodes, ~, tcReorder] = unique(trlCodes);
    
    uniqueCodes_noNothing = uniqueCodes;
    uniqueCodes_noNothing(uniqueCodes_noNothing==218) = [];
    letterCodes = [400:406, 412:432];
    
    %%
    %make letter templates
    cubeDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes'];
    alignedCube = load([cubeDir filesep sessionName '_warpedCube.mat']);

    templateLoadDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'allAlphabets' filesep 't5.2019.05.01'];
    templates = load([templateLoadDir 'warpedTemplates.mat']);
    letterLens = templates.out.conLen(1:26);
    
    letterFields = fieldnames(alignedCube);
    letterFields = letterFields(1:26);
    
    N = size(smoothSpikes_blockMean,2);
    K = 26;
    L = 150;
    W = zeros(N, K, L);
    
    for k=1:K
        W(:,k,:) = squeeze(nanmean(alignedCube.(letterFields{k})(:,52:end,:),1))';
        W(:,k,(templates.out.conLen(k)+5):end) = 0;
    end
    
    %%
    %for each trial, infer sequence
    wordBlocks = sessionList{sessionIdx,3};
    trl = find(ismember(alignDat.bNumPerTrial, wordBlocks));
    
    for t=52:length(trl)
        trlTime = (endTrl(trl(t))-startTrl(trl(t)));
        loopIdx = (alignDat.eventIdx(trl(t))):(alignDat.eventIdx(trl(t))+trlTime);
        X = smoothSpikes_blockMean(loopIdx,:)'+1;
        
        [W,H,cost,loadings,power] = seqNMF(X,'K',K,'L',L,'lambda',0.01,'W_init',W,'W_fixed',1,'shift',0);
    end
    
end %all sessions