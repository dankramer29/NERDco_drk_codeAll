%%
%todo: add letter changing signal

sessionList = {
    't5.2019.05.08',[5 6 8 10 12 14 16 18 20 22 24]}; %sentences 

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
        trialTimes(t) = allR(t).restCue-allR(t).goCue;
    end
    trialTimes = round(trialTimes/10);
    maxTime = max(trialTimes);
    
    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'rigidBodyPosXYZ','currentMovement','headVel'};
    timeWindow = [0, maxTime*10];
    
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
    alignDat.eventIdx(end) = [];
    
    rawCube = load(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/unwarpedTemplates/t5.2019.05.08_unwarpedCube.mat']);
    alignDat.zScoreSpikes = alignDat.zScoreSpikes(:,rawCube.chanIdx);
    
    %use means and standard deviations from single letter data
    zScoreSpikes_cubeStats = alignDat.rawSpikes;
    bList = unique(alignDat.bNumPerTrial);
    allLoopIdx = [];
    for b=1:size(alignDat.blockmeans,1)
        bMeanIdx = b;
        if bMeanIdx>size(rawCube.blockMeans,1)
            bMeanIdx = size(rawCube.blockMeans,1);
        end
        
        trlIdx = find(alignDat.bNumPerTrial==bList(b));
        for t=1:length(trlIdx)
            loopIdx = alignDat.eventIdx(trlIdx(t)):(alignDat.eventIdx(trlIdx(t))+timeWindow(end)/10);
            loopIdx = loopIdx + 1;
            loopIdx(loopIdx>size(zScoreSpikes_cubeStats,1)) = [];
            
            zScoreSpikes_cubeStats(loopIdx,:) = zScoreSpikes_cubeStats(loopIdx,:) - rawCube.blockMeans(bMeanIdx,:);
            zScoreSpikes_cubeStats(loopIdx,:) = zScoreSpikes_cubeStats(loopIdx,:)./rawCube.featureSTD;
            
            allLoopIdx = [allLoopIdx, loopIdx];
        end
    end
    alignDat.zScoreSpikes = zScoreSpikes_cubeStats(:,rawCube.chanIdx);
    
    %%
    %get word text
    sentenceText = loadSentenceText();
    mappedText = cell(length(alignDat.eventIdx),1);
    for t=1:length(mappedText)
        mappedText{t} = sentenceText{allR(t).currentMovement(100)-3000};
    end
    
    nChar = zeros(length(alignDat.eventIdx),1);
    for t=1:length(mappedText)
        nChar(t) = length(strrep(mappedText{t},' ',''));
    end
    
    %%
    %save time series data for RNN consumption    
    nTrials = length(trialTimes);
    nChan = size(alignDat.zScoreSpikes,2);
    fullData = zeros(nTrials, maxTime, nChan);
    fullDataWeight = zeros(nTrials, maxTime);
    numBinsPerTrial = trialTimes;
    
    for t=1:nTrials
        loopIdx = alignDat.eventIdx(t):(alignDat.eventIdx(t)+maxTime);
        loopIdx(loopIdx<1) = [];
        
        fullData(t,1:length(loopIdx),:) = alignDat.zScoreSpikes(loopIdx,:);
        
        trlLoopIdx = alignDat.eventIdx(t):(alignDat.eventIdx(t)+trialTimes(t));
        fullDataWeight(t,1:length(trlLoopIdx),:) = 1;
    end
    
    fullData = single(fullData);
    fullDataWeight = single(fullDataWeight);
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'timeSeriesData' filesep sessionName '.mat'],...
        'fullData','mappedText','numBinsPerTrial','fullDataWeight');
    
    %%
    %label the data, using templates made only from TRAINING data
    for valFoldIdx=1:10
        %%
        %get aligned cube
        warpCube = load(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/warpedTemplates/t5.2019.05.08_warpedCube.mat']);
        
        %get a reduced template for each letter
        letterCutoff = [99 91 70 104 110 132 84 98 125 110 104 79 92 127 68 90 113 104 74 86 86 83 110 103 115 100 ...
            82 77 116 71 110] + 60;
        lettersWC = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z',...
            'gt','comma','apos','tilde','question'};
        letters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z',...
            '>',',','''','~','?'};
        templates = cell(length(lettersWC),1);
        hfTemplates = cell(length(lettersWC),1);

        for x=1:length(lettersWC)
            tmp = warpCube.(lettersWC{x});
            avg = squeeze(nanmean(tmp,1));
            smoothAvg = gaussSmooth_fast(avg,4.0);
            smoothAvg = smoothAvg(60:letterCutoff(x),:);

            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(smoothAvg);
            templates{x} = MU + (SCORE(:,1:10)*COEFF(:,1:10)');
            hfTemplates{x} = templates{x}-mean(templates{x});
        end

        %%
        %estimate character length using training data
        charTimes = (letterCutoff-60)/100;

        %%
        %for each word, find the hotspots for this template - does it look good
        %enough for crude labeling? 
        allHMMModel = cell(length(mappedText),1);
        allLabeling = cell(length(mappedText),1);
        allLetterStarts = cell(length(mappedText),1);
        allLetterStretches = cell(length(mappedText),1);
        %if exist([outDir filesep 'letterLabels.mat'],'file')
        %    load([outDir filesep 'letterLabels.mat'],'allLabeling');
        %end

        %%
        allEventIdx = alignDat.eventIdx;
        allTimes = trialTimes;
        zScoreSpikes = alignDat.zScoreSpikes;
        
        if strcmp(sessionName, 't5.2019.05.08')
            %two skipped sentences, and one with numbers in it that might be
            %able to be rescued (62)
            badTrials = [18, 32, 62];
        else
            badTrials = [];
        end
        
        currentIterTemplates = templates;
        
        for hmmIterIdx=1:5
            for t=1:length(mappedText)
                %%
                %fit HMM
                disp(mappedText{t});

                if ismember(t, badTrials)
                    continue;
                end

                word = strrep(mappedText{t},' ','');
                loopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
                loopIdx(loopIdx<1) = [];
                dat = zScoreSpikes(loopIdx,:);
                dat = gaussianSmooth(dat, 4.0);
                datLabel = zeros(size(dat,1),1);
                datLabel_withBlanks = zeros(size(dat,1),1);

                allTempIdx = zeros(length(word),1);
                for c=1:length(word)
                    allTempIdx(c) = find(strcmp(word(c), letters));
                end

                hmmBinSize = 5;
                hmmBlankProb = 0.1;
                [A_hmm, B_hmm, diagVariance, stateLabels, stateLabelsSeq] = makeForcedAlignmentHMM(currentIterTemplates, allTempIdx, hmmBinSize, hmmBlankProb);
                A_hmm = sparse(A_hmm);

                startProb = zeros(size(A_hmm,1),1);
                startProb(1) = hmmBlankProb;
                startProb(2) = 1-hmmBlankProb;

                binDat = binTimeSeries( dat, hmmBinSize, @mean );
                terminatedSequence = [binDat, zeros(size(binDat,1),1)];
                terminatedSequence = [terminatedSequence; zeros(5,size(terminatedSequence,2))];
                terminatedSequence((end-4):end,end) = 1;

                [pStates, pSeq] = hmmdecode_frw_gaussian_v2(terminatedSequence,A_hmm,B_hmm,startProb,diagVariance);
                while any(isnan(pStates(:)))
                    diagVariance(1:(end-1)) = diagVariance(1:(end-1))+0.5;
                    [pStates, pSeq] = hmmdecode_frw_gaussian_v2(terminatedSequence,A_hmm,B_hmm,startProb,diagVariance);
                end
                
                [currentState, logP] = hmmviterbi_frw_gaussian_v3(terminatedSequence,A_hmm,B_hmm,startProb,diagVariance);

                labeledStates = stateLabelsSeq(currentState);

                letterStarts = zeros(length(word),1);
                letterStretches = zeros(length(word),1);
                for c=1:length(word)
                    tmpIdx = find(labeledStates==c);
                    letterStarts(c) = tmpIdx(1)*hmmBinSize;
                    letterStretches(c) = (length(tmpIdx)*hmmBinSize)/size(currentIterTemplates{allTempIdx(c)},1);
                end

                %%
                %make heatmaps
%                 uniqueElements = unique(allTempIdx);
%                 heatmapCell = cell(length(uniqueElements),1);
% 
%                 possibleStart = 1:10:(size(dat,1)-40);
%                 possibleStretch = linspace(0.4,1.5,15);
% 
%                 for c=1:length(uniqueElements)
%                     templateIdx = uniqueElements(c);
%                     template = currentIterTemplates{templateIdx};
%                     allCorr = nan(length(possibleStretch), length(possibleStart));
% 
%                     for stretchIdx=1:length(possibleStretch)
%                         newX = linspace(0,1,round(size(template,1)*possibleStretch(stretchIdx)));
%                         stretchedTemplate = interp1(linspace(0,1,size(template,1)), template, newX);
%                         for startIdx=1:length(possibleStart)
%                             loopIdx = possibleStart(startIdx):(possibleStart(startIdx)+size(stretchedTemplate,1)-1);
%                             if loopIdx(end)>size(dat,1)
%                                 continue;
%                             end
%                             cVal = nanmean(diag(corr(stretchedTemplate, dat(loopIdx,:))));
%                             allCorr(stretchIdx, startIdx) = cVal;
%                         end
%                     end
%                     heatmapCell{c} = allCorr;
%                 end
% 
%                 heatmapCellBySeq = cell(length(word),1);
%                 for c=1:length(word)
%                     elementIdx = find(uniqueElements==allTempIdx(c));
%                     heatmapCellBySeq(c) = heatmapCell(elementIdx);
%                 end
% 
%                 filePrefix = [outDir filesep 'hmmLabelIter' num2str(hmmIterIdx) '_' num2str(t)];
%                 heatmapWordPlot( heatmapCellBySeq, possibleStart/100, possibleStretch, word, letterStarts/100, letterStretches, filePrefix );
% 
%                 close all;

                %%
                %assign labels
                for c=1:(length(letterStarts)-1)
                    datLabel(letterStarts(c):letterStarts(c+1)) = allTempIdx(c);
                end
                datLabel(letterStarts(end):end) = allTempIdx(end);

                binIdx = 1:hmmBinSize;
                labeledStates = stateLabels(currentState);
                for c=1:length(labeledStates)
                    datLabel_withBlanks(binIdx) = labeledStates(c);
                    binIdx = binIdx + hmmBinSize;
                end
                datLabel_withBlanks = datLabel_withBlanks(1:length(datLabel));

                termIdx = find(datLabel_withBlanks==length(letters)+2);
                if ~isempty(termIdx)
                    datLabel_withBlanks(termIdx) = datLabel_withBlanks(termIdx(1)-1);
                end

                allLabeling{t} = [datLabel, datLabel_withBlanks];
                allLetterStarts{t} = letterStarts;
                allLetterStretches{t} = letterStretches;

                relabeledStateIdxPerLetter = cell(length(letters),1);
                currIdx = 1;
                for x=1:length(letters)
                    nBins = floor(size(templates{x},1)/hmmBinSize);
                    binIdx = currIdx:(currIdx+nBins-1);

                    relabeledStateIdxPerLetter{x} = binIdx;
                    currIdx = currIdx + nBins;
                end

                relabeldPStates = zeros(size(pStates,2), currIdx);
                for c=1:length(word)
                    hmmStateIdx = find(stateLabelsSeq==c);
                    letterIdx = stateLabels(hmmStateIdx(1));

                    relabeldPStates(:,relabeledStateIdxPerLetter{letterIdx}) = relabeldPStates(:,relabeledStateIdxPerLetter{letterIdx}) + pStates(hmmStateIdx,:)';
                end

                hmmBlankIdx = find(stateLabelsSeq==-1 | stateLabelsSeq==0);
                relabeldPStates(:,end) = sum(pStates(hmmBlankIdx,:));

                allHMMModel{t} = {pStates, stateLabels, stateLabelsSeq, relabeldPStates, relabeledStateIdxPerLetter, currentState};
            end

            %%
            %estimated times for each character
%             charTimes = cell(length(letters),1);
%             for t=1:length(mappedText)
%                 if ismember(t,badTrials)
%                     continue;
%                 end
%                 word = strrep(mappedText{t},' ','');
%                 for c=1:length(word)
%                     letIdx = find(allHMMModel{t}{6}==c);
%                     
%                     arrayIdx = find(strcmp(letters, word(c)));
%                     charTimes{arrayIdx}(end+1) = length(letIdx)*hmmBinSize/100;
%                 end
%             end
            
            save([outDir filesep 'letterLabelsIter' num2str(hmmIterIdx) '_valFold' num2str(valFoldIdx)],'allLabeling',...
                'allHMMModel','allLetterStarts','allLetterStretches');

            %%
            %update hmm model
            cvPart = load(['/Users/frankwillett/Data/Derived/Handwriting/letterSequenceTrials/' sessionName '_cvPartitions.mat']);

            relabeledStateIdxPerLetter = cell(length(letters),1);
            currIdx = 1;
            for x=1:length(letters)
                nBins = floor(size(templates{x},1)/hmmBinSize);
                binIdx = currIdx:(currIdx+nBins-1);

                relabeledStateIdxPerLetter{x} = binIdx;
                currIdx = currIdx + nBins;
            end

            allProb = [];
            allEmissions = [];
            skipTrlIdx = [cvPart.cvIdx{valFoldIdx}, badTrials];
            for t=1:length(mappedText)               
                if ismember(t, skipTrlIdx)
                    continue;
                end

                loopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
                loopIdx(loopIdx<1) = [];
                dat = zScoreSpikes(loopIdx,:);
                dat = gaussianSmooth(dat, 4.0);
                binDat = binTimeSeries( dat, hmmBinSize, @mean );

                relabeledP = allHMMModel{t}{4};
                allProb = [allProb; relabeledP(1:size(binDat,1),:)];
                allEmissions = [allEmissions; binDat];
                
                if any(any(isnan(relabeledP(1:size(binDat,1),:))))
                    disp(t);
                end
            end

            refitTemplates = cell(size(templates));
            for c=1:length(letters)
                disp(letters{c});

                newTemplate = zeros(size(templates{c}));            
                specificProb = allProb(:,relabeledStateIdxPerLetter{c});

                binIdx = 1:hmmBinSize;
                for x=1:(size(newTemplate,1)/hmmBinSize)
                    weightedEmission = sum(specificProb(:,x).*allEmissions)/sum(specificProb(:,x));
                    newTemplate(binIdx,:) = repmat(weightedEmission, hmmBinSize, 1);
                    binIdx = binIdx + hmmBinSize;

                    if x==1
                        disp(sum(specificProb(:,x)))
                    end
                end

                refitTemplates{c} = newTemplate;
            end

            currentIterTemplates = refitTemplates;
            
            %replace conditions without enough data
            deficientIdx = [13, 18, 24, 26, 31];
            currentIterTemplates(deficientIdx) = templates(deficientIdx);
        
            save([outDir filesep 'refitTemplatesIter' num2str(hmmIterIdx) '_valFold' num2str(valFoldIdx)],'templates','refitTemplates','currentIterTemplates');
        end %hmm refitting iterations
        
        %%
        %extract single letters from all time series data
        skipTrlIdx = [cvPart.cvIdx{valFoldIdx}, badTrials];
        allLetters_withBlank = extractLetterSnippets( zScoreSpikes, allLetterStarts, allEventIdx, allLabeling, skipTrlIdx, lettersWC, 'includeBlanks' );
        allLetters_noBlank = extractLetterSnippets( zScoreSpikes, allLetterStarts, allEventIdx, allLabeling, skipTrlIdx, lettersWC, 'extractBlanks' );
        snippetData = {allLetters_withBlank, allLetters_noBlank};
    
        penEnd = [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, ...
         0.50, 0.0, 1.0, -0.5, 0.0, 1.0, ...
         1.0, 0.0, 0.0, 0.0, 0.0, -0.5, ...
         0.5, 0.0, 0.5, 0.5, 0.5, 0.0, ...
         -0.5, 0.0, 0.0, 0.0, 1.0, 0.5, 0.0];
     
        %augment with single letter snippets
        deficientIdx = [13, 18, 24, 26, 31];
        for x=1:length(deficientIdx)
            letIdx = deficientIdx(x);
            letName = lettersWC{letIdx};
            
            for obsIdx=1:size(warpCube.(letName),1)
                %find when this snippet terminates
                tIdx = find(warpCube.([letName '_T'])(:,obsIdx)>letterCutoff(letIdx));
                pullIdx = 60:tIdx;
                if isempty(pullIdx)
                    continue;
                end
                
                for datasetIdx=1:length(snippetData)
                    snippetData{datasetIdx}.(letName){end+1} = squeeze(warpCube.(letName)(obsIdx,60:tIdx,:));
                    snippetData{datasetIdx}.([letName '_long']){end+1} = squeeze(warpCube.(letName)(obsIdx,60:tIdx,:));
                    snippetData{datasetIdx}.([letName '_penEndState'])(end+1) = -2;
                    snippetData{datasetIdx}.([letName '_penLetterEndState'])(end+1) = penEnd(letIdx);
                    snippetData{datasetIdx}.([letName '_isFirstLetter'])(end+1) = 1;
                    snippetData{datasetIdx}.([letName '_isLastLetter'])(end+1) = 1;
                    snippetData{datasetIdx}.([letName '_trlIdx'])(end+1) = -1;
                end
            end
        end
        
        allLetters_withBlank = snippetData{1};
        allLetters_noBlank = snippetData{2};
        
        save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_allLettersForSynthWithBlank_valFold' num2str(valFoldIdx) '.mat'],...
            '-struct','allLetters_withBlank');
        
        save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_allLettersForSynthNoBlank_valFold' num2str(valFoldIdx) '.mat'],...
            '-struct','allLetters_noBlank');
                
        %%
        suffix = {'withBlank','noBlank'};
        
        for datasetIdx=1:2
            unwarpedCube = struct();
            for c=1:length(lettersWC)
                tmp = snippetData{datasetIdx}.([lettersWC{c} '_long']);
                letterLen = zeros(length(tmp),1);
                for x=1:length(letterLen)
                    letterLen(x) = size(tmp{x},1);
                end

                bounds = [mean(letterLen)-std(letterLen)*3, mean(letterLen)+std(letterLen)*3];
                useIdx = find(letterLen>bounds(1) & letterLen<bounds(2));

                maxLen = max(letterLen(useIdx));
                dataMatrix = nan(length(useIdx), maxLen, size(tmp{1},2));
                for t=1:size(dataMatrix,1)
                    dataMatrix(t,1:letterLen(useIdx(t)),:) = tmp{useIdx(t)};
                end

                unwarpedCube.(lettersWC{c}) = dataMatrix;
            end

            save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes' filesep ...
                sessionName '_allSnippets_' suffix{datasetIdx} '_valFold' num2str(valFoldIdx) '_unwarpedCube.mat'],'-struct','unwarpedCube');
        end
        
        refitTemplates_deficientReplaced = refitTemplates;
        deficientIdx = [13, 18, 24, 26, 31];
        refitTemplates_deficientReplaced(deficientIdx) = templates(deficientIdx);
        hmmTemplates = refitTemplates_deficientReplaced;
        
        save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'warpedTemplates' filesep sessionName 'hmmTemplates_valFold' num2str(valFoldIdx) '.mat'],'hmmTemplates');
        %deficient letters: j, q, x, z, questionMark

        %%
        %try decoding with the hmm
        hmmBinSize = 5;
        stayProb = 0.2;
        skipProb = 0.2;
        blankStayProb = 0.50;
                
        %for t=1:length(refitTemplates_deficientReplaced)
        %    refitTemplates_deficientReplaced{t} = refitTemplates_deficientReplaced{t} - mean(refitTemplates_deficientReplaced{t});
        %end
        
        [ A_hmm, B_hmm, stateLabels, letterStartIdx ] = makeHMMLetterDecoder( refitTemplates_deficientReplaced, hmmBinSize, stayProb, skipProb, blankStayProb );
        diagVariance = ones(size(A_hmm,1),1);
        
        lettersForDecode = letters;
        lettersForDecode{end+1} = '-';
        
        for trlIdx = 1:length(cvPart.cvIdx{valFoldIdx})
            t = cvPart.cvIdx{valFoldIdx}(trlIdx);
            
            disp(mappedText{t});
            if ismember(t, badTrials)
                continue;
            end
            
            loopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
            loopIdx(loopIdx<1) = [];
            dat = zScoreSpikes(loopIdx,:);
            dat = gaussianSmooth(dat, 4.0);

            binDat = binTimeSeries( dat, hmmBinSize, @mean );
            
            startProb = zeros(size(A_hmm,1),1);
            startProb(letterStartIdx) = 1/(length(refitTemplates)+1);
        
            [pStates, pSeq] = hmmdecode_frw_gaussian_v2(binDat,A_hmm,B_hmm,startProb,diagVariance);
            [currentState, logP] = hmmviterbi_frw_gaussian_v3(binDat,A_hmm,B_hmm,startProb,diagVariance);
            
            decIdx = stateLabels(currentState);
            decIdx = binTimeSeries(decIdx, round(30/hmmBinSize), @mode);
            
            decString = char(zeros(length(decIdx),1));
            for x=1:length(decIdx)
                decString(x) = char(lettersForDecode{decIdx(x)});
            end
            
            disp(decString');
        end

        %%
        %put the labels into a big matrix to match the data matrix
        nTrials = length(allTimes);
        nChan = size(zScoreSpikes,2);
        fullDataLabels_noBlank = single(zeros(nTrials, maxTime, length(lettersWC)));
        fullDataLabels_withBlank = single(zeros(nTrials, maxTime, length(lettersWC)+1));
        
        currIdx = 1;
        for t=1:nTrials
            if ismember(t, badTrials)
                continue;
            end
            tmp = allLabeling{t};
            
            firstLetter = find(tmp(:,1)~=0,1,'first');
            tmp(tmp==0,1) = tmp(firstLetter,1);
            
            for x=1:length(allLabeling{t})
                fullDataLabels_noBlank(t,x,tmp(x,1)) = 1;
                fullDataLabels_withBlank(t,x,tmp(x,2)) = 1;
            end
        end
        
        save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'timeSeriesLabels' filesep sessionName '_valFold' num2str(valFoldIdx) '.mat'],...
            'fullDataLabels_noBlank','fullDataLabels_withBlank','mappedText','numBinsPerTrial');
    end
  
    %%
    %save in shareable format
    allTrials = single(fullData);
    allTrialLabels_withBlank = fullDataLabels_withBlank;
    allTrialLabels_noBlank = fullDataLabels_noBlank;
    charSequences = mappedText;
    nTimeStepsPerTrial = numBinsPerTrial;
    letterCategoryIndexes = letters;
    letterCategoryIndexes{end+1} = 'blank';
    
    dataFormat = 'allTrials is an NxTxC matrix, where N is the number of trials, T is the number of 10 ms time steps, and C is the number of channels. nTimeStepsPerTrial indicates the number of time steps for each trial (time steps after this have zeroed values). charSequences indicates the sequence of characters written on that trial. Labels are one-hot encodings, either with a blank category or not. The blank category is the last column (32)';
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_share.mat'],...
        'allTrials','allTrialLabels_withBlank','allTrialLabels_noBlank','charSequences','nTimeStepsPerTrial','dataFormat','letterCategoryIndexes');

end %all sessions