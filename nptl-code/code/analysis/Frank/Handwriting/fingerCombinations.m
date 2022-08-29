%%
blockSets = {[4 5 6 7 9 10 11 12 13 14]};
setNames = {'finger'};
sessionName = 't5.2019.07.03';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'FingerTyping' filesep 'fingerCombinations' filesep];
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
        'l5','l4','l3','l2','r2','r3','r4','r5','l1','r1',...
        'l54','l53','l52','l51','l5r1','l5r2','l5r3','l5r4','l5r5',...
        'l43','l42','l41','l4r1','l4r2','l4r3','l4r4','l4r5',...
        'l32','l31','l3r1','l3r2','l3r3','l3r4','l3r5',...
        'l21','l2r1','l2r2','l2r3','l2r4','l2r5',...
        'l1r1','l1r2','l1r3','l1r4','l1r5',...
        'r12','r13','r14','r15',...
        'r23','r24','r25',...
        'r34','r35',...
        'r45',...
        'r345','r245','r235','r234','r2345','r145','r135','r134','r1345','r125','r124','r1245','r123','r1235','r1234','r12345',...
         };

    %%
    %quickly look at representation geometry
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

    mpCodeSets = codeSets;
    mPCA_out = cell(length(codeSets),1);
    for pIdx=1:length(mpCodeSets) 
        trlIdx = find(ismember(trlCodes, mpCodeSets{pIdx}));
        mc = trlCodes(trlIdx)';
        [~,~,mc_oneStart] = unique(mc);

        mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_blockMean, alignDat.eventIdx(trlIdx), ...
            mc_oneStart, tw, binMS/1000, opts_m );
    end

    [ C, L, obj ] = simpleClassify( alignDat.zScoreSpikes_blockMean, mc_oneStart, alignDat.eventIdx+10, movLabels, 50, 1, 1, true );
    
    setLabel = {'single','allPair','leftPair','rightPair','allRight'};
    smallSets = {1:10,1:55,[1 2 3 4 9 11:14,20:22,28:29,35],[5 6 7 8 10 46:55],[5 6 7 8 10 46:71]};
    
    for setIdx=1:length(setLabel)
        trlIdx = find(ismember(trlCodes, uniqueCodes(smallSets{setIdx})));
        mc = trlCodes(trlIdx)';
        [~,~,mc_oneStart] = unique(mc);
        
        [ C, L, obj ] = simpleClassify( alignDat.zScoreSpikes_blockMean, mc_oneStart, alignDat.eventIdx(trlIdx)+10, movLabels(smallSets{setIdx}), 50, 1, 1, true );
        title([setLabel{setIdx} ' - ' num2str((1-L)*100,4) '%']);
        saveas(gcf,[outDir filesep 'classifier_' setLabel{setIdx} '.png'],'png');
        
        useVals = mPCA_out{1}.featureVals(:,smallSets{setIdx},:,:);
        useLabels = movLabels(smallSets{setIdx});
        
        distMatrix = plotDistMat_cv( useVals, [61,120],useLabels);
        saveas(gcf,[outDir filesep 'simMatrixDist_' setLabel{setIdx} '.png'],'png');

        simMatrix = plotCorrMat_cv( useVals  , [61,120], useLabels, [], [] );
        title('Vector Correlation');
        saveas(gcf,[outDir filesep 'simMatrix_' setLabel{setIdx} '.png'],'png');
        
        movVec = squeeze(nanmean(nanmean( mPCA_out{1}.featureVals(:,smallSets{setIdx},61:120,:),4),3))';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(movVec);

        figure;  
        hold on
        for t=1:length(smallSets{setIdx})
            text(SCORE(t,1), SCORE(t,2), SCORE(t,3), useLabels{t}, 'FontSize',16,'FontWeight','bold');
        end
        xlim([-2,2]);
        ylim([-2,2]);
        zlim([-2,2]);
        
        stVals = squeeze(nanmean( mPCA_out{1}.featureVals(:,smallSets{setIdx},61:120,:),3));
        innerIdx = 1:15;
        colors = hsv(length(innerIdx))*0.8;
        
        figure;  
        hold on
        for t=1:length(innerIdx)
            for x=1:size(stVals,3)
                sc = (squeeze(stVals(:,innerIdx(t),x))-MU')'*COEFF(:,1:3);
                text(sc(1), sc(2), sc(3), useLabels{innerIdx(t)}, 'FontSize',16,'FontWeight','bold','Color',colors(t,:));
            end
        end
        xlim([-2,2]);
        ylim([-2,2]);
        zlim([-2,2]);

    end
    
    %%
    movVec = squeeze(nanmean(nanmean( mPCA_out{1}.featureVals(:,:,61:120,:),4),3))';
    %prepVec = squeeze(nanmean(nanmean( mPCA_out{1}.featureVals(:,:,61:120,:),4),3))';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(movVec);

    dirColors = hsv(16)*0.8;
    magColors = [0.8 0 0; 0 0.8 0; 0 0 0.8];
    markerTypes = {'o','s','d'};

    %%
    figure;  
    hold on
    for minorIdx=1:length(minorSets)
        for x=1:length(minorSets{minorIdx})
            plotIdx = minorSets{minorIdx}(x);
            plot3(SCORE(plotIdx,1), SCORE(plotIdx,2), SCORE(plotIdx,3),...
                markerTypes{minorIdx},'Color',dirColors(x,:),...
                'MarkerFaceColor',dirColors(x,:),'MarkerSize',18);

            ringIdx = [minorSets{minorIdx}, minorSets{minorIdx}(1)];
            for r=1:(length(ringIdx)-1)
                segIdx = [ringIdx(r), ringIdx(r+1)];
                plot3(SCORE(segIdx,1), SCORE(segIdx,2), SCORE(segIdx,3), ...
                    'LineWidth',3,'Color',dirColors(r,:));
            end
        end
    end

    saveas(gcf,[outDir 'prepFirst3_' setNames{blockSetIdx} '.png'],'png');
    saveas(gcf,[outDir 'prepFirst3_' setNames{blockSetIdx} '.fig'],'fig');
    
    %%
    figure;  
    hold on
    for minorIdx=1:length(minorSets)
        for x=1:length(minorSets{minorIdx})
            plotIdx = minorSets{minorIdx}(x);
            plot3(SCORE(plotIdx,4), SCORE(plotIdx,5), SCORE(plotIdx,6),...
                markerTypes{minorIdx},'Color',magColors(minorIdx,:),...
                'MarkerFaceColor',magColors(minorIdx,:),'MarkerSize',18);

            ringIdx = [minorSets{minorIdx}, minorSets{minorIdx}(1)];
            plot3(SCORE(ringIdx,4), SCORE(ringIdx,5), SCORE(ringIdx,6), ...
                'LineWidth',3,'Color',magColors(minorIdx,:));
        end
    end
    
    saveas(gcf,[outDir 'prepNext3_' setNames{blockSetIdx} '.png'],'png');
    saveas(gcf,[outDir 'prepNext3_' setNames{blockSetIdx} '.fig'],'fig');
    
    %%
    close all;
    
    %%
    %time series decoding
    straightLineCodes = codeSets{1}(33:48);
    makePlot = true;
    [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_blockMean, alignDat, trlCodes, straightLineCodes, makePlot );        

    %%
    uniqueCodes_noNothing = uniqueCodes;
    for x=1:length(mPCA_out)
        if ~isempty(mPCA_out{x})
            ciDim = mPCA_out{x}.readouts(:,6)*0.4;
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
    theta = linspace(0,2*pi,17);
    theta = theta(1:16);
    dToUse = [1:16, 1:16, 1:16];

    rotTraj = cell(size(allModelTraj));
    for x=1:length(allModelTraj)
        t = -theta(dToUse(x));
        rotMat = [[cos(t), cos(t+pi/2)]; [sin(t), sin(t+pi/2)]];
        rotTraj{x} = [(rotMat * allModelTraj{x}(:,1:2)')', (rotMat * allModelTraj{x}(:,3:4)')'];
    end

    allPlotSets = {{1:16, 17:32, 33:48}};
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