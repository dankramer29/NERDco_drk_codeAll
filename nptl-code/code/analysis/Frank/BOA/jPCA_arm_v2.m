%%
%During the last blocks of arm, the activity patterns change for some unknown reason
%(as can be seen through population raster), so I am excluding them. 
%Original definition with all blocks: 't5.2019.03.18',{[7 9 11 13 15 17 20 22 24 26 28],[5 8 10 12 14 16 19 21 23 25 27]};

datasets = {
    't5.2019.03.18',{[7 9 11 13 15 17 20],[5 8 10 12 14 16 19 21 23 25 27]};
};
setNames = {'arm','head'};
useWarpedCubes = false;
      
%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'BOA' filesep 'jPCA' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    for blockSetIdx=1:length(datasets{d,2})
        %load and concatenate all R structs for the specified block set
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

        %assign a specific code for each target location
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
        %align the data to go cue
        alignFields = {'timeGoCue'};
        smoothWidth = 0;
        datFields = {'windowsMousePosition','windowsMousePosition_speed'};
        timeWindow = [-1000,2000];
        binMS = 10;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 1.0;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        targCodesUse = targCodes(useTrl);
        movLabels = {'t1','t2','t3','t4','t5','t6','t7','t8','t10','t11','t12','t13','t14','t15','t16','t17'};
       
        %%
        %apply marginalized PCA
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
        opts_m.nResamples = 10;

        [tcList,~,tcReorder] = unique(targCodesUse);
        smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3.0);
        
        mPCA_cue = apply_mPCA_general( smoothSpikes, alignDat.eventIdx(useTrl), ...
            tcReorder, [-50,150], 0.010, opts_m);
        
        codeSets_g = {[16 14 7 2 1 3 10 15],[13 11 8 5 4 6 9 12]};
        factorCodes = zeros(length(tcReorder),1);
        for t=1:length(tcReorder)
            if ismember(tcReorder(t), codeSets_g{1})
                distCode = 2;
                [~,dirCode] = ismember(tcReorder(t), codeSets_g{1});
            else
                distCode = 1;
                [~,dirCode] = ismember(tcReorder(t), codeSets_g{2});
            end
            
            factorCodes(t,1) = dirCode;
            factorCodes(t,2) = distCode;
        end
        
        opts_m_twoFactor = opts_m;
        opts_m_twoFactor.margGroupings = {{1,[1 3]},{2,[2 3]},{[1 2],[1 2 3]},{3}};
        opts_m_twoFactor.margNames = {'Dir','Dist','Dir x Dist','Time'};
        opts_m_twoFactor.plotCI = false;
        
        mPCA_twoFactor = apply_mPCA_general( smoothSpikes_fromCube, alignDat.eventIdx, ...
            factorCodes, [-50,150], 0.010, opts_m_twoFactor);
        
        %%
        %save mPCA plot with forced axes
        mp = mPCA_cue.margPlot;
        mp.layoutInfo.nPerMarg = 5;
        [yAxesFinal, allHandles, allYAxes] = marg_mPCA_plot( mPCA_cue.margResample, mp.timeAxis, mp.lineArgs, ...
            mp.plotTitles, 'sameAxes', [], [-3.5, 3.5], mPCA_cue.margResample.CIs, mp.lineArgsPerMarg, opts_m.margGroupings, opts_m.plotCI, mp.layoutInfo );
        set(gcf,'Position',[136   194   596   868]);
        saveas(gcf,[outDir filesep 'mPCA_' setNames{blockSetIdx} '_' warpSuffix '.png'],'png');
        saveas(gcf,[outDir filesep 'mPCA_' setNames{blockSetIdx} '_' warpSuffix '.svg'],'svg');
        
        %%
        %condition legend
        figure
        hold on
        for x=1:length(tcList)
            text(targList(tcList(x),1), targList(tcList(x),2), num2str(tcList(x)));
        end
        xlim([-1200,1200]);
        ylim([-1200,1200]);
        
        saveas(gcf,[outDir filesep 'targetLegend_' num2str(setNames{blockSetIdx}) '.png'],'png');
        saveas(gcf,[outDir filesep 'targetLegend_' num2str(setNames{blockSetIdx}) '.fig'],'fig');
        
        %%
        %prep states
        codeSets = {[16 14 7 2 1 3 10 15],[13 11 8 5 4 6 9 12]};
        prepVec = squeeze(nanmean(mPCA_cue.featureAverages(:,:,1:50),3))';

        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

        colors = hsv(8)*0.8;
        ms = {'o','s'};
        
        figure
        hold on
        for setIdx=1:length(codeSets)
            codes = codeSets{setIdx};
            for x=1:length(codes)
                plot3(SCORE(codes(x),1), SCORE(codes(x),2), SCORE(codes(x),3), ms{setIdx}, 'Color', colors(x,:), ...
                    'MarkerFaceColor', colors(x,:), 'MarkerSize', 12);
            end
        end
        axis equal;
        saveas(gcf,[outDir filesep 'prepStates_' num2str(setNames{blockSetIdx}) '.png'],'png');
        saveas(gcf,[outDir filesep 'prepStates_' num2str(setNames{blockSetIdx}) '.fig'],'fig');
        
        %%
        %ortho prep analysis
        sCodes = [codeSets{1}, codeSets{2}];

        radialDir = [1,0;
                   1/sqrt(2), 1/sqrt(2);
                   0,1;
                   -1/sqrt(2),1/sqrt(2);
                   -1,0;
                   -1/sqrt(2),-1/sqrt(2);
                   0,-1;
                   1/sqrt(2),-1/sqrt(2);];
        codeDir = [radialDir; radialDir*0.5];

        idxWindow = [20, 50];
        idxWindowPrep = [-50, 0];

        allDir = [];
        allNeural = [];

        allDir_prep = [];
        allNeural_prep = [];

        for t=1:length(alignDat.eventIdx)
            [LIA,LOCB] = ismember(tcReorder(t),sCodes);
            if LIA
                currDir = codeDir(LOCB,:);
                newDir = repmat(currDir, idxWindow(2)-idxWindow(1)+1, 1);

                loopIdx = (alignDat.eventIdx(t)+idxWindow(1)):(alignDat.eventIdx(t)+idxWindow(2));
                newNeural = smoothSpikes_fromCube(loopIdx,:);

                allDir = [allDir; newDir];
                allNeural = [allNeural; newNeural];

                %zeroing
                newDir = repmat(currDir, idxWindowPrep(2)-idxWindowPrep(1)+1, 1);
                loopIdx = (alignDat.eventIdx(t)+idxWindowPrep(1)):(alignDat.eventIdx(t)+idxWindowPrep(2));
                newNeural = smoothSpikes_fromCube(loopIdx,:);

                allDir_prep = [allDir_prep; newDir];
                allNeural_prep = [allNeural_prep; newNeural];
            end
        end

        Y_mov = [allDir; zeros(size(allDir_prep))];
        X_mov = [[ones(size(allNeural,1),1), allNeural]; [ones(size(allNeural_prep,1),1), allNeural_prep]];
        goodRows = find(all(~isnan(X_mov),2));
        
        [ filts_mov, featureMeans ] = buildLinFilts( Y_mov(goodRows,:), X_mov(goodRows,:), 'ridge', 1e3 );

        Y_prep = [allDir_prep; zeros(size(allDir))];
        X_prep = [[ones(size(allNeural_prep,1),1), allNeural_prep]; [ones(size(allNeural,1),1), allNeural]];
        goodRows = find(all(~isnan(X_prep),2));
        
        [ filts_prep, featureMeans ] = buildLinFilts( Y_prep(goodRows,:), X_prep(goodRows,:), 'ridge', 1e3 );

        decVel = [ones(size(smoothSpikes_fromCube,1),1), smoothSpikes_fromCube]*filts_mov;

        colors = jet(length(sCodes))*0.8;
        figure
        hold on
        for t=1:length(alignDat.eventIdx)
            [LIA,LOCB] = ismember(tcReorder(t),sCodes(1:16));
            if LIA
                currDir = codeDir(LOCB,:);
                newDir = repmat(currDir, idxWindow(2)-idxWindow(1)+1, 1);

                loopIdx = (alignDat.eventIdx(t)+idxWindow(1)):(alignDat.eventIdx(t)+idxWindow(2));

                traj = cumsum(decVel(loopIdx,:));
                plot(cumsum(decVel(loopIdx,1)), cumsum(decVel(loopIdx,2)),'Color',colors(LOCB,:));
                plot(traj(end,1), traj(end,2),'o','Color',colors(LOCB,:),'MarkerSize',8,'MarkerFaceColor',colors(LOCB,:));
            end
        end
        axis equal;
        
        %%
        %ortho prep space?
        mPCA_out = {mPCA_cue, mPCA_cue};
        mPCA_out{1}.featureAverages = mPCA_out{1}.featureAverages(:,codeSets{1},:);
        mPCA_out{2}.featureAverages = mPCA_out{2}.featureAverages(:,codeSets{2},:);
        
        movLabelSets = {'right','up right','up','up left','left','down left','down','down right'};
        movLabelSets = {movLabelSets, movLabelSets};
        
        color = [1 0 0];
        nDims = 4;
        nCon = size(mPCA_out{1}.featureAverages,2);
        timeWindow = [-49,149];

        X = [filts_prep, filts_mov];
        X = X(2:end,:);

        headings = {'X','Y','CIS'};

        lineStyles = {'-',':'};
        timeAxis = (timeWindow(1):timeWindow(2))*0.01;
        ciDim = mPCA_out{1}.readouts(:,6)*0.5;
        nPerPage = 6;
        currIdx = 1:nPerPage;
        nPages = ceil(size(mPCA_out{1}.featureAverages,2)/nPerPage);

        for pageIdx=1:nPages
            figure('Position',[73          49         526        1053]);
            for plotConIdx=1:length(currIdx)
                plotCon = currIdx(plotConIdx);
                if plotCon > size(mPCA_out{1}.featureAverages, 2)
                    continue
                end

                for dimIdx = 1:3
                    subplot(nPerPage,3,(plotConIdx-1)*3+dimIdx);
                    hold on;
                    
                    for plotSet=1:2
                        tmp = squeeze(mPCA_out{plotSet}.featureAverages(:,plotCon,2:(end-1)))';
                        if dimIdx==1 || dimIdx==2
                            plot(timeAxis, tmp*X(:,dimIdx),'LineWidth',2,'Color',color*0.5,'LineStyle',lineStyles{plotSet});
                            plot(timeAxis, tmp*X(:,2+dimIdx),'LineWidth',2,'Color',color,'LineStyle',lineStyles{plotSet});
                        else
                            plot(timeAxis, tmp*ciDim,'LineWidth',2,'Color',color*0.5,'LineStyle',lineStyles{plotSet});
                        end
                    end

                    plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);
                    xlim([timeAxis(1), timeAxis(end)]);
                    ylim([-1,1]);
                    plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
                    set(gca,'FontSize',16,'LineWidth',2);

                    if dimIdx==1
                        ylabel(movLabelSets{plotSet}{plotCon});
                    end

                    if plotConIdx==1
                        title(headings{dimIdx});
                    end
                end
            end

            saveas(gcf,[outDir 'prepDynamicsPage_' num2str(pageIdx) '_set_' num2str(plotSet) '.png'],'png');
            currIdx = currIdx + nPerPage;
        end

        %%
        %jPCA
        tw_all = [-49, 149];
        timeStep = binMS/1000;
        timeAxis = (tw_all(1):tw_all(2))*timeStep;
        
        Data = struct();
        timeMS = round(timeAxis*1000);
        for n=1:length(tcList)
            Data(n).A = squeeze(nanmean(datSmooth.(movLabels{n}),1));
            Data(n).times = timeMS;
        end

        jPCA_params.normalize = true;
        jPCA_params.softenNorm = 0;
        jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.meanSubtract = true;
        jPCA_params.numPCs = 6;  % default anyway, but best to be specific

        winStart = [50,100,150,200,250];
        for wIdx=1:length(winStart)
            windowIdx = [winStart(wIdx), winStart(wIdx)+200];

            %short window
            jPCATimes = windowIdx(1):10:windowIdx(2);
            for x = 1:length(jPCATimes)
                [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
                jPCATimes(x) = Data(1).times(minIdx);
            end

            [Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
            phaseSpace(Projections, jPCA_Summary);  % makes the plot
            saveas(gcf, [outDir filesep setNames{blockSetIdx} '_' num2str(windowIdx(1)) '_to_' num2str(windowIdx(2)) '_jPCA_' warpSuffix '.png'],'png');
        end
        close all;
        
        %%
        %population image plot
        nTargsToShow = 8;
        nDimToShow = 5;

        figure('Position',[680   185   692   913]);
        for c=1:nTargsToShow
            concatDat = datSmooth.(movLabels{c});
            concatDat(isnan(concatDat)) = 0;

            reducedDat = zeros(size(concatDat,1), size(concatDat,2), nDimToShow);
            for trialIdx=1:size(concatDat,1)
                reducedDat(trialIdx,:,:) = squeeze(concatDat(trialIdx,:,:))*mPCA_cue.readouts(:,1:nDimToShow);
            end
    
            for dimIdx=1:nDimToShow
                subtightplot(nTargsToShow,nDimToShow,(c-1)*nDimToShow + dimIdx);
                hold on;

                imagesc(timeAxis, 1:size(reducedDat,1), squeeze(reducedDat(:,:,dimIdx)),prctile(reducedDat(:),[2.5, 97.5]));
                axis tight;
                plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);

                cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
                colormap(cMap);

                if dimIdx==1
                    ylabel(movLabels{c},'FontSize',16,'FontWeight','bold');
                end
                if c==1
                    title(['Dimension ' num2str(dimIdx)],'FontSize',16);
                end

                set(gca,'FontSize',16);
                if c==length(movLabels)
                    set(gca,'YTick',[]);
                    xlabel('Time (s)');
                else
                    set(gca,'XTick',[],'YTick',[]);
                end
            end
        end
        
        saveas(gcf,[outDir filesep 'popRaster_' num2str(setNames{blockSetIdx}) '_' warpSuffix '.png'],'png');
        saveas(gcf,[outDir filesep 'popRaster_' num2str(setNames{blockSetIdx}) '_' warpSuffix '.fig'],'fig');
    end %block set
    
    close all;
end %datasets