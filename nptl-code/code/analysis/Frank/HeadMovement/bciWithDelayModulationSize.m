%%
datasets = {
    't5.2019.03.11',[10 12 22 28]
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'bciWithDelay' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    bNums = horzcat(datasets{d,2});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}), 4.5, datasets{d,2}(1), filtOpts );

    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            R{x}(t).tPosLoop = repmat(R{x}(t).posTarget(1:2),1,length(R{x}(t).stateTimer));
        end
        allR = [allR, R{x}];
    end
    clear R;

    targPos = horzcat(allR.posTarget)';
    [targList, ~, targCodes] = unique(targPos, 'rows');
    targCodeRemap = [4 5 3 0 6 2 1];
    circleTargCodes = targCodes;
    
    for x=1:length(targCodeRemap)
        circleTargCodes(targCodes==x) = targCodeRemap(x);
    end
    
    targList(:,2) = -targList(:,2);
    
    theta = linspace(0,2*pi,7);
    theta = theta(1:6);
    targTemplate = [cos(theta)', sin(theta)'];

    %%        
    alignFields = {'timeGoCue'};
    smoothWidth = 0;
    datFields = {'windowsMousePosition','windowsMousePosition_speed'};
    timeWindow = [-2000,3000];
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
    alignDat.rawSpikes = alignDat.rawSpikes * (1000/binMS);
    
    smoothSnippetMatrix = gaussSmooth_fast(alignDat.zScoreSpikes,2.5);
    smoothSpikes = gaussSmooth_fast(alignDat.meanSubtractSpikes*(1000/binMS),2.5);
    
    %%
    %separately
    margGroupings = {{1, [1 2]}, ...
        {2}};
    margNames = {'Target','Time'};

    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 5;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'singleTrial';
    opts_m.alignMode = 'rotation';
    opts_m.plotCI = true;

    trlIdx = find(circleTargCodes~=0);
    mPCA_out = apply_mPCA_general( smoothSnippetMatrix, alignDat.eventIdx(trlIdx), ...
        circleTargCodes(trlIdx), [-150,250], 0.010, opts_m);

    %%
    movWindow = [20 60];
    baselineWindow = [-150 -110];
    codeSets = {1:6};

    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_internalBaseline( circleTargCodes(trlIdx), smoothSnippetMatrix, ...
        alignDat.eventIdx(trlIdx), movWindow, baselineWindow, codeSets, 'raw' );
    singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, {'Targ1','Targ2','Targ3','Targ4','Targ5','Targ6'} );

    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline_raw.png'],'png');
    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline_raw.svg'],'svg');
    
    %%
    movWindow = [20 60];
    baselineWindow = [-150 -110];
    codeSets = {1:6};

    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_internalBaseline( circleTargCodes(trlIdx), smoothSnippetMatrix, ...
        alignDat.eventIdx(trlIdx), movWindow, baselineWindow, codeSets, 'subtractMean' );
    singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, {'Targ1','Targ2','Targ3','Targ4','Targ5','Targ6'} );

    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline_raw.png'],'png');
    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline_raw.svg'],'svg');
end %datasets