%%
blockList = [4 6 9 11 13 15 17];
sessionName = 't5.2019.05.06';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'bezierTemplates' filesep];
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

codeSets = {uniqueCodes(1:40)};
movLabels = {'right1h','right2h','right3h','right4h','right5h','right6h',...
    'up1h','up2h','up3h','up4h','up5h','up6h',...
    'left1h','left2h','left3h','left4h','left5h','left6h',...
    'down1h','down2h','down3h','down4h','down5h','down6h',...
    'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
     };

%%
templates = cell(length(uniqueCodes),1);

figure
for codeIdx=1:length(uniqueCodes)
    trlIdx = find(trlCodes==uniqueCodes(codeIdx));
    
    cDat = triggeredAvg(alignDat.headVel(:,1:2)*10000, alignDat.eventIdx(trlIdx), [0, 80]);
    avgDat = squeeze(mean(cDat,1));
    
    subtightplot(7,7,codeIdx)
    plot(avgDat,'LineWidth',2);
    axis off;
    
    templates{codeIdx} = avgDat;
end

templateCodes = uniqueCodes(1:40);
save([outDir 'templates.mat'], 'templates', 'templateCodes');