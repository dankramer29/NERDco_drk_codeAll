%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.12.03',{[15 22]},{'HandFoot'},[15];
};

targSetData = load('/Users/frankwillett/Data/Derived/discreteDecoding/t5.2018.12.03/rawData');

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%         
    bNums = horzcat(datasets{d,2}{:});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 3.5, 15, filtOpts );

    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            if strcmp(datasets{d,1}(1:2),'t5')
                R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
            end
        end
        allR = [allR, R{x}];
    end

    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
    timeWindow = [-1000,2000];
    binMS = 20;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
 
    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 0.5;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
        
    movCodeTrl = alignDat.currentMovement(alignDat.eventIdx);
    nothingTrl = movCodeTrl==218;
    
    dirMap = [
        231, -1, 0, 0;
        232, 1, 0, 0;
        233, 0, 1, 0;
        234, 0, -1, 0;
        244, -1, 0, 1;
        245, 1, 0, 1;
        246, 0, 1, 1;
        247, 0, -1, 1];
  
    %%
    smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);
    dPCA_all = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx, ...
        movCodeTrl, [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );

    cWindow = 30:50;
    idxSets = {1:4,5:8}; 
    simMatrix = plotCorrMat( dPCA_all.featureAverages(:,2:end,:), cWindow, [], idxSets, idxSets);
    
    saveas(gcf, [outDir filesep 'CorrMat_' datasets{d,3}{blockSetIdx} '.png'],'png');
    
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
                dirIdx = find(dirMap(:,1)==R{x}(t).startTrialParams.currentMovement);
                R{x}(t).posTarget = dirMap(dirIdx,2:3)';
                
                R{x}(t).blockNum=bNums(x);
                R{x}(t).tPosLoop = repmat(R{x}(t).posTarget(1:2),1,length(R{x}(t).clock));
            end
            allR = [allR, R{x}];
        end
        clear R;

        targPos = horzcat(allR.posTarget)';
        [targList, ~, targCodes] = unique(targPos, 'rows');
        useTrl = 1:length(targCodes);
        
        %%        
        alignFields = {'goCue'};
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
    R2 = zeros(length(allPD));
    rotMat = cell(length(allPD), length(allPD));
    for x=1:length(allPD)
        for y=1:length(allPD)
           rotMat{x,y} = allPD{x}\allPD{y};
           [B,BINT,R,RINT,STATS1] = regress(allPD{y}(:,1),allPD{x});
           [B,BINT,R,RINT,STATS2] = regress(allPD{y}(:,2),allPD{x});
           R2(x,y) = mean([STATS1(1), STATS2(1)]);
        end
    end
    
    figure
    imagesc(R2);
    colorbar;
    set(gca,'XTick',1:4,'XTickLabel',datasets{d,3},'XTickLabelRotation',45);
    set(gca,'YTick',1:4,'YTickLabel',datasets{d,3});
    set(gca,'FontSize',14);
    saveas(gcf, [outDir filesep 'R2Mat_' datasets{d,3}{blockSetIdx} '.png'],'png');

    nCon = length(allPD);
    figure('Position',[154   367   859   738]);
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
            
            if y==1
                ylabel(datasets{d,3}{x});
            end
            if x==nCon
                xlabel(datasets{d,3}{y});
            end
            set(gca,'FontSize',14,'XTick',[],'YTick',[]);
        end
    end
    saveas(gcf, [outDir filesep 'PDRotMat_' datasets{d,3}{blockSetIdx} '.png'],'png');
    
end