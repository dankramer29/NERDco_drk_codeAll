%%
blockList = [5 7 9 12 14 18 20];
sessionName = 't5.2019.05.01';

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

%%
%get word text
wordText = cell(length(trlCodes),1);
for t=1:length(trlCodes)
    wordText{t} = getMovementText(uint16(trlCodes(t)));
    wordText{t} = deblank(wordText{t}(10:end));
end

%mov times
movTime = zeros(length(allR),1);
for t=1:length(trlCodes)
    movTime(t) = (allR(t).restCue - allR(t).goCue)/1000;
end

nChar = zeros(length(wordText),1);
for t=1:length(wordText)
    nChar(t) = length(wordText{t});
end

%%
%cpm for each block

%%
%letter-specific regression
Y = movTime;
X = zeros(length(Y),27);
X(:,1) = 1;

alphabet = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','y','x','z'};
for t=1:length(trlCodes)
    for a=1:length(alphabet)
        idx = strfind(wordText{t}, alphabet{a});
        if isempty(idx)
            X(t,a+1) = 0;
        else
            X(t,a+1) = length(idx);
        end
    end
end

[B,BINT,R,RINT] = regress(Y(200:350,:),X(200:350,:));

figure
bar(B(2:end),'LineWidth',2,'FaceColor','w');
set(gca,'XTick',1:26,'XTickLabel',alphabet);
set(gca,'FontSize',20,'LineWidth',2);

%%
%make data cubes for each condition & save
dat = struct();

for t=1:length(movLabels)
    concatDat = triggeredAvg( alignDat.zScoreSpikes, alignDat.eventIdx(trlCodes==fullCodes(t)), [-50,150] );
    dat.(movLabels{t}) = concatDat;
end

save('alphabetCube_wordDay.mat','-struct','dat');

%%
%substitute in aligned data
alignedCube = load('alphabetCube_aligned.mat');
alignDat.zScoreSpikes_align = alignDat.zScoreSpikes;

for t=1:length(movLabels)
    trlIdx = find(trlCodes==letterCodes(t));
    for x=1:length(trlIdx)
        loopIdx = (alignDat.eventIdx(trlIdx(x))-49):(alignDat.eventIdx(trlIdx(x))+150);
        alignDat.zScoreSpikes_align(loopIdx,:) = alignedCube.(movLabels{t})(x,2:end,:);
    end
end

alignDat.zScoreSpikes_align(isnan(alignDat.zScoreSpikes_align)) = 0;
smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes_align, 3);

%%
timeWindow_mpca = [-500,4000];
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
tw_all = [-49, 250];
timeStep = binMS/1000;
timeAxis = (tw_all(1):tw_all(2))*timeStep;
nDimToShow = 5;
nPerPage = 10;
currIdx = 1:nPerPage;

for pageIdx=1:3
    figure('Position',[680   185   442   913]);
    for conIdx=1:length(currIdx)
        c = currIdx(conIdx);
        if c > length(allCodes)
            break;
        end
        concatDat = triggeredAvg( mPCA_out{1}.readoutZ_unroll(:,1:nDimToShow), alignDat.eventIdx(trlCodes==allCodes(c)), tw_all );

        for dimIdx=1:nDimToShow
            subtightplot(length(currIdx),nDimToShow,(conIdx-1)*nDimToShow + dimIdx);
            hold on;

            tmp = squeeze(concatDat(:,:,dimIdx));
            imagesc(timeAxis, 1:size(concatDat,1), tmp, prctile(tmp(:),[2.5 97.5]));
            axis tight;
            plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);
            plot([1.5,1.5],get(gca,'YLim'),'-k','LineWidth',2);

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
            if c==length(allCodes)
                set(gca,'YTick',[]);
                xlabel('Time (s)');
            else
                set(gca,'XTick',[],'YTick',[]);
            end
        end
    end
    currIdx = currIdx + length(currIdx);
end
