%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.08.29',{[1 2 3],[4,5,6],[7,8,9],[10,11,12],[16,17,18],[19,20,21],[23,24]},{'RightHand','LeftHand','RightFoot','LeftFoot','Head','Tongue','HeadCursor'};
    't5.2018.12.03',{[13 19],[4 24],[1 20],[6 17]},{'RightArm','RightLeg','RightHand','RightFoot'}; %ARM & LEG - Reach out to screen
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
    else
        theta = linspace(0,2*pi,7);
        theta = theta(1:6);
    end
    
    targList = [cos(theta)', sin(theta)'];

    targCodes = nan(length(targPos),1);
    for t=1:length(targCodes)
        tPos = targPos(t,1:2);
        tPos = tPos / norm(tPos);
        err = matVecMag(targList - tPos,2);
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
    bNumAll(badTrl) = [];

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
    %single trial cosine tuning plot
    for prepIdx=1:2
        if prepIdx==2
            dPC_window = [-1000, 0];
            cWindow = 30:50; %30:50
        else
            dPC_window = [0, 1000];
            cWindow = 5:25;
        end
        
        dPCA_all_xval = cell(length(datasets{d,2}),1);
        for blockSetIdx=1:length(datasets{d,2})
            trlIdx = find(ismember(bNumAll, datasets{d,2}{blockSetIdx}));

            dPCA_all_xval{blockSetIdx} = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
                fullCodes(trlIdx), dPC_window/binMS, binMS/1000, {'CI','CD'}, 20, 'xval');
            close(gcf);
        end

        axHandle = [];
        xLims = [];
        yLims = [];
        toPlot = [1 2 3 4 6 7];

        figure
        for plotIdx=1:length(toPlot)
            blockSetIdx = toPlot(plotIdx);
            cdIdx = find(dPCA_all_xval{blockSetIdx}.cval.whichMarg==1);
            cdIdx = cdIdx(1:2);

            colors = hsv(nTargs)*0.8;

            axHandle(plotIdx) = subtightplot(2,3,plotIdx);
            hold on;
            
            zs = squeeze(dPCA_all_xval{blockSetIdx}.cval.Z_singleTrial(:,cdIdx,:,cWindow));
            zs = nanmean(zs,4);
            zs = permute(zs,[1 3 2]);
            
            xAxis = squeeze(zs(:,:,1));
            yAxis = squeeze(zs(:,:,2));
            
            xAxis_target = zeros(size(xAxis));
            yAxis_target = zeros(size(xAxis));
            for x=1:size(xAxis_target,2)
                xAxis_target(:,x) = targList(x,1);
                yAxis_target(:,x) = targList(x,2);
            end
            
            xAxis = xAxis(:);
            yAxis = yAxis(:);
            xAxis_target = xAxis_target(:);
            yAxis_target = yAxis_target(:);
            
            badTrl = isnan(xAxis);
            xAxis(badTrl) = [];
            yAxis(badTrl) = [];
            xAxis_target(badTrl) = [];
            yAxis_target(badTrl) = [];
            
            X = [xAxis, yAxis];        
            
            theta = linspace(0,2*pi,360);
            theta = theta(1:(end-1));
            err = zeros(length(theta),1);
            scales = zeros(length(theta),2);
            for t=1:length(theta)
                rotMat = [cos(theta(t)), -sin(theta(t)); sin(theta(t)), cos(theta(t))];
                predVals = X*rotMat;
                xScale = predVals(:,1)\xAxis_target;
                yScale = predVals(:,2)\yAxis_target;
                
                predVals = [predVals(:,1)*xScale, predVals(:,2)*yScale];
                tmp = (predVals-[xAxis_target, yAxis_target]).^2;
                err(t) = mean(tmp(:));
                scales(t,:) = [xScale, yScale];
            end
            
            [~,minIdx] = min(err);
            finalTheta = theta(minIdx);
            
            transMat = [cos(finalTheta), -sin(finalTheta); sin(finalTheta), cos(finalTheta)];
            transMat(:,1) = transMat(:,1)*sign(scales(minIdx,1));
            transMat(:,2) = transMat(:,2)*sign(scales(minIdx,2));
            
            for t=1:nTargs
                zs = squeeze(dPCA_all_xval{blockSetIdx}.cval.Z_singleTrial(:,cdIdx,t,cWindow));
                zs = nanmean(zs,3);
                zs = zs * transMat;
                
                plot(zs(:,1), zs(:,2), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 2);
                plot(nanmean(zs(:,1)), nanmean(zs(:,2)), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 10);
            end
            axis equal;
            title(datasets{d,3}{blockSetIdx});

            xLims = [xLims; get(gca,'XLim')];
            yLims = [yLims; get(gca,'YLim')];
            axis off;
        end

        if prepIdx==1
            xl = [min(xLims(:)), max(xLims(:))];
            yl = [min(yLims(:)), max(yLims(:))];
        end
        for x=1:length(axHandle)
            set(axHandle(x), 'XLim', xl, 'YLim', yl);
        end
        
        saveas(gcf, [outDir filesep 'RingMod_' num2str(prepIdx) '.png'],'png');
        saveas(gcf, [outDir filesep 'RingMod_' num2str(prepIdx) '.svg'],'svg');
    end
