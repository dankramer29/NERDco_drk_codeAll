datasets = {'t5.2018.03.21',{[20 21 22 23]},{'IS'}};

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
        useThresh = max(avgMS(targCodes(t))*0.1,0.035);
        
        rtIdx = find(R(t).headSpeed(1001:end)>useThresh,1,'first');
        if isempty(rtIdx)
            rtIdx = 21;
            rtIdxAll(t) = nan;
        else
            rtIdx = rtIdx + 1000;
            if rtIdx<(R(t).timeGoCue+150)
                rtIdxAll(t) = nan;
            else
                rtIdxAll(t) = rtIdx;
            end
        end       
        R(t).rtTime = rtIdxAll(t);
        if isnan(R(t).rtTime)
            R(t).rtTime = 21;
        end
    end
    
    TP = [R.posTarget]';
    outerIdx = ~all(TP==0,2);
    
    smoothWidth = 0;
    datFields = {'windowsPC1GazePoint','windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

    afSet = {'timeGoCue','rtTime','timeGoCue',};
    twSet = {[-500,500],[-1000,2000],[-1500 3000]};
    pfSet = {'goCue','moveOnset','goCueLonger'};
    
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 60;
        datFields = {'windowsPC1GazePoint','windowsMousePosition','cursorPosition','currentTarget','headSpeed'};
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        for blockSetIdx = 1:length(datasets{d,2})

            %all activity
            if strcmp(datasets{d,3}{blockSetIdx},'ISBCI')
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]' & outerIdx;
            else
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]' & ~isnan(rtIdxAll) & outerIdx;
            end
            trlIdx = find(trlIdx);

            tPos = TP(trlIdx,1:2);
            [targList, ~, targCodes] = unique(tPos,'rows');
            
            speedCodes = zeros(length(R),1);
            for t=1:length(R)
                speedCodes(t) = R(t).startTrialParams.speedCode;
            end
            speedList = unique(speedCodes);
            speedCodes = speedCodes(trlIdx);

            [distList, ~, distCodes] = unique(round(matVecMag(tPos(:,:),2)),'rows');
            [dirList, ~, dirCodes] = unique(atan2(tPos(:,2), tPos(:,1)),'rows');
            
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
            
            for innerDistCode=1:3
                innerIdx = distCodes==innerDistCode & speedCodes>0;
                speedConcat = triggeredAvg(alignDat.headSpeed, alignDat.eventIdx(trlIdx(innerIdx)), timeWindow/binMS);
                meanProfile = nanmean(speedConcat);
                meanProfile = [meanProfile(6:end), zeros(1,5)];
                
                %two-factor
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(innerIdx)), ...
                    [speedCodes(innerIdx), dirCodes(innerIdx)], timeWindow/binMS, binMS/1000, {'Speed', 'Dir', 'CI', 'Speed x Dir'} );
                close(gcf);

                [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'Speed', 'Dir', 'CI', 'Speed x Dir'}, 'sameAxes', meanProfile');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
            end
            
            dPCA_initial = cell(3,1);
            for innerSpeedCode=1:3
                innerIdx = speedCodes==innerSpeedCode;
                speedConcat = triggeredAvg(alignDat.headSpeed, alignDat.eventIdx(trlIdx(innerIdx)), timeWindow/binMS);
                meanProfile = nanmean(speedConcat);
                meanProfile = [meanProfile(6:end), zeros(1,5)];
                
                %two-factor
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(innerIdx)), ...
                    [distCodes(innerIdx), dirCodes(innerIdx)], timeWindow/binMS, binMS/1000, {'Dist', 'Dir', 'CI', 'Dist x Dir'} );
                close(gcf);

                [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'Dist', 'Dir', 'CI', 'Dist x Dir'}, 'sameAxes', meanProfile');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
                
                dPCA_initial{innerSpeedCode} = dPCA_out;
            end
            
            %cross
            for innerSpeedCode=1:3
                innerIdx = speedCodes(trlIdx)==innerSpeedCode;
                speedConcat = triggeredAvg(alignDat.headSpeed, alignDat.eventIdx(trlIdx(innerIdx)), timeWindow/binMS);
                meanProfile = nanmean(speedConcat);
                meanProfile = [meanProfile(6:end), zeros(1,5)];
                
                %two-factor
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(innerIdx)), ...
                    [distCodes(innerIdx), dirCodes(innerIdx)], timeWindow/binMS, binMS/1000, {'Dist', 'Dir', 'CI', 'Dist x Dir'} );
                close(gcf);
                
                crossIdx = 2;
                dPCA_out.whichMarg = dPCA_initial{crossIdx}.whichMarg;
                for axIdx=1:20
                    for conIdx=1:size(dPCA_simul.Z,2)
                        dPCA_out.Z(axIdx,conIdx,:) = dPCA_initial{crossIdx}.W(:,axIdx)' * squeeze(dPCA_out.featureAverages(:,conIdx,:));
                    end
                end       

                [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'Dist', 'Dir', 'CI', 'Dist x Dir'}, 'sameAxes', meanProfile');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
                
                dPCA_initial{innerSpeedCode} = dPCA_out;
            end
            
 
            
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
                [speedCodes(trlIdx), dirCodes], timeWindow/binMS, binMS/1000, {'Speed', 'Dir', 'CI', 'Speed x Dir'} );
            close(gcf);

            nSpeed = length(speedList);
            nDir = length(dirList);
            lineArgs = cell(length(speedList), length(dirList));
            if nDir==2
                %colors = jet(1000)*0.8;
                %normDist = round((distList/max(distList))*1000);
                %colors = colors(normDist,:);

                colors = jet(nSpeed)*0.8;
                ls = {'-',':'};

                for distIdx=1:nSpeed
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
                lineArgs, {'Speed', 'Dir', 'CI', 'Speed x Dir'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %within-direction single factor dPCA
%             msAll = cell(nDir,1);
%             for dirIdx=1:nDir
%                 innerDirIdx = find(dirCodes==dirIdx);
%                 dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(outerIdx(innerDirIdx))), ...
%                     speedCodes(trlIdx(outerIdx(innerDirIdx))), timeWindow/binMS, binMS/1000, {'Speed', 'CI'} );
%                 lineArgs = cell(nSpeed,1);
%                 colors = jet(nSpeed)*0.8;
%                 for l=1:length(lineArgs)
%                     lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
%                 end
%                 
%                 [modScales, figHandles, modScalesZero] = oneFactor_dPCA_plot_mag( dPCA_out, (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
%                     lineArgs, {'Dist','CI'}, [] );
%                 msAll{dirIdx} = modScales{1,1};
%                 %close all;
%             end
%             
%             figure
%             hold on
%             for dirIdx=1:nDir
%                 plot(distList, msAll{dirIdx}, '-o', 'LineWidth',2);
%             end
%             xlabel('Distance');
%             ylabel('Component 1 Modulation');
%             set(gca,'FontSize',16);
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_modScale_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_modScale_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %behavior
            if strcmp(datasets{d,3}{blockSetIdx},'ISBCI')
                bField = 'timeGoCue';
            else
                bField = 'rtTime';
            end
            
            colors = jet(nSpeed)*0.8;
            figure
            for codeIdx=1:nSpeed
                plotIdx = find(speedCodes(trlIdx)==codeIdx);
                tmp = randperm(length(plotIdx));
                plotIdx = plotIdx(tmp(1:5));
                hold on
                for t=1:length(plotIdx)
                    outerTrlIdx = trlIdx(plotIdx(t));
                    headPos = double(R(outerTrlIdx).windowsMousePosition');
                    headVel = [0 0; diff(headPos)];
                    [B,A] = butter(4, 10/500);
                    headVel = filtfilt(B,A,headVel);
                    headSpeed = matVecMag(headVel,2)*1000;

                    showIdx = (R(outerTrlIdx).(bField)-200):(R(outerTrlIdx).(bField)+800);
                    showIdx(showIdx>length(headSpeed))=[];
                    plot(headSpeed(showIdx),'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_exampleBehavior.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_exampleBehavior.svg'],'svg');
            
            colors = jet(nSpeed)*0.8;
            figure
            hold on;
            for codeIdx=1:nSpeed
                plotIdx = find(speedCodes(trlIdx)==codeIdx);
                concatDat = nan(length(plotIdx),1000);
                for t=1:length(plotIdx)
                    outerTrlIdx = trlIdx((plotIdx(t)));
                    headPos = double(R(outerTrlIdx).windowsMousePosition');
                    %headPos = double(R(outerTrlIdx).cursorPosition(1:2,:)');
                    headVel = [0 0; diff(headPos)];
                    [B,A] = butter(4, 10/500);
                    headVel = filtfilt(B,A,headVel);
                    headSpeed = matVecMag(headVel,2)*1000;

                    showIdx = (R(outerTrlIdx).(bField)-200):(R(outerTrlIdx).(bField)+800);
                    %showIdx = R(outerTrlIdx).timeGoCue:(R(outerTrlIdx).timeGoCue+999);
                    showIdx(showIdx>length(headSpeed))=[];
                    concatDat(t,1:length(showIdx)) = headSpeed(showIdx);
                end
                plot(nanmean(concatDat),'Color',colors(codeIdx,:),'LineWidth',2);
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgBehavior.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgBehavior.svg'],'svg');
            
            close all;
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
