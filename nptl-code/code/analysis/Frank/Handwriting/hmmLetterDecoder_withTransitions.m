%%
sessionList = {
    't5.2019.06.26',{[2 3 4 5 6 7 8 9 10], [11 12 13 14 15 16 17 21], [23 24 25 26 27 28]}}; %many balanced words (1000)   

for sessionIdx=1:size(sessionList,1)
    
    sessionName = sessionList{sessionIdx, 1};
    blockLists = sessionList{sessionIdx, 2};

    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
 
    outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceLabeling' filesep sessionName];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

    %%
    rawCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_unwarpedCube.mat');
    if exist([outDir filesep 'binnedData.mat'],'file')
        load([outDir filesep 'binnedData.mat']);
    else      
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

        highRateIdx = rawCube.chanIdx;
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
    
        save([outDir filesep 'binnedData.mat']);
    end
    
    %%
    %get word text
    mappedText = cell(length(allEventIdx),1);
    for t=1:length(mappedText)
        mappedText{t} = getMovementText(allCodes(t));
        mappedText{t} = deblank(mappedText{t}(10:end));
    end
    
    nChar = zeros(length(allEventIdx),1);
    for t=1:length(mappedText)
        nChar(t) = length(mappedText{t});
    end
    
    %%
    %mean(1:N/2)*(1-alpha) + mean(1:N)*(alpha)
    %mean(1:N/2)*(1-alpha) + 0.5*mean(1:N/2)*alpha + 0.5*mean((N/2+1):N)*alpha
    %mean(1:N/2)*(1-alpha+alpha*0.5) +mean((N/2+1):N)*alpha*0.5
    %mean(1:N/2)*(1-alpha*0.5) + mean((N/2+1):N)*alpha*0.5
    %var[] = (1-alpha*0.5)^2*sigma^2/(N/2) + mean((N/2+1):N)*alpha*0.5
    
    %%
    %label the data, using templates made only from TRAINING data
    for valFoldIdx=1:10
        %%
        %get aligned cube
        %warpCube = load(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/warpedTemplates/t5.2019.06.26_valFold' num2str(valFoldIdx) '_warpedCube.mat']);
        unwarpCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_allSnippets_valFold10_unwarpedCube.mat');
        warpCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_allSnippets_valFold10_warpedCube.mat');
        allLetters = load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/snippetData/t5.2019.06.26_allLettersForSynth_valFold10.mat');
        
        charTimes = [1.8978,    1.6891,    1.4364,    2.3316,    1.9827,    2.2933,    1.7473,    1.3126,    2.0947,    2.3324, ...
                             1.6643,    1.7545,    1.9491,    2.1498,    0.8917,    1.4529,    1.7696,    2.3593,    1.4289,    1.4394, ...
                             1.2787,    1.8691,    1.6790,    1.6661,    1.8402,    1.8008];
                         
         penLowHigh = [0, 1, 0, 0, 1, 0, ...
            0, 0, 1, 0, 1, 0, ...
            0, 1, 1, 0, 0, 0, ...
            0, 0, 0, 0, 0, 0, ...
            0, 0];
        
        %split templates into transition categories
        letters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z'};
        for letterIdx=1:length(letters)
            tmp = allLetters.(letters{letterIdx});
            letterLen = zeros(length(tmp),1);
            for x=1:length(letterLen)
                letterLen(x) = size(tmp{x},1);
            end

            bounds = [mean(letterLen)-std(letterLen)*3, mean(letterLen)+std(letterLen)*3];
            useIdx = letterLen>bounds(1) & letterLen<bounds(2);
            pStart = allLetters.([letters{letterIdx} '_penEndState']);
            
            warpCube.([letters{letterIdx} '_low']) = warpCube.([letters{letterIdx}])(pStart(useIdx)==0.25 | pStart(useIdx)==0.5,:,:);
            warpCube.([letters{letterIdx} '_high']) = warpCube.([letters{letterIdx}])(pStart(useIdx)==1.0,:,:);
        end
        
        %get a reduced template for each letter
        templates = cell(length(letters),2);
        pSuffix = {'_low','_high'};
        
        for x=1:length(letters)
            for penState=1:2
                tmp = warpCube.([letters{x} pSuffix{penState}]);
                if size(tmp,1)<25
                    tmp = warpCube.([letters{x}]);
                end
                
                avg = squeeze(nanmean(tmp,1));
                smoothAvg = gaussSmooth_fast(avg,2.0);

                nSteps = round(charTimes(x)*100);
                correctTimeTemplate = interp1(1:size(smoothAvg,1), smoothAvg, linspace(1,size(smoothAvg,1),nSteps));

                [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(correctTimeTemplate);
                templates{x,penState} = MU + (SCORE(:,1:10)*COEFF(:,1:10)');
            end
        end
        
        %maybe take a few bins off of the shorter transitions?
        
        figure
        hold on;
        plot(templates{3,1});
        plot(templates{3,2},':');
        
        allAvgTemplates = [];
        for x=1:length(letters)
            tmp = warpCube.(letters{x});
            avg = squeeze(nanmean(tmp,1));
            smoothAvg = gaussSmooth_fast(avg,4.0);
            allAvgTemplates = [allAvgTemplates; smoothAvg];
        end
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(smoothAvg);
        redDimCoeff = COEFF(:,1:10);
        
        %%
        %make hmm from templates
        binSize = 10;
        stayProb = 0.20;
        skipProb = 0.20;
        
        nBins = 0;
        letterStartIdx = zeros(length(templates),2);
        for x=1:length(templates)
            for y=1:2
                letterStartIdx(x,y) = nBins+1;
                nBins = nBins + floor(size(templates{x},1)/binSize);
            end
        end
        
        nStates = nBins+1; %+1 for blank
        blankStartIdx = nStates;
        
        A_hmm = zeros(nStates, nStates);
        B_hmm = zeros(nStates, size(templates{1,1},2));
        penHighMass = mean(penLowHigh);
        
        stateLabels = [];
        for x=1:length(templates)
            for y=1:2
                nBins = floor(size(templates{x,y},1)/binSize);
                loopIdx = 1:binSize;
                currentIdx = letterStartIdx(x,y);

                for b=1:nBins
                    neuralTemplate = mean(templates{x,y}(loopIdx,:));
                    B_hmm(currentIdx,:) = neuralTemplate;

                    if b<nBins
                        A_hmm(currentIdx,currentIdx) = stayProb;
                        if b==(nBins-1)
                            %second to last, no skipping
                            A_hmm(currentIdx,currentIdx+1) = 1-stayProb;
                        else
                            A_hmm(currentIdx,currentIdx+1) = 1-stayProb-skipProb;
                            A_hmm(currentIdx,currentIdx+2) = skipProb;
                        end
                    else
                        %last bin
                        A_hmm(currentIdx,currentIdx) = stayProb;
                        if y==1
                            %transition to pen-low letters
                            nextLettersLow = letterStartIdx(penLowHigh==0,1);
                            nextLettersHigh = letterStartIdx(penLowHigh==0,2);
                        elseif y==2
                            %transition to pen-high letters
                            nextLettersLow = letterStartIdx(penLowHigh==1,1);
                            nextLettersHigh = letterStartIdx(penLowHigh==1,2);
                        end

                        nextLetters = [nextLettersLow; nextLettersHigh; blankStartIdx];
                        A_hmm(currentIdx, nextLetters) = (1-stayProb)*(1/length(nextLetters));

%                         A_hmm(currentIdx, nextLettersLow) = 0.98*(1-stayProb)*(1-penHighMass)*(1/length(nextLettersLow));
%                         A_hmm(currentIdx, nextLettersHigh) = 0.98*(1-stayProb)*penHighMass*(1/length(nextLettersHigh));
%                         A_hmm(currentIdx, blankStartIdx) = 0.02*(1-stayProb);
                    end

                    currentIdx = currentIdx + 1;
                    loopIdx = loopIdx + binSize;
                    stateLabels = [stateLabels; x];
                end
            end
        end
        
        %add blank state?
        blankStayProb = 0.5;
        A_hmm(end,end) = blankStayProb;
        A_hmm(end,letterStartIdx(:)) = (1-blankStayProb)/(26*2);
        stateLabels(end+1) = 27;
        B_hmm(end,:) = mean(B_hmm(1:(end-1),:));
        
        B_hmm_red = B_hmm*redDimCoeff;
        A_hmm_sparse = sparse(A_hmm);
        
        %%
        %test each letter - what are the distributions of times?
%         for letterIdx=1:26
%             stateStart = letterStartIdx(letterIdx);
%             lastState = find(stateLabels==letterIdx,1,'last');
%             
%             nReps = 1000;
%             timeDist = zeros(nReps,1);
%             for repIdx=1:nReps
%                 currState = stateStart;
%                 stateExit = false;
%                 currTime = 0;
%                 
%                 while ~stateExit
%                     prevState = currState;
%                     currState = find(mnrnd(1, A_hmm(currState,:)));
%                     stateExit = prevState==lastState && currState~=lastState;
%                     currTime = currTime + 1;
%                 end
%                 timeDist(repIdx) = currTime;
%             end
%         end

        %%
        cvPartition = load(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/cvPartitions/' sessionName '_cvPartitions.mat']);
        valTrials = cvPartition.cvIdx{10};
        
        allLabels = [];
        allDecLabels = [];
        
        decWord = cell(length(mappedText),1);
        decProb = cell(length(mappedText),1);
        for t=1:length(mappedText)
            word = mappedText{t};
            loopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
            dat = zScoreSpikes(loopIdx,:);
            %dat = gaussianSmooth(dat, 4.0);

            binSize = 10;
            binDat = binTimeSeries( dat, binSize );
            binDatRed = binDat * redDimCoeff;

            pStateStart = zeros(size(A_hmm,1),1);
            pStateStart([letterStartIdx(:); blankStartIdx]) = 1/(26*2+1);

            pStates = hmmdecode_frw_gaussian(binDatRed,A_hmm,B_hmm_red,pStateStart,1.0);
            
            %[~,maxIdx] = max(pStates,[],1);
            %sl = stateLabels(maxIdx);
            
            [currentState, logP] = hmmviterbi_frw_gaussian(binDatRed,A_hmm,B_hmm_red,pStateStart,1.0);
            sl = stateLabels(currentState);
            
            if ismember(t, valTrials)
                realLabels = squeeze(fullDataLabels(t,1:length(loopIdx),:));
                bs = 10;
                nb = floor(size(realLabels,1)/bs);
                binLabels = zeros(nb, 1);
                binIdx = 1:10;
                for x=1:nb
                    [~,binLabels(x)] = max(mean(realLabels(binIdx,:))); 
                    binIdx = binIdx + bs;
                end
                
                allDecLabels = [allDecLabels; sl];
                allLabels = [allLabels; binLabels];
            end

            conLabelsHMM = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','-'};
            txtOutput = [conLabelsHMM{sl}];

            finalBinSize = 4;
            finalTxtOutput = zeros(floor(length(txtOutput)/finalBinSize),1);
            binIdx = 1:4;
            for b=1:length(finalTxtOutput)
                finalTxtOutput(b) = mode(txtOutput(binIdx));
                binIdx = binIdx + finalBinSize;
            end

            decWord{t} = char(finalTxtOutput)';
            disp(decWord{t});

            bts = binTimeSeries(pStates', finalBinSize);
            btsReduced = zeros(size(bts,1),27);
            for x=1:size(bts,1)
                for c=1:27
                    btsReduced(x,c) = sum(bts(x,stateLabels==c));
                end
            end

            decProb{t} = btsReduced;
        end

        flCorrect = zeros(length(mappedText),1);
        for t=1:length(mappedText)
            firstLetter = decWord{t}(2);
            firstRealLetter = mappedText{t}(1);
            flCorrect(t) = (firstLetter==firstRealLetter);
        end

        disp(mean(flCorrect));
        
        useIdx = allDecLabels~=27 & allLabels~=27;
        disp(mean(allDecLabels(useIdx)==allLabels(useIdx)));

        %%
        %word-level inference
        googleWords = importdata('/Users/frankwillett/Downloads/google-10000-english-master/google-10000-english-usa.txt');
        headwords = importdata('/Users/frankwillett/Downloads/10000-headwords/headwords 1st 1000.txt');
        headwords = lower(headwords);

        wordsTested = load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/timeSeriesData/t5.2019.06.26.mat','mappedText');

        wordList = [googleWords; headwords; wordsTested.mappedText];
        wordList = unique(wordList);
        save('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/wordListForInference','wordList');
        
        %%
        charEmissions = zeros(26,26);
        for x=1:26
            cProb = 0.90;
            oProb = (1-cProb)/25;

            charEmissions(x,:) = oProb;
            charEmissions(x,x) = cProb;
        end

        %%
        A_hmm = cell(length(wordList),1);
        B_hmm = cell(length(wordList),1);
        eProbIdx_hmm = cell(length(wordList),1);
        for w=1:length(wordList)
            %if mod(w,100)==0
            %    disp(w);
            %end
            word = wordList{w};
            nChar = length(word);

            nStates = nChar*2*26 + 1;
            tProb = 0.5;

            A = zeros(nStates, nStates);
            B = zeros(nStates, 26+1);
            eProbIdx = zeros(nStates, 1);
            for x=1:nChar
                for y=1:26
                    %augmented state propagation
                    currIdx = (x-1)*26*2 + y;

                    A(currIdx,currIdx) = 1-tProb;
                    A(currIdx,currIdx+26) = tProb;
                    A(currIdx+26,currIdx+26) = 1-tProb;

                    if x==nChar
                        %transition to end of word state
                        A(currIdx+26,end) = tProb;
                    else
                        %transition to next letter
                        nextBlockStart = x*26*2+1;
                        nextLetterIdx = word(x+1)-96;
                        A(currIdx+26,nextBlockStart:(nextBlockStart+25)) = charEmissions(nextLetterIdx,:)*tProb;
                    end

                    %emissions in this state and augmented state
                    B(currIdx,:) = [charEmissions(y,:), 0];
                    B(currIdx+26,:) = [charEmissions(y,:), 0];

                    %mark which letter these states belong to
                    eProbIdx(currIdx) = y;
                    eProbIdx(currIdx+26) = y;
                end
            end

            A(end,end) = 1.0;
            B(end,27) = 1.0;
            eProbIdx(end) = 27;

            A_hmm{w} = sparse(A);
            B_hmm{w} = B;
            eProbIdx_hmm{w} = eProbIdx;
        end

        %%
        cMatReorder = [1 2 3 4 8 9 10 11 12 13 14 15 6 16 7 17 18 19 20 5 21 22 23 24 25 26];
        results = cell(length(valTrials),1);
        
        for trlIdx = 1:length(valTrials)
            trialIdx = valTrials(trlIdx);
            
            decProbNoBlank = decProb{trialIdx};
            decProbNoBlank(:,27) = 0;
            decProbNoBlank = decProbNoBlank ./ sum(decProbNoBlank,2);
            decProbNoBlank = [decProbNoBlank; zeros(40,27)];
            decProbNoBlank((end-39):end,27) = 1;
            decProbNoBlank(:,1:26) = decProbNoBlank(:,cMatReorder);
            
            emProb = zeros(length(wordList),1)-1000000;
            for w=1:length(wordList)
                nStates = size(A_hmm{w},1);
                word = wordList{w};

                firstLetterIdx = word(1)-96;
                startProb = zeros(nStates,1);
                startProb(1:26) = charEmissions(firstLetterIdx,:)';

                %compute probability of observations
                LOGPSEQ = hmmprob_softmax_frw(decProbNoBlank,A_hmm{w},eProbIdx_hmm{w},startProb);
                emProb(w) = LOGPSEQ;
            end

            emProb(isnan(emProb)) = -1000000;
            [~,sortIdx] = sort(emProb,'descend');

            disp(['Raw: ' decWord{trialIdx} ', Word Inference: ' wordList{sortIdx(1)} ', True: ' strtrim(mappedText{trialIdx})]);
            results{trialIdx} = wordList(sortIdx(1:5));
        end

        %%
        correct = zeros(length(valTrials),2);
        for t=1:length(valTrials)
            trialIdx = valTrials(t);
            
            trueText = mappedText{trialIdx};
            correct(t,1) = length(results{trialIdx}{1})==length(trueText) && all(results{trialIdx}{1}==trueText);

            topFive = false;
            for x=1:5
                topFive = topFive | (length(results{trialIdx}{x})==length(trueText) && all(results{trialIdx}{x}==trueText));
            end
            correct(t,2) = topFive;
        end
        
        disp(mean(correct));

    end
end %all sessions