%     
%     f = zeros(1,4);
%     H = zeros(4);
%     H(1:2,1:2) = X'*X;
%     H(3:4,3:4) = X'*X;
% 
%     f(1:2) = -2*xAxis_target'*X;
%     f(3:4) = -2*yAxis_target'*X;
% 
%     Aeq = 
%     beq = 
% 
%     b = quadprog(H,f);
%     transMat = [b(1:2), b(3:4)];
            
    %%
    %cross-plot
    dPC_window = [0, 1000];
    cWindow = 5:25;

    dPCA_all_xval = cell(length(datasets{d,2}),1);
    for blockSetIdx=1:length(datasets{d,2})
        trlIdx = find(ismember(bNumAll, datasets{d,2}{blockSetIdx}));

        dPCA_all_xval{blockSetIdx} = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
            fullCodes(trlIdx), dPC_window/binMS, binMS/1000, {'CI','CD'}, 20, 'xval');
        close(gcf);
    end
    
    %get rot mat for each one
    allRotMat = cell(length(datasets{d,2}),1);
    for blockSetIdx=1:length(datasets{d,2})
        cdIdx = find(dPCA_all_xval{blockSetIdx}.cval.whichMarg==1);
        cdIdx = cdIdx(1:2);

        zs = squeeze(dPCA_all_xval{blockSetIdx}.cval.Z_singleTrial(:,cdIdx,:,cWindow));
        zs = nanmean(zs,4);
        zs = permute(zs,[1 3 2]);

        xAxis = squeeze(zs(:,:,1));
        yAxis = squeeze(zs(:,:,2));

        xAxis_target = zeros(size(xAxis));
        yAxis_target = zeros(size(xAxis));
        for x=1:size(xAxis_target,2)
            xAxis_target(:,x) = targList(x,1);
            yAxis_target(:,x) = targList(x,2);
        end

        xAxis = xAxis(:);
        yAxis = yAxis(:);
        xAxis_target = xAxis_target(:);
        yAxis_target = yAxis_target(:);

        badTrl = isnan(xAxis);
        xAxis(badTrl) = [];
        yAxis(badTrl) = [];
        xAxis_target(badTrl) = [];
        yAxis_target(badTrl) = [];

        X = [xAxis, yAxis];        

        theta = linspace(0,2*pi,360);
        theta = theta(1:(end-1));
        err = zeros(length(theta),1);
        scales = zeros(length(theta),2);
        for t=1:length(theta)
            rotMat = [cos(theta(t)), -sin(theta(t)); sin(theta(t)), cos(theta(t))];
            predVals = X*rotMat;
            xScale = predVals(:,1)\xAxis_target;
            yScale = predVals(:,2)\yAxis_target;

            predVals = [predVals(:,1)*xScale, predVals(:,2)*yScale];
            tmp = (predVals-[xAxis_target, yAxis_target]).^2;
            err(t) = mean(tmp(:));
            scales(t,:) = [xScale, yScale];
        end

        [~,minIdx] = min(err);
        finalTheta = theta(minIdx);

        transMat = [cos(finalTheta), -sin(finalTheta); sin(finalTheta), cos(finalTheta)];
        transMat(:,1) = transMat(:,1)*sign(scales(minIdx,1));
        transMat(:,2) = transMat(:,2)*sign(scales(minIdx,2));
        
        allRotMat{blockSetIdx} = transMat;
    end

    xLims = [];
    yLims = [];
    toPlot = [1 2 3 4 5 6 7];
    axHandle = zeros(length(toPlot));
    
    figure
    for rowIdx=1:length(toPlot)
        cdIdx_row = find(dPCA_all_xval{rowIdx}.whichMarg==1);
        cdIdx_row = cdIdx_row(1:2);
        
        for colIdx=1:length(toPlot)
            colors = hsv(nTargs)*0.8;
            axHandle(rowIdx, colIdx) = subtightplot(length(toPlot),length(toPlot),(rowIdx-1)*length(toPlot) + colIdx);
            hold on;
            
            for t=1:nTargs
                if rowIdx==colIdx
                    cdIdx = find(dPCA_all_xval{rowIdx}.cval.whichMarg==1);
                    cdIdx = cdIdx(1:2);
                    zs = squeeze(dPCA_all_xval{rowIdx}.cval.Z_singleTrial(:,cdIdx,t,cWindow));
                else
                    fv = squeeze(dPCA_all_xval{colIdx}.featureVals(:,t,cWindow,:));
                    zs = zeros(size(fv,3), 2, length(cWindow));
                    for timeIdx=1:size(fv,2)
                        projResult = squeeze(fv(:,timeIdx,:))'*dPCA_all_xval{rowIdx}.W(:,cdIdx);
                        zs(:,:,timeIdx) = projResult;
                    end
                end
                zs = nanmean(zs,3);
                zs = zs * allRotMat{rowIdx};

                plot(zs(:,1), zs(:,2), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 2);
                plot(nanmean(zs(:,1)), nanmean(zs(:,2)), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 10);
            end
            axis equal;

            xLims = [xLims; get(gca,'XLim')];
            yLims = [yLims; get(gca,'YLim')];
            axis off;
            
            if colIdx==1
                ylabel(datasets{d,3}{rowIdx});
            end
            if rowIdx==length(toPlot)
                %xlabel('
            end
        end
    end
    
    xl = [min(xLims(:)), max(xLims(:))];
    yl = [min(yLims(:)), max(yLims(:))];
    for x=1:length(axHandle)
        for y=1:length(axHandle)
            set(axHandle(x,y), 'XLim', xl, 'YLim', yl);
        end
    end

    saveas(gcf, [outDir filesep 'RingCross_' num2str(prepIdx) '.png'],'png');
    saveas(gcf, [outDir filesep 'RingCross_' num2str(prepIdx) '.svg'],'svg');

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
    setNames = datasets{d,3};
    
    cMat = zeros(length(allPD),length(allPD),2);
    for x=1:length(allPD)
        for y=1:length(allPD)
            cMat(x,y,1) = corr(allPD{x}(:,1), allPD{y}(:,1));
            cMat(x,y,2) = corr(allPD{x}(:,2), allPD{y}(:,2));
        end
    end
    cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

    titles = {'Horizontal Direction','Vertical Direction'};
    figure('Position',[680   788   823   310]);
    for dimIdx=1:2
        subplot(1,2,dimIdx);
        hold on;
        imagesc(squeeze(cMat(:,:,dimIdx)),[-1 1]);
        colormap(cMap);
        colorbar('FontSize',16,'LineWidth',2);
        set(gca,'XTick',1:length(setNames),'XTickLabel',setNames,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(setNames),'YTickLabel',setNames);
        set(gca,'FontSize',16,'LineWidth',2);
        axis tight;

        title(titles{dimIdx});
    end
    saveas(gcf, [outDir filesep 'CMat_all.png'],'png');
    saveas(gcf, [outDir filesep 'CMat_all.svg'],'svg');
    
    cValSame = [cMat(1,3,1), cMat(2,4,1)];
    cValDifferent = [cMat(1,2,1), cMat(1,4,1), cMat(2,3,1), cMat(3,4,1)];
    
    cValSame_v = [cMat(1,3,2), cMat(2,4,2)];
    cValDifferent_v = [cMat(1,2,2), cMat(1,4,2), cMat(2,3,2), cMat(3,4,2)];
    
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
    
    figure
    imagesc(R2,[0,max(R2(:))]);
    colorbar;
    set(gca,'XTick',1:length(setNames),'XTickLabel',setNames,'XTickLabelRotation',45);
    set(gca,'YTick',1:length(setNames),'YTickLabel',setNames);
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
    
    %%
    save([outDir filesep 'rawData'],'dPCA_all','simMatrix','allPD','allPVal');
    
end