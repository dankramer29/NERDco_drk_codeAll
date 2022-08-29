datasets = {'t5.2018.01.31'};

for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
    datDir = [paths.dataPath filesep 'BG Processed' filesep datasets{d,1} filesep];

    outDir = [paths.dataPath filesep 'Derived' filesep 'MentalRehearsal' filesep datasets{d,1}];
    mkdir(outDir);
   
    %%
    %distance decoding
    bNums = [3];
    allDat = cell(length(bNums),1);
    for b=1:length(bNums)
        dataPath = [datDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'];
        allDat{b} = load(dataPath);
    end

    allR = [];
    for x=1:length(allDat)
        allR = [allR, allDat{x}.R];
    end

    eyePos = [allR.windowsPC1LeftEye]';
    headPos = [allR.windowsMousePosition]';
    state = [allR.state]';
    
    figure
    hold on
    plot(zscore(eyePos),'b');
    plot(zscore(headPos),'r');
    plot(state==2);
end
