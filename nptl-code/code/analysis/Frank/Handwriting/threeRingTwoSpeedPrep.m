%%
blockSets = {[2 5 7 9 11 13 15 17 19 21], [4 6 8 10 12 14 16 18 20 22]};
setNames = {'head','arm'};
sessionName = 't5.2019.07.01';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep '3ringSpeedPrep' filesep];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

for blockSetIdx=1:length(blockSets)
    %%       
    bNums = horzcat(blockSets{blockSetIdx});
    movField = 'rigidBodyPosXYZ';
    filtOpts.filtFields = {'rigidBodyPosXYZ'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, bNums, 4.5, bNums(1), filtOpts );

    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
        end
        allR = [allR, R{x}];
    end

    for t=1:length(allR)
        allR(t).headVel = [0 0 0; diff(allR(t).rigidBodyPosXYZ')]';
    end

    alignFields = {'goCue'};
    smoothWidth = 0;
    datFields = {'rigidBodyPosXYZ','currentMovement','headVel','windowsPC1GazePoint','windowsMousePosition'};
    timeWindow = [-1000,4000];
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];

    alignDat.zScoreSpikes_allBlocks = zscore(alignDat.rawSpikes);
    alignDat.zScoreSpikes_blockMean = alignDat.zScoreSpikes;

    smoothSpikes_allBlocks = gaussSmooth_fast(zscore(alignDat.rawSpikes),3);
    smoothSpikes_blockMean = gaussSmooth_fast(alignDat.zScoreSpikes,3);

    trlCodes = alignDat.currentMovement(alignDat.eventIdx);
    uniqueCodes = unique(trlCodes);

    codeSets = {uniqueCodes};
    movLabels = {
        'rd1CS','rd2CS','rd3CS','rd4CS','rd5CS','rd6CS','rd7CS','rd8CS',...
        'rd1MS','rd2MS','rd3MS','rd4MS','rd5MS','rd6MS','rd7MS','rd8MS',...
        'rd1FS','rd2FS','rd3FS','rd4FS','rd5FS','rd6FS','rd7FS','rd8FS',...
        'rd1CF','rd2CF','rd3CF','rd4CF','rd5CF','rd6CF','rd7CF','rd8CF',...
        'rd1MF','rd2MF','rd3MF','rd4MF','rd5MF','rd6MF','rd7MF','rd8MF',...
        'rd1FF','rd2FF','rd3FF','rd4FF','rd5FF','rd6FF','rd7FF','rd8FF',...
         };
     
     clear allR R;

    %%
    %plot head behavior
    plotVar = 'rigidBodyPosXYZ';
    minorSets = {1:8, 9:16, 17:24, 25:32, 33:40, 41:48};

    timeWindows = zeros(48,2);
    timeWindows(:,1) = 1;
    timeWindows(1:24,2) = 180;
    timeWindows(25:48,2) = 60;
    
    %%
    %single trial
    for setIdx=1:length(codeSets)
        figure('Position',[680         700        1241         398]);

        for minorIdx=1:length(minorSets)
            subtightplot(2,3,minorIdx);
            hold on;

            cs = codeSets{setIdx}(minorSets{minorIdx});
            colors = hsv(size(cs,1))*0.8;

            for t=1:length(cs)
                trlIdx = find(trlCodes==cs(t));
                localCodeIdx = find(cs(t)==uniqueCodes);

                for x=1:length(trlIdx)
                    loopIdx = (alignDat.eventIdx(trlIdx(x))):(alignDat.eventIdx(trlIdx(x))+timeWindows(localCodeIdx,2));
                    tmp = alignDat.(plotVar)(loopIdx,:);
                    tmp = tmp - tmp(1,:);

                    plot(tmp(:,1), tmp(:,2),'-','Color',colors(t,:),'LineWidth',1);
                end
            end

            xlim([-0.015,0.015]);
            ylim([-0.015,0.015]);

            axis equal;
            axis off;
        end
    end

    saveas(gcf,[outDir 'singleTrialHead_' setNames{blockSetIdx} '.png'],'png');
    
    %%
    %averages
    for setIdx=1:length(codeSets)
        figure('Position',[680         700        1241         398]);

        for minorIdx=1:length(minorSets)
            subtightplot(2,3,minorIdx);
            hold on;

            cs = codeSets{setIdx}(minorSets{minorIdx});
            colors = hsv(size(cs,1))*0.8;

            for t=1:length(cs)
                trlIdx = find(trlCodes==cs(t));
                localCodeIdx = find(cs(t)==uniqueCodes);

                allTrials = cell(length(trlIdx),1);
                for x=1:length(trlIdx)
                    loopIdx = (alignDat.eventIdx(trlIdx(x))):(alignDat.eventIdx(trlIdx(x))+timeWindows(localCodeIdx,2));
                    tmp = alignDat.(plotVar)(loopIdx,:);
                    tmp = tmp - tmp(1,:);
                    allTrials{x} = tmp;
                end

                concatDat = cat(3,allTrials{:});
                avg = squeeze(mean(concatDat,3));
                plot(avg(:,1), avg(:,2),'-','Color',colors(t,:),'LineWidth',3);
            end

            xlim([-0.015,0.015]);
            ylim([-0.015,0.015]);

            axis equal;
            axis off;
        end
    end
    
    saveas(gcf,[outDir 'avgHead_' setNames{blockSetIdx} '.png'],'png');
    
    %%
    %speed profiles for 6 conditions
    speedProfiles = cell(length(uniqueCodes),1);
    for c=1:length(uniqueCodes)
        trlIdx = find(trlCodes==uniqueCodes(c));
        cDat = triggeredAvg(alignDat.headVel(:,1:2), alignDat.eventIdx(trlIdx), [-50,200]);
        
        mn = squeeze(mean(cDat,1));
        speedProfiles{c} = matVecMag(mn,2)*1000*100;
    end
    
    figure;
    hold on;
    colors = hsv(length(minorSets))*0.8;
    for minorIdx=1:length(minorSets)
        for x=1:length(minorSets{minorIdx})
            cIdx = minorSets{minorIdx}(x);
            loopIdx = (timeWindows(cIdx,1):(timeWindows(cIdx,2)+10))+50;
            plot((1:length(loopIdx))/100,speedProfiles{cIdx}(loopIdx),'Color',colors(minorIdx,:),'LineWidth',3);
        end
    end
    xlabel('Time (s))');
    ylabel('Speed (cm/s)');
    set(gca,'FontSize',18,'LineWidth',2);
    
    saveas(gcf,[outDir 'avgHead_' setNames{blockSetIdx} '.png'],'png');
        
    %%
    %quickly look at prep geometry
    timeWindow_mpca = [-500,1500];
    tw =  timeWindow_mpca/binMS;
    tw(1) = tw(1) + 1;
    tw(2) = tw(2) - 1;

    margGroupings = {{1, [1 2]}, {2}};
    margNames = {'Condition-dependent', 'Condition-independent'};
    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 5;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'singleTrial';
    opts_m.alignMode = 'rotation';
    opts_m.plotCI = true;
    opts_m.nResamples = 10;

    mpCodeSets = {codeSets{1}(1:48), codeSets{1}(1:24), codeSets{1}(25:48)};
    mPCA_out = cell(length(codeSets),1);
    for pIdx=1:length(mpCodeSets) 
        trlIdx = find(ismember(trlCodes, mpCodeSets{pIdx}));
        mc = trlCodes(trlIdx)';
        [~,~,mc_oneStart] = unique(mc);

        mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_blockMean, alignDat.eventIdx(trlIdx), ...
            mc_oneStart, tw, binMS/1000, opts_m );
    end

    %%
    %prepVec = squeeze(nanmean(nanmean( mPCA_out{1}.featureVals(:,:,1:50,:),4),3))';
    prepVec = squeeze(nanmean(nanmean( mPCA_out{1}.featureVals(:,:,1:50,:),4),3))';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

    dirColors = hsv(8)*0.8;
    magColors = [0.8 0 0; 0 0.8 0; 0 0 0.8; 0.8 0 0; 0 0.8 0; 0 0 0.8];
    speedColors = [0.8 0 0; 0.8 0 0; 0.8 0 0; 0 0 0.8; 0 0 0.8; 0 0 0.8];
    markerTypes = {'o','s','d','o','s','d'};
    markerSizes = [8 8 8 16 16 16];

    %%
    figure;  
    hold on
    for minorIdx=1:length(minorSets)
        for x=1:length(minorSets{minorIdx})
            plotIdx = minorSets{minorIdx}(x);
            plot3(SCORE(plotIdx,1), SCORE(plotIdx,2), SCORE(plotIdx,3),...
                markerTypes{minorIdx},'Color',dirColors(x,:),...
                'MarkerFaceColor',dirColors(x,:),'MarkerSize',markerSizes(minorIdx));

            ringIdx = [minorSets{minorIdx}, minorSets{minorIdx}(1)];
            for r=1:(length(ringIdx)-1)
                segIdx = [ringIdx(r), ringIdx(r+1)];
                plot3(SCORE(segIdx,1), SCORE(segIdx,2), SCORE(segIdx,3), ...
                    'LineWidth',3,'Color',dirColors(r,:));
            end
        end
    end

    saveas(gcf,[outDir 'prepFirst3_' setNames{blockSetIdx} '_dir.png'],'png');
    saveas(gcf,[outDir 'prepFirst3_' setNames{blockSetIdx} '_dir.fig'],'fig');

    %%
    figure;  
    hold on
    for minorIdx=1:length(minorSets)
        for x=1:length(minorSets{minorIdx})
            plotIdx = minorSets{minorIdx}(x);
            plot3(SCORE(plotIdx,1), SCORE(plotIdx,2), SCORE(plotIdx,3),...
                markerTypes{minorIdx},'Color',speedColors(minorIdx,:),...
                'MarkerFaceColor',speedColors(minorIdx,:),'MarkerSize',markerSizes(minorIdx));

            ringIdx = [minorSets{minorIdx}, minorSets{minorIdx}(1)];
            for r=1:(length(ringIdx)-1)
                segIdx = [ringIdx(r), ringIdx(r+1)];
                plot3(SCORE(segIdx,1), SCORE(segIdx,2), SCORE(segIdx,3), ...
                    'LineWidth',3,'Color',speedColors(minorIdx,:));
            end
        end
    end

    saveas(gcf,[outDir 'prepFirst3_' setNames{blockSetIdx} '_speed.png'],'png');
    saveas(gcf,[outDir 'prepFirst3_' setNames{blockSetIdx} '_speed.fig'],'fig');
    
    %%
    figure;  
    hold on
    for minorIdx=1:length(minorSets)
        for x=1:length(minorSets{minorIdx})
            plotIdx = minorSets{minorIdx}(x);
            plot3(SCORE(plotIdx,4), SCORE(plotIdx,5), SCORE(plotIdx,6),...
                markerTypes{minorIdx},'Color',magColors(minorIdx,:),...
                'MarkerFaceColor',magColors(minorIdx,:),'MarkerSize',markerSizes(minorIdx));

            ringIdx = [minorSets{minorIdx}, minorSets{minorIdx}(1)];
            plot3(SCORE(ringIdx,4), SCORE(ringIdx,5), SCORE(ringIdx,6), ...
                'LineWidth',3,'Color',magColors(minorIdx,:));
        end
    end
    
    saveas(gcf,[outDir 'prepNext3_' setNames{blockSetIdx} '_dist.png'],'png');
    saveas(gcf,[outDir 'prepNext3_' setNames{blockSetIdx} '_dist.fig'],'fig');
    
    %%
    figure;  
    hold on
    for minorIdx=1:length(minorSets)
        for x=1:length(minorSets{minorIdx})
            plotIdx = minorSets{minorIdx}(x);
            plot3(SCORE(plotIdx,4), SCORE(plotIdx,5), SCORE(plotIdx,6),...
                markerTypes{minorIdx},'Color',speedColors(minorIdx,:),...
                'MarkerFaceColor',speedColors(minorIdx,:),'MarkerSize',markerSizes(minorIdx));

            ringIdx = [minorSets{minorIdx}, minorSets{minorIdx}(1)];
            plot3(SCORE(ringIdx,4), SCORE(ringIdx,5), SCORE(ringIdx,6), ...
                'LineWidth',3,'Color',speedColors(minorIdx,:));
        end
    end
    
    saveas(gcf,[outDir 'prepNext3_' setNames{blockSetIdx} '_speed.png'],'png');
    saveas(gcf,[outDir 'prepNext3_' setNames{blockSetIdx} '_speed.fig'],'fig');
    
    %%
    close all;
    
    %%
    %time series decoding
    straightLineCodes = codeSets{1}(41:48);
    makePlot = true;
    [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_blockMean, alignDat, trlCodes, straightLineCodes, makePlot );        

    %%
    uniqueCodes_noNothing = uniqueCodes;
    for x=1:length(mPCA_out)
        if ~isempty(mPCA_out{x})
            ciDim = mPCA_out{x}.readouts(:,6);
            break;
        end
    end

    color = [1 0 0];
    nPerPage = 6;
    currIdx = 1:nPerPage;
    nPages = ceil(length(uniqueCodes_noNothing)/nPerPage);
    headings = {'X','Y','CIS'};
    dynTraj = cell(length(uniqueCodes_noNothing),1);
    allModelTraj = cell(length(uniqueCodes_noNothing),1);

    for pageIdx=1:nPages
        figure('Position',[73          49         526        1053]);
        for plotConIdx=1:length(currIdx)
            if currIdx(plotConIdx) > length(uniqueCodes_noNothing)
                continue;
            end
            
            codeIdx = currIdx(plotConIdx);
            tWin = [-50, timeWindows(codeIdx,2)-1] ;
            concatDat = triggeredAvg( smoothSpikes_blockMean, alignDat.eventIdx(trlCodes==uniqueCodes_noNothing(codeIdx)), tWin );
            avgNeural = squeeze(mean(concatDat,1));
            timeAxis = (tWin(1):tWin(2))/100;

            for dimIdx = 1:3
                subplot(nPerPage,3,(plotConIdx-1)*3+dimIdx);
                hold on;
                if dimIdx==1 || dimIdx==2
                    plot(timeAxis, 1.6*[ones(size(avgNeural,1),1), avgNeural]*filts_prep(:,dimIdx),'LineWidth',2,'Color',color*0.5);
                    plot(timeAxis, 1.6*[ones(size(avgNeural,1),1), avgNeural]*filts_mov(:,dimIdx),'LineWidth',2,'Color',color);
                else
                    plot(timeAxis, avgNeural*ciDim,'LineWidth',2,'Color',color*0.5);
                end

                plot(get(gca,'XLim'),[0 0],'-k','LineWidth',2);
                xlim([timeAxis(1), timeAxis(end)]);
                ylim([-1,1]); 
                plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
                set(gca,'FontSize',16,'LineWidth',2);

                if dimIdx==1
                    ylabel(movLabels{codeIdx});
                end

                if plotConIdx==1
                    title(headings{dimIdx});
                end
            end
            
            prepVel = [ones(size(avgNeural,1),1), avgNeural]*filts_prep(:,1:2);
            outVel =  [ones(size(avgNeural,1),1), avgNeural]*filts_mov(:,1:2);
            CIS = avgNeural*ciDim;
            allModelTraj{currIdx(plotConIdx),1} = [prepVel, outVel, CIS];
        end

        saveas(gcf,[outDir filesep 'prepDynamicsPage_' num2str(pageIdx) '.png'],'png');
        currIdx = currIdx + nPerPage;
    end
    close all;
    
    %%
    %project to target direction to summarize
    theta = linspace(0,2*pi,9);
    theta = theta(1:8);
    dToUse = [1:8,1:8,1:8,1:8,1:8,1:8];

    rotTraj = cell(size(allModelTraj));
    for x=1:length(allModelTraj)
        t = -theta(dToUse(x));
        rotMat = [[cos(t), cos(t+pi/2)]; [sin(t), sin(t+pi/2)]];
        rotTraj{x} = [(rotMat * allModelTraj{x}(:,1:2)')', (rotMat * allModelTraj{x}(:,3:4)')'];
    end

    allPlotSets = {{1:8, 9:16, 17:24}, {25:32, 33:40, 41:48}};
    setColorsVel = [1.0 0 0; 0.8 0 0; 0.6 0 0;];
    setColorsPrep =  [0 0 1.0; 0 0 0.8; 0 0 0.6];
    
    for outerIdx=1:length(allPlotSets)
        figure('Position',[680   849   693   249]);
        plotSets = allPlotSets{outerIdx};
        for setIdx=1:length(plotSets)
            pIdx = plotSets{setIdx};
            timeAxis = (1:length(rotTraj{pIdx(1)}))*0.01 - 0.5;

            subplot(1,3,1);
            hold on

            allConcat = cat(3,rotTraj{pIdx});
            plot(timeAxis,squeeze(mean(allConcat(:,1,:),3)),'Color',setColorsPrep(setIdx,:),'LineWidth',3);
            plot(timeAxis,squeeze(mean(allConcat(:,3,:),3)),'Color',setColorsVel(setIdx,:),'LineWidth',3);
            plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);

            title('X Dimension');
            xlabel('Time (s)');
            legend({'Prep','Velocity'});
            set(gca,'FontSize',16,'LineWidth',2);
            xlim([timeAxis(1), timeAxis(end)]);
            ylim([-0.2,1.0]);

            subplot(1,3,2);
            hold on

            allConcat = cat(3,rotTraj{pIdx});
            plot(timeAxis,squeeze(mean(allConcat(:,2,:),3)),'Color',setColorsPrep(setIdx,:),'LineWidth',3);
            plot(timeAxis,squeeze(mean(allConcat(:,4,:),3)),'Color',setColorsVel(setIdx,:),'LineWidth',3);
            plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);
            title('Y Dimension');
            xlabel('Time (s)');
            legend({'Prep','Velocity'});
            set(gca,'FontSize',16,'LineWidth',2);
            xlim([timeAxis(1), timeAxis(end)]);
            ylim([-0.2,1.0]);

            subplot(1,3,3);
            hold on

            allConcat = cat(3,allModelTraj{pIdx});
            plot(timeAxis,squeeze(mean(allConcat(:,5,:),3)),'Color',setColorsVel(setIdx,:),'LineWidth',3);
            plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);
            title('CIS');
            xlabel('Time (s)');
            set(gca,'FontSize',16,'LineWidth',2);
            xlim([timeAxis(1), timeAxis(end)]);
            ylim([-0.4,1.0]);
        end
        
        saveas(gcf,[outDir filesep 'prepVsVelAvg' num2str(setIdx) '.png'],'png');
    end
end