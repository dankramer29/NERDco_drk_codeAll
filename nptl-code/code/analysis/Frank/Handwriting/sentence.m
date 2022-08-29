%%
blockList = [28 29 30];
sessionName = 't5.2019.04.22';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Alphabet' filesep sessionName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%       
bNums = horzcat(blockList);
movField = 'windowsMousePosition';
filtOpts.filtFields = {'windowsMousePosition'};
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

alignFields = {'goCue'};
smoothWidth = 0;
datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
timeWindow = [-1000,50000];
binMS = 10;
alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
meanRate = mean(alignDat.rawSpikes)*1000/binMS;
tooLow = meanRate < 1.0;
alignDat.rawSpikes(:,tooLow) = [];
alignDat.meanSubtractSpikes(:,tooLow) = [];
alignDat.zScoreSpikes(:,tooLow) = [];
smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);

%blank out data after the sentence is over
allTLen = zeros(length(allR),1);
for t=1:length(allR)
    trialLen = allR(t).restCue - allR(t).goCue;
    trialLen = round(trialLen / binMS);

    blankIdx = (alignDat.eventIdx(t)+trialLen):(alignDat.eventIdx(t)+timeWindow(2)/binMS);
    alignDat.zScoreSpikes(blankIdx,:) = nan;
    smoothSpikes(blankIdx,:) = nan;

    allTLen(t) = trialLen;
end

trlCodes = alignDat.currentMovement(alignDat.eventIdx);
movLabels = {'sentence'};
letterCodes = unique(trlCodes);

%%
%substitute in aligned data
alignedCube = load('sentenceCube_aligned_reg.mat');
alignDat.zScoreSpikes_align = alignDat.zScoreSpikes;

for t=1:length(movLabels)
    trlIdx = find(trlCodes==letterCodes(t));
    for x=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(x))-99):(alignDat.eventIdx(trlIdx(x))+4999);
        alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(movLabels{t})(x,2:end,:);
    end
end

alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0;
smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes_align, 3);

%%
timeWindow_mpca = [-1000,40000];
tw =  timeWindow_mpca/binMS;
tw(1) = tw(1) + 1;
tw(2) = tw(2) - 1;
    
margGroupings = {{1,[1 2]}};
margNames = {'Time'};
opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 8;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

codeSets = {letterCodes};

mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(codeSets) 
    trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end
close all;

%%
codeList = [letterCodes];

tw_all = [-99, 5000];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;
nDimToShow = 5;
nPerPage = 1;
currIdx = 1:1;

for pageIdx=1:1
    figure('Position',[106        1022        1811          76]);
    for conIdx=1:length(currIdx)
        c = currIdx(conIdx);
        if c > length(codeList)
            break;
        end
        concatDat = triggeredAvg( mPCA_out{1}.readoutZ_unroll(:,1:nDimToShow), alignDat.eventIdx(trlCodes==codeList(c)), tw_all );

        for dimIdx=1:nDimToShow
            subtightplot(nDimToShow,length(currIdx),dimIdx);
            hold on;

            imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),[-1 1]);
            axis tight;
            plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);

            cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
            colormap(cMap);

            %title(movLabels{c});
            if dimIdx==1
                ylabel(movLabels{c},'FontSize',16,'FontWeight','bold');
            end
            if c==1
                title(['Dimension ' num2str(dimIdx)],'FontSize',16);
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
end

%%
%make data cubes for each condition & save
dat = struct();

for t=1:length(codeList)
    concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(trlCodes==codeList(t)), [-99, 5000] );
    dat.(movLabels{t}) = concatDat;
end

save('sentenceCube.mat','-struct','dat');