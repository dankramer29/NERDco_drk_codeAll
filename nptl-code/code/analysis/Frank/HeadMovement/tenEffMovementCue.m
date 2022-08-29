%%
datasets = {
    't5.2018.12.19',{[1 2 3 4 5 6 7 8 9 10]},{'TenEff'};
};

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    bNums = horzcat(datasets{d,2}{1});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, bNums, 4.5, bNums(1), filtOpts );

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

    clear R;

    %%
    %bin
    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};

    timeWindow = [-1500, 3000];
    binMS = 20;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 0.5;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
    
    smoothWidth = 60;
    alignDat_smooth = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
    alignDat_smooth.zScoreSpikes(:,tooLow) = [];
    
    %%
    %cue labeling 
%       DIR_LEFT_HAND_UP(300)
%       DIR_LEFT_HAND_DOWN(301)
%       DIR_LEFT_HAND_RIGHT(302)
%       DIR_LEFT_HAND_LEFT(303)
%       
%       DIR_RIGHT_HAND_UP(304)
%       DIR_RIGHT_HAND_DOWN(305)
%       DIR_RIGHT_HAND_RIGHT(306)
%       DIR_RIGHT_HAND_LEFT(307)
%       
%       DIR_LEFT_FOOT_UP(308)
%       DIR_LEFT_FOOT_DOWN(309)
%       DIR_LEFT_FOOT_RIGHT(310)
%       DIR_LEFT_FOOT_LEFT(311)
%       
%       DIR_RIGHT_FOOT_UP(312)
%       DIR_RIGHT_FOOT_DOWN(313)
%       DIR_RIGHT_FOOT_RIGHT(314)
%       DIR_RIGHT_FOOT_LEFT(315)
%       
%       DIR_LEFT_ARM_UP(316)
%       DIR_LEFT_ARM_DOWN(317)
%       DIR_LEFT_ARM_RIGHT(318)
%       DIR_LEFT_ARM_LEFT(319)
%       
%       DIR_RIGHT_ARM_UP(320)
%       DIR_RIGHT_ARM_DOWN(321)
%       DIR_RIGHT_ARM_RIGHT(322)
%       DIR_RIGHT_ARM_LEFT(323)
%       
%       DIR_LEFT_LEG_UP(324)
%       DIR_LEFT_LEG_DOWN(325)
%       DIR_LEFT_LEG_RIGHT(326)
%       DIR_LEFT_LEG_LEFT(327)
%       
%       DIR_RIGHT_LEG_UP(328)
%       DIR_RIGHT_LEG_DOWN(329)
%       DIR_RIGHT_LEG_RIGHT(330)
%       DIR_RIGHT_LEG_LEFT(331)
%       
%       DIR_HEAD_UP(332)
%       DIR_HEAD_DOWN(333)
%       DIR_HEAD_RIGHT(334)
%       DIR_HEAD_LEFT(335)
%       
%       DIR_TONGUE_UP(336)
%       DIR_TONGUE_DOWN(337)
%       DIR_TONGUE_RIGHT(338)
%       DIR_TONGUE_LEFT(339)
      
    cueSets = {300:303,304:307,308:311,312:315,316:319,320:323,324:327,328:331,332:335,336:339};
    effNames = {'Left Wrist','Right Wrist','Left Ankle','Right Ankle','Left Arm','Right Arm','Left Leg','Right Leg','Head','Tongue'};
    movCues = alignDat.currentMovement(alignDat.eventIdx);
    
    %%
    headVel = diff(alignDat.windowsMousePosition);
    colors = hsv(4)*0.8;
    xLims = [];
    yLims = [];
    axHandles = zeros(length(cueSets),1);
    
    figure;
    for c=1:length(cueSets)
        axHandles(c) = subtightplot(2,5,c);
        hold on;
        useTrlIdx = find(ismember(movCues, cueSets{c}));
        
        for t=1:length(useTrlIdx)
            loopIdx = (0:50) + alignDat.eventIdx(useTrlIdx(t));
            colorIdx = movCues(useTrlIdx(t)) - cueSets{c}(1) + 1;
            plot(headVel(loopIdx,1), headVel(loopIdx,2), '.', 'Color', colors(colorIdx,:));
        end
        axis tight;
        
        xLims = [xLims; get(gca,'XLim')];
        yLims = [yLims; get(gca,'YLim')];
        axis off;
    end
    
    finalX = [min(xLims(:,1)), max(xLims(:,2))];
    finalY = [min(yLims(:,1)), max(yLims(:,2))];
    
    for c=1:length(axHandles)
        set(axHandles(c),'XLim',finalX,'YLim',finalY);
    end
    
    %speed
    axHandles = zeros(length(cueSets),1);
    figure;
    for c=1:length(cueSets)
        axHandles(c) = subtightplot(2,5,c);
        hold on;
        useTrlIdx = find(ismember(movCues, cueSets{c}));
        
        for t=1:length(useTrlIdx)
            loopIdx = (0:50) + alignDat.eventIdx(useTrlIdx(t));
            colorIdx = movCues(useTrlIdx(t)) - cueSets{c}(1) + 1;
            plot(alignDat.windowsMousePosition_speed(loopIdx), '-', 'Color', colors(colorIdx,:));
        end
        axis tight;
        
        xLims = [xLims; get(gca,'XLim')];
        yLims = [yLims; get(gca,'YLim')];
    end
        
    finalX = [min(xLims(:,1)), max(xLims(:,2))];
    finalY = [min(yLims(:,1)), max(yLims(:,2))];
    
    for c=1:length(axHandles)
        set(axHandles(c),'XLim',finalX,'YLim',[0,0.002]);
    end
    
    %%
    badTrl = false(size(movCues));
    for b=1:length(badTrl)
        if ismember(movCues(b), horzcat(cueSets{1:8}))
            loopIdx = alignDat.eventIdx(b)+(0:50);
            badTrl(b) = any(alignDat.windowsMousePosition_speed(loopIdx)>0.0002);
        end
    end
    goodTrl = ~badTrl;
    
    dPCA_out = apply_dPCA_simple( alignDat_smooth.zScoreSpikes, alignDat_smooth.eventIdx(goodTrl), ...
        movCues(goodTrl), timeWindow/binMS, binMS/1000, {'CD','CI'} );
    
    %%         
    cWindow = (10:50)+1500/20;
    idxSets = {1:4,5:8,9:12,13:16,17:20,21:24,25:28,29:32,33:36,37:40};
    fa = dPCA_out.featureAverages(:,2:end,:);
    
    simMatrix = plotCorrMat( fa, cWindow, [], idxSets, idxSets );
    
    %X corr and Y corr
    xCorrMat = zeros(10);
    yCorrMat = zeros(10);
    
    for rowIdx=1:10
        for colIdx=1:10
