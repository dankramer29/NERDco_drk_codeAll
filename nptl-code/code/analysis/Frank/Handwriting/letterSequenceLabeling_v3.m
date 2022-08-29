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
    %get aligned cube
    rawCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_unwarpedCube.mat');
    warpCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_warpedCube.mat');
    
    %%
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
    %estimate character length
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
    
    [B,BINT,R,RINT,STATS] = regress(allTimes/100,[ones(size(designMat,1),1), designMat]);
    
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
    if exist([outDir filesep 'letterLabels.mat'],'file')
        load([outDir filesep 'letterLabels.mat'],'allLabeling');
    end
    
    for t=109:length(mappedText)
        word = mappedText{t};
        loopIdx = allEventIdx(t):(allEventIdx(t)+allTimes(t));
        dat = zScoreSpikes(loopIdx,:);
        dat = gaussianSmooth(dat, 4.0);
        datLabel = zeros(size(dat,1),1);
        currIdx = -60;
        letterStarts = zeros(length(word),1);
        letterStretches = zeros(length(word),1);
        
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
        
        %initial guess pairwise
        [letterStarts, letterStretches] = stepForwardPairedLabeling(dat, templates, word, letters);
        heatmapWordPlot( heatmapCell, possibleStart/100, possibleStretch, word, letterStarts/100, letterStretches );
      
        %initial guess      
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
            
            validStartIdx = find(possibleStart>=(currIdx-50) & possibleStart<=(currIdx+250));
            reducedCorr = allCorr(:,validStartIdx);
            heatmapCell{c} = allCorr;
            
            if isempty(validStartIdx)
                letterStarts(c) = possibleStart(end);
                letterStretches(c) = 1.0;
                continue;
            end
            
            [~,maxIdx] = max(reducedCorr(:));
            [maxStretch, maxStartIdx] = ind2sub(size(allCorr),maxIdx);
            finalStartIdx = possibleStart(validStartIdx(maxStartIdx));
            letterStarts(c) = finalStartIdx;
            letterStretches(c) = possibleStretch(maxStretch);
            
            letterLen = round(possibleStretch(maxStretch)*size(template,1));
            currIdx = finalStartIdx+letterLen;
        end
        
        %plot initial guess
        heatmapWordPlot( heatmapCell, possibleStart/100, possibleStretch, word, letterStarts/100, letterStretches );
        saveas(gcf,[outDir filesep 'initialLabel_' num2str(t) '_' word '.png'],'png');
        
        %iterative refinement
        allTempIdx = zeros(length(word),1);
        for c=1:length(word)
            allTempIdx(c) = find(strcmp(word(c), letters));
        end
        
        [cost, reconDat] = reconCost( dat, templates(allTempIdx), letterStarts, letterStretches );
        
        nReps = 3;
        [currStart, currStretch] = iterativeLabelSearch_additive(dat, templates(allTempIdx), word, possibleStretch, letterStarts, letterStretches, cTimes, nReps);

        %plot refinement
        heatmapWordPlot( heatmapCell, possibleStart/100, possibleStretch, word, currStart/100, currStretch );
        saveas(gcf,[outDir filesep 'refinedLabel_' num2str(t) '_' word '.png'],'png');
        
        %%
        %assign labels
        for c=1:(length(letterStarts)-1)
            datLabel(letterStarts(c):letterStarts(c+1)) = word(c);
        end
        datLabel(letterStarts(end):end) = word(end);
        allLabeling{t} = datLabel;
        
        %%
        close all;
    end
    
    save([outDir filesep 'letterLabels'],'allLabeling');
    
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
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '.mat'],'fullData','mappedText','numBinsPerTrial');
    
    allTrials = single(fullData);
    wordPerTrial = mappedText;
    nTimeStepsPerTrial = allTimes;
    dataFormat = 'allTrials is an NxTxC matrix, where N is the number of trials, T is the number of 10 ms time steps, and M is the number of channels. nTimeStepsPerTrial indicates the number of time steps for each trial (time steps after this have zeroed values). wordPerTrial indicates the cued word on that trial';
    save([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_share.mat'],'allTrials','wordPerTrial','nTimeStepsPerTrial','dataFormat');
    
end %all sessions