%%
blockList = [2 5 7 9 11 13 15 18];
sessionName = 't5.2019.06.03';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'bezierTemplates3' filesep];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%       
bNums = horzcat(blockList);
movField = 'rigidBodyPosXYZ';
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500;
R = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );

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
    'rd1c','rd2c','rd3c','rd4c','rd5c','rd6c','rd7c','rd8c','rd9c','rd10c','rd11c','rd12c','rd13c','rd14c','rd15c','rd16c',...
    'rd1m','rd2m','rd3m','rd4m','rd5m','rd6m','rd7m','rd8m','rd9m','rd10m','rd11m','rd12m','rd13m','rd14m','rd15m','rd16m',...
    'rd1f','rd2f','rd3f','rd4f','rd5f','rd6f','rd7f','rd8f','rd9f','rd10f','rd11f','rd12f','rd13f','rd14f','rd15f','rd16f',...
     };

%%
%plot head behavior
plotVar = 'rigidBodyPosXYZ';
minorSets = {1:16,...
    17:32,...
    33:48};

timeWindows = zeros(56,2);
timeWindows(:,1) = 1;
timeWindows(:,2) = 60;

%%
%single trial
for setIdx=1:length(codeSets)
    figure('Position',[680         700        1241         398]);
    
    for minorIdx=1:length(minorSets)
        subtightplot(1,3,minorIdx);
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

%%
%averages
for setIdx=1:length(codeSets)
    figure('Position',[680         700        1241         398]);
    
    for minorIdx=1:length(minorSets)
        subtightplot(1,3,minorIdx);
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

%%
templates = cell(length(uniqueCodes),1);

figure
for codeIdx=1:length(uniqueCodes)
    trlIdx = find(trlCodes==uniqueCodes(codeIdx));
    
    cDat = triggeredAvg(alignDat.headVel(:,1:2)*10000, alignDat.eventIdx(trlIdx), [0, 80]);
    avgDat = squeeze(mean(cDat,1));
    
    subtightplot(8,8,codeIdx)
    plot(avgDat,'LineWidth',2);
    axis off;
    
    templates{codeIdx} = avgDat;
end

templateCodes = uniqueCodes;
save([outDir 'templates.mat'], 'templates', 'templateCodes');

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

mpCodeSets = codeSets;
mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(mpCodeSets) 
    trlIdx = find(ismember(trlCodes, mpCodeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_blockMean, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end

%%
prepVec = squeeze(nanmean(nanmean( mPCA_out{1}.featureVals(:,:,1:50,:),4),3))';
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

colors = hsv(16)*0.8;
markerTypes = {'o','s','d'};
ringColors = [0.8 0 0; 0 0.8 0; 0 0 0.8];

figure
hold on
for minorIdx=1:length(minorSets)
    for x=1:length(minorSets{minorIdx})
        plotIdx = minorSets{minorIdx}(x);
        plot3(SCORE(plotIdx,4), SCORE(plotIdx,5), SCORE(plotIdx,6),markerTypes{minorIdx},'Color',colors(x,:),...
            'MarkerFaceColor',colors(x,:),'MarkerSize',18);
        
        ringIdx = [minorSets{minorIdx}, minorSets{minorIdx}(1)];
        plot3(SCORE(ringIdx,4), SCORE(ringIdx,5), SCORE(ringIdx,6),'LineWidth',3,'Color',ringColors(minorIdx,:));
    end
end