%%
%see movementTypes.m for code definitions
allMovTypes = {
    {[15],'2targ_1'
    [16],'2targ_ortho'
    [17],'2targ_2'
    }

    {[15],'2targ_1'
    [16],'2targ_ortho'
    [17],'2targ_2'
    }
    
    {[18],'2targ_1'
    }
    };

allFilterNames = {
'008-blocks013_014-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'009-blocks011_012_014-thresh-3.5-ch80-bin15ms-smooth25ms-delay0ms.mat'
'008-blocks016_017-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
};

allSessionNames = {'t5.2018.01.08','t5.2018.01.17','t5.2018.01.19'};
allMoveTypeText = {{'2targ 1','2targ ortho','2targ 2'},{'2targ 1','2targ ortho','2targ 2'},{'2targ 1'}};

for outerSessIdx = 1:length(allSessionNames)
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    sessionName = allSessionNames{outerSessIdx};
    filterName = allFilterNames{outerSessIdx};
    movTypes = allMovTypes{outerSessIdx};
    
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'head_vs_bci_2targ' filesep allSessionNames{outerSessIdx}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

    %%
    %load cursor filter for threshold values, use these across all movement types
    model = load([paths.dataPath filesep 'BG Datasets' filesep sessionName filesep 'Data' filesep 'Filters' filesep ...
        filterName]);

    %%
    %load cued movement dataset
    R = getSTanfordBG_RStruct( sessionPath, horzcat(movTypes{:,1}), model.model );

    smoothWidth = 0;
    if outerSessIdx==3
        datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    else
        datFields = {'windowsMousePosition','cursorPosition','currentTarget','xk'};
    end
    binMS = 20;
    unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

    alignFields = {'timeGoCue'};
    smoothWidth = 0;
    if outerSessIdx==3
        datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget'};
    else
        datFields = {'windowsMousePosition','cursorPosition','currentTarget'};
    end
    timeWindow = [-100, 1000];
    binMS = 20;
    alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 0.5;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
    
    %%
    %make movies
    for x=1:size(movTypes,1)
        trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{x,1}));
        loopIdx = find(ismember(unrollDat.blockNum, movTypes{x,1}));

        theta = linspace(0,2*pi,9)';
        theta(end) = [];
        targList = 409*[cos(theta), sin(theta)];
        targList = [targList; [0 0]];

        tRad = repmat(R(trlIdx(end)).startTrialParams.targetDiameter/2,length(loopIdx),1);
        
        targXY = zeros(length(loopIdx),2)+1000;
        targColor = [108,108,108]/255;
        targRad = tRad;
        
        cursorXY = unrollDat.cursorPosition(loopIdx,1:2);
        cursorColor = [255,255,255]/255;
        cursorRad = repmat(45/2,length(loopIdx),1);
        
        extraCursors = cell(4,3);
        extraCursors{1,1} = unrollDat.currentTarget(loopIdx,1:2);
        extraCursors{1,2} = tRad;
        extraCursors{1,3} = 0.6*[1 1 1];
        extraCursors{2,1} = unrollDat.currentTarget(loopIdx,3:4);
        extraCursors{2,2} = tRad;
        extraCursors{2,3} = 0.6*[0 208 108]/255;
        extraCursors{3,1} = unrollDat.windowsMousePosition(loopIdx,1:2)*1080;
        extraCursors{3,1}(:,2) = -extraCursors{3,1}(:,2);
        extraCursors{3,2} = repmat(45/2,length(loopIdx),1);
        extraCursors{3,3} = [0 208 108]/255;

        if outerSessIdx>=3
            extraCursors{4,1} = unrollDat.windowsPC1LeftEye(loopIdx,1:2)-[840 525];
            extraCursors{4,1}(:,2) = -extraCursors{4,1}(:,2);
            extraCursors{4,2} = repmat(45/2,length(loopIdx),1);
            extraCursors{4,3} = [208 108 108]/255;
        else
            extraCursors(4,:) = [];
        end
        playMovie = false;
        fps = 50;
        xLim = [-500, 500];
        yLim = [-500, 500];
        inTarget = false(length(loopIdx),1);
        bgColor = [0 0 0];

        cursorXY(:,2) = -cursorXY(:,2);
        targXY(:,2) = -targXY(:,2);
        for t=1:size(extraCursors,1)
            extraCursors{t,1}(:,2) = -extraCursors{t,1}(:,2);
        end
        
         M = makeCursorMovie_v2( cursorXY, targXY, targList, cursorColor, ...
            targColor, cursorRad, targRad, extraCursors, ...
                playMovie, fps, xLim, yLim, inTarget, bgColor );
         writeMpegMovie( M, [outDir filesep 'movie_' movTypes{x,2}], 50 );
    end

end