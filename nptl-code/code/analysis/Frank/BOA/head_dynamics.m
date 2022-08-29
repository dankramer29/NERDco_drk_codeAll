%%
datasets = {
    't5.2018.01.22',{[16 18 20 22],[17 19 21 23],[24 25 26 27 28 29]};
    't5.2018.01.24',{[11 12 13 14],[6 7 8 9 10]};
    't5.2018.03.21',{[9 16 17],[19 20 21 22 23]};
    't5.2019.03.18',{[5 8 10 12 14 16 19 21 23 25 27]};
    't5.2019.05.06',{[23 24 25 26 27 28]}
};
setNamesAll = {{'vertP','vertG','3ring'},...
    {'horzG','IS'},...
    {'horzG2','IS2'},...
    {'2ring'},...
    {'IS3'},...
    };
useWarpedCubes = true;
      
%%
for d=1:size(datasets,1)
    
    setNames = setNamesAll{d};
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

        %%
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
        useTrl = setdiff(useTrl, ~[allR.isSuccessful]);
        
        targCodesUse = targCodes(useTrl);
        [tcList,~,tcReorder] = unique(targCodesUse);
                
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
        %special speed coding
        if strcmp(setNames{blockSetIdx},'IS')
            speedCodes = zeros(length(allR),1);
            for t=1:length(allR)
                speedCodes(t) = allR(t).startTrialParams.speedCode;
            end
            
            tmp = targCodesUse;
            tmp(tmp==1) = 0;
            targCodesUse = tmp+speedCodes(useTrl);
            [tcList,~,tcReorder] = unique(targCodesUse);
        elseif strcmp(setNames{blockSetIdx},'IS2')
            speedCodes = zeros(length(allR),1);
            for t=1:length(allR)
                speedCodes(t) = allR(t).startTrialParams.speedCode;
            end
            
            tmp = targCodesUse;
            targCodesUse = (tmp-1)*3 + speedCodes(useTrl);
            [tcList,~,tcReorder] = unique(targCodesUse);
        elseif strcmp(setNames{blockSetIdx},'IS3')
            speedCodes = zeros(length(allR),1);
            for t=1:length(allR)
                speedCodes(t) = allR(t).startTrialParams.speedCode;
            end
            
            tmp = targCodesUse;
            targCodesUse = tmp + (speedCodes(useTrl)-1)*9;
            [tcList,~,tcReorder] = unique(targCodesUse);
        end
        
        %%
        if strcmp(setNames{blockSetIdx},'vertP')
            movLabels = {'t1','t2','t3','t4','t5','t7','t8','t9','t10','t11'};
            codeSets = {[1 10],[2 9],[3 8],[4 7],[5 6]};
            
            radialDir = [0,1;
                0,-1];
            codeDir = [radialDir; radialDir*0.8; radialDir*0.6; radialDir*0.4; radialDir*0.2];
            
            movLabelSets = {'up','down'};
            timeWindow = [-500,1500];
            
        elseif strcmp(setNames{blockSetIdx},'IS')
            movLabels = {'t1','t2','t3','t4','t5','t6'};
            codeSets = {[1 4],[2 5],[3 6]};
            
            radialDir = [-1,0;
                1,0];
            codeDir = [radialDir; radialDir*0.6; radialDir*0.3];
            
            movLabelSets = {'left','right'};
            timeWindow = [-1500,3000];
            
        elseif strcmp(setNames{blockSetIdx},'IS2')
            movLabels = {'t1','t2','t3','t4','t5','t6','t7','t8','t9','t10','t11','t12','t13','t14','t15','t16','t17','t18'};
            codeSets = {[1 16],[2 17],[3 18],[4 13],[5 14],[6 15],[7 10],[8 11],[9 12]};
            
            radialDir = [-1,0;
                1,0];
            codeDir = repmat(radialDir, 9, 1);
            
            movLabelSets = {'left','right'};
            timeWindow = [-1500,3000];
        
        elseif strcmp(setNames{blockSetIdx},'IS3')
            movLabels = {'t1S','t2S','t3S','t4S','t5S','t6S','t7S','t8S','t1F','t2F','t3F','t4F','t5F','t6F','t7F','t8F'};
            codeSets = {[8 6 4 2 1 3 5 7],[8 6 4 2 1 3 5 7]+8};
            
            radialDir = [1,0;
               1/sqrt(2), 1/sqrt(2);
               0,1;
               -1/sqrt(2),1/sqrt(2);
               -1,0;
               -1/sqrt(2),-1/sqrt(2);
               0,-1;
               1/sqrt(2),-1/sqrt(2);];
            codeDir = [radialDir; radialDir*0.3];
            
            movLabelSets = {'slow','fast'};
            timeWindow = [-1500,3000];
            
        elseif strcmp(setNames{blockSetIdx},'horzG') || strcmp(setNames{blockSetIdx},'horzG2')
            movLabels = {'t1','t2','t3','t4','t5','t7','t8','t9','t10','t11'};
            codeSets = {[1 10],[2 9],[3 8],[4 7],[5 6]};
            
            radialDir = [-1,0;
                1,0];
            codeDir = [radialDir; radialDir*0.8; radialDir*0.6; radialDir*0.4; radialDir*0.2];
            
            movLabelSets = {'left','right'};
            timeWindow = [-500,1500];
            
        elseif strcmp(setNames{blockSetIdx},'vertG')
            movLabels = {'t1','t2','t3','t4','t5','t7','t8','t9','t10','t11'};
            codeSets = {[1 10],[2 9],[3 8],[4 7],[5 6]};
            
            radialDir = [0,1;
                0,-1];
            codeDir = [radialDir; radialDir*0.8; radialDir*0.6; radialDir*0.4; radialDir*0.2];
            
            movLabelSets = {'up','down'};
            timeWindow = [-500,1500];
            
        elseif strcmp(setNames{blockSetIdx},'3ring')
            movLabels = {'t25','t23','t10','t2','t1','t3','t16','t24',...
                         't22','t20','t11','t5','t4','t6','t15','t21',...
                          't19','t17','t12','t8','t7','t9','t14','t18'};
            codeSets = {[24 22 10 2 1 3 15 23],[21 19 11 5 4 6 14 20],[18 16 12 8 7 9 13 17]};
            
            radialDir = [1,0;
               1/sqrt(2), 1/sqrt(2);
               0,1;
               -1/sqrt(2),1/sqrt(2);
               -1,0;
               -1/sqrt(2),-1/sqrt(2);
               0,-1;
               1/sqrt(2),-1/sqrt(2);];
            codeDir = [radialDir; radialDir*0.66; radialDir*0.33];
            timeWindow = [-500,1500];
            
            movLabelSets = {'right','up right','up','up left','left','down left','down','down right'};
            
        elseif strcmp(setNames{blockSetIdx},'2ring')
            movLabels = {'t1','t2','t3','t4','t5','t6','t7','t8','t10','t11','t12','t13','t14','t15','t16','t17'};
            codeSets = {[16 14 7 2 1 3 10 15],[13 11 8 5 4 6 9 12]};
            
            radialDir = [1,0;
               1/sqrt(2), 1/sqrt(2);
               0,1;
               -1/sqrt(2),1/sqrt(2);
               -1,0;
               -1/sqrt(2),-1/sqrt(2);
               0,-1;
               1/sqrt(2),-1/sqrt(2);];
            codeDir = [radialDir; radialDir*0.5];
            timeWindow = [-500,1500];
            
            movLabelSets = {'right','up right','up','up left','left','down left','down','down right'};
        end
        
        binMS = 10;
        twBin = timeWindow/binMS;
        twBin(1) = twBin(1) + 1;
        twBin(2) = twBin(2) - 1;
        
        %%        
        %align the data to go cue
        alignFields = {'timeGoCue'};
        smoothWidth = 0;
        datFields = {'windowsMousePosition','windowsMousePosition_speed'};
        
        alignDat = binAndAlignR( allR(useTrl), timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 1.0;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];

        %%
        %make data cubes for each condition & save
        if strcmp(setNames{blockSetIdx},'IS2')
            smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 6);
        else
            smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);
        end
        
        dat = struct();
        datSmooth = struct();
        for t=1:length(tcList)
            concatDat = triggeredAvg( smoothSpikes, alignDat.eventIdx(targCodesUse==tcList(t)), twBin );
            datSmooth.(movLabels{t}) = concatDat;
            
            concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(targCodesUse==tcList(t)), twBin );
            dat.(movLabels{t}) = concatDat;
        end

        save([outDir filesep 'unwarpedCubes_' setNames{blockSetIdx} '.mat'],'-struct','dat');
        save([outDir filesep 'unwarpedCubes_' setNames{blockSetIdx} '_smooth.mat'],'-struct','datSmooth');
        
        if exist([outDir filesep 'warpedCubes_' setNames{blockSetIdx} '_smooth.mat'],'file') && useWarpedCubes
            %time-warped cubes
            datSmooth = load([outDir filesep 'warpedCubes_' setNames{blockSetIdx} '_smooth.mat']);
            warpSuffix = 'warped';
        else
            warpSuffix = 'raw';
        end
        
        %%
        %make smoothed spikes from the data cube, which might be warped
        [tcList,~,tcReorder] = unique(targCodesUse);
        smoothSpikes_fromCube = alignDat.zScoreSpikes;
        
        for conIdx=1:length(movLabels)
            fieldName = movLabels{conIdx};
            conTrl = find(tcReorder==conIdx);
            for trlIdx=1:length(conTrl)
                globalIdx = alignDat.eventIdx(conTrl(trlIdx));
                loopIdx = (globalIdx+twBin(1)):(globalIdx+twBin(2));
                smoothSpikes_fromCube(loopIdx,:) = datSmooth.(fieldName)(trlIdx,:,:);
            end
        end
        
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
        opts_m.plotCI = false;
        opts_m.nResamples = 10;

        [tcList,~,tcReorder] = unique(targCodesUse);
        mPCA_cue = apply_mPCA_general( smoothSpikes_fromCube, alignDat.eventIdx, ...
            tcReorder, twBin, 0.010, opts_m);
        
        factorCodes = zeros(length(tcReorder),2);
        for t=1:length(tcReorder)
            for setIdx=1:length(codeSets)
                if ismember(tcReorder(t), codeSets{setIdx})
                    distCode = setIdx;
                    [~,dirCode] = ismember(tcReorder(t), codeSets{setIdx});
                end
            end

            factorCodes(t,1) = dirCode;
            factorCodes(t,2) = distCode;
        end
                
        opts_m_twoFactor = opts_m;
        opts_m_twoFactor.plotCI = false;
        opts_m_twoFactor.margGroupings = {{1,[1 3]},{2,[2 3]},{[1 2],[1 2 3]},{3}};
        
        if length(codeSets)>3
            factorCodes = factorCodes(:,[2 1]);
            opts_m_twoFactor.margNames = {'Dist','Dir','Dist x Dir','Time'};
        else
            opts_m_twoFactor.margNames = {'Dir','Dist','Dir x Dist','Time'};
        end
        
        mPCA_twoFactor = apply_mPCA_general( smoothSpikes_fromCube, alignDat.eventIdx, ...
            factorCodes, twBin, 0.010, opts_m_twoFactor);
        
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
        %prep states
        prepVec = squeeze(nanmean(mPCA_cue.featureAverages(:,:,1:50),3))';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

        colors = hsv(8)*0.8;
        if strcmp(setNames{blockSetIdx},'IS3')
            markerSizes = [10 20];
        else
            markerSizes = [20,10,5];
        end
        
        figure
        hold on
        for setIdx=1:length(codeSets)
            codes = codeSets{setIdx};
            for x=1:length(codes)
                plot3(SCORE(codes(x),1), SCORE(codes(x),2), SCORE(codes(x),3), 'o', 'Color', colors(x,:), ...
                    'MarkerFaceColor', colors(x,:), 'MarkerSize', markerSizes(setIdx));
            end
        end
        axis equal;
        
        saveas(gcf,[outDir filesep 'prepStates.png'],'png');
        saveas(gcf,[outDir filesep 'prepStates.svg'],'svg');
        saveas(gcf,[outDir filesep 'prepStates.fig'],'fig');
        
        %%
        %ortho prep analysis
        sCodes = [codeSets{2}];
        idxWindow = [20, 50];
        
        if strcmp(setNames{blockSetIdx},'IS')
            idxWindowPrep = [-90, -50];
            idxWindow = [20, 100];
        else
            idxWindowPrep = [-49, 0];
        end

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

        %Y_prep = [allDir_prep; zeros(size(allDir))];
        %X_prep = [[ones(size(allNeural_prep,1),1), allNeural_prep]; [ones(size(allNeural,1),1), allNeural]];
        Y_prep = [allDir_prep];
        X_prep = [[ones(size(allNeural_prep,1),1), allNeural_prep]];
        
        goodRows = find(all(~isnan(X_prep),2));
        
        [ filts_prep, featureMeans ] = buildLinFilts( Y_prep(goodRows,:), X_prep(goodRows,:), 'ridge', 1e3 );

        decVel = [ones(size(smoothSpikes_fromCube,1),1), smoothSpikes_fromCube]*filts_mov;

        colors = jet(length(sCodes))*0.8;
        figure
        hold on
        for t=1:length(alignDat.eventIdx)
            [LIA,LOCB] = ismember(tcReorder(t),sCodes);
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
        X = orthoPrepSpace( mPCA_cue.featureAverages, 2, 2, 1:40, 70:120 );
        X = [filts_mov(2:end,:), filts_prep(2:end,:)];
        
        mPCA_all = cell(length(codeSets),1);
        for x=1:length(codeSets)
            mPCA_all{x} = mPCA_cue;
            mPCA_all{x}.featureAverages = mPCA_cue.featureAverages(:,codeSets{x},:);
        end

        color = [1 0 0];
        nDims = 4;
        nCon = size(mPCA_all{1}.featureAverages,2);
        timeWindow = twBin;

        if nCon==2
            figPos = [670          52        1307        1053];
        else
            figPos = [73          49         526        1053];
        end
        
        %X = [filts_prep, filts_mov];
        %X = X(2:end,:);
        
        %[Q,R] = qr(X,0);
        %X = Q*0.5;

        headings = {'X','Y','CIS'};

        lineStyles = {':','-','--','-.','-',':','--','-.','-',':','--','-.','-',':','--','-.'};
        timeAxis = (timeWindow(1):timeWindow(2))*0.01;
        ciDim = mPCA_all{1}.readouts(:,6)*0.5;
        nPerPage = min(size(mPCA_all{1}.featureAverages,2),6);
        currIdx = 1:nPerPage;
        nPages = ceil(size(mPCA_all{1}.featureAverages,2)/nPerPage);

        for pageIdx=1:nPages
            figure('Position',figPos);
            for plotConIdx=1:length(currIdx)
                plotCon = currIdx(plotConIdx);
                if plotCon > size(mPCA_all{1}.featureAverages, 2)
                    continue
                end

                for dimIdx = 1:3
                    subplot(nPerPage,3,(plotConIdx-1)*3+dimIdx);
                    hold on;
                    
                    for plotSet=1:length(mPCA_all)
                        tmp = squeeze(mPCA_all{plotSet}.featureAverages(:,plotCon,:))';
                        if dimIdx==1 || dimIdx==2
                            plot(timeAxis, tmp*X(:,dimIdx),'LineWidth',2,'Color',color*0.5,'LineStyle',lineStyles{plotSet});
                            plot(timeAxis, tmp*X(:,2+dimIdx),'LineWidth',2,'Color',color,'LineStyle',lineStyles{plotSet});
                        else
                            %plot(timeAxis, zscore(tmp*X(:,4)),'LineWidth',2,'Color','r','LineStyle',lineStyles{plotSet});
                            %plot(timeAxis, zscore(tmp*ciDim),'LineWidth',2,'Color',color*0.5,'LineStyle',lineStyles{plotSet});
                            plot(timeAxis, tmp*ciDim,'LineWidth',2,'Color',color*0.5,'LineStyle',lineStyles{plotSet});
                        end
                    end

                    plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);
                    xlim([timeAxis(1), timeAxis(end)]);
                    ylim([-1,1]);
                    plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
                    set(gca,'FontSize',16,'LineWidth',2);

                    if plotConIdx==1
                        title(headings{dimIdx});
                    end
                end
            end

            saveas(gcf,[outDir filesep 'prepDynamicsPage_' num2str(pageIdx) '_set_' num2str(plotSet) '.png'],'png');
            currIdx = currIdx + nPerPage;
        end
    end %block set
    
    close all;
end %datasets