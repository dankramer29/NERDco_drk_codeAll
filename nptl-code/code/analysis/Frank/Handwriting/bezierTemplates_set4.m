%%
blockList = [3 6 9 11 13 16 18 22 25 27];
sessionName = 't5.2019.06.17';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'bezierTemplates4' filesep];
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
movLabels = {'right1h','right2h','right3h','right4h','right5h','right6h','right7h','right8h','right9h','right10h',...
    'up1h','up2h','up3h','up4h','up5h','up6h','up7h','up8h','up9h','up10h',...
    'left1h','left2h','left3h','left4h','left5h','left6h','left7h','left8h','left9h','left10h'...
    'down1h','down2h','down3h','down4h','down5h','down6h','down7h','down8h','down9h','down10h',...
    'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
     };

%%
%plot head behavior
plotVar = 'rigidBodyPosXYZ';
minorSets = {[1 2 3 4 5 6], ...
    [7 8 9 10 11 12], ...
    [13 14 15 16 17 18], ...
    [19 20 21 22 23 24], ...
    25:40,...
    [41 42 49 50],...
    [43 44 51 52],...
    [45 46 53 54],...
    [47 48 55 56]};

timeWindows = zeros(56,2);
timeWindows(:,1) = 1;
timeWindows(:,2) = 80;

timeWindows(49:56,2) = 140;

%%
%single trial
for setIdx=1:length(codeSets)
    figure
    
    for minorIdx=1:length(minorSets)
        subtightplot(3,3,minorIdx);
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
        subtightplot(3,3,minorIdx);
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