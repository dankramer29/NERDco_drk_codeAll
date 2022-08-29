%%
datasets = {
    't5.2018.02.19',{[28],[29],[28 29]},{'W1','W2','W12'},[28];
    't5.2018.02.21',{[16],[17],[16 17],[21],[22],[21 22]},{'W1h','W2h','W12h','W3j','W4j','W34j'},[22];
    't5.2018.03.05',{[6],[7],[6 7]},{'W1','W2','W12'},[6]
    't5.2018.03.09',{[6],[7],[6 7]},{'W1','W2','W12'},[6]};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Wia_movCue' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = unique(horzcat(datasets{d,2}{:}));
    if strcmp(datasets{d,1}(1:2),'t5')
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
    else
        movField = 'glove';
        filtOpts.filtFields = {'glove'};
    end
    filtOpts.filtCutoff = 10/500;
    [ R, stream ] = getStanfordRAndStream( sessionPath, bNums, 3.5, datasets{d,4}, filtOpts );
    
    an = [];
    for s=1:length(stream)
        an = [an; [stream{s}.spikeRaster, stream{s}.spikeRaster2]];
    end
    allNeural_smooth = gaussSmooth_fast(double(an),60);
    allNeural_raw = double(an);
    
    wmp = [];
    for s=1:length(stream)
        tmpZero = zeros(stream{s}.continuous.clock(1)-1,size(stream{s}.continuous.windowsMousePosition,2));
        wmp = [wmp; [tmpZero; stream{s}.continuous.windowsMousePosition]];
    end
    [B,A] = butter(4,10/500);
    wmp = filtfilt(B,A,wmp);
    wmp_speed = matVecMag(diff(wmp),2);
    
    if isfield(stream{1}.continuous,'windowsPC1GazePoint')
        gp = [];
        for s=1:length(stream)
            tmpZero = zeros(stream{s}.continuous.clock(1)-1,size(stream{s}.continuous.windowsPC1GazePoint,2));
            gp = [gp; [tmpZero; double(stream{s}.continuous.windowsPC1GazePoint)]];
        end
        [B,A] = butter(4,10/500);
        gp = filtfilt(B,A,gp);
    else
        gp = zeros(size(wmp));
    end
    
    vidDir = [paths.dataPath filesep 'Derived' filesep 'WatchVideoAlignment' filesep datasets{d,1}];
    allCues = [];
    allCueTimes = [];
    bNumPerTrial = [];
    globalIdx = 0;
    for s=1:length(stream)
        tmp = load([vidDir filesep num2str(bNums(s)) '.mat']);
        allCues = [allCues; tmp.mc];
        allCueTimes = [allCueTimes; round(tmp.mct_xpc+globalIdx)];
        bNumPerTrial = [bNumPerTrial; repmat(bNums(s),length(tmp.mc),1)];
        globalIdx = globalIdx + size(stream{s}.spikeRaster,1);
    end
    
    %%
    %smooth 20 ms
    binMS=20;
    binNeural_smooth = allNeural_smooth(1:binMS:end,:);
    binCueTimes = round(allCueTimes/binMS);
    binWMP = wmp(1:binMS:end,:);
    binGP = gp(1:binMS:end,:);
    binWMP_speed = wmp_speed(1:binMS:end);
    
    alignDat_smooth.zScoreSpikes = zscore(binNeural_smooth);
    alignDat_smooth.eventIdx = binCueTimes;
    alignDat_smooth.movementByTrial = allCues;
    alignDat_smooth.windowsMousePosition = binWMP;
    alignDat_smooth.windowsMousePosition_speed = binWMP_speed;
    alignDat_smooth.bNumPerTrial = bNumPerTrial;
    
    %%
    %raw 50 ms
    binMS=50;
    nBins = floor(length(allNeural_raw)/binMS);
    binIdx = 1:binMS;
    binNeural_raw = zeros(nBins, size(allNeural_raw,2));
    for n=1:nBins
        binIdx(binIdx>length(allNeural_raw)) = [];
        binNeural_raw(n,:) = sum(allNeural_raw(binIdx,:));
        binIdx = binIdx + binMS;
    end
    
    binCueTimes = round(allCueTimes/binMS);
    binWMP = wmp(1:binMS:end,:);
    binGP = gp(1:binMS:end,:);
    binWMP_speed = wmp_speed(1:binMS:end);
        
    alignDat_raw.zScoreSpikes = zscore(binNeural_raw);
    alignDat_raw.eventIdx = binCueTimes;
    alignDat_raw.movementByTrial = allCues;
    alignDat_raw.windowsMousePosition = binWMP;
    alignDat_raw.windowsMousePosition_speed = binWMP_speed;
    alignDat_raw.bNumPerTrial = bNumPerTrial;
    
    save([outDir filesep 'watchAlignDat.mat'],'alignDat_smooth','alignDat_raw');
end
