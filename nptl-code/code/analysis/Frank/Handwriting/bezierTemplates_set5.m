%%
blockList = [2 5 7 9 11 13 15 17 19 23];
sessionName = 't5.2019.06.19';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'bezierTemplates5' filesep];
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
movLabels = {'single1CW','double1CW','single1CCW','double1CCW',...
    'single2CW','double2CW','single2CCW','double2CCW',...
    'single3CW','double3CW','single3CCW','double3CCW',...
    'single4CW','double4CW','single4CCW','double4CCW',...
    'single5CW','double5CW','single5CCW','double5CCW',...
    'single6CW','double6CW','single6CCW','double6CCW',...
    'single7CW','double7CW','single7CCW','double7CCW',...
    'single8CW','double8CW','single8CCW','double8CCW',...
    'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
     };

%%
%plot head behavior
plotVar = 'rigidBodyPosXYZ';
%minorSets = {1:4, 5:8, 9:12, 13:16, 17:20, 21:24, 25:28, 29:32, 33:48};
minorSets = {[1 3 9 11 17 19 25 27],[5 7 13 15 21 23 29 31],[2 4 10 12 18 20 26 28],[6 8 14 16 22 24 30 32],33:48};

timeWindows = zeros(56,2);
timeWindows(:,1) = 1;
timeWindows(:,2) = 80;
timeWindows(2:2:32,2) = 100;

%%
%single trial
for setIdx=1:length(codeSets)
    figure
    
    for minorIdx=1:length(minorSets)
        subtightplot(2,3,minorIdx);
        hold on;
        
        cs = codeSets{setIdx}(minorSets{minorIdx});
        if minorIdx==5
            colors = hsv(length(cs))*0.8;
        else
            colors = zeros(length(cs),3);
            tmp = hsv(length(cs)/2)*0.8;
            colors(1:2:end,:) = tmp;
            colors(2:2:end,:) = tmp;
        end
        
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

        axis equal;
        axis off;
    end
end

saveas(gcf,[outDir filesep 'curveSingleTrial.png'],'png');

%%
%averages
for setIdx=1:length(codeSets)
    figure
    
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

        axis equal;
        axis off;
    end
end

saveas(gcf,[outDir filesep 'curveAvg.png'],'png');

%%
templates = cell(length(uniqueCodes),1);

figure
for codeIdx=1:length(uniqueCodes)
    trlIdx = find(trlCodes==uniqueCodes(codeIdx));
    
    cDat = triggeredAvg(alignDat.headVel(:,1:2)*10000, alignDat.eventIdx(trlIdx), [0, timeWindows(codeIdx,2)]);
    avgDat = squeeze(mean(cDat,1));
    
    subtightplot(8,8,codeIdx)
    plot(avgDat,'LineWidth',2);
    axis off;
    
    templates{codeIdx} = avgDat;
end

templateCodes = uniqueCodes;
save([outDir 'templates.mat'], 'templates', 'templateCodes');