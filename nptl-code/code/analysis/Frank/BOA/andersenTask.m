%%
datasets = {
    't5.2018.12.10',{[13 14 15 16 17 18 19 20 21 22 23 24 25 27 28]};
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'BOA' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = horzcat(datasets{d,2}{:});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 4.5, bNums(1), filtOpts );
    
    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
        end
        allR = [allR, R{x}];
    end
    
    clear R;
    
    %%
    %add target pos for each time step
    for t=1:length(allR)
        allR(t).targetPos = repmat(allR(t).posTarget,1,length(allR(t).clock));
    end

    %%
    %bin and align spikes for each trial 
    alignFields = {'timeGoCue'};
    smoothWidth = 0;
    datFields = {'targetPos','cursorPosition','windowsMousePosition','rigidBodyPosXYZ','rigidBodyRotXYZ','windowsPC1GazePoint','windowsPC1GazePointValid'};
    timeWindow = [-6500, 2000];
    binMS = 20;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.zScoreSpikes(:,tooLow) = [];
    %alignDat.eventIdx(end) = [];
    
    %%
    tPos = alignDat.targetPos(alignDat.eventIdx,1:3);
    factors = zeros(length(alignDat.eventIdx),3);
    [~,~,factors(:,1)] = unique(tPos(:,1));
    [~,~,factors(:,2)] = unique(tPos(:,2));
    [~,~,factors(:,3)] = unique(tPos(:,3));
    
    %%
    %0-1.5s = dead time
    %1.5s: gaze target on
    %3.0s: start position on
    %4.5s: target on
    %6.0s - 7.0s: go
    margGroupings = {{1, [1 4]}, {2, [2 4]}, {3, [3 4]}, {[1 2], [1 2 4]}, {[1 3], [1 3 4]}, {[2 3], [2 3 4]}, {[1 2 3], [1 2 3 4]}, {4}};
    margNames = {'Gaze','Start','Target','G x S','G x T','S x T','G x S x T','Time'};
    %margGroupings = {{1, [1 3]}, {2, [2 3], [1 2],[1 2 3]}, {3}};
    %margNames = {'Distance','Direction','Time'};

    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 3;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'parametric';
    opts_m.alignMode = 'rotation';
    opts_m.nResamples = 10;
    opts_m.plotCI = true;

    smoothData = gaussSmooth_fast(alignDat.zScoreSpikes, 1.5);
    mPCA_out = apply_mPCA_general( smoothData, alignDat.eventIdx, ...
            factors, [-320, 90], 0.020, opts_m );

    %%
    %gaze behavior
    opts_m_gaze = opts_m;
    opts_m_gaze.nCompsPerMarg = 2;
    mPCA_out_gaze = apply_mPCA_general( alignDat.windowsPC1GazePoint, alignDat.eventIdx, ...
        factors, [-320, 90], 0.020, opts_m_gaze );
    
    %%
    %head behavior
    opts_m_gaze = opts_m;
    opts_m_gaze.nCompsPerMarg = 3;
    mPCA_out_head = apply_mPCA_general( [alignDat.rigidBodyPosXYZ, alignDat.rigidBodyRotXYZ], alignDat.eventIdx, ...
        factors, [-320, 90], 0.020, opts_m_gaze );
end