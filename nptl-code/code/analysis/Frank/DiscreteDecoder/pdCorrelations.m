%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.08.29',{[1 2 3],[4,5,6],[7,8,9],[10,11,12],[16,17,18],[19,20,21]},{'RightHand','LeftHand','RightFoot','LeftFoot','Head','Tongue'};
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    allPD = cell(length(datasets{d,2}),1);
    allPVal = cell(length(datasets{d,2}),1);
    
    for blockSetIdx=1:length(datasets{d,2})
    %for blockSetIdx=7
        clear allR;
        
        bNums = horzcat(datasets{d,2}{blockSetIdx});
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
        filtOpts.filtCutoff = 10/500;
        R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{blockSetIdx}), 3.5, datasets{d,2}{blockSetIdx}(1), filtOpts );

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

        centerCode = find(all(targList==0,2) | targList(:,4)~=0);
        if ~isempty(centerCode)
            useTrl = find(targCodes~=centerCode);
        else
            useTrl = 1:length(targCodes);
        end
        
        %%        
        alignFields = {'timeGoCue'};
        smoothWidth = 0;
        datFields = {'windowsMousePosition','windowsMousePosition_speed'};
        timeWindow = [-1000,2000];
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];

        %%
        allDat = [];
        allTargPos = [];
        for trlIdx=1:length(alignDat.eventIdx)
            loopIdx = (10:50) + alignDat.eventIdx(trlIdx);
            allDat = [allDat; mean(alignDat.zScoreSpikes(loopIdx,:))];
            allTargPos = [allTargPos; targPos(trlIdx,:)];
        end
        
        pVals = zeros(192,1);
        E = zeros(192,3);
        for featIdx=1:192
            [B,BINT,R,RINT,STATS] = regress(allDat(:,featIdx), [ones(length(allTargPos),1), allTargPos(:,1:2)]);
            pVals(featIdx) = STATS(3);
            E(featIdx,:) = B;
        end
        
        %%
        allPD{blockSetIdx} = E(:,2:3);
        allPVal{blockSetIdx} = pVals;
    end
            
    %%
    rotMat = cell(length(allPD), length(allPD));
    for x=1:length(allPD)
        for y=1:length(allPD)
           rotMat{x,y} = allPD{x}\allPD{y};
        end
    end

    nCon = length(allPD);
    figure
    hold on
    for x=1:nCon
        for y=1:nCon
            subplot(nCon,nCon,(x-1)*nCon+y);
            hold on;
            plot([0, rotMat{x,y}(1,1)], [0,rotMat{x,y}(2,1)],'-o','LineWidth',2);
            plot([0, rotMat{x,y}(1,2)], [0,rotMat{x,y}(2,2)],'-o','LineWidth',2);
            plot([0,0],[-1,1],'-k');
            plot([-1,1],[0,0],'-k');
            xlim([-1,1]);
            ylim([-1,1]);
            axis equal;
        end
    end
    saveas(gcf, [outDir filesep 'PDRotMat_' datasets{d,3}{blockSetIdx} '.png'],'png');
    
end