%(1) Structured imagined movements only, (2) all structured movements, (3)
%rehearsed movements only, (4) all structured imagined & rehearsed
%movements, (5) all data

datasets = {'t5.2018.01.31'};

for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
    datDir = [paths.dataPath filesep 'BG Processed' filesep datasets{d,1} filesep];

    outDir = [paths.dataPath filesep 'Derived' filesep 'MentalRehearsal' filesep datasets{d,1}];
    mkdir(outDir);
    
    %%
    %structured imagined movements & WIA movements
    bNums = [3 7 10 11];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end

    allR = [];
    for x=1:length(allDat)
        allR = [allR, allDat{x}.R];
    end
    
    wiaCodes = zeros(length(allR),1);
    goCue = zeros(length(allR),1);
    for t=1:length(allR)
        wiaCodes(t) = allR(t).startTrialParams.wiaCode;
        allR(t).blockNum=1;
        if ~isempty(allR(t).timeGoCue)
            goCue(t) = allR(t).timeGoCue;
        end
    end
    goCue = round(goCue/20);
    
    %all WIA
    datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget'};
    binMS = 10;
    smoothWidth = 0;
    alignFields = {'timeGoCue'};
    trlIdx = find(goCue>1);
    timeWindow = [-500, 1500];
    alignDat_allWia = binAndAlignR( allR(trlIdx), timeWindow, binMS, smoothWidth, alignFields, datFields );

    %Imagined only
    trlIdx = find(goCue>1 & wiaCodes==2);
    alignDat_imagined = binAndAlignR( allR(trlIdx), timeWindow, binMS, smoothWidth, alignFields, datFields );

    allR_wia = allR;
    
    %%
    %rehearsed movements
    bNums = [22 25 26 29];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end
    
    binnedSpikes = cell(length(bNums),1);
    for b=1:length(bNums)
        binMS = 10;
        nBins = floor(size(allDat{b}.stream.spikeRaster,1)/binMS);
        binnedSpikes{b} = zeros(nBins, 192);
        
        loopIdx = 1:binMS;
        for x=1:nBins
            binnedSpikes{b}(x,:) = [sum(allDat{b}.stream.spikeRaster(loopIdx,:)), sum(allDat{b}.stream.spikeRaster2(loopIdx,:))];
            loopIdx = loopIdx + binMS;
        end
    end
    
    allBinnedSpikes = [];
    for b=1:length(bNums)
        allBinnedSpikes = [allBinnedSpikes; binnedSpikes{b}];
    end
    
    snippetLen = 200;
    snippetAdvance = 100;
    
end

%--WIA with different speeds, distances
%--two-target rehearsed VMR (guided rehearsal) vs. two different targets unrehearsed VMR
%--movement sequence rehearsal, structured
%repetition of the sequence (with audio for "start" and "stop"), then overt repetition
%--structured path rehearsal, 10 reps of each path (with "done") 

%-other models
%-support
%-return/test?