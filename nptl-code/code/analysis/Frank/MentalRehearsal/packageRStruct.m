datasets = {'t5.2018.01.31',0:29;
    't5.2018.02.09',[3:20,22]
    't5.2018.02.19',[0 1 7 14 15]};

for d=3:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
    outDir = [paths.dataPath filesep 'BG Processed' filesep datasets{d,1} filesep];
    mkdir(outDir);
    
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    
    bNums = datasets{d,2};
    [ R_all, streams_all ] = getStanfordRAndStream( sessionPath, bNums, 3.5, 0, filtOpts );
   
    for b=1:length(bNums)
        disp(bNums(b));
        R = R_all{b};
        stream = streams_all{b};
        save([outDir 'RS_' strrep(datasets{d,1},'.','_') '_block' num2str(bNums(b)) '.mat'],'R','stream'); 
    end
    
end