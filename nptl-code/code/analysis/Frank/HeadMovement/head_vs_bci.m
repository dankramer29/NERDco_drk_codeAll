%%
%see movementTypes.m for code definitions
movTypes = {[1 2],'head'
    [3],'bci_ol'
    [4 5 6],'bci_cl'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

excludeChannels = [];
sessionName = 't5.2017.12.27';
filterName = '011-blocks013_014-thresh-4.5-ch60-bin15ms-smooth25ms-delay0ms.mat';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-500 2000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'head_vs_bci'];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%
%load cursor filter for threshold values, use these across all movement types
model = load([paths.dataPath filesep 'BG Datasets' filesep sessionName filesep 'Data' filesep 'Filters' filesep ...
    filterName]);

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, [1 2 3 4 5 6], model.model );

smoothWidth = 30;
datFields = {'windowsMousePosition','cursorPosition','currentTarget','xk'};
binMS = 10;
unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

alignFields = {'timeGoCue'};
smoothWidth = 30;
datFields = {'windowsMousePosition','cursorPosition','currentTarget'};
timeWindow = [-800, 1000];
binMS = 10;
alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

meanRate = mean(alignDat.rawSpikes)*1000/binMS;
tooLow = meanRate < 0.5;
alignDat.rawSpikes(:,tooLow) = [];
alignDat.meanSubtractSpikes(:,tooLow) = [];
alignDat.zScoreSpikes(:,tooLow) = [];
%%
%correlation between head velocity and decoded velocity for cursor blocks
headPos = unrollDat.windowsMousePosition;
headVel = [0 0; diff(headPos)];
[B,A] = butter(4, 10/500);
headVel = filtfilt(B,A,headVel);

cursorVel = unrollDat.xk(:,[2 4]);

clBlocks = find(ismember(unrollDat.blockNum, [4 5 6 13 14]));
satIdx = find(any(abs(headPos)>0.40,2));
clBlocks = setdiff(clBlocks, satIdx);

figure
ax1 = subplot(1,2,1);
hold on;
plot(zscore(headVel(clBlocks,1)));
plot(zscore(cursorVel(clBlocks,1)));

ax2 = subplot(1,2,2);
hold on;
plot(zscore(headVel(clBlocks,2)));
plot(-zscore(cursorVel(clBlocks,2)));

linkaxes([ax1, ax2],'x');

%%
%dPCA, head vs. bci
dPCA_out = cell(size(movTypes,1),1);
trlCodes = nan(length(alignDat.eventIdx),1);
for pIdx = 1:size(movTypes,1)
    trlIdx = find(ismember(alignDat.bNumPerTrial, movTypes{pIdx,1}));
    tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
    
    [targList, ~, targCodes] = unique(tPos,'rows');
    outerIdx = find(targCodes~=5);
    trlCodes(trlIdx(outerIdx)) = targCodes(outerIdx);
    
    dPCA_out{pIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(outerIdx)), ...
        targCodes(outerIdx), timeWindow/binMS, binMS/1000, {'CI','CD'} );
    close(gcf);
end    

trlCodesRemap = trlCodes;
trlCodesRemap(trlCodesRemap>4) = trlCodesRemap(trlCodesRemap>4)-1;

crossCon = 1;
dPCA_cross = dPCA_out;
for c=1:length(dPCA_out)
    dPCA_cross{c}.whichMarg = dPCA_out{crossCon}.whichMarg;
    for axIdx=1:20
        for conIdx=1:size(dPCA_cross{c}.Z,2)
            dPCA_cross{c}.Z(axIdx,conIdx,:) = dPCA_out{crossCon}.W(:,axIdx)' * squeeze(dPCA_cross{c}.featureAverages(:,conIdx,:));
        end
    end
end               
    
