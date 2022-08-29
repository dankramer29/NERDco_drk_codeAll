%%
datasets = {
    't5.2018.02.19',{[28],[29],[28 29]},{'W1','W2','W12'},[28];
    't5.2018.02.21',{[16],[17],[16 17],[21],[22],[21 22]},{'W1h','W2h','W12h','W3j','W4j','W34j'},[22];
    't5.2018.03.05',{[6],[7],[6 7]},{'W1','W2','W12'},[6]
    't5.2018.03.09',{[6],[7],[6 7]},{'W1','W2','W12'},[6]};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Wia_movCue' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = unique(horzcat(datasets{d,2}{:}));
    if strcmp(datasets{d,1}(1:2),'t5')
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
    else
        movField = 'glove';
        filtOpts.filtFields = {'glove'};
    end
    filtOpts.filtCutoff = 10/500;
    [ R, stream ] = getStanfordRAndStream( sessionPath, bNums, 3.5, datasets{d,4}, filtOpts );
    
    an = [];
    for s=1:length(stream)
        an = [an; [stream{s}.spikeRaster, stream{s}.spikeRaster2]];
    end
    allNeural = gaussSmooth_fast(double(an),60);
    
    wmp = [];
    for s=1:length(stream)
        tmpZero = zeros(stream{s}.continuous.clock(1)-1,size(stream{s}.continuous.windowsMousePosition,2));
        wmp = [wmp; [tmpZero; stream{s}.continuous.windowsMousePosition]];
    end
    [B,A] = butter(4,10/500);
    wmp = filtfilt(B,A,wmp);
    wmp_speed = matVecMag(diff(wmp),2);
    
    if isfield(stream{1}.continuous,'windowsPC1GazePoint')
        gp = [];
        for s=1:length(stream)
            tmpZero = zeros(stream{s}.continuous.clock(1)-1,size(stream{s}.continuous.windowsPC1GazePoint,2));
            gp = [gp; [tmpZero; double(stream{s}.continuous.windowsPC1GazePoint)]];
        end
        [B,A] = butter(4,10/500);
        gp = filtfilt(B,A,gp);
    else
        gp = zeros(size(wmp));
    end
    
    vidDir = [paths.dataPath filesep 'Derived' filesep 'WatchVideoAlignment' filesep datasets{d,1}];
    allCues = [];
    allCueTimes = [];
    bNumPerTrial = [];
    globalIdx = 0;
    for s=1:length(stream)
        tmp = load([vidDir filesep num2str(bNums(s)) '.mat']);
        allCues = [allCues; tmp.mc];
        allCueTimes = [allCueTimes; round(tmp.mct_xpc+globalIdx)];
        bNumPerTrial = [bNumPerTrial; repmat(bNums(s),length(tmp.mc),1)];
        globalIdx = globalIdx + size(stream{s}.spikeRaster,1);
    end
    
    binMS=20;
    binNeural = allNeural(1:20:end,:);
    binCueTimes = round(allCueTimes/20);
    binWMP = wmp(1:20:end,:);
    binGP = gp(1:20:end,:);
    binWMP_speed = wmp_speed(1:20:end);
    
    twSet = {[-1500,3000]};
    pfSet = {'goCue'};
    movLegend = {'Down','Left','Right','Up'};
    
    for alignSetIdx=1:length(pfSet)
        timeWindow = twSet{alignSetIdx};

        for blockSetIdx = 1:length(datasets{d,2})
            
            trlIdx = ismember(bNumPerTrial, datasets{d,2}{blockSetIdx});
            trlIdx = find(trlIdx);
            movCues = allCues(trlIdx);
            codeList = unique(movCues);
                        
            %single-factor
            dPCA_out = apply_dPCA_simple( binNeural, binCueTimes(trlIdx), ...
                movCues, timeWindow/binMS, binMS/1000, {'CD','CI'} );
            lineArgs = cell(length(codeList),1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'CD','CI'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        
            %%
            rejectThresh = 0.15*10e-4;
            cd = triggeredAvg(binWMP_speed, binCueTimes(trlIdx), timeWindow/binMS);
            highSpeedTrl = (any(cd>rejectThresh,2));
            
            bField = 'goCue';
            colors = jet(length(codeList))*0.8;
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);

                hold on
                for t=1:length(plotIdx)
                    loopIdx = (binCueTimes(plotIdx(t))-75):(binCueTimes(plotIdx(t))+150);
                    loopIdx(loopIdx>length(binWMP_speed))=[];
                    plot(binWMP_speed(loopIdx),'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
                cd = triggeredAvg(binWMP_speed, binCueTimes(plotIdx), timeWindow/binMS);
                hold on
                plot(nanmean(cd),'Color',colors(codeIdx,:));
            end
            legend(mat2stringCell(1:length(codeList)));
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
                cd = triggeredAvg(binGP, binCueTimes(plotIdx), timeWindow/binMS);
                tmpMean = squeeze(nanmean(cd,1));
                traj = tmpMean;

                hold on
                plot(traj(:,1),traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
            end
            legend(movLegend);
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgEyeTraj_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgEyeTraj_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
                cd = triggeredAvg(diff(binWMP), binCueTimes(plotIdx), timeWindow/binMS);
                tmpMean = squeeze(nanmean(cd,1));
                traj = cumsum(tmpMean);

                hold on
                plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
            end
            legend(movLegend);
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %anova for the three time periods            
            pNames = {'Delay','Beep1','Beep2'};
            periodTime = {[-1500,0],[0,1500],[1500,3000]};
            dimTitles = {'X','Y'};
            figure('Position',[322         596        1229         502]);
            for p=1:length(periodTime)
                binIdx = (round(periodTime{p}(1)/binMS):round(periodTime{p}(2)/binMS)) - timeWindow(1)/binMS;
                binIdx(binIdx<1)=[];
                
                for dimIdx=1:2
                    tmpDat = [];
                    for codeIdx=1:length(codeList)
                        plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
                        cd = triggeredAvg(diff(binWMP), binCueTimes(plotIdx), timeWindow/binMS);
                        
                        tmp = mean(squeeze(cd(:,binIdx,dimIdx)),2);
                        tmpDat = [tmpDat; [tmp, repmat(codeIdx,length(tmp),1)]];
                    end
                    
                    pVal = anova1(tmpDat(:,1), tmpDat(:,2), 'off');
                    subplot(2,3,(dimIdx-1)*3+p);
                    boxplot(tmpDat(:,1), tmpDat(:,2));
                    set(gca,'XTickLabel',movLegend);
                    title([pNames{p} ' ' dimTitles{dimIdx} ' p=' num2str(pVal)]);
                    set(gca,'FontSize',16);
                end
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_anova_.png'],'png');

            close all;
        end %block set
        
        if strcmp(datasets{d,1},'t5.2018.02.19')
            
            %eIdx = find(ismember(alignDat.bNumPerTrial, [18 22 24]));
            eIdx = find(ismember(alignDat.bNumPerTrial, [20]));
            iIdx = find(ismember(alignDat.bNumPerTrial, [23 25]));
            allIdx = [eIdx; iIdx];
            
            %end
            movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
            codeList = unique(movCues);
            
            movType = zeros(length(allIdx),1);
            movType(1:length(eIdx)) = 0;
            movType((length(eIdx)+1):end) = 1;
            
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx), ...
                [movType, movCues], timeWindow/binMS, binMS/1000, {'IM', 'Dir', 'CI', 'IM x Dir'} );
            
        
            lineArgs = cell(2,4);
            colors = jet(4)*0.8;
            ls = {'-',':'};
            for x=1:2
                for c=1:4
                    lineArgs{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
                end
            end
            
            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'IM', 'Dir', 'CI', 'IM x Dir'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        end
    end %alignment set
end
