%%
%todo: add letter changing signal

sessionList = {
    't5.2019.05.08',[5 26]}; %sentences 

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
    [~, streams] = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );
    binDat = binStream( streams{2}, 10, 0, {} );

    rawCube = load(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/unwarpedTemplates/t5.2019.05.08_unwarpedCube.mat']);
    
    %use means and standard deviations from single letter data
    zScoreSpikes_cubeStats = binDat.rawSpikes;
    zScoreSpikes_cubeStats = zScoreSpikes_cubeStats - rawCube.blockMeans(end,:);
    zScoreSpikes_cubeStats = zScoreSpikes_cubeStats./rawCube.featureSTD;
    zScoreSpikes_cubeStats = zScoreSpikes_cubeStats(:, rawCube.chanIdx);
    
    %zScoreSpikes_cubeStats = zScoreSpikes_cubeStats(12000:end,:);
    maxTime = size(zScoreSpikes_cubeStats,1);
    nChan = size(zScoreSpikes_cubeStats,2);
    
    %zScoreSpikes_cubeStats = zScoreSpikes_cubeStats - mean(zScoreSpikes_cubeStats);
    
    %%
    %save time series data for RNN consumption   
    mappedText = {'unknown','unknown'};
    
    fullData = zeros(2, maxTime, nChan);
    fullDataWeight = ones(2, maxTime);
    fullData(1,:,:) = zScoreSpikes_cubeStats;

    numBinsPerTrial = [maxTime; maxTime];
    
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'timeSeriesData' filesep sessionName '_secretMessage.mat'],...
        'fullData','mappedText','numBinsPerTrial','fullDataWeight');
    
    %%
    %make fake labels
    fullDataLabels_noBlank = single(zeros(2, maxTime, 31));
    fullDataLabels_withBlank = single(zeros(2, maxTime, 31+1));

    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'timeSeriesLabels' filesep sessionName '_secretMessage.mat'],...
        'fullDataLabels_noBlank','fullDataLabels_withBlank','mappedText','numBinsPerTrial');
    
    %%
    %try decoding with a simple HMM?
    load([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'warpedTemplates' filesep sessionName 'hmmTemplates_valFold' num2str(1) '.mat'],'hmmTemplates');
       
    %try decoding with the hmm
    hmmBinSize = 5;
    stayProb = 0.2;
    skipProb = 0.2;
    blankStayProb = 0.50;

    %for t=1:length(refitTemplates_deficientReplaced)
    %    refitTemplates_deficientReplaced{t} = refitTemplates_deficientReplaced{t} - mean(refitTemplates_deficientReplaced{t});
    %end

    [ A_hmm, B_hmm, stateLabels, letterStartIdx ] = makeHMMLetterDecoder( hmmTemplates, hmmBinSize, stayProb, skipProb, blankStayProb );
    diagVariance = ones(size(A_hmm,1),1);

    letters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z',...
        '>',',','''','~','?'};
    lettersForDecode = letters;
    lettersForDecode{end+1} = '-';

    dat = gaussianSmooth(zScoreSpikes_cubeStats, 4.0);
    binDat = binTimeSeries( dat, hmmBinSize, @mean );

    startProb = zeros(size(A_hmm,1),1);
    startProb(letterStartIdx) = 1/(length(hmmTemplates)+1);

    [pStates, pSeq] = hmmdecode_frw_gaussian_v2(binDat,A_hmm,B_hmm,startProb,diagVariance);
    [currentState, logP] = hmmviterbi_frw_gaussian_v3(binDat,A_hmm,B_hmm,startProb,diagVariance);

    decIdx = stateLabels(currentState);
    decIdx = binTimeSeries(decIdx, round(30/hmmBinSize), @mode);

    decString = char(zeros(length(decIdx),1));
    for x=1:length(decIdx)
        decString(x) = char(lettersForDecode{decIdx(x)});
    end

    disp(decString');
    
end %all sessions