%             reducedMat = simMatrix(idxSets{rowIdx}(3:4),idxSets{colIdx}(3:4));
%             sameVals = diag(reducedMat)';
%             diffVals = [reducedMat(1,2), reducedMat(2,1)];
%             xCorrMat(rowIdx,colIdx) = mean([sameVals, -diffVals]);
%             
%             reducedMat = simMatrix(idxSets{rowIdx}(1:2),idxSets{colIdx}(1:2));
%             sameVals = diag(reducedMat)';
%             diffVals = [reducedMat(1,2), reducedMat(2,1)];
%             yCorrMat(rowIdx,colIdx) = mean([sameVals, -diffVals]);
            
            xCorrMat(rowIdx,colIdx) = mean(diag(simMatrix(idxSets{rowIdx}(3:4),idxSets{colIdx}(3:4))));
            yCorrMat(rowIdx,colIdx) = mean(diag(simMatrix(idxSets{rowIdx}(1:2),idxSets{colIdx}(1:2))));
        end
    end
    
    oppositeSides_x = [xCorrMat(1,2), xCorrMat(1,4), xCorrMat(2,3), xCorrMat(3,4), xCorrMat(5,6), xCorrMat(5,8), ...
        xCorrMat(6,7), xCorrMat(7,8)];
    sameSides_x = [xCorrMat(1,3), xCorrMat(2,4), xCorrMat(5,7), xCorrMat(6,8)];
    
    oppositeSides_y = [yCorrMat(1,2), yCorrMat(1,4), yCorrMat(2,3), yCorrMat(3,4), yCorrMat(5,6), yCorrMat(5,8), ...
        yCorrMat(6,7), yCorrMat(7,8)];
    sameSides_y = [yCorrMat(1,3), yCorrMat(2,4), yCorrMat(5,7), yCorrMat(6,8)];
    
    allCorrMats = {xCorrMat, yCorrMat};
    boxSets = {1:4,5:8,9:10};
    titles = {'Horizontal Direction','Vertical Direction'};
    
    figure('Position',[239   754   973   344]);
    for cMatIdx=1:length(allCorrMats)
        cMat = allCorrMats{cMatIdx};
        cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

        subplot(1,2,cMatIdx);
        imagesc(cMat,[-1 1]);
        colormap(cMap);
        set(gca,'XTick',1:length(cMat),'XTickLabel',effNames,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(cMat),'YTickLabel',effNames);
        set(gca,'FontSize',16);
        set(gca,'YDir','normal');
        colorbar('LineWidth',2,'FontSize',16);
        axis tight;
        
        colors = [173,150,61;
            119,122,205;
            91,169,101;
            197,90,159;
            202,94,74]/255;

        currentIdx = 0;
        currentColor = 1;
        for c=1:length(boxSets)
            newIdx = currentIdx + (1:length(boxSets{c}))';
            rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(currentColor,:));
            currentIdx = currentIdx + length(boxSets{c});
            currentColor = currentColor + 1;
        end
        axis tight;
        title(titles{cMatIdx});
        set(gca,'LineWidth',2);
    end
    saveas(gcf,[outDir filesep datasets{d,3}{1} 'corrMatDir_diag.png'],'png');
    saveas(gcf,[outDir filesep datasets{d,3}{1} 'corrMatDir_diag.svg'],'svg');
    
    %%
    %PD correlations
    allPD = cell(length(idxSets),2);
    allPVal = cell(length(idxSets),2);
    targLayout = [0,1; 0,-1; -1,0; 1,0];

    for setIdx=1:length(cueSets)
        allDat = [];
        allTargPos = [];
        allDat_mean = [];
        allTargPos_mean = [];

        useTrlIdx = find(ismember(movCues, cueSets{setIdx}));
        for trlIdx=1:length(useTrlIdx)
            globalTrlIdx = useTrlIdx(trlIdx);
            targLoc = targLayout(movCues(globalTrlIdx)-cueSets{setIdx}(1)+1,:);

            loopIdx = (10:50) + alignDat.eventIdx(globalTrlIdx);
            allDat = [allDat; alignDat.zScoreSpikes(loopIdx,:)];
            allTargPos = [allTargPos; repmat(targLoc,length(loopIdx),1)];
            
            allDat_mean = [allDat_mean; mean(alignDat.zScoreSpikes(loopIdx,:))];
            allTargPos_mean = [allTargPos_mean; targLoc];
        end

        nFeat = size(alignDat.zScoreSpikes,2);
        pVals = zeros(nFeat,1);
        E = zeros(nFeat,3);
        pVals_mean = zeros(nFeat,1);
        E_mean = zeros(nFeat,3);
        
        for featIdx=1:nFeat
            [B,BINT,R,RINT,STATS] = regress(allDat(:,featIdx), [ones(length(allTargPos),1), allTargPos(:,1:2)]);
            [B_mean,BINT_mean,R_mean,RINT_mean,STATS_mean] = regress(allDat_mean(:,featIdx), [ones(length(allTargPos_mean),1), allTargPos_mean(:,1:2)]);
            
            pVals(featIdx) = STATS(3);
            E(featIdx,:) = B;
            
            pVals_mean(featIdx) = STATS_mean(3);
            E_mean(featIdx,:) = B_mean;
        end

        allPD{setIdx,1} = E(:,2:3);
        allPVal{setIdx,1} = pVals;
        
        allPD{setIdx,2} = E_mean(:,2:3);
        allPVal{setIdx,2} = pVals_mean;
    end
    
    cMat = zeros(length(allPD),length(allPD),2);
    for x=1:length(allPD)
        for y=1:length(allPD)
            %sigIdx = find(allPVal{x,2}<0.001 & allPVal{y,2}<0.001);
            sigIdx = 1:length(allPD{x,1});
            cMat(x,y,1) = corr(allPD{x,1}(sigIdx,1), allPD{y,1}(sigIdx,1));
            cMat(x,y,2) = corr(allPD{x,1}(sigIdx,2), allPD{y,1}(sigIdx,2));
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
        colorbar('LineWidth',2,'FontSize',16);
        set(gca,'XTick',1:length(effNames),'XTickLabel',effNames,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(effNames),'YTickLabel',effNames);
        set(gca,'FontSize',16);
        axis tight;
        
        colors = [173,150,61;
            119,122,205;
            91,169,101;
            197,90,159;
            202,94,74]/255;

        currentIdx = 0;
        currentColor = 1;
        for c=1:length(boxSets)
            newIdx = currentIdx + (1:length(boxSets{c}))';
            rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(currentColor,:));
            currentIdx = currentIdx + length(boxSets{c});
            currentColor = currentColor + 1;
        end

        title(titles{dimIdx});
        set(gca,'LineWidth',2);
    end
    saveas(gcf, [outDir filesep 'CMat_PD.png'],'png');
    saveas(gcf, [outDir filesep 'CMat_PD.svg'],'svg');

    %%
    %2D dPCA plot
    errTrials = {[],[64],[10],[29],[81],[29],[10,52],[27],[52],[]};
    for e=1:length(errTrials)
        errTrials{e} = errTrials{e} + (e-1)*82;
    end
    allErrTrials = horzcat(errTrials{:});
    
    for prepIdx=1:2
        if prepIdx==2
            dPC_window = [-1000, 0];
            cWindow = 30:50; %30:50
        else
            dPC_window = [200, 800];
            cWindow = 1:31;
        end
        
        dPCA_all_xval = cell(length(cueSets),1);
        allTrlIdx = cell(length(cueSets),1);
        for setIdx=1:length(cueSets)
            trlIdx = find(ismember(movCues, cueSets{setIdx}));
            
            dPCA_all_xval{setIdx} = apply_dPCA_simple( alignDat_smooth.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
                movCues(trlIdx), dPC_window/binMS, binMS/1000, {'CI','CD'}, 20, 'xval');
            close(gcf);
            
            allTrlIdx{setIdx} = trlIdx;
        end

        axHandle = [];
        xLims = [];
        yLims = [];
        nTargs = 4;
        
        figure('Position',[193   624   845   386]);
        for plotIdx=1:length(dPCA_all_xval)
            cdIdx = find(dPCA_all_xval{plotIdx}.cval.whichMarg==1);
            cdIdx = cdIdx(1:2);

            colors = hsv(nTargs)*0.8;

            axHandle(plotIdx) = subtightplot(2,5,plotIdx);
            hold on;
            
            zs = squeeze(dPCA_all_xval{plotIdx}.cval.Z_singleTrial(:,cdIdx,:,cWindow));
            zs = nanmean(zs,4);
            zs = permute(zs,[1 3 2]);
            
            xAxis = squeeze(zs(:,:,1));
            yAxis = squeeze(zs(:,:,2));
            
            xAxis_target = zeros(size(xAxis));
            yAxis_target = zeros(size(xAxis));
            for x=1:size(xAxis_target,2)
                xAxis_target(:,x) = targLayout(x,1);
                yAxis_target(:,x) = targLayout(x,2);
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
                zs = squeeze(dPCA_all_xval{plotIdx}.cval.Z_singleTrial(:,cdIdx,t,cWindow));
                zs = nanmean(zs,3);
                zs = zs * transMat;
                
                plot(zs(:,1), zs(:,2), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 2);
                plot(nanmean(zs(:,1)), nanmean(zs(:,2)), 'x', 'LineWidth', 2, 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 10);
            end
            axis equal;
            title(effNames{plotIdx});
            
            errTrlIdx = find(ismember(allTrlIdx{plotIdx}, allErrTrials));
            if ~isempty(errTrlIdx)
                for t=1:length(errTrlIdx)
                    zs = squeeze(dPCA_all_xval{plotIdx}.cval.Z_trialOrder(errTrlIdx(t),cdIdx,cWindow));
                    zs = nanmean(zs,2);
                    zs = zs' * transMat;
                    
                    %plot(zs(1), zs(2), 'ro');
                end
            end

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
            
end %datasets
