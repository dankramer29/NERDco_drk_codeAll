datasets = {'t5.2018.01.19',{[11]},{'eye'}};
%speedThresh = 0.065;
speedThresh = 0.035;

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Eye' filesep datasets{d,1}];
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
        useThresh = speedThresh;
        
        rtIdx = find(R(t).headSpeed>useThresh,1,'first');
        if isempty(rtIdx)
            rtIdx = 21;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTime = rtIdx;
    end
    
    smoothWidth = 0;
    datFields = {'windowsMousePosition','cursorPosition','currentTarget','xk'};
    binMS = 20;
    unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

    afSet = {'timeGoCue'};
    twSet = {[-500,1000]};
    pfSet = {'goCue'};
        
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 30;
        datFields = {'windowsMousePosition','cursorPosition','currentTarget','headSpeed'};
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
            trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]' & isnan(rtIdxAll);
            %trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]';
            trlIdx = find(trlIdx);

            if strcmp(afSet{alignSetIdx},'trialLength')
                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)-10,1:2);
            else
                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
            end
            [targList, ~, targCodes] = unique(tPos,'rows');
            centerCode = find(all(targList==0,2));
            outerIdx = find(targCodes~=centerCode);
            
            %single-factor
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(outerIdx)), ...
                targCodes(outerIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
            lineArgs = cell(length(targList)-1,1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'CD','CI'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        
            bField = 'timeGoCue';
            colors = jet(8)*0.8;
            useCodeIdx = [1:4, 6:9];
            figure
            for codeIdx=1:8
                plotIdx = trlIdx(find(targCodes==useCodeIdx(codeIdx)));

                hold on
                for t=1:length(plotIdx)
                    outerTrlIdx = plotIdx(t);
                    headPos = double(R(outerTrlIdx).windowsMousePosition');
                    headVel = [0 0; diff(headPos)];
                    [B,A] = butter(4, 10/500);
                    headVel = filtfilt(B,A,headVel);
                    headSpeed = matVecMag(headVel,2)*1000;

                    showIdx = R(outerTrlIdx).(bField):(R(outerTrlIdx).(bField)+1000);
                    showIdx(showIdx>length(headSpeed))=[];
                    showIdx(showIdx<1) = [];
                    plot(headSpeed(showIdx),'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            
            figure
            for codeIdx=1:8
                plotIdx = trlIdx(find(targCodes==useCodeIdx(codeIdx)));
                cd = triggeredAvg(alignDat.headSpeed, alignDat.eventIdx(plotIdx), [0, 50]);
                hold on
                plot(nanmean(cd),'Color',colors(codeIdx,:));
            end
            legend(mat2stringCell(1:8));

            figure
            for codeIdx=1:8
                plotIdx = trlIdx(find(targCodes==useCodeIdx(codeIdx)));
                cd = triggeredAvg(diff(alignDat.windowsMousePosition), alignDat.eventIdx(plotIdx), [0, 20]);
                tmpMean = squeeze(nanmean(cd,1));
                traj = cumsum(tmpMean);

                hold on
                %plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
                plot(traj(end,1), traj(end,2),'o','Color',colors(codeIdx,:),'MarkerFaceColor',colors(codeIdx,:));
            end
            axis equal;
            legend(mat2stringCell(1:8));

            figure;
            hold on;
            for codeIdx=1:8
                plot(targList(useCodeIdx(codeIdx),1), targList(useCodeIdx(codeIdx),2),...
                    'o','Color',colors(codeIdx,:),'MarkerFaceColor',colors(codeIdx,:));
            end
            axis equal;
        end %block set
    end %alignment set
    
end
