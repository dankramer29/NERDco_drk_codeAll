%%
datasets = {
    't5.2018.08.27',{[9,11,12,13,14,15,16]},{'CardinalJoint32_Delay'};
    't5.2018.12.05',{[14 15 16 17 19 20 21 22 23 24 25 26]},{'QuadReachRadial6'};
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
        targList(:,2) = -targList(:,2);
        
        centerCode = find(all(targList==0,2) | targList(:,4)~=0);
        if ~isempty(centerCode)
            useTrl = find(~ismember(targCodes,centerCode));
        else
            useTrl = 1:length(targCodes);
        end
        
        noGoCue = false(size(allR));
        for t=1:length(allR)
            if isempty(allR(t).timeGoCue)
                noGoCue(t) = true;
            end
        end
        useTrl = setdiff(useTrl, find(noGoCue));
        
        %%        
        alignFields = {'timeGoCue'};
        smoothWidth = 0;
        datFields = {'windowsMousePosition','windowsMousePosition_speed'};
        timeWindow = [-1000,2000];
        binMS = 20;
        alignDat = binAndAlignR( allR(useTrl), timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        %%
        tList = unique(targCodes);
        figure
        hold on
        for x=1:length(tList)
            text(targList(tList(x),1), targList(tList(x),2), num2str(tList(x)));
        end
        xlim([-1200,1200]);
        ylim([-1200,1200]);
        
        if strfind(datasets{d,3}{blockSetIdx}, 'DualJoystick')
            targLayout = targList(:,1:2);
            targLayout(1:8,:) = targLayout(1:8,:) - mean(targLayout(1:8,:));
            targLayout(1:8,:) = targLayout(1:8,:)./matVecMag(targLayout(1:8,:),2);
            targLayout(9:16,:) = targLayout(9:16,:) - mean(targLayout(9:16,:));
            targLayout(9:16,:) = targLayout(9:16,:)./matVecMag(targLayout(9:16,:),2);
            
            codeSets = {[1 3 5 7 8 6 4 2],[9 11 13 15 16 14 12 10]};
            taskType='Dual';
            idxSets = codeSets;
            
        elseif strfind(datasets{d,3}{blockSetIdx}, 'Quad_Radial8')
            targLayout = targList(:,1:2);
            
            idxSets = {[1 4 8 12 15 11 7 3],[2 6 10 14 16 13 9 5],[19 23 27 30 33 31 26 22],[18 21 25 29 32 28 24 20]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
            taskType='Quad';
        elseif strfind(datasets{d,3}{blockSetIdx}, 'Quad_Radial4')
            targLayout = targList(:,1:2);
            
            idxSets = {[1 4 7 3],[2 6 8 5],[11 15 17 14],[10 13 16 12]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
            taskType='Quad';
        elseif strfind(datasets{d,3}{blockSetIdx}, 'QuadReachRadial6')
            targLayout = targList(:,1:2);
            
            idxSets = {[15 19 23 24 20 16],[1 5 9 10 6 2],[17 21 25 26 22 18],[3 7 11 12 8 4]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
            taskType='Quad';
        elseif strfind(datasets{d,3}{blockSetIdx}, 'CardinalJoint32_Delay')
            targLayout = targList(:,1:2);
            
            idxSets = {[26 28 31 27],[1 4 7 3],[25 30 32 29],[2 6 8 5]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
            taskType='Quad';
        end
        
        %%
        smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);
        dPCA_all = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx, ...
            targCodes(useTrl), [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );
        
        tListUnique = unique(targCodes(useTrl));
        remappedSets = idxSets;
        for s=1:length(remappedSets)
            for t=1:length(remappedSets{s})
                remappedSets{s}(t) = find(tListUnique==idxSets{s}(t));
            end
        end
        
        cWindow = 30:50;
        fa = dPCA_all.featureAverages;
        reorderIdx = horzcat(remappedSets{:});
        fa = fa(:,reorderIdx,:);
        
        globalIdx = 1;
        corrSets = cell(length(idxSets),1);
        for c=1:length(corrSets)
            corrSets{c} = globalIdx:(globalIdx+length(idxSets{c})-1);
            globalIdx = globalIdx + length(idxSets{c});
        end
        
        simMatrix = plotCorrMat( fa, cWindow, [], corrSets, corrSets);
        saveas(gcf, [outDir filesep 'SimMatrix_' datasets{d,3}{blockSetIdx} '.png'],'png');
        
        %% 
        tCodesUse = targCodes(useTrl);
        allPD = cell(length(idxSets),1);
        allPVal = cell(length(idxSets),1);
        allDec = cell(length(idxSets),1);
        cWindow = 10:50;
        %cWindow = -40:-10;
        
        for setIdx=1:length(idxSets)
            allDat = [];
            allTargPos = [];
            allDat_raw = [];
            allTargPos_raw = [];
            
            useTrlIdx = find(ismember(tCodesUse, idxSets{setIdx}));
            for trlIdx=1:length(useTrlIdx)
                globalTrlIdx = useTrlIdx(trlIdx);
                targLoc = targLayout(tCodesUse(globalTrlIdx),:);
                
                loopIdx = cWindow + alignDat.eventIdx(globalTrlIdx);
                allDat = [allDat; mean(alignDat.zScoreSpikes(loopIdx,:))];
                allTargPos = [allTargPos; targLoc];
                
                allDat_raw = [allDat_raw; alignDat.zScoreSpikes(loopIdx,:)];
                allTargPos_raw = [allTargPos_raw; repmat(targLoc,length(loopIdx),1)];
            end
            
            allDec{setIdx} = buildLinFilts( allTargPos_raw, allDat_raw, 'inverseLinear');

            pVals = zeros(192,1);
            E = zeros(192,3);
            for featIdx=1:192
                [B,BINT,R,RINT,STATS] = regress(allDat(:,featIdx), [ones(length(allTargPos),1), allTargPos(:,1:2)]);
                pVals(featIdx) = STATS(3);
                E(featIdx,:) = B;
            end
            
            allPD{setIdx} = E(:,2:3);
            allPVal{setIdx} = pVals;
        end
        
        if d==1
            setNames = {'Right Hand','Left Hand','Right Foot','Left Foot'};
        else
            setNames = {'Right Arm','Left Arm','Right leg','Left leg'};
        end
        
        cMat = zeros(length(allPD),length(allPD),2);
        for x=1:length(allPD)
            for y=1:length(allPD)
                cMat(x,y,1) = corr(allPD{x}(:,1), allPD{y}(:,1));
                cMat(x,y,2) = corr(allPD{x}(:,2), allPD{y}(:,2));
            end
        end
        cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

        titles = {'Horizontal Direction','Vertical Direction'};
        figure('Position',[680   868   644   230]);
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
        saveas(gcf, [outDir filesep 'CMat_' datasets{d,3}{blockSetIdx} '.png'],'png');
        saveas(gcf, [outDir filesep 'CMat_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
        
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
                    ylabel(setNames{x});
                end
                if x==nCon
                    xlabel(setNames{y});
                end
                set(gca,'FontSize',14,'XTick',[],'YTick',[]);
            end
        end
        saveas(gcf, [outDir filesep 'PDRotMat_' datasets{d,3}{blockSetIdx} '.png'],'png');
        
        %%
        %single trial cosine tuning plot
        theta = linspace(pi/2,2*pi+pi/2,7);
        theta = theta(1:6);
        
        targLayout = [cos(theta)',sin(theta)'];
        targLayout = targLayout([2 1 6 5 4 3],:);
        nTargs = size(targLayout,1);
        effNames = {'Right Arm','Left Arm','Right Leg','Left Leg'};
        
        for prepIdx=1:2
            if prepIdx==2
                dPC_window = [-1000, 0];
                cWindow = 30:50; %30:50
            else
                dPC_window = [200, 800];
                cWindow = 1:31;
            end

            dPCA_all_xval = cell(length(idxSets),1);
            for setIdx=1:length(idxSets)
                trlIdx = find(ismember(targCodes(useTrl),idxSets{setIdx}));

                dPCA_all_xval{setIdx} = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
                    targCodes(useTrl(trlIdx)), dPC_window/binMS, binMS/1000, {'CI','CD'}, 20, 'xval');
                close(gcf);
            end
            
            decSingleTrial = cell(length(idxSets),1);
            for setIdx=1:length(idxSets)
                fv = dPCA_all_xval{setIdx}.featureVals;
                decSingleTrial{setIdx} = zeros(size(fv,4),2,size(fv,2),size(fv,3));
                for trlIdx=1:size(fv,4)
                    for targIdx=1:size(fv,2)
                        decSingleTrial{setIdx}(trlIdx,:,targIdx,:) = allDec{setIdx}'*squeeze(fv(:,targIdx,:,trlIdx));
                    end
                end
            end

            axHandle = [];
            xLims = [];
            yLims = [];

            figure
            for setIdx=1:length(idxSets)
                cdIdx = find(dPCA_all_xval{setIdx}.cval.whichMarg==1);
                cdIdx = cdIdx(1:2);

                colors = hsv(nTargs)*0.8;

                axHandle(setIdx) = subtightplot(2,2,setIdx);
                hold on;

                zs = squeeze(dPCA_all_xval{setIdx}.cval.Z_singleTrial(:,cdIdx,:,cWindow));
                %zs = decSingleTrial{setIdx};
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
                    zs = squeeze(dPCA_all_xval{setIdx}.cval.Z_singleTrial(:,cdIdx,t,cWindow));
                    zs = nanmean(zs,3);
                    zs = zs * transMat;

                    plot(zs(:,1), zs(:,2), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 2);
                    plot(nanmean(zs(:,1)), nanmean(zs(:,2)), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 10);
                end
                axis equal;
                title(effNames{setIdx});

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

    end %block set
end %datasets