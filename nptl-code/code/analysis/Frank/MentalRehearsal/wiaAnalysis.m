datasets = {'t5.2018.01.31',{[3],[7],[10 11],[3 7]},{'A','I','WIA','I_vs_A'};
    't5.2018.02.09',{[4 8],[6 9],[7 11],[4 6 7 8 9 11],[4 6 8 9],[6 7 9 11],[5],[14 15]},{'A','I','W','WIA','I_vs_A','I_vs_W','VMI','VMR'}
    't5.2018.02.19',{[0 1 7],[2],[3],[8],[3 8],[4 9],[5 12],[6 13],[14 15],[16]},{'E','I1','I2','I3','I23','INC','W','Micro','Joy8','Joy1'}
    't5.2018.02.21',{[7],[28 29],[32 33],[36]},{'Eye','I_lag1','I_lag2','E'}};

speedThresh = 0.065;
%speedThresh = 0.045;

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Wia' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    blockList = unique(horzcat(datasets{d,2}{:}));
    [ cellR, stream ] = getStanfordRAndStream( sessionPath, blockList, 3.5, blockList(1), filtOpts );
    
    R = []; 
    for x=1:length(cellR)
        for t=1:length(cellR{x})
            cellR{x}(t).blockNum=blockList(x);
        end
        R = [R, cellR{x}];
    end
    
    for t=1:length(R)
        if isempty(R(t).timeGoCue)
            R(t).timeGoCue = 21;
        end
        R(t).windowsMousePosition_speed = R(t).windowsMousePosition_speed * 1000;
        R(t).maxSpeed = max(R(t).windowsMousePosition_speed);
    end
    
    rtIdxAll = zeros(length(R),1);
    
    tPos = [R.posTarget]';
    tPos = tPos(:,1:2);
    [targList,~,targCodes] = unique(tPos,'rows');
    ms = [R.maxSpeed];
    avgMS = zeros(length(targList),1);
    for t=1:length(targList)
        avgMS(t) = mean(ms(targCodes==t));
    end
    
    for t=1:length(R)
        useThresh = max(avgMS(targCodes(t))*0.1,0.035);
        
        rtIdx = find(R(t).windowsMousePosition_speed > useThresh,1,'first');
        if isempty(rtIdx) || rtIdx<(R(t).timeGoCue+150)
            rtIdx = 21;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTime = rtIdx;
    end
    
    afSet = {'rtTime','timeGoCue','trialLength','timeGoCue'};
    twSet = {[-740,740],[-1500 5000],[-3000 3000],[-1000 2000]};
    pfSet = {'movStart','goCueVeryLong','trialEnd','goCue'};
    
    allCodes = zeros(length(R),1);
    for t=1:length(R)
        allCodes(t) = R(t).startTrialParams.wiaCode;
    end
    
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 60;
        if isfield(R(1),'windowsPC1GazePoint')
            eyeField = 'windowsPC1GazePoint';
        else
            eyeField = 'windowsPC1LeftEye';
        end
        datFields = {'windowsMousePosition_speed','windowsMousePosition','cursorPosition','currentTarget',eyeField};
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        %for blockSetIdx = 1:length(datasets{d,2})
        for blockSetIdx = 1:length(datasets{d,2})

            %only attempted movements can be aligned on RT
            if strcmp(afSet{alignSetIdx},'rtTime') && ~any(strcmp(datasets{d,3}{blockSetIdx},{'A','E'}))
                continue;
            end
            
            %all activity
            trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]';
            %trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}) & [R.isSuccessful]';
            trlIdx = find(trlIdx);

            if strcmp(afSet{alignSetIdx},'trialLength')
                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)-10,1:2);
            else
                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
            end
            if strcmp(datasets{d,3}{blockSetIdx},{'Joy1'})
                tPattern = [0 0; 409 0];
                targCodes = getTargetCode( tPos, tPattern  );
                outerIdx = 1:length(targCodes);             
            elseif strcmp(datasets{d,3}{blockSetIdx},{'Eye'})
                tPattern = ringPattern(1, 8)*409*(1/3);
                targCodes = getTargetCode( tPos, tPattern );
                outerIdx = find(~all(tPos==0,2));
            elseif strcmp(datasets{d,1},'t5.2018.01.31')
                tPattern = [ringPattern(1, 4)*409; ringPattern(1, 4)*409/3];
                targCodes = getTargetCode( tPos, tPattern );
                outerIdx = find(~all(tPos==0,2));                
            else
                tPattern = ringPattern(1, 8)*409;
                targCodes = getTargetCode( tPos, tPattern );
                outerIdx = find(~all(tPos==0,2));
            end
            trlIdx = trlIdx(outerIdx);
            targCodes = targCodes(outerIdx);
            
            %single-factor
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
                targCodes, timeWindow/binMS, binMS/1000, {'CD','CI'} );
            lineArgs = cell(length(unique(targCodes)),1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'CD','CI'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
                       
            %movement
            bField = 'timeGoCue';
            codeList = unique(targCodes);
            colors = jet(length(codeList))*0.8;
            timeAxis = (binMS/1000)*((timeWindow(1)/binMS):(timeWindow(2)/binMS));
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(targCodes==codeList(codeIdx));

                hold on
                for t=1:length(plotIdx)
                    outerTrlIdx = plotIdx(t);
                    loopIdx = alignDat.eventIdx(outerTrlIdx) + ((timeWindow(1)/binMS):(timeWindow(2)/binMS));
                    if any(loopIdx<1)
                        continue;
                    end
                    mouseSpeed = alignDat.windowsMousePosition_speed(loopIdx);
                    plot(timeAxis, mouseSpeed,'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            plot([0 0],get(gca,'YLim'),'--k');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_allSpeedProfiles_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_allSpeedProfiles_' pfSet{alignSetIdx} '.svg'],'svg');

            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(targCodes==codeList(codeIdx));
                cd = triggeredAvg(alignDat.windowsMousePosition_speed, alignDat.eventIdx(plotIdx), timeWindow/binMS);
                hold on
                plot(timeAxis, nanmean(cd),'Color',colors(codeIdx,:), 'LineWidth', 2);
            end
            legend(mat2stringCell(1:length(codeList)));
            plot([0 0],get(gca,'YLim'),'--k');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeedProfiles_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeedProfiles_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(targCodes==codeList(codeIdx));
                cd = triggeredAvg(diff(alignDat.windowsMousePosition), alignDat.eventIdx(plotIdx), timeWindow/binMS);
                tmpMean = squeeze(nanmean(cd,1));
                traj = cumsum(tmpMean(2:(end-1),:));

                hold on
                plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
                plot(traj(end,1), traj(end,2),'o','Color',colors(codeIdx,:),'LineWidth',2);
            end
            axis equal;
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:size(tPattern,1)
                hold on
                plot(tPattern(codeIdx,1), tPattern(codeIdx,2),'o','Color',colors(codeIdx,:),'MarkerFaceColor',colors(codeIdx,:),'LineWidth',2);
            end
            axis equal;
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_targLegend_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_targLegend_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure('Position',[56         649        1434         287]);
            subplot(1,3,1);
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(targCodes==codeList(codeIdx));
                cd = triggeredAvg((alignDat.(eyeField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
                tmpMean = squeeze(nanmean(cd,1));
                traj = tmpMean;

                hold on
                plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
                plot(traj(end,1), traj(end,2),'o','Color',colors(codeIdx,:),'LineWidth',2);
            end
            axis equal;
            
            for dimIdx=1:2
                subplot(1,3,1+dimIdx);
                hold on
                for codeIdx=1:length(codeList)
                    plotIdx = trlIdx(targCodes==codeList(codeIdx));
                    cd = triggeredAvg((alignDat.(eyeField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
                    tmpMean = squeeze(nanmean(cd,1));
                    traj = tmpMean;

                    plot(traj(:,dimIdx), 'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgGazeTraj_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgGazeTraj_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %anova for the three time periods
            if strcmp(pfSet{alignSetIdx},'goCue')
                pNames = {'Delay','Move'};
                periodTime = {[-1000,0],[0,2000]};
                dimTitles = {'X','Y'};
                figure('Position',[322         596        1229         502]);
                for p=1:length(periodTime)
                    binIdx = (round(periodTime{p}(1)/binMS):round(periodTime{p}(2)/binMS)) - timeWindow(1)/binMS;
                    binIdx(binIdx<1)=[];

                    for dimIdx=1:2
                        tmpDat = [];
                        for codeIdx=1:length(codeList)
                            plotIdx = trlIdx(targCodes==codeList(codeIdx));
                            cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);

                            tmp = mean(squeeze(cd(:,binIdx,dimIdx)),2);
                            tmpDat = [tmpDat; [tmp, repmat(codeIdx,length(tmp),1)]];
                        end

                        pVal = anova1(tmpDat(:,1), tmpDat(:,2), 'off');
                        subplot(2,2,(dimIdx-1)*2+p);
                        boxplot(tmpDat(:,1), tmpDat(:,2));
                        %set(gca,'XTickLabel',codeLegend);
                        title([pNames{p} ' ' dimTitles{dimIdx} ' p=' num2str(pVal)]);
                        set(gca,'FontSize',16);
                    end
                end
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_anova_.png'],'png');
            end
            
            close all;
            
            %%
%             psthOpts = makePSTHOpts();
%             psthOpts.gaussSmoothWidth = 0;
%             psthOpts.neuralData = {zscore(alignDat.zScoreSpikes)};
%             psthOpts.timeWindow = timeWindow/binMS;
%             psthOpts.trialEvents = alignDat.eventIdx(trlIdx(outerIdx));
%             psthOpts.trialConditions = targCodes(outerIdx);
% 
%             psthOpts.conditionGrouping = {1:length(codeList)};
%             tmp = lineArgs';
%             tmp = tmp(:);
% 
%             psthOpts.lineArgs = tmp;
%             psthOpts.plotsPerPage = 10;
%             psthOpts.plotDir = [outDir filesep datasets{d,3}{blockSetIdx} '_PSTH' filesep];
%             featLabels = cell(192,1);
%             for f=1:192
%                 featLabels{f} = ['C' num2str(f)];
%             end
%             psthOpts.featLabels = featLabels;
%             psthOpts.prefix = [datasets{d,3}{blockSetIdx} '_' pfSet{alignSetIdx}];
%             psthOpts.subtractConMean = false;
%             psthOpts.timeStep = binMS/1000;
%             
%             pOut = makePSTH_simple(psthOpts);
%             close all; 
            
            %%
            %two-factor
            if length(unique(allCodes(trlIdx)))==1 || any(strcmp(datasets{d,3}{blockSetIdx},{'A','I','W'}))
                continue;
            end
            
            [distList, ~, distCodes] = unique(matVecMag(tPos(outerIdx,:),2),'rows');
            [dirList, ~, dirCodes] = unique(atan2(tPos(outerIdx,2), tPos(outerIdx,1)),'rows');
            
            if strcmp(datasets{d,3}{blockSetIdx},'WIA')
                if strcmp(datasets{d,1},'t5.2018.01.31')
                    dirToUse = [1 3];
                else
                    dirToUse = [1 5];
                end
            else
                if strcmp(datasets{d,1},'t5.2018.01.31')
                    dirToUse = 1:4;
                else
                    dirToUse = 1:8;
                end
            end
            useIdx = ismember(dirCodes,dirToUse);
            useCodes = allCodes;
            useCodes(useCodes==3)=0;
            
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                [useCodes(trlIdx(useIdx)), dirCodes(useIdx)], timeWindow/binMS, binMS/1000, {'WIA', 'Dir', 'CI', 'WIA x Dir'} );
            close(gcf);

            dirList = dirToUse;
            wiaList = unique(useCodes(trlIdx));
            nWia = length(wiaList);
            
            if nWia==2
                nDir = length(dirList);
                lineArgs = cell(nWia, length(dirList));
                colors = hsv(nDir)*0.8;
                ls = {'-',':'};

                for wiaIdx=1:nWia
                    for dirIdx=1:nDir
                        lineArgs{wiaIdx,dirIdx} = {'Color',colors(dirIdx,:),'LineWidth',2,'LineStyle',ls{wiaIdx}};
                    end
                end
            else
                nDir = length(dirList);
                lineArgs = cell(nWia, length(dirList));
                colors = hsv(nDir)*0.8;
                ls = {'-',':','-.'};

                for wiaIdx=1:nWia
                    for dirIdx=1:nDir
                        lineArgs{wiaIdx,dirIdx} = {'Color',colors(dirIdx,:),'LineWidth',2,'LineStyle',ls{wiaIdx}};
                    end
                end
            end

            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'Wia', 'Dir', 'CI', 'Wia x Dir'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
         
            close all;
        end %block set
    end %alignment set
    
end
