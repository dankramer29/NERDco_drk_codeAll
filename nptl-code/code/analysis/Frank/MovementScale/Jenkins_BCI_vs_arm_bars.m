datasets = {'JenkinsData','R_2018-01-18_1',{[6],[8],[17],[12],[10 14],[15 19]},{'Horz 2','Horz 1','Horz 0.75','Vert 2','Vert 1','Vert 0.75'};
    'JenkinsData','R_2018-01-19_1',{[3],[5],[7],[13 16],[11],[9]},{'Horz 2','Horz 1','Horz 0.75','Vert 2','Vert 1','Vert 0.75'}};

speedThresh = 50;

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementScale' filesep 'arm_bci_jenkins' filesep datasets{d,2}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'Monk' filesep datasets{d,1} filesep datasets{d,2} '.mat'];

    %%
    %load cued movement dataset
    load(sessionPath);
    for t=1:length(R)
        R(t).currentTarget = repmat(R(t).startTrialParams.posTarget(1:2),1,length(R(t).counter));
        R(t).saveTag = R(t).startTrialParams.saveTag;
        R(t).blockNum = R(t).saveTag;
        R(t).clock = R(t).counter;
    end
    
    R = R(ismember([R.saveTag], horzcat(datasets{d,3}{:})));
    
    rtIdxAll = zeros(length(R),1);
    [B,A] = butter(4, 5/500);
    for t=1:length(R)
        %RT
        pos = double(R(t).cursorPos(1:2,:)');
        pos(21:end,:) = filtfilt(B,A,pos(21:end,:)); %reseed
        vel = [0 0; diff(pos)];
        vel(1:21,:) = 0;
        speed = matVecMag(vel,2)*1000;
        R(t).speed = speed;
        R(t).maxSpeed = max(speed);
    end
    
    tPos = zeros(length(R),2);
    for t=1:length(R)
        tPos(t,:) = R(t).startTrialParams.posTarget(1:2);
    end
   
    [targList,~,targCodes] = unique(tPos,'rows');
    ms = [R.maxSpeed];
    avgMS = zeros(length(targList),1);
    for t=1:length(targList)
        avgMS(t) = mean(ms(targCodes==t));
    end
    
    for t=1:length(R)
        useThresh = max(avgMS(targCodes(t))*0.3,30);
        
        rtIdx = find(R(t).speed>useThresh,1,'first');
        if isempty(rtIdx)
            rtIdx = 150;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTime = rtIdx;
    end
    
    smoothWidth = 0;
    datFields = {'cursorPos','currentTarget'};
    binMS = 20;
    unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

    afSet = {'timeTargetOn','rtTime'};
    twSet = {[-300,1000],[-740,740]};
    pfSet = {'goCue','moveOnset'};
    
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 0;
        datFields = {'cursorPos','currentTarget'};
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes,1.5);
        %meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        %tooLow = meanRate < 0.5;
        %alignDat.zScoreSpikes(:,tooLow) = [];
        
        chanSet = {[1:96],[97:192]};
        arrayNames = {'M1','PMd'};
        for arrayIdx=1:length(chanSet)
            for blockSetIdx = 1:length(datasets{d,2})

                %all activity
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,3}{blockSetIdx}) & [R.isSuccessful]';
                trlIdx = find(trlIdx);

                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
                [targList, ~, targCodes] = unique(tPos,'rows');
                centerCode = find(all(targList==0,2));
                outerIdx = find(targCodes~=centerCode);

                %single-factor
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes(:,chanSet{arrayIdx}), alignDat.eventIdx(trlIdx(outerIdx)), ...
                    targCodes(outerIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                lineArgs = cell(length(targList)-1,1);
                colors = jet(length(lineArgs))*0.8;
                for l=1:length(lineArgs)
                    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
                end
                oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'CD','CI'}, 'sameAxes');
                saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.svg'],'svg');

                %two-factor
                [distList, ~, distCodes] = unique(round(matVecMag(tPos(outerIdx,:),2)),'rows');
                [dirList, ~, dirCodes] = unique(atan2(tPos(outerIdx,2), tPos(outerIdx,1)),'rows');

                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes(:,chanSet{arrayIdx}), alignDat.eventIdx(trlIdx(outerIdx)), ...
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
                saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.svg'],'svg');

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
                saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_modScale_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_modScale_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.svg'],'svg');

                if arrayIdx==1
                    %behavior
                    colors = jet(nDist)*0.8;
                    figure
                    for codeIdx=1:nDist
                        plotIdx = find(distCodes==codeIdx);
                        tmp = randperm(length(plotIdx));
                        plotIdx = plotIdx(tmp(1:2));
                        hold on
                        for t=1:length(plotIdx)
                            outerTrlIdx = trlIdx(outerIdx(plotIdx(t)));
                            plot(R(outerTrlIdx).speed(21:end),'Color',colors(codeIdx,:),'LineWidth',2);
                        end
                    end
                    saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_exampleBehavior.png'],'png');
                    saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_exampleBehavior.svg'],'svg');

                    colors = jet(nDist)*0.8;
                    figure
                    hold on;
                    for codeIdx=1:nDist
                        plotIdx = find(distCodes==codeIdx);
                        concatDat = nan(length(plotIdx),1000);
                        for t=1:length(plotIdx)
                            outerTrlIdx = trlIdx(outerIdx(plotIdx(t)));
                            showIdx = 1:(min(1000,length(R(outerTrlIdx).speed)));
                            concatDat(t,1:length(showIdx)) = R(outerTrlIdx).speed(showIdx);
                        end
                        plot(nanmean(concatDat),'Color',colors(codeIdx,:),'LineWidth',2);
                    end
                    saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_avgBehavior.png'],'png');
                    saveas(gcf,[outDir filesep datasets{d,4}{blockSetIdx} '_avgBehavior.svg'],'svg');
                end
                close all;
            end %block set
        end %array
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
