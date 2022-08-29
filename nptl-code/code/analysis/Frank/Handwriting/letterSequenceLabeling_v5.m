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
        warpCube = load(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/warpedTemplates/t5.2019.06.26_valFold' num2str(valFoldIdx) '_warpedCube.mat']);

        %get a reduced template for each letter
        letterCutoff = [151, 121, 95, 131, 121, 181, 121, 111, 171, 171, 111, 131, 91, 171, 51, 101, 121, ...
                171, 61, 131, 61, 51, 111, 111, 131, 121] + 60;
        letters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z'};
        templates = cell(length(letters),1);

        for x=1:length(letters)
            tmp = warpCube.(letters{x});
            avg = squeeze(nanmean(tmp,1));
            smoothAvg = gaussSmooth_fast(avg,4.0);
            smoothAvg = smoothAvg(60:letterCutoff(x),:);

            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(smoothAvg);
            templates{x} = MU + (SCORE(:,1:10)*COEFF(:,1:10)');
        end

        %%
        %estimate character length using training data
        conLabels = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};
        designMat = zeros(length(allTimes), 26);
        for x=1:length(allTimes)
            for t=1:length(conLabels)
                tmpIdx = find(mappedText{x}==conLabels{t});
                if ~isempty(tmpIdx)
                    designMat(x,t) = length(tmpIdx);
                end
            end
        end

        cvPartition = load(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/cvPartitions/' sessionName '_cvPartitions.mat']);
        
        allIdx = 1:size(designMat,1);
        trainIdx = setdiff(allIdx, cvPartition.cvIdx{valFoldIdx});
        designMat = designMat(trainIdx,:);
        
        [B,BINT,R,RINT,STATS] = regress(allTimes(trainIdx)/100,[ones(size(designMat,1),1), designMat]);

        figure;
        hold on;
        plot(B,'o');
        set(gca,'XTick',1:27,'XTickLabel',[{'RT'},conLabels],'FontSize',16);

        charTimes = B(2:end);

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
        for t=1:length(mappedText)
            word = mappedText{t};
            loopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
            dat = zScoreSpikes(loopIdx,:);
            dat = gaussianSmooth(dat, 4.0);
            datLabel = zeros(size(dat,1),1);

            %naive ballpark times
            allTempIdx = zeros(length(word),1);
            for c=1:length(word)
                allTempIdx(c) = find(strcmp(word(c), letters));
            end
            cTimes = charTimes(allTempIdx);
            cTimes = cumsum(cTimes);
            cTimes = [0; cTimes(1:(end-1))]/cTimes(end);

            heatmapCell = cell(length(word),1);

            %make heatmaps
            possibleStart = 1:10:(size(dat,1)-50);
            possibleStretch = linspace(0.66,1.5,10);

            for c=1:length(word)
                templateIdx = find(strcmp(word(c), letters));
                template = templates{templateIdx};
                allCorr = nan(length(possibleStretch), length(possibleStart));

                for stretchIdx=1:length(possibleStretch)
                    newX = linspace(0,1,round(size(template,1)*possibleStretch(stretchIdx)));
                    stretchedTemplate = interp1(linspace(0,1,size(template,1)), template, newX);
                    for startIdx=1:length(possibleStart)
                        loopIdx = possibleStart(startIdx):(possibleStart(startIdx)+size(stretchedTemplate,1)-1);
                        if loopIdx(end)>size(dat,1)
                            continue;
                        end
                        cVal = nanmean(diag(corr(stretchedTemplate, dat(loopIdx,:))));
                        allCorr(stretchIdx, startIdx) = cVal;
                    end
                end
                heatmapCell{c} = allCorr;
            end

            %initial guess (pairwise stepping)
            [letterStarts, letterStretches] = stepForwardPairedLabeling(dat, templates, word, letters);

            heatmapWordPlot( heatmapCell, possibleStart/100, possibleStretch, word, letterStarts/100, letterStretches );
            saveas(gcf,[outDir filesep 'initialLabel_' num2str(t) '_' word '.png'],'png');

            %iterative refinement
            allTempIdx = zeros(length(word),1);
            for c=1:length(word)
                allTempIdx(c) = find(strcmp(word(c), letters));
            end

            nReps = 3;
            [currStart, currStretch] = iterativeLabelSearch_additive(dat, templates(allTempIdx), word, possibleStretch, letterStarts, letterStretches, cTimes, nReps);

            heatmapWordPlot( heatmapCell, possibleStart/100, possibleStretch, word, currStart/100, currStretch );
            saveas(gcf,[outDir filesep 'refinedLabel_' num2str(t) '_' word '.png'],'png');

            %%
            %assign labels
            if c==1
                datLabel(:) = word(c);
            else
                for c=1:(length(letterStarts)-1)
                    datLabel(letterStarts(c):letterStarts(c+1)) = word(c);
                end
                datLabel(letterStarts(end):end) = word(end);
            end
            allLabeling{t} = datLabel;
            allLetterStarts{t} = currStart;
            allLetterStretches{t} = currStretch;

            %%
            close all;
        end

        save([outDir filesep 'letterLabels_valFold' num2str(valFoldIdx)],'allLabeling');

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
                
        penEnd = [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, ...
             0.50, 0.0, 1.0, -0.5, 0.0, 1.0, ...
             1.0, 0.0, 0.0, 0.0, 0.0, -0.5, ...
             0.5, 0.0, 0.5, 0.5, 0.5, 0.0, ...
             -0.5, 0.0, 0];

        for c=1:length(charLabelOrder)
            allLetters.(charLabelOrder(c)) = {};
            allLetters.([charLabelOrder(c) '_long']) = {};
            allLetters.([charLabelOrder(c) '_penEndState']) = [];
            allLetters.([charLabelOrder(c) '_penLetterEndState']) = [];
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
                
                loopIdxLong = [(loopIdx(1)-10):(loopIdx(1)-1), loopIdx];
                loopIdxLong(loopIdxLong<1) = [];
                
                newLetterLong = zScoreSpikes(loopIdxLong,:);
                newLetter = zScoreSpikes(loopIdx,:);

                charName = char(allLabeling{t}(changePoints(x)+10));
                allLetters.(charName){end+1} = newLetter;
                allLetters.([charName '_long']){end+1} = newLetterLong;

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
                allLetters.([charName '_penLetterEndState'])(end+1) = penEnd(unicodeToIdx(charName));
                allLetters.([charName '_penEndState'])(end+1) = penEndState;
                allLetters.([charName '_trlIdx'])(end+1) = t;
            end
        end
        
        save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_allLettersForSynth_valFold' num2str(valFoldIdx) '.mat'],...
            '-struct','allLetters');
        
        pTemplateStartList = unique(penEnd);
        pTemplateEndList = unique(penStart);
        
        allSnippets = {};
        allPenCategory = [];
        
        unwarpedCube = struct();
        for c=1:length(charLabelOrder)
            tmp = allLetters.([charLabelOrder(c) '_long']);
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
            
            unwarpedCube.(charLabelOrder(c)) = dataMatrix;
            
            allSnippets = [allSnippets, tmp(useIdx)];
            newPenCategory = [];
            for x=1:length(useIdx)
                penStartCategory = find(allLetters.([charLabelOrder(c) '_penLetterEndState'])(useIdx(x))==pTemplateStartList);
                penEndCategory = find(allLetters.([charLabelOrder(c) '_penEndState'])(useIdx(x))==pTemplateEndList);
                if isempty(penEndCategory)
                    penEndCategory = -100;
                end
                newPenCategory = [newPenCategory; [penStartCategory, penEndCategory]];
            end
            allPenCategory = [allPenCategory; newPenCategory];
        end
        
        %transitions  
        for startIdx=1:length(pStartList)
            for endIdx=1:length(pEndList)
                tmp = allSnippets(allPenCategory(:,1)==startIdx & allPenCategory(:,2)==endIdx);
                
               letterLen = zeros(length(tmp),1);
                for x=1:length(letterLen)
                    letterLen(x) = size(tmp{x},1);
                end
            
                maxLen = max(letterLen);
                dataMatrix = nan(length(tmp), maxLen, size(tmp{1},2));
                for t=1:size(dataMatrix,1)
                    dataMatrix(t,(end-letterLen(t)+1):end,:) = tmp{t};
                end

                unwarpedCube.(['trans_' num2str(startIdx) '_' num2str(endIdx)]) = dataMatrix;
            end
        end

         save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'rnnDecoding' filesep 'unwarpedTemplates' filesep ...
             sessionName '_allSnippets_valFold' num2str(valFoldIdx) '_unwarpedCube.mat'],'-struct','unwarpedCube');

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
    %save in shareable format
    numBinsPerTrial = allTimes;
    fullData = single(fullData);
    fullDataLabels = single(fullDataLabels);
    fullDataWeight = single(fullDataWeight);
        
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '.mat'],...
        'fullData','mappedText','numBinsPerTrial','fullDataLabels','fullDataWeight');
    
    %%
    allTrials = single(fullData);
    wordPerTrial = mappedText;
    nTimeStepsPerTrial = numBinsPerTrial;
    dataFormat = 'allTrials is an NxTxC matrix, where N is the number of trials, T is the number of 10 ms time steps, and M is the number of channels. nTimeStepsPerTrial indicates the number of time steps for each trial (time steps after this have zeroed values). wordPerTrial indicates the cued word on that trial';
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_share.mat'],'allTrials','wordPerTrial','nTimeStepsPerTrial','dataFormat');
    
    %%
    %bin at 20 ms
    %binSize = 2;
    %fullData = permute(binTimeSeries(permute(fullData,[2 1 3]), binSize),[2 1 3]);
    
    %save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_bin20.mat'],...
    %    'fullData','mappedText','numBinsPerTrial','fullDataLabels','fullDataWeight','shuffIdx');

end %all sessions


%%
%shareable single-word data
load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/timeSeriesData/t5.2019.06.26.mat');
load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/timeSeriesLabels/t5.2019.06.26_valFold10.mat')

