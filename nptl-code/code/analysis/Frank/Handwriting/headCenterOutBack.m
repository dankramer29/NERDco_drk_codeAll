%%
blockList = [3 6 8 10 12 14 16 18 20 22];
sessionName = 't5.2019.06.24';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'headCenterVsOut' filesep];
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
movLabels = {'right3CW','right2CW','right1CW','right4CW','right5CW',...
    'right3CCW','right2CCW','right1CCW','right4CCW','right5CCW',...
    'up3CW','up2CW','up1CW','up4CW','up5CW',...
    'up3CCW','up2CCW','up1CCW','up4CCW','up5CCW',...
    'left3CW','left2CW','left1CW','left4CW','left5CW',...
    'left3CCW','left2CCW','left1CCW','left4CCW','left5CCW',...
    'down3CW','down2CW','down1CW','down4CW','down5CW',...
    'down3CCW','down2CCW','down1CCW','down4CCW','down5CCW',...    
    'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
     };

%%
%plot head behavior
plotVar = 'rigidBodyPosXYZ';
minorSets = {1:5, 6:10, 11:15, 16:20, 21:25, 26:30, 31:35, 36:40, 41:56};

timeWindows = zeros(56,2);
timeWindows(:,1) = 1;
timeWindows(:,2) = 80;

%%
%single trial
for setIdx=1:length(codeSets)
    figure
    
    for minorIdx=1:length(minorSets)
        subtightplot(3,3,minorIdx);
        hold on;
        
        cs = codeSets{setIdx}(minorSets{minorIdx});
        colors = hsv(length(cs))*0.8;
        
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
straightIdx = codeSets{1}(41:56);
cVel = triggeredAvg(alignDat.headVel(:,1:2), alignDat.eventIdx(trlCodes==straightIdx(6)), [-49 149]);

meanVel = squeeze(mean(cVel,1));
meanSpeed = matVecMag(meanVel,2);

smoothSpikes_blockMean = gaussSmooth_fast(alignDat.zScoreSpikes_blockMean, 3);

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

trlIdx = find(ismember(trlCodes, straightIdx));
mc = trlCodes(trlIdx)';
[~,~,mc_oneStart] = unique(mc);

mPCA_out = apply_mPCA_general( smoothSpikes_blockMean, alignDat.eventIdx(trlIdx), ...
    mc_oneStart, tw, binMS/1000, opts_m );

bgSignal = meanSpeed;
[yAxesFinal, allHandles, allYAxes] = general_mPCA_plot( mPCA_out.readout_xval, mPCA_out.margPlot.timeAxis, mPCA_out.margPlot.lineArgs, ...
    mPCA_out.margPlot.plotTitles, 'sameAxesGlobal', bgSignal, [], mPCA_out.readout_xval.CIs, mPCA_out.margPlot.ciColors, true, mPCA_out.margPlot.layoutInfo );

%%
dat = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.24_head_warpedCube.mat');

curveIdx = codeSets{1}(1:40);
straightIdx = codeSets{1}(41:56);

cVel = triggeredAvg(alignDat.headVel(:,1:2), alignDat.eventIdx(trlCodes==curveIdx(3)), [-49 149]);

figure
for dimIdx=1:2
    subplot(2,2,dimIdx);
    hold on;
    for t=1:size(cVel,1)
        plot(squeeze(cVel(t,:,dimIdx)));
    end
    
    mn = squeeze(mean(cVel,1));
    plot(mn(:,dimIdx),'LineWidth',3,'Color','k');
    axis tight;
end

for dimIdx=1:2
    subplot(2,2,2+dimIdx);
    hold on;
    
    allWarp = [];
    for t=1:size(cVel,1)
        rawTrace = squeeze(cVel(t,:,dimIdx));
        clk = dat.right1CW_T(:,t);
        warpTrace = interp1(1:length(rawTrace), rawTrace, clk, 'linear', 0);

        plot(warpTrace);
        allWarp = [allWarp; warpTrace'];
    end
    
    mn = squeeze(mean(allWarp));
    plot(mn,'LineWidth',3,'Color','r');
    
    axis tight;
end

%%
speed = zeros(size(cVel,1), size(cVel,2));
for t=1:size(cVel,1)
    speed(t,:) = matVecMag(squeeze(cVel(t,:,:)),2);
end




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