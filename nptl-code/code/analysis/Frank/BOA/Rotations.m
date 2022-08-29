%%
%'t5.2018.08.27',{[9,11,12,13,14,15,16]},{'CardinalJoint32_Delay'};
datasets = {
    't5.2018.12.05',{[14 15 16 17 19 20 21 22 23 24 25 26]},{'QuadReachRadial6'};
    't5.2019.02.13',{[14 15 16 17 19 20 21 22]},{'Quad_Radial8'};
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'Fig4' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    allPD = cell(length(datasets{d,2}),1);
    allPVal = cell(length(datasets{d,2}),1);
    
    for blockSetIdx=1:length(datasets{d,2})
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
        tooLow = meanRate < 1.0;
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
        
        if strfind(datasets{d,3}{blockSetIdx}, 'Quad_Radial8')
            targLayout = targList(:,1:2);
            
            idxSets = {[18 21 25 29 32 28 24 20],[1 4 8 12 15 11 7 3],[19 23 27 31 33 30 26 22],[2 6 10 14 16 13 9 5]};
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
        for set=1:length(idxSets)
            Data = struct();
            timeMS = round(-25:50)*20;

            for n=1:length(idxSets{set})
                trlAvg = squeeze(dPCA_all.featureAverages(:,idxSets{set}(n),:));
                Data(n).A = trlAvg';
                Data(n).times = timeMS;
            end

            jPCA_params.normalize = true;
            jPCA_params.softenNorm = 0;
            jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.meanSubtract = true;
            jPCA_params.numPCs = 6;  % default anyway, but best to be specific

            for startTime = 0:20:400
                windowIdx = [startTime, 200+startTime];

                %short window
                jPCATimes = windowIdx(1):20:windowIdx(2);
                for x = 1:length(jPCATimes)
                    [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
                    jPCATimes(x) = Data(1).times(minIdx);
                end

                [Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
                phaseSpace(Projections, jPCA_Summary);  % makes the plot
            end
            close all; 
        end
        
        %% 
        tCodesUse = targCodes(useTrl);
        allPD = cell(length(idxSets),1);
        allPVal = cell(length(idxSets),1);
        allDec = cell(length(idxSets),1);
        cWindow = 10:50;
        %cWindow = -40:-10;
        allXDat = cell(length(idxSets),1);
        allYDat = cell(length(idxSets),1);
        
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
            %allDec{setIdx} = allDec{setIdx}./matVecMag(allDec{setIdx},1);
            
            nFeatures = size(allDat,2);
            pVals = zeros(nFeatures,1);
            E = zeros(nFeatures,3);
            for featIdx=1:nFeatures
                [B,BINT,R,RINT,STATS] = regress(allDat(:,featIdx), [ones(length(allTargPos),1), allTargPos(:,1:2)]);
                pVals(featIdx) = STATS(3);
                E(featIdx,:) = B;
            end
            
            allPD{setIdx} = E(:,2:3);
            allPVal{setIdx} = pVals;
            
            allXDat{setIdx} = allDat;
            allYDat{setIdx} = [ones(length(allTargPos),1), allTargPos(:,1:2)];
        end
        
        if d==2
            setNames = {'Right Hand','Left Hand','Right Foot','Left Foot'};
        else
            setNames = {'Right Arm','Left Arm','Right leg','Left leg'};
        end
        
        cMat_xVal = zeros(length(allPD),length(allPD),2);
        for x=1:length(allPD)
            for y=1:length(allPD)
                [ meanMagnitude_1, meanSquaredMagnitude_1, B_1 ] = cvStatsForOLS( allYDat{x}, allXDat{x}, 10, true, true );
                [ meanMagnitude_2, meanSquaredMagnitude_2, B_2 ] = cvStatsForOLS( allYDat{y}, allXDat{y}, 10, true, true );
                cMat_xVal(x,y,1) = B_1(:,2)'*B_2(:,2)/(meanMagnitude_1(2,2)*meanMagnitude_2(2,2));
                cMat_xVal(x,y,2) = B_1(:,3)'*B_2(:,3)/(meanMagnitude_1(3,3)*meanMagnitude_2(3,3));
            end
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
            imagesc(squeeze(cMat_xVal(:,:,dimIdx)),[-1 1]);
            colormap(cMap);
            cBar = colorbar('FontSize',16,'LineWidth',2);
            if dimIdx==2
                tmp = get(cBar,'YLabel');
                set(tmp,'String','Correlation');
            end
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
        if strcmp(datasets{d,3},'QuadReachRadial6')
            theta = linspace(pi/2,2*pi+pi/2,7);
            theta = theta(1:6);

            targLayout = [cos(theta)',sin(theta)'];
            targReorder = [2 3 1 4 6 5];
            targLayout = targLayout(targReorder,:);
        elseif strcmp(datasets{d,3},'Quad_Radial8')
            theta = linspace(0,2*pi,9);
            theta = theta(1:8);

            targLayout = [cos(theta)',sin(theta)'];
            targReorder = [5 4 6 3 7 2 8 1];
            targLayout = targLayout(targReorder,:);
        end
        
        nTargs = size(targLayout,1);
        colors = hsv(nTargs)*0.8;
        colors = colors(targReorder,:);

        for prepIdx=1:2
            if prepIdx==2
                dPC_window = [-1000, 0];
                cWindow = 30:50; %30:50
            else
                %dPC_window = [200, 800];
                %cWindow = 1:31;
                dPC_window = [200, 1000];
                cWindow = 1:41;
            end

            dPCA_all_xval = cell(length(idxSets),1);
            pca_Z = cell(length(idxSets),1);
            for setIdx=1:length(idxSets)
                trlIdx = find(ismember(targCodes(useTrl),idxSets{setIdx}));

                dPCA_all_xval{setIdx} = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
                    targCodes(useTrl(trlIdx)), dPC_window/binMS, binMS/1000, {'CD','CI'}, 20, 'xval', 'marg');
                close(gcf);
                
                trlAvg = squeeze(mean(dPCA_all_xval{setIdx}.featureAverages(:,:,cWindow),3));
                winAvg = squeeze(mean(dPCA_all_xval{setIdx}.featureVals(:,:,cWindow,:),3));

                [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(trlAvg');
                pca_Z{setIdx} = zeros(size(winAvg,3),size(winAvg,2),2);
                winAvg = permute(winAvg,[3 2 1]);

                for tIdx=1:size(winAvg,1)
                    pca_Z{setIdx}(tIdx,:,1) = (squeeze(winAvg(tIdx,:,:))-MU)*COEFF(:,1);
                    pca_Z{setIdx}(tIdx,:,2) = (squeeze(winAvg(tIdx,:,:))-MU)*COEFF(:,2);
                end
            end

            axHandle = [];
            xLims = [];
            yLims = [];

            figure
            for setIdx=1:length(idxSets)
                cdIdx = find(dPCA_all_xval{setIdx}.cval.whichMarg==1);
                cdIdx = cdIdx(1:2);

                axHandle(setIdx) = subtightplot(2,2,setIdx);
                hold on;

                zs = squeeze(dPCA_all_xval{setIdx}.cval.Z_singleTrial(:,cdIdx,:,cWindow));
                zs = nanmean(zs, 4);
                zs = permute(zs, [1 3 2]);
                
                %Z = pca_Z{setIdx}; 
                %zs = nanmean(Z,4);

                xAxis = squeeze(zs(:,:,1));
                yAxis = squeeze(zs(:,:,2));

                xAxis_target = zeros(size(xAxis));
                yAxis_target = zeros(size(xAxis));
                for x=1:size(xAxis_target,2)
                    xAxis_target(:,x) = targLayout(x,1);
                    yAxis_target(:,x) = targLayout(x,2);
                end
                
%                 figure
%                 hold on
%                 for t=1:8
%                     plot(squeeze(zs(:,t,1)), squeeze(zs(:,t,2)),'o', 'Color', colors(t,:));
%                 end
%                 
%                 figure
%                 hold on
%                 for t=1:8
%                     plot(targLayout(t,1), targLayout(t,2),'o', 'Color', colors(t,:),'MarkerFaceColor', colors(t,:),'MarkerSize',12);
%                 end

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
                
                [D, Z, TRANSFORM] = procrustes([xAxis_target, yAxis_target], X, 'Scaling', true);
                transmat = TRANSFORM.T;
                
                for t=1:nTargs
                    tmp = squeeze(zs(:,t,:));
                    tmp = tmp * transmat;

                    plot(tmp(:,1), tmp(:,2), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 2);
                    plot(nanmean(tmp(:,1)), nanmean(tmp(:,2)), 'o', 'Color', colors(t,:), 'MarkerFaceColor', colors(t,:), 'MarkerSize', 10);
                end
                axis equal;
                title(setNames{setIdx});
                
                offset = [0, 0];
                scale = 1.0;
                plot([offset(1), transmat(1,1)*scale + offset(1)], [offset(2), transmat(2,1)*scale+offset(2)],'-ko','LineWidth',2);
                plot([offset(1), transmat(1,2)*scale + offset(1)], [offset(2), transmat(2,2)*scale+offset(2)],'-kx','LineWidth',2);

                if setIdx==1
                    plot([0,5],[0,0],'-k','LineWidth',2);
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

    end %block set
    
    close all;
end %datasets