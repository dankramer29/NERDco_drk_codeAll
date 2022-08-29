datasets = {'t5.2018.01.22',{[16 18 20 22],[17 19 21 23],[16 18 20 22 17 19 21 23],[24 25 26 27 28 29]},{'vertP','vertG','vertAll','3ring'}};

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
        R(t).headSpeed = headSpeed;
        
        tPos = R(t).posTarget(1:2);
        if norm(tPos)<=21 && ~all(tPos==0)
            useThresh = 0.025;
        else
            useThresh = speedThresh;
        end
        
        rtIdx = find(headSpeed>useThresh,1,'first');
        if isempty(rtIdx) || rtIdx<(R(t).timeGoCue+150)
            rtIdx = 21;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTime = rtIdx;
    end
    
    smoothWidth = 0;
    datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

    afSet = {'timeGoCue','rtTime'};
    twSet = {[-500,500],[-740,740]};
    pfSet = {'goCue','moveOnset'};
    
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 30;
        datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget'};
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        %prep activity means analysis
        if strcmp(pfSet{alignSetIdx},'goCue')
            alignDat_raw = binAndAlignR( R, timeWindow, binMS, 0, alignFields, datFields );

            nTrials = length(alignDat_raw.bNumPerTrial);
            prepTable = zeros(nTrials,10);
            prepNeuralTable = zeros(nTrials,192);
            prepTable_20 = zeros(nTrials*16, 10);
            prepNeuralTable_20 = zeros(nTrials*16, 192);
            currentIdx = 1:16;

            for t=1:length(alignDat_raw.bNumPerTrial)
                prepTable(t,1) = R(t).rtTime - R(t).timeGoCue;
                prepTable(t,2) = max(R(t).headSpeed);
                prepTable(t,3) = R(t).isSuccessful & ~isnan(rtIdxAll(t));
                prepTable(t,4) = alignDat_raw.bNumPerTrial(t);
                prepTable(t,5:6) = R(t).posTarget(1:2);
                if ismember(alignDat_raw.bNumPerTrial(t),[16 18 20 22])
                    prepTable(t,7) = 1;
                elseif ismember(alignDat_raw.bNumPerTrial(t),[17 19 21 23])
                    prepTable(t,7) = 2;
                elseif ismember(alignDat_raw.bNumPerTrial(t),[24 25 26 27 28 29])
                    prepTable(t,7) = 3;
                end
                prepTable(t,8) = ~all(R(t).posTarget(1:2)==0);

                prepIdx = ((-300)/binMS):0;
                prepIdx = prepIdx + alignDat_raw.eventIdx(t);
                prepNeuralTable(t,:) = sum(alignDat_raw.rawSpikes(prepIdx,:));

                currentIdx = currentIdx + length(prepIdx);
                prepNeuralTable_20(currentIdx,:) = alignDat_raw.rawSpikes(prepIdx,:);
                prepTable_20(currentIdx,:)  = repmat(prepTable(t,:), length(prepIdx), 1);
            end            

            validIdx = prepTable_20(:,3)==1;
            coef = buildLinFilts(prepTable_20(validIdx,5:6), [ones(sum(validIdx),1), prepNeuralTable_20(validIdx,:)], 'standard');
            predVals = [ones(sum(validIdx),1), prepNeuralTable_20(validIdx,:)]*coef;

            for blockSetIdx = 1:3
                validIdx = prepTable(:,3)==1 & prepTable(:,7)==blockSetIdx;
                predVals_avg = ([ones(sum(validIdx),1), prepNeuralTable(validIdx,:)] * coef)/16;

                coef2 = buildLinFilts(prepTable(validIdx,5:6), [ones(length(predVals_avg),1), predVals_avg], 'standard');
                predVals_avg = [ones(length(predVals_avg),1), predVals_avg]*coef2;

                tPos = round(prepTable(validIdx,5:6));
                [targList, ~, targCodes] = unique(tPos,'rows');
                centerCode = find(all(targList==0,2));
                outerIdx = find(targCodes~=centerCode);

                plotIdx = setdiff(1:length(targList), centerCode);
                plotTL = targList(plotIdx,:);
                [distList, ~, distCodes] = unique(round(matVecMag(plotTL,2)),'rows');
                [dirList, ~, dirCodes] = unique(atan2(plotTL(:,2), plotTL(:,1)),'rows');

                if length(dirList)==2
                    colors = [flipud(jet(5)*0.8); jet(5)*0.8];
                    markerTypes = {'o','o','o','o','o','<','<','<','<','<'};
                else
                    cPall = hsv(8)*0.8;
                    mTypePall = {'o','<','s'};
                    colors = zeros(length(plotTL),3);
                    markerTypes = cell(length(plotTL),1);
                    for t=1:length(plotTL)
                        colors(t,:) = cPall(dirCodes(t,:),:);
                        markerTypes{t} = mTypePall{distCodes(t)};
                    end
                end

                figure
                hold on
                for t=1:length(plotIdx)
                    trlIdx = find(targCodes==plotIdx(t));
                    plot(mean(predVals_avg(trlIdx,1)), mean(predVals_avg(trlIdx,2)), 'Marker', markerTypes{t}, 'MarkerFaceColor',colors(t,:),...
                        'MarkerEdgeColor',colors(t,:));
                end
                axis equal;

                saveas(gcf,[outDir filesep '2dprep_means_' num2str(blockSetIdx) '.png'],'png');
                saveas(gcf,[outDir filesep '2dprep_means_' num2str(blockSetIdx) '.svg'],'svg');
            end
            
            %save table for sharing
            useIdx = prepTable(:,3)==1 & prepTable(:,8)==1;
            prepTable = prepTable(useIdx,:);
            prepNeuralTable = prepNeuralTable(useIdx,:);
            
            useIdx = prepTable_20(:,3)==1 & prepTable_20(:,8)==1;
            prepTable_20 = prepTable_20(useIdx,:);
            prepNeuralTable_20 = prepNeuralTable_20(useIdx,:);
            
            prepTableFields = {'rt','maxSpeed','isSuccessful','blockNum','targX','targY','taskCode','isOuterReach'};
            taskCodes = {'vert_precise','vert_gross','3ring'};
            
            save([outDir filesep 'T5_2018_01_22_prep.mat'],'prepTable','prepNeuralTable','prepTable_20','prepNeuralTable_20','prepTableFields','taskCodes');
        end %prep 2D plots
        
        for blockSetIdx = 1:length(datasets{d,2})

            %all activity
            trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]' & ~isnan(rtIdxAll);
            trlIdx = find(trlIdx);

            tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+5,1:2);
            [targList, ~, targCodes] = unique(tPos,'rows');
            centerCode = find(all(targList==0,2));
            outerIdx = find(targCodes~=centerCode);

            [distList, ~, distCodes] = unique(round(matVecMag(tPos(outerIdx,:),2)),'rows');
            [dirList, ~, dirCodes] = unique(atan2(tPos(outerIdx,2), tPos(outerIdx,1)),'rows');

            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(outerIdx)), ...
                [distCodes, dirCodes], timeWindow/binMS, binMS/1000, {'Dist', 'Dir', 'CI', 'Dist x Dir'} );
            close(gcf);

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

            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'Dist', 'Dir', 'CI', 'Dist x Dir'}, 'sameAxes');
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
                    lineArgs, {'Dist','CI'}, [] );
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
            
            %behavior
            colors = jet(nDist)*0.8;
            figure
            for codeIdx=1:nDist
                plotIdx = find(distCodes==codeIdx);
                tmp = randperm(length(plotIdx));
                plotIdx = plotIdx(tmp(1:5));
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
