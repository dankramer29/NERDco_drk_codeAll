%%
datasets = {
    't5.2018.08.20',{[11 12 13],[15],[18 19 20],[21,22,23]},{'Quad_Radial4_Slow','Quad_Radial4_Fast','Quad_Radial8_Slow','Quad_Radial8_Fast'};
    't5.2018.08.22',{[17 18]},{'DualJoystick_800'};
    't5.2018.08.27',{[1 3 5],[9,11,12,13,14,15,16]},{'DualJoystick_800','CardinalJoint32_Delay'};
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
            
            codeSets = {[1 3 5 7 8 6 4 2],[9 11 13 15 16 14 13 10]};
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
            
            idxSets = {[1 4 7 3],[2 6 8 5],[25 30 32 29],[26 28 31 27]};
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
        
        cWindow = 30:50;
        idxSets = {1:6, 7:12, 13:18, 19:24};
        [ simMatrix ] = plotCorrMat( dPCA_all.featureAverages, cWindow, [], idxSets, idxSets )
         
        nCon = size(dPCA_all.featureAverages,2);
        simMatrix = zeros(nCon, nCon);
        for x=1:nCon
            %get the top dimensions this movement lives in
            avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
            avgTraj = mean(avgTraj(40:75,:));

            for y=1:nCon
                avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
                avgTraj_y = mean(avgTraj_y(40:75,:));

                simMatrix(x,y) = corr(avgTraj', avgTraj_y');
            end
        end

        reorderIdx = horzcat(idxSets{:});
        reorderIdx(reorderIdx>centerCode) = reorderIdx(reorderIdx>centerCode)-1;
        
        figure
        imagesc(simMatrix(reorderIdx,reorderIdx));
        set(gca,'FontSize',16);
        set(gca,'YDir','normal');

        colors = hsv(length(idxSets))*0.8;

        currentIdx = 1:length(idxSets{1});
        for setIdx = 1:length(idxSets)
            rectangle('Position',[currentIdx(1)-0.5, currentIdx(1)-0.5,length(currentIdx), length(currentIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
            currentIdx = currentIdx + length(idxSets{1});
        end
        axis tight;


        %% 
        allPD = cell(length(idxSets),1);
        allPVal = cell(length(idxSets),1);
        
        for setIdx=1:length(idxSets)
            allDat = [];
            allTargPos = [];
            
            useTrlIdx = find(ismember(targCodes, idxSets{setIdx}));
            for trlIdx=1:length(useTrlIdx)
                globalTrlIdx = useTrlIdx(trlIdx);
                targLoc = targLayout(targCodes(globalTrlIdx),:);
                
                loopIdx = (10:50) + alignDat.eventIdx(globalTrlIdx);
                allDat = [allDat; mean(alignDat.zScoreSpikes(loopIdx,:))];
                allTargPos = [allTargPos; targLoc];
            end

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
        
        if strcmp(taskType,'Quad')
            setNames = {'Left Hand','Left Foot','Right Foot','Right Hand'};
        elseif strcmp(taskType,'Dual')
            setNames = {'Left Hand','Right Hand'};
        end
        
        figure('Position',[680           1        1241        1097]);
        for x=1:length(allPD)
            for y=1:length(allPD)
                subplot(length(allPD),length(allPD),(x-1)*length(allPD) + y);
                hold on;

                sigIdx = allPVal{y}<0.000001 | allPVal{x}<0.000001;

                plot(allPD{y}(sigIdx,1), allPD{x}(sigIdx,1), 'bo');
                plot(allPD{y}(sigIdx,2), allPD{x}(sigIdx,2), 'ro');
                axis equal;
                %plot(get(gca, 'XLim'), get(gca,'YLim'),'--k','LineWidth',2);

                cMat = corr(allPD{y}(sigIdx,:), allPD{x}(sigIdx,:));
                corr_x = cMat(1,1);
                corr_y = cMat(2,2);
                title([num2str(corr_x,3) ', ' num2str(corr_y,3)]);

                if x==length(allPD)
                    xlabel(setNames{y});
                end
                if y==1
                    ylabel(setNames{x});
                end
                set(gca,'FontSize',16,'LineWidth',1);
            end
        end
        saveas(gcf, [outDir filesep 'PDCorr_' datasets{d,3}{blockSetIdx} '.png'],'png');
        
    end %block set
end %datasets