crossPostfix = {'_within','_cross'};
for plotCross = 1:2
    movTypeText = {'Head','OL BCI','CL BCI'};
    topN = 8;
    plotIdx = 1;

    timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
    yLims = [];
    axHandles=[];   

    figure('Position',[272         454        1523         651]);
    for pIdx=1:length(movTypes)
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        for c=1:topN
            axHandles(plotIdx) = subtightplot(length(movTypes),topN,(pIdx-1)*topN+c);
            hold on

            colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
            for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                if plotCross==1
                    plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                elseif plotCross==2
                    plot(timeAxis, squeeze(dPCA_cross{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                end
            end

            axis tight;
            yLims = [yLims; get(gca,'YLim')];
            plotIdx = plotIdx + 1;

            plot(get(gca,'XLim'),[0 0],'k');
            plot([0, 0],[-100, 100],'--k');
            set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

            if pIdx==length(movTypes)
                xlabel('Time (s)');
            else
                set(gca,'XTickLabels',[]);
            end
            if pIdx==1
                title(['Dim ' num2str(c)],'FontSize',11)
            end
            text(0.3,0.8,'Go','Units','Normalized','FontSize',12);

            if c==1
                text(-0.45,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
            end
            set(gca,'FontSize',14);
        end
    end

    finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
    for p=1:length(axHandles)
        set(axHandles(p), 'YLim', finalLimits);
    end

    saveas(gcf,[outDir filesep 'dPCA_all' crossPostfix{plotCross} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_all' crossPostfix{plotCross} '.svg'],'svg');
end

%%
%measure trial-averaged result of applying cursor decoder to other
%conditions
nonCursorIdx = 1:83520;

decoder = model.model.K([2 4 2 4],1:192);
decoder = bsxfun(@times, decoder, model.model.invSoftNormVals(1:192)');
decoder(:,tooLow)=[];
decOut = alignDat.meanSubtractSpikes * decoder';
decOut(nonCursorIdx,2) = -decOut(nonCursorIdx,2);

plotIdx = find(~isnan(trlCodes));
decoder_cross_plot( decOut, alignDat.bNumPerTrial(plotIdx), trlCodes(plotIdx), trlCodesRemap(plotIdx), alignDat.eventIdx(plotIdx), ...
    timeAxis, movTypes, [], movTypeText, timeWindow, binMS );

saveas(gcf,[outDir filesep 'decoder_cross.png'],'png');
saveas(gcf,[outDir filesep 'decoder_cross.svg'],'svg');

%%
%make cursor decoder with additional requirement of zero tuning for
%head movement; 
cursorTrl = find(ismember(alignDat.bNumPerTrial, movTypes{3,1}) & ~isnan(trlCodes));
headTrl = find(ismember(alignDat.bNumPerTrial, movTypes{1,1}) & ~isnan(trlCodes));
cursorIdx = expandEpochIdx([alignDat.eventIdx(cursorTrl(1:(end-1)))+10, alignDat.eventIdx(cursorTrl(2:end))]);
headIdx = expandEpochIdx([alignDat.eventIdx(headTrl(1)), alignDat.eventIdx(headTrl(end))]);

%OLE + orthoganlize to PCA dimensions
posErrMatrix = alignDat.currentTarget - alignDat.cursorPosition;
posErrMatrix = posErrMatrix(:,1:2);

orthoCorr = zeros(length(zeroWeights),2);
alphaCoeff = linspace(0,1,5);
for x=1:length(alphaCoeff)
    %orthoDec = buildLinFilts(posErrMatrix(cursorIdx,:), alignDat.zScoreSpikes(cursorIdx,:), 'inverseLinear');
    orthoDec = decoder(1:2,:)';
    
    expFeature = dPCA_out{1}.featureAverages(:,:)';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(expFeature);
    projValues = orthoDec' * COEFF(:,1:8);
    orthoDec = orthoDec - alphaCoeff(x) * (COEFF(:,1:8) * projValues');     

    decOut = alignDat.meanSubtractSpikes * orthoDec(:,[1 2 1 2]);
    decOut(nonCursorIdx,2) = -decOut(nonCursorIdx,2);
    decoder_cross_plot( decOut, alignDat.bNumPerTrial(plotIdx), trlCodes(plotIdx), trlCodesRemap(plotIdx), alignDat.eventIdx(plotIdx), ...
        timeAxis, movTypes, [], movTypeText, timeWindow, binMS );
    orthoCorr(x,:) = diag(corr(decOut(cursorIdx,1:2), posErrMatrix(cursorIdx,1:2)));

    saveas(gcf,[outDir filesep 'ole_ortho_' num2str(x) '.png'],'png');
    saveas(gcf,[outDir filesep 'ole_ortho_' num2str(x) '.svg'],'svg');
end
    