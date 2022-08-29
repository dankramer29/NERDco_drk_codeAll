%%
blockList = [7 8];
sessionName = 't5.2019.04.08';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Pilot' filesep sessionName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

alignedCube = load('hwCube_aligned.mat');

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
timeWindow = [-1000,4000];
binMS = 10;
alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
meanRate = mean(alignDat.rawSpikes)*1000/binMS;
tooLow = meanRate < 1.0;
alignDat.rawSpikes(:,tooLow) = [];
alignDat.meanSubtractSpikes(:,tooLow) = [];
alignDat.zScoreSpikes(:,tooLow) = [];

smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);

trlCodes = alignDat.currentMovement(alignDat.eventIdx);
nothingTrl = trlCodes==218;

%%
timeWindow_mpca = [-500,3500];
tw =  timeWindow_mpca/binMS;
tw(1) = tw(1) + 1;
tw(2) = tw(2) - 1;
    
margGroupings = {{1, [1 2]}, {2}};
margNames = {'Condition-dependent', 'Condition-independent'};
opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 8;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

%      LETTER_A(400)
%      LETTER_B(401)
%      LETTER_C(402)
%      LETTER_D(403)
%      LETTER_T(404)
%      LETTER_M(405)
%      LETTER_O(406)
%       
%      LETTER_CAT(407)
%      LETTER_BAT(408)
%      LETTER_BOMB(409)
%      LETTER_TOM(410)

wordCodes = [407, 408, 410, 411];
codeSets = {wordCodes};

mPCA_out = cell(length(codeSets),1);
for pIdx=1:length(codeSets) 
    trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
    mc = trlCodes(trlIdx)';
    [~,~,mc_oneStart] = unique(mc);
    
    mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes, alignDat.eventIdx(trlIdx), ...
        mc_oneStart, tw, binMS/1000, opts_m );
end

%%
codeList = [wordCodes];
movLabels = {'cat','bat','tom','mat'};

tw_all = [-99, 399];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;
nDimToShow = 5;

figure('Position',[174    83   908   913]);
for c=1:length(codeList)
    concatDat = triggeredAvg( mPCA_out{pIdx}.readoutZ_unroll(:,1:nDimToShow), alignDat.eventIdx(trlCodes==codeList(c)), tw_all );
    
    for dimIdx=1:nDimToShow
        subtightplot(11,nDimToShow,(c-1)*nDimToShow + dimIdx);
        hold on;
        
        imagesc(timeAxis, 1:size(concatDat,1), squeeze(concatDat(:,:,dimIdx)),[-1 1]);
        axis tight;
        plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
        plot([3,3],get(gca,'YLim'),'-k','LineWidth',2);
        
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
