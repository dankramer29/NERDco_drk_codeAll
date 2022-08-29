%%
%During the last blocks of arm, the activity patterns change for some unknown reason
%(as can be seen through population raster), so I am excluding them. 
%Original definition with all blocks: 't5.2019.03.18',{[7 9 11 13 15 17 20 22 24 26 28],[5 8 10 12 14 16 19 21 23 25 27]};

datasets = {
    't5.2019.03.18',{[7 9 11 13 15 17 20]};
};
setNames = {'arm'};
useWarpedCubes = false;
      
%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'BOA' filesep 'jPCA' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    for blockSetIdx=1:length(datasets{d,2})
        %load and concatenate all R structs for the specified block set
        clear allR;
        
        bNums = horzcat(datasets{d,2}{blockSetIdx});
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
        filtOpts.filtCutoff = 10/500;
        R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{blockSetIdx}), 4.5, datasets{d,2}{blockSetIdx}(1), filtOpts );

        allR = []; 
        for x=1:length(R)
            for t=1:length(R{x})
                R{x}(t).blockNum=bNums(x);
                R{x}(t).tPosLoop = repmat(R{x}(t).posTarget(1:2),1,length(R{x}(t).stateTimer));
            end
            allR = [allR, R{x}];
        end
        clear R;
        
        R = struct();
        for t=1:length(allR)
            R(t).spikeRaster = [allR(t).spikeRaster; allR(t).spikeRaster2];
            R(t).targetPos = allR(t).posTarget(1:2);
            R(t).timeGoCue = allR(t).timeGoCue;
        end
        R([1 91 181 271 358 447 537]) = []; %bad first trials
        save('/Users/frankwillett/Data/prepStateExercise/R.mat','R');
    end

end %datasets