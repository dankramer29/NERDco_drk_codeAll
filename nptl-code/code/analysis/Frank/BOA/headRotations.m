datasets = {'t5.2018.01.22',{[16 18 20 22],[17 19 21 23],[16 18 20 22 17 19 21 23],[24 25 26 27 28 29]},{'vertP','vertG','vertAll','3ring'};
    't5.2018.01.24',{[11 12 13 14],[15 16 17],[18]},{'horzG','horzG_OL','radial8_OL'};
    't5.2018.02.19',{[14, 15]},{'radial8_OL'};
    't5.2018.01.31',{[3],[7]},{'overt','imagined'};
    't5.2018.03.21',{[9 16 17],[10 15 18 28],[25 26 27]},{'horzG','horzP','horzG_OL_arm'}};

speedThresh = 0.065;
%speedThresh = 0.045;

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementScale' filesep 'head' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    R = getSTanfordBG_RStruct( sessionPath, unique(horzcat(datasets{d,2}{:})), [], 3.5);
    for t=1:length(R)
        if isempty(R(t).timeGoCue)
            R(t).timeGoCue = 21;
        end
    end
    
    rtIdxAll = zeros(length(R),1);
    for t=1:length(R)
        %RT
        headPos = double(R(t).windowsMousePosition');
        headVel = [0 0; diff(headPos)];
        [B,A] = butter(4, 10/500);
        headVel = filtfilt(B,A,headVel);
        headSpeed = matVecMag(headVel,2)*1000;
        R(t).headSpeed = headSpeed';
        R(t).maxSpeed = max(headSpeed);
    end
    
    tPos = [R.posTarget]';
    tPos = tPos(:,1:2);
    [targList,~,targCodes] = unique(tPos,'rows');
    ms = [R.maxSpeed];
    avgMS = zeros(length(targList),1);
    for t=1:length(targList)
        avgMS(t) = mean(ms(targCodes==t));
    end
    
    for t=1:length(R)
        useThresh = max(avgMS(targCodes(t))*0.2,0.035);
        
        rtIdx = find(R(t).headSpeed>useThresh,1,'first');
        if isempty(rtIdx) || rtIdx<(R(t).timeGoCue+150)
            rtIdx = 21;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTime = rtIdx;
    end
    
    tmp = trlIdx(outerIdx);
    figure
    hold on;
    for t=1:length(tmp)
        loopIdx = (R(tmp(t)).rtTime-500):(R(tmp(t)).rtTime+500);
        plot(R(tmp(t)).headSpeed(loopIdx),'b');
    end
    
    afSet = {'timeGoCue','rtTime','timeGoCue','timeGoCue','timeGoCue'};
    twSet = {[-500,1200],[-740,740],[0 1000],[-500 2000],[-500, 3500]};
    pfSet = {'goCue','moveOnset','goCuePost','all','allLong'};
    
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 0;
        if isfield(R(1),'windowsPC1LeftEye')
            datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','headSpeed'};
        else
            datFields = {'windowsPC1GazePoint','windowsMousePosition','cursorPosition','currentTarget','headSpeed'};
        end
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 1.5);

        for blockSetIdx = 1:length(datasets{d,2})

            %all activity
            %trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]' & ~isnan(rtIdxAll);
            trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]';
            trlIdx = find(trlIdx);

            tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
            [targList, ~, targCodes] = unique(tPos,'rows');
            centerCode = find(all(targList==0,2));
            outerIdx = find(targCodes~=centerCode);
            
            %codes and line styles
            [distList, ~, distCodes] = unique(round(matVecMag(tPos(outerIdx,:),2)),'rows');
            [dirList, ~, dirCodes] = unique(atan2(tPos(outerIdx,2), tPos(outerIdx,1)),'rows');

            nDist = length(distList);
            nDir = length(dirList);
            lineArgs = cell(length(distList), length(dirList));
            if nDir==2
                %colors = jet(1000)*0.8;
                %normDist = round((distList/max(distList))*1000);
                %colors = colors(normDist,:);

                colors = jet(nDist)*0.8;
                ls = {'-',':'};

                for distIdx=1:nDist
                    for dirIdx=1:nDir
                        lineArgs{distIdx,dirIdx} = {'Color',colors(distIdx,:),'LineWidth',2,'LineStyle',ls{dirIdx}};
                    end
                end
            else
                colors = hsv(nDir)*0.8;
                ls = {':','-.','-'};

                for distIdx=1:nDist
                    for dirIdx=1:nDir
                        lineArgs{distIdx,dirIdx} = {'Color',colors(dirIdx,:),'LineWidth',2,'LineStyle',ls{distIdx}};
                    end
                end
            end
            
            %speed profile
            speedConcat = triggeredAvg(alignDat.headSpeed, alignDat.eventIdx(trlIdx(outerIdx)), timeWindow/binMS);
            meanProfile = nanmean(speedConcat);
            meanProfile = [meanProfile(6:end), nan(1,5)];
            
            timeAxis = 0.02*(timeWindow(1):binMS:timeWindow(2))/binMS;
            
            figure
            hold on
            plot(timeAxis, speedConcat');
            plot(timeAxis, nanmean(speedConcat), 'k', 'LineWidth', 2);
            set(gca,'FontSize',16);
            xlabel('Time (s)');
            ylabel('Speed');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_'  pfSet{alignSetIdx} '_speed.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_'  pfSet{alignSetIdx} '_speed.svg'],'svg');
            
            %single factor
            sFactorArgs = lineArgs';
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(outerIdx)), ...
                dirCodes + (distCodes-1)*nDir, timeWindow/binMS, binMS/1000, {'CD','CI'} );
            oneFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
                sFactorArgs(:), {'CD','CI'}, 'sameAxes', meanProfile');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %farthest distance only
            farDistOnly = distCodes==max(distCodes);
            farTrlIdx = trlIdx(outerIdx);
            farTrlIdx = farTrlIdx(farDistOnly);
            
            colors = hsv(nDir)*0.8;
            lineArgs_far = cell(nDir, 1);
            for dirIdx=1:nDir
                lineArgs_far{dirIdx} = {'Color',colors(dirIdx,:),'LineWidth',2};
            end

            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(farTrlIdx), ...
                dirCodes(farDistOnly), timeWindow/binMS, binMS/1000, {'CD','CI'} );
            oneFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
                lineArgs_far, {'CD','CI'}, 'sameAxes', meanProfile');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1facFar_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1facFar_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
            
            if strcmp(pfSet{alignSetIdx},'moveOnset')
                prepWindow = [-600,-400]/binMS;
                movWindow = [0,200]/binMS;
                prepIdx = 37 + (prepWindow(1):prepWindow(2));
                movIdx = 37 + (movWindow(1):movWindow(2));
                nDim = 5;
                axIdx = find(dPCA_out.whichMarg==1);

                tmp = mean(squeeze(dPCA_out.Z(axIdx(1:nDim),:,prepIdx)),3);
                tmp = tmp - mean(tmp,2);
                pMag = mean(matVecMag(tmp,1));

                tmp = mean(squeeze(dPCA_out.Z(axIdx(1:nDim),:,movIdx)),3);
                tmp = tmp - mean(tmp,2);
                mMag = mean(matVecMag(tmp,1));
                
                disp(pMag/mMag);
            end
            
            %two-factor
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(outerIdx)), ...
                [distCodes, dirCodes], timeWindow/binMS, binMS/1000, {'Dist', 'Dir', 'CI', 'Dist x Dir'} );
            close(gcf);

            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'Dist', 'Dir', 'CI', 'Dist x Dir'}, 'sameAxes', meanProfile');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %within-direction single factor dPCA
            msAll = cell(nDir,1);
            for dirIdx=1:nDir
                innerDirIdx = find(dirCodes==dirIdx);
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(outerIdx(innerDirIdx))), ...
                    distCodes(innerDirIdx), timeWindow/binMS, binMS/1000, {'Dist', 'CI'} );
                lineArgs = cell(nDist,1);
                colors = jet(nDist)*0.8;
                for l=1:length(lineArgs)
                    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
                end
                
                [modScales, figHandles, modScalesZero] = oneFactor_dPCA_plot_mag( dPCA_out, (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'Dist','CI'}, meanProfile' );
                msAll{dirIdx} = modScales{1,1};
                %close all;
            end
            
            figure
            hold on
            for dirIdx=1:nDir
                plot(distList, msAll{dirIdx}, '-o', 'LineWidth',2);
            end
            xlabel('Distance');
            ylabel('Component 1 Modulation');
            set(gca,'FontSize',16);
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_modSeale_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_modSeale_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %PSTH                        
%             psthOpts = makePSTHOpts();
%             psthOpts.gaussSmoothWidth = 1.5;
%             psthOpts.neuralData = {zscore(alignDat.zScoreSpikes)};
%             psthOpts.timeWindow = timeWindow/binMS;
%             psthOpts.trialEvents = alignDat.eventIdx(trlIdx(outerIdx));
%             psthOpts.trialConditions = (distCodes-1)*8 + dirCodes;
% 
%             psthOpts.conditionGrouping = {1:24};
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
%             psthOpts.prefix = '3ring';
%             psthOpts.subtractConMean = false;
%             psthOpts.timeStep = binMS/1000;
%             
%             pOut = makePSTH_simple(psthOpts);
            close all;
            
            %behavior
            colors = jet(nDist)*0.8;
            figure
            for codeIdx=1:nDist
                plotIdx = find(distCodes==codeIdx);
                tmp = randperm(length(plotIdx));
                plotIdx = plotIdx(tmp(1:min(length(tmp),5)));
                hold on
                for t=1:length(plotIdx)
                    outerTrlIdx = trlIdx(outerIdx(plotIdx(t)));
                    headPos = double(R(outerTrlIdx).windowsMousePosition');
                    headVel = [0 0; diff(headPos)];
                    [B,A] = butter(4, 10/500);
                    headVel = filtfilt(B,A,headVel);
                    headSpeed = matVecMag(headVel,2)*1000;

                    showIdx = (R(outerTrlIdx).rtTime-200):(R(outerTrlIdx).rtTime+800);
                    showIdx(showIdx>length(headSpeed))=[];
                    if any(showIdx<1)
                        continue;
                    end
                    plot(headSpeed(showIdx),'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_exampleBehavior.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_exampleBehavior.svg'],'svg');
            
            colors = jet(nDist)*0.8;
            figure
            hold on;
            for codeIdx=1:nDist
                plotIdx = find(distCodes==codeIdx);
                concatDat = nan(length(plotIdx),1000);
                for t=1:length(plotIdx)
                    outerTrlIdx = trlIdx(outerIdx(plotIdx(t)));
                    headPos = double(R(outerTrlIdx).windowsMousePosition');
                    headVel = [0 0; diff(headPos)];
                    [B,A] = butter(4, 10/500);
                    headVel = filtfilt(B,A,headVel);
                    headSpeed = matVecMag(headVel,2)*1000;

                    showIdx = (R(outerTrlIdx).rtTime-200):(R(outerTrlIdx).rtTime+800);
                    showIdx(showIdx>length(headSpeed))=[];
                    if any(showIdx<1)
                        continue;
                    end
                    concatDat(t,1:length(showIdx)) = headSpeed(showIdx);
                    
                end
                plot(nanmean(concatDat),'Color',colors(codeIdx,:),'LineWidth',2);
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgBehavior.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgBehavior.svg'],'svg');
            
        end %block set
    end %alignment set
    
end


%%
tmp=load('/Users/frankwillett/Data/Derived/MovementScale/head/t5.2018.01.22/T5_2018_01_22_prep.mat');
for taskCode=1:3
    trlIdx = find(prepTable(:,7)==taskCode);
    tPos = prepTable(trlIdx,5:6);
    [distList, ~, distCodes] = unique(round(matVecMag(tPos,2)));
    
    anova1(prepTable(trlIdx,2), distCodes);
end
