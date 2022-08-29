%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.08.29',{[1 2 3],[4,5,6],[7,8,9],[10,11,12],[16,17,18],[19,20,21]},{'RightHand','LeftHand','RightFoot','LeftFoot','Head','Tongue'};
    't5.2018.12.03',{[13 19],[4 24],[1 20],[6 17]},{'RightArm','RightLeg','RightHand','RightFoot'};
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
    bNums = horzcat(datasets{d,2}{:});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 3.5, 1, filtOpts );

    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            R{x}(t).tPosLoop = repmat(R{x}(t).posTarget(1:2),1,length(R{x}(t).stateTimer));
        end
        allR = [allR, R{x}];
    end
    clear R;

    hasGoCue = false(length(allR),1);
    for t=1:length(allR)
        hasGoCue(t) = ~isempty(allR(t).timeGoCue);
    end
    validTrl = find(hasGoCue);
    allR = allR(validTrl);
    
    targPos = horzcat(allR.posTarget)';
    %[targList, ~, targCodes] = unique(targPos, 'rows');
    
    if strcmp(datasets{d,1},'t5.2018.08.29')
        theta = linspace(0,2*pi,9);
        theta = theta(1:8);
        targScale = 245.4;
    else
        theta = linspace(0,2*pi,7);
        theta = theta(1:6);
        targScale = 409;
    end
    
    targList = [cos(theta)', sin(theta)']*targScale;

    targCodes = nan(length(targPos),1);
    for t=1:length(targCodes)
        err = matVecMag(targList - targPos(t,1:2),2);
        [minErr,minIdx] = min(err);
        if minErr<2
            targCodes(t) = minIdx;
        end
    end

    fullCodes = targCodes;
    bSets = datasets{d,2};
    bNumAll = [allR.blockNum];
    for b=1:length(bSets)
        trlIdx = find(ismember(bNumAll, bSets{b}));
        fullCodes(trlIdx) = fullCodes(trlIdx) + (b-1)*size(targList,1);
    end
    
    badTrl = isnan(fullCodes);
    allR(badTrl) = [];
    fullCodes(badTrl) = [];

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
    smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes,3);
    dPCA_all = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx, ...
        fullCodes, [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );
    
    cWindow = 30:50;
    nTargs = size(targList,1);
    
    globalIdx = 0;
    idxSets = cell(length(datasets{d,2}),1);
    for setIdx=1:length(idxSets)
        idxSets{setIdx} = (1:nTargs)+globalIdx;
        globalIdx = globalIdx+nTargs;
    end
    
    simMatrix = plotCorrMat( dPCA_all.featureAverages, cWindow, [], idxSets, idxSets);
    saveas(gcf, [outDir filesep 'CorrMat.png'],'png');

    %%
    allPD = cell(length(datasets{d,2}),1);
    allPVal = cell(length(datasets{d,2}),1);
    
    for blockSetIdx=1:length(datasets{d,2})
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

        hasGoCue = false(length(allR),1);
        for t=1:length(allR)
            hasGoCue(t) = ~isempty(allR(t).timeGoCue);
        end
        validTrl = find(hasGoCue);
        allR = allR(validTrl);
    
        targPos = horzcat(allR.posTarget)';
        [targList, ~, targCodes] = unique(targPos, 'rows');

        centerCode = find(all(targList==0,2) | targList(:,4)~=0);
        if ~isempty(centerCode)
            useTrl = find(~ismember(targCodes,centerCode));
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
        cWindow = 20:40;
        %cWindow = -25:0;
        allDat = [];
        allTargPos = [];
        for trlIdx=1:length(alignDat.eventIdx)
            loopIdx = cWindow + alignDat.eventIdx(trlIdx);
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
    cMat = zeros(length(allPD),length(allPD),2);
    for x=1:length(allPD)
        for y=1:length(allPD)
            cMat(x,y,1) = corr(allPD{x}(:,1), allPD{y}(:,1));
            cMat(x,y,2) = corr(allPD{x}(:,2), allPD{y}(:,2));
        end
    end
    
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
    
    for x=1:size(R2,1)
        R2(x,x) = 0;
    end

    setNames = datasets{d,3};
    
    figure
    imagesc(R2,[0,max(R2(:))]);
    colorbar;
    set(gca,'XTick',1:4,'XTickLabel',setNames,'XTickLabelRotation',45);
    set(gca,'YTick',1:4,'YTickLabel',setNames);
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

    %%
    figure('Position',[680           1        1241        1097]);
    for x=1:length(allPD)
        for y=1:length(allPD)
            subplot(length(allPD),length(allPD),(x-1)*length(allPD) + y);
            hold on;
            
            sigIdx = allPVal{y}<0.000001 | allPVal{x}<0.000001;
            
            plot(allPD{y}(sigIdx,1), allPD{x}(sigIdx,1), 'bo');
            plot(allPD{y}(sigIdx,2), allPD{x}(sigIdx,2), 'ro');
            axis equal;
            %plot(get(gca, 'XLim'), get(gca,'YLim'),'--k','LineWidth',2);
            
            cMat = corr(allPD{y}(sigIdx,:), allPD{x}(sigIdx,:));
            corr_x = cMat(1,1);
            corr_y = cMat(2,2);
            title([num2str(corr_x,3) ', ' num2str(corr_y,3)]);
            
            if x==length(allPD)
                xlabel(datasets{d,3}{y});
            end
            if y==1
                ylabel(datasets{d,3}{x});
            end
            set(gca,'FontSize',16,'LineWidth',1);
        end
    end
    saveas(gcf, [outDir filesep 'PDCorr.png'],'png');
    
end