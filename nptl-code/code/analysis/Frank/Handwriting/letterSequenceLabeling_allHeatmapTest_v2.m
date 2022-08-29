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
    %save time series data for RNN consumption
    nTrials = length(allTimes);
    nChan = size(allSpikes,2);
    fullData = zeros(nTrials, maxTime, nChan);
    fullDataWeight = zeros(nTrials, maxTime);
    numBinsPerTrial = allTimes;
    
    for t=1:nTrials
        loopIdx = allEventIdx(t):(allEventIdx(t)+maxTime);
        fullData(t,1:length(loopIdx),:) = gaussSmooth_fast(zScoreSpikes(loopIdx,:),5.0);
        
        trlLoopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
        fullDataWeight(t,1:length(trlLoopIdx),:) = 1;
    end
    
    fullData = single(fullData);
    fullDataWeight = single(fullDataWeight);
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'timeSeriesData' filesep sessionName '.mat'],...
        'fullData','mappedText','numBinsPerTrial','fullDataWeight');
    
    %%
%     %%
%     figure
%     for valFoldIdx=1:10
%         warpCube = load(['/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_valFold' num2str(valFoldIdx) '_unwarpedCube.mat']);
%         tmp = squeeze(warpCube.z(:,:,40));
%        
%         subplot(4,3,valFoldIdx);
%         imagesc(tmp,[-1 1]);
%     end
%     
%     figure
%     hold on
%     for valFoldIdx=1:10
%         warpCube = load(['/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_valFold' num2str(valFoldIdx) '_unwarpedCube.mat']);
%         tmp = squeeze(warpCube.z(:,:,10));
%         plot(mean(tmp));
%     end
%     
%     warpCube1 = load(['/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_valFold' num2str(1) '_unwarpedCube.mat']);
%     warpCube2 = load(['/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_valFold' num2str(2) '_unwarpedCube.mat']);
%        
    %%
    %label the data, using templates made only from TRAINING data
    for valFoldIdx=1:10
        %%
        %get aligned cube
        %warpCube = load(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/warpedTemplates/t5.2019.06.26_valFold' num2str(valFoldIdx) '_warpedCube.mat']);
        warpCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_allSnippets_valFold10_warpedCube.mat');
        charTimes = [1.8978,    1.6891,    1.4364,    2.3316,    1.9827,    2.2933,    1.7473,    1.3126,    2.0947,    2.3324, ...
                             1.6643,    1.7545,    1.9491,    2.1498,    0.8917,    1.4529,    1.7696,    2.3593,    1.4289,    1.4394, ...
                             1.2787,    1.8691,    1.6790,    1.6661,    1.8402,    1.8008];
                         
        %get a reduced template for each letter
        letterCutoff = [151, 121, 95, 131, 121, 181, 121, 111, 171, 171, 111, 131, 91, 171, 51, 101, 121, ...
                171, 61, 131, 61, 51, 111, 111, 131, 121] + 60;
        letters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z'};
        templates = cell(length(letters),1);

        for x=1:length(letters)
            tmp = warpCube.(letters{x});
            avg = squeeze(nanmean(tmp,1));
            smoothAvg = gaussSmooth_fast(avg,2.0);
            
            nSteps = round(charTimes(x)*100);
            correctTimeTemplate = interp1(1:size(smoothAvg,1), smoothAvg, linspace(1,size(smoothAvg,1),nSteps));

            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(correctTimeTemplate);
            templates{x} = MU + (SCORE(:,1:10)*COEFF(:,1:10)');
        end
        
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
        stayProb = 0.10;
        skipProb = 0.10;
        
        nBins = 0;
        letterStartIdx = [];
        for x=1:length(templates)
            letterStartIdx = [letterStartIdx; nBins+1];
            nBins = nBins + floor(size(templates{x},1)/binSize);
        end
        
        nStates = nBins+1; %+1 for blank
        letterStartIdx = [letterStartIdx; nStates];
        
        A_hmm = zeros(nStates, nStates);
        B_hmm = zeros(nStates, size(templates{1},2));
        
        stateLabels = [];
        for x=1:length(templates)
            nBins = floor(size(templates{x},1)/binSize);
            loopIdx = 1:binSize;
            currentIdx = letterStartIdx(x);
        
            for b=1:nBins
                neuralTemplate = mean(templates{x}(loopIdx,:));
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
                    A_hmm(currentIdx,letterStartIdx) = (1-stayProb)/27;
                end
                
                currentIdx = currentIdx + 1;
                loopIdx = loopIdx + binSize;
                stateLabels = [stateLabels; x];
            end
        end
        
        %add blank state?
        blankStayProb = 0.5;
        A_hmm(end,end) = blankStayProb;
        A_hmm(end,letterStartIdx(1:(end-1))) = (1-blankStayProb)/26;
        stateLabels(end+1) = 27;
        B_hmm(end,:) = mean(B_hmm(1:(end-1),:));
        
        B_hmm_red = B_hmm*redDimCoeff;

        %%
        %for each word, find the hotspots for this template - does it look good
        %enough for crude labeling? 
        %267: financial
        allLabeling = cell(length(mappedText),1);
        allLetterStarts = cell(length(mappedText),1);
        allLetterStretches = cell(length(mappedText),1);
        %if exist([outDir filesep 'letterLabels.mat'],'file')
        %    load([outDir filesep 'letterLabels.mat'],'allLabeling');
        %end

        %%
        decWord = cell(length(mappedText),1);
        for t=1:length(mappedText)
            word = mappedText{t};
            loopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
            dat = zScoreSpikes(loopIdx,:);
            %dat = gaussianSmooth(dat, 4.0);
            
            binSize = 10;
            binDat = binTimeSeries( dat, binSize );
            binDatRed = binDat * redDimCoeff;
            
            pStateStart = zeros(size(A_hmm,1),1);
            pStateStart(letterStartIdx) = 1/27;
             
            [currentState, logP] = hmmviterbi_frw_gaussian(binDatRed,A_hmm,B_hmm_red,pStateStart,1.0);
            sl = stateLabels(currentState);

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
%             vMult = linspace(0.2,5,100);
%             for v=1:length(vMult)
%                 [currentState, logP] = hmmviterbi_frw_gaussian(binDat,A_hmm,B_hmm,pStateStart,vMult(v));
%                 sl = stateLabels(currentState);
% 
%                 conLabelsHMM = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','-'};
%                 txtOutput = [conLabelsHMM{sl}];
%                 disp(txtOutput);
%             end
            
            %heatmapCell = cell(length(word),1);

            %make heatmaps
%             alphabet = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};
%             possibleStart = 1:10:(size(dat,1)-50);
%             possibleStretch = linspace(0.66,1.5,10);
% 
%             for c=1:length(alphabet)
%                 templateIdx = find(strcmp(alphabet{c}, letters));
%                 template = templates{templateIdx};
%                 allCorr = nan(length(possibleStretch), length(possibleStart));
% 
%                 for stretchIdx=1:length(possibleStretch)
%                     newX = linspace(0,1,round(size(template,1)*possibleStretch(stretchIdx)));
%                     stretchedTemplate = interp1(linspace(0,1,size(template,1)), template, newX);
%                     for startIdx=1:length(possibleStart)
%                         loopIdx = possibleStart(startIdx):(possibleStart(startIdx)+size(stretchedTemplate,1)-1);
%                         if loopIdx(end)>size(dat,1)
%                             continue;
%                         end
%                         cVal = nanmean(diag(corr(stretchedTemplate, dat(loopIdx,:))));
%                         %cVal = -mean(mean((stretchedTemplate - dat(loopIdx,:)).^2));
%                         allCorr(stretchIdx, startIdx) = cVal;
%                     end
%                 end
%                 heatmapCell{c} = allCorr;
%             end
% 
%             tmp = cat(3,heatmapCell{:});
%             tmp = tmp(:);
%             tmp(isnan(tmp)) = [];
%             cRange = [min(tmp),max(tmp)];
%             
%             figure
%             for x=1:26
%                 subtightplot(4,7,x);
%                 hold on;
%                 imagesc(heatmapCell{x},cRange);
%                 axis tight;
%                 title(letters{x});
%                 set(gca,'XTick',[],'YTick',[]);
%             end
        end

      flCorrect = zeros(length(mappedText),1);
      for t=1:length(mappedText)
          firstLetter = decWord{t}(2);
          firstRealLetter = mappedText{t}(1);
          flCorrect(t) = (firstLetter==firstRealLetter);
      end
      
      disp(mean(flCorrect));
      
        %%
        %extract single letters from all time series data
        cvPart = load(['/Users/frankwillett/Data/Derived/Handwriting/letterSequenceTrials/' sessionName '_cvPartitions.mat']);

        allLetters = struct();
        charLabelOrder = ['a','b','c','d','t','m',...
                'o','e','f','g','h','i',...
                'j','k','l','n','p','q',...
                'r','s','u','v','w','x',...
                'y','z'];

        unicodeToIdx = zeros(256,1);
        for x=1:length(charLabelOrder)
            unicodeToIdx(charLabelOrder(x)) = x;
        end

        %0 = low, 1 = high
        penStart = [0.25, 1, 0.5, 0.5, 1, 0.5, ...
                    0.25, 0.25, 1, 0.25, 1, 0.5, ...
                    0.5, 1, 1, 0.5, 0.5, 0.25, ...
                    0.5, 0.5, 0.5, 0.5, 0.5, 0.5, ...
                    0.5, 0.5];

        for c=1:length(charLabelOrder)
            allLetters.(charLabelOrder(c)) = {};
            allLetters.([charLabelOrder(c) '_penEndState']) = [];
            allLetters.([charLabelOrder(c) '_isFirstLetter']) = [];
            allLetters.([charLabelOrder(c) '_isLastLetter']) = [];
            allLetters.([charLabelOrder(c) '_trlIdx']) = [];
        end

        for t=1:length(allLabeling)
            if ismember(t, cvPart.cvIdx{valFoldIdx})
                %skip the validation fold
                continue;
            end
            changePoints = find(diff(allLabeling{t})~=0);
            if allLabeling{t}(1)~=0
                %this word consists of only a single letter, ignore it
                continue;
            end

            for x=1:length(changePoints)
                if x==1
                    loopIdx = (allEventIdx(t)):(allEventIdx(t)+changePoints(x+1));
                elseif x==length(changePoints)
                    loopIdx = (allEventIdx(t)+changePoints(x)):(allEventIdx(t)+length(allLabeling{t}));
                else
                    loopIdx = (allEventIdx(t)+changePoints(x)):(allEventIdx(t)+changePoints(x+1));
                end
                newLetter = zScoreSpikes(loopIdx,:);

                charName = char(allLabeling{t}(changePoints(x)+10));
                allLetters.(charName){end+1} = newLetter;

                isFirstLetter = (x==1);
                isLastLetter = (x==length(changePoints));

                if x<length(changePoints)
                    nextLetter = allLabeling{t}(changePoints(x+1)+10);
                    penEndState = penStart(unicodeToIdx(nextLetter));
                else
                    penEndState = -1;
                end

                allLetters.([charName '_isFirstLetter'])(end+1) = isFirstLetter;
                allLetters.([charName '_isLastLetter'])(end+1) = isLastLetter;
                allLetters.([charName '_penEndState'])(end+1) = penEndState;
                allLetters.([charName '_trlIdx'])(end+1) = t;
            end
        end

        save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_allLettersForSynth_valFold' num2str(valFoldIdx) '.mat'],...
            '-struct','allLetters');

        %%
        %put it all into a big matrix
        charLabelOrder = ['a','b','c','d','t','m',...
                    'o','e','f','g','h','i',...
                    'j','k','l','n','p','q',...
                    'r','s','u','v','w','x',...
                    'y','z'];
        charLabelMap = zeros(256,1);
        charLabelMap(charLabelOrder) = 1:length(charLabelOrder);
        charLabelMap(1) = 27;

        nTrials = length(allTimes);
        nChan = size(allSpikes,2);
        fullDataLabels = zeros(nTrials, maxTime, 27);

        currIdx = 1;
        for t=1:nTrials
            tmp = allLabeling{t};
            tmp(tmp==0)=1;
            tmp = charLabelMap(tmp);
            for x=1:length(tmp)
                fullDataLabels(t,x,tmp(x)) = 1;
            end
        end
        
        save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'timeSeriesLabels' filesep sessionName '_valFold' num2str(valFoldIdx) '.mat'],...
            'fullDataLabels','mappedText','numBinsPerTrial');
    end
end %all sessions