%%
blockList = [2 5 7 9 11 13 15 17 19 23];
sessionName = 't5.2019.06.19';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'headCenterVsOut_sCurve' filesep];
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
%substitute in aligned data
alignedCube = load(['/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.19_head_warpedCube.mat']);
alignDat.zScoreSpikes_align = alignDat.zScoreSpikes_blockMean;

for t=1:length(uniqueCodes)
    trlIdx = find(trlCodes==uniqueCodes(t));
    if isempty(trlIdx)
        continue;
    end
    labelIdx = t;
    nBins = size(alignedCube.(movLabels{labelIdx}),2);
    %winToUse = allTimeWindows(trlIdx,:);

    for x=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(x))-49):(alignDat.eventIdx(trlIdx(x))+(nBins-50));
        alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(movLabels{labelIdx})(x,:,:);
    end
end

alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0;
smoothSpikes_align = gaussSmooth_fast(alignDat.zScoreSpikes_align, 3);


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
straightIdx = codeSets{1}(33:48);
cVel = triggeredAvg(alignDat.headVel(:,1:2), alignDat.eventIdx(trlCodes==codeSets{1}(33)), [-49 149]);

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

mPCA_out = apply_mPCA_general( smoothSpikes_align, alignDat.eventIdx(trlIdx), ...
    mc_oneStart, tw, binMS/1000, opts_m );

bgSignal = meanSpeed;
[yAxesFinal, allHandles, allYAxes] = general_mPCA_plot( mPCA_out.readout_xval, mPCA_out.margPlot.timeAxis, mPCA_out.margPlot.lineArgs, ...
    mPCA_out.margPlot.plotTitles, 'sameAxesGlobal', bgSignal, [], mPCA_out.readout_xval.CIs, mPCA_out.margPlot.ciColors, true, mPCA_out.margPlot.layoutInfo );

%%
dat = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.19_head_warpedCube.mat');
datUnaligned = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.19_head_unwarpedCube.mat');

figure
hold on;
plot(squeeze(dat.double1CCW(1,:,20)));
plot(squeeze(datUnaligned.double1CCW(1,:,20)));

figure
hold on;
plot(squeeze(dat.double1CCW(1,:,20)));

rawTrace = squeeze(datUnaligned.double1CCW(1,:,20));
clk = dat.double1CCW_T(:,1);
warpTrace = interp1(clk, rawTrace, 1:length(rawTrace), 'linear', 0);
plot(warpTrace);

%%
dat = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.19_head_warpedCube.mat');

curveIdx = codeSets{1}(1:32);
straightIdx = codeSets{1}(33:48);

cVel = triggeredAvg(alignDat.headVel(:,1:2), alignDat.eventIdx(trlCodes==straightIdx(1)), [-50 150]);

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
        clk = dat.rd1h_T(:,t);
        warpTrace = interp1(clk, rawTrace, 1:length(rawTrace), 'linear', nan);

        plot(warpTrace);
        allWarp = [allWarp; warpTrace];
    end
    
    mn = squeeze(nanmean(allWarp));
    plot(mn,'LineWidth',3,'Color','k');
    
    axis tight;
end

%%
%population rasters
fNames = fieldnames(dat);
alignNames = {'aligned','unaligned'};

for alignIdx=1:2
    unalignedDim = gaussSmooth_fast(alignDat.zScoreSpikes_blockMean, 3.0) * mPCA_out.W(:,1:5);
    codeList = codeSets{1};

    tw_all = [-50, 150];
    timeStep = binMS/1000;
    timeAxis = (tw_all(1):tw_all(2))*timeStep;
    nDimToShow = 5;
    nPerPage = 10;
    currIdx = 1:10;

    for pageIdx=1:6
        figure('Position',[ 680   185   711   913]);
        for conIdx=1:length(currIdx)
            c = currIdx(conIdx);
            if c > length(codeList)
                break;
            end

            if alignIdx==1
                concatDat = triggeredAvg( unalignedDim, alignDat.eventIdx(trlCodes==codeList(c)), tw_all );
                for t=1:size(concatDat,1)
                    rawTrace = squeeze(concatDat(t,:,:));
                    clk = dat.([movLabels{c} '_T'])(:,t);
                    concatDat(t,:,:) = interp1(1:length(rawTrace), rawTrace, clk, 'linear', 0);
                end
            else
                concatDat = triggeredAvg( unalignedDim, alignDat.eventIdx(trlCodes==codeList(c)), tw_all );
            end

            for dimIdx=1:nDimToShow
                subtightplot(length(currIdx),nDimToShow,(conIdx-1)*nDimToShow + dimIdx);
                hold on;

                tmp = squeeze(concatDat(:,:,dimIdx));
                tmp(isnan(tmp)) = [];
                tmp(isinf(tmp)) = [];
                %imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),prctile(tmp(:),[5 95]));
                imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),[-1 1]);
                axis tight;
                plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
                plot([1.5,1.5],get(gca,'YLim'),'-k','LineWidth',2);

                cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
                colormap(cMap);

                %title(movLabels{c});
                if dimIdx==1
                    ylabel(movLabels{c},'FontSize',12,'FontWeight','bold');
                end
                if c==1
                    title(['Dimension ' num2str(dimIdx)],'FontSize',12);
                end

                set(gca,'FontSize',16);
                if c==length(codeList)
                    set(gca,'YTick',[]);
                    xlabel('Time (s)');
                else
                    set(gca,'XTick',[],'YTick',[]);
                end
            end
        end
        currIdx = currIdx + length(currIdx);

        saveas(gcf,[outDir filesep 'popRaster_page' num2str(pageIdx) '_' alignNames{alignIdx} '.png'],'png');
    end
end
    