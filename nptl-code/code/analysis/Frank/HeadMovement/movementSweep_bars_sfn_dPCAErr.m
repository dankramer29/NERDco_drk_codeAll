%%
%see movementTypes.m for code definitions
movTypes = {[5 6],'head'
    [8 9],'face'
    [12 13],'arm'
    [16 17],'leg'
    [20 21],'tongue'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);
excludeChannels = [];

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1200 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'all'];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep 't5.2017.10.16' filesep];

%%
%load cursor filter for threshold values, use these across all movement types
model = load([paths.dataPath filesep 'BG Datasets' filesep 't5.2017.10.16' filesep 'Data' filesep 'Filters' filesep ...
    '002-blocks002-thresh-4.5-ch50-bin15ms-smooth25ms-delay0ms.mat']);

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, setdiff(blockList,[1 2 3]), model.model );

trlCodes = zeros(size(R));
for t=1:length(trlCodes)
    trlCodes(t) = R(t).startTrialParams.currentMovement;
end

alignField = 'goCue';

allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
meanRate = mean(allSpikes)*1000;
tooLow = meanRate < 0.5;

allSpikes(:,tooLow) = [];
%allSpikes = gaussSmooth_fast(allSpikes, 30);

globalIdx = 0;
alignEvents = zeros(length(R),2);
allBlocks = zeros(size(allSpikes,1),1);
for t=1:length(R)
    loopIdx = (globalIdx+1):(globalIdx + length(R(t).spikeRaster));
    allBlocks(loopIdx) = R(t).blockNum;
    alignEvents(t,1) = globalIdx + R(t).(alignField);
    alignEvents(t,2) = globalIdx + R(t).trialStart;
    globalIdx = globalIdx + size(R(t).spikeRaster,2);
end

[trlCodeList,~,trlCodesRemap] = unique(trlCodes);

%%
nBins = (timeWindow(2)-timeWindow(1))/binMS;
snippetMatrix = zeros(nBins, size(allSpikes,2));
blockRows = zeros(nBins, 1);
validTrl = false(length(trlCodes),1);
globalIdx = 1;

for t=1:length(trlCodes)
    disp(t);
    loopIdx = (alignEvents(t,1)+timeWindow(1)):(alignEvents(t,1)+timeWindow(2));

    if loopIdx(1)<1 || loopIdx(end)>size(allSpikes,1)
        loopIdx(loopIdx<1)=[];
        loopIdx(loopIdx>size(allSpikes,1))=[];
    else
        validTrl(t) = true;
    end
        
    newRow = zeros(nBins, size(allSpikes,2));
    binIdx = 1:binMS;
    for b=1:nBins
        if binIdx(end)>length(loopIdx)
            continue;
        end
        newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
        binIdx = binIdx + binMS;
    end

    newIdx = (globalIdx):(globalIdx+nBins-1);
    globalIdx = globalIdx+nBins;
    blockRows(newIdx) = repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1);
    snippetMatrix(newIdx,:) = newRow;
end

%%
bNumPerTrial = [R.blockNum];
for b=1:length(blockList)
    disp(b);
    blockTrl = find(bNumPerTrial==blockList(b));
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (alignEvents(blockTrl(t),2)):(alignEvents(blockTrl(t),2)+400)];
    end
    
    binIdx = find(blockRows==blockList(b));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(binIdx,:)));
end
rawSnippetMatrix = snippetMatrix;
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix, 3);

%%
clear R allSpikes
pack;

%%
%across all conditions
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesRemap, [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );
close(gcf);

%%
movWindow = 20:100;
baselineWindow = -140:-100;

cVar = zeros(length(trlCodeList),1);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
codes = cell(size(movTypes,1),2);
all_dPCA = cell(size(movTypes,1),2);

for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    trlIdx = find(trlIdx);
    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
    tmpCodes = trlCodesRemap(trlIdx);
    shuffledCodes = tmpCodes(randperm(length(tmpCodes)));
    
    dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
    close(gcf);
    
    all_dPCA{pIdx} = dPCA_out;
    
    cdIdx = find(dPCA_out.whichMarg==1);
    cdIdx = cdIdx(1:8);
    
    dimCI = dPCA_CI( dPCA_out, smoothSnippetMatrix, eventIdx(trlIdx), tmpCodes, timeWindow/binMS );
    yAxesFinal = oneFactor_dPCA_plot_pretty( dPCA_out, timeAxis, lineArgs, {'CD','CI'}, 'sameAxes', [], [], dimCI, colors );
    
    %conservative cross-validated dPCA
    allW = cell(length(tmpCodes),1);
    lambdaToUse = [];
    for x=1:length(tmpCodes)
        disp(x);
        leaveOneOutIdx = setdiff(1:length(tmpCodes),x);
        dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx(leaveOneOutIdx)), ...
            tmpCodes(leaveOneOutIdx), timeWindow/binMS, binMS/1000, {'CI','CD'},20,lambdaToUse );
        close(gcf);
        
        lambdaToUse = dPCA_out.optimalLambda;
        allW{x} = dPCA_out;
    end
        
    %sort dimensions by factor 
    resortW = allW;
    nPerMarg = 6;
    
    nFactors = 2;
    for x=1:length(allW)
        resortW{x}.whichMarg = zeros(nPerMarg*nFactors,1);
        margIdx = 1:nPerMarg;
        
        for n=1:nFactors
            axIdx = find(allW{x}.whichMarg==n);
            axIdx = axIdx(1:nPerMarg);
            
            resortW{x}.whichMarg(margIdx) = n;
            resortW{x}.W(:,margIdx) = allW{x}.W(:,axIdx);
            
            if n<nFactors
                margIdx = margIdx + nPerMarg;
            end
        end
        resortW{x}.W(:,(margIdx(end)+1):end) = [];
    end
    
    allDim1 = [];
    for x=1:length(allW)
        allDim1 = [allDim1; resortW{x}.W(:,1)'];
    end
    
    figure
    hold on
    plot(resortW{1}.W(:,1));
    plot(allW{1}.W(:,3));
    
    figure
    hold on
    plot(allDim1');
    plot(allW{1}.W(:,3),'LineWidth',2);
    
    %realign dimensions by sign only
    for x=1:length(resortW)
        dotProduct = sum(resortW{x}.W.*resortW{1}.W);
        resortW{x}.W = resortW{x}.W .* sign(dotProduct);
    end
    
    nDim = size(resortW{1}.W,2);
    nSteps = size(dPCA_out.featureAverages,3);
    codeList = unique(tmpCodes);
    tWin = timeWindow/binMS;
    Z = zeros(nDim,size(dPCA_out.featureAverages,2),size(dPCA_out.featureAverages,3));
    dimCI = zeros(nDim,size(dPCA_out.featureAverages,2),size(dPCA_out.featureAverages,3),2);
    
    for dimIdx=1:nDim
        for conIdx=1:size(dPCA_out.featureAverages,2)
            innerTrlIdx = find(tmpCodes==codeList(conIdx));
            concatDat = zeros(length(innerTrlIdx),nSteps);
            for x=1:length(innerTrlIdx)
                loopIdx = ((eventIdx(trlIdx(innerTrlIdx(x)))+tWin(1)):(eventIdx(trlIdx(innerTrlIdx(x)))+tWin(2)))+1;
                concatDat(x,:) = smoothSnippetMatrix(loopIdx,:) * resortW{innerTrlIdx(x)}.W(:,dimIdx);
            end

            [MUHAT,SIGMAHAT,MUCI,SIGMACI] = normfit(concatDat);
            dimCI(dimIdx,conIdx,:,:) = MUCI';
            Z(dimIdx,conIdx,:) = MUHAT;
        end
    end
    
    dPCA_cval = struct();
    dPCA_cval.Z = Z;
    dPCA_cval.explVar = resortW{1}.explVar;
    dPCA_cval.whichMarg = resortW{1}.whichMarg;
    
    codeList = unique(tmpCodes);
    colors = jet(length(codeList))*0.8;
    lineArgs = cell(length(codeList),1);
    for l=1:length(lineArgs)
        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
    end
    timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
    yAxesFinal = oneFactor_dPCA_plot_pretty( dPCA_cval, timeAxis, lineArgs, {'CD','CI'}, 'sameAxes', [], [], dimCI, colors );
    
    dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'}, 20, 'xval' );
    yAxesFinal = oneFactor_dPCA_plot_pretty( dPCA_out, timeAxis, lineArgs, {'CD','CI'}, 'sameAxes', [], [], dPCA_out.dimCI, colors );

%     reducedSnippedMatrix = snippetMatrix * dPCA_out.W(:,cdIdx);
% 
%     for codeIdx=1:length(codes{pIdx,2})
%         dataLabels = [];
%         dataMatrix = [];
%         trlIdxForThisCode = trlIdx(tmpCodes==codes{pIdx,2}(codeIdx));
%         for x=1:length(trlIdxForThisCode)
%             loopIdxWindow = eventIdx(trlIdxForThisCode(x))+movWindow;
%             loopIdxBaseline = eventIdx(trlIdxForThisCode(x))+baselineWindow;
%             if any(loopIdxBaseline<=0) || any(loopIdxWindow<=0)
%                 continue;
%             end
%             
%             dataMatrix = [dataMatrix; mean(reducedSnippedMatrix(loopIdxBaseline,:)); mean(reducedSnippedMatrix(loopIdxWindow,:))];
%             dataLabels = [dataLabels; 1; 2];
%         end
%         
%         nResample = 10000;
%         testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
%         resampleVec = zeros(nResample,1);
%         for resampleIdx=1:nResample
%             shuffLabels = dataLabels(randperm(length(dataLabels)));
%             resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
%         end
%         
%         cVar(codes{pIdx,2}(codeIdx),1) = testStat;
%         cVar(codes{pIdx,2}(codeIdx),2) = prctile(resampleVec,99);
%         
%         resampleVec = zeros(nResample,1);
%         for resampleIdx=1:nResample
%             class2 = dataMatrix(dataLabels==2,:);
%             class2 = class2(randi(size(class2,1), size(class2,1), 1),:);
%             
%             class1 = dataMatrix(dataLabels==1,:);
%             class1 = class1(randi(size(class1,1), size(class1,1), 1),:);
%             
%             testStat = norm(mean(class2) - mean(class1));
%             resampleVec(resampleIdx) = testStat;
%         end
%         cVar(codes{pIdx,2}(codeIdx),3:4) = prctile(resampleVec,[2.5,97.5]);    
%     end
end    

%%
%bar plot
movLegends = {{'SayBa','SayGa','MouthOpen','JawClench','LipsPucker','EyebrowsRaise','NoseWrinkle'}    
{'Up','Down','Left','Right'}
{'TurnRight','TurnLeft','TurnUp','TurnDown','TiltRight','TiltLeft','Forward','Backward'}
{'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise'}
{'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'}
    };
movLabels = horzcat(movLegends{:});

colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

figure('Position',[164   751   989   338]);
plotIdx = 1;
colorIdx = 1;

hold on
for pIdx=[2 5 1 3 4]
    dat = cVar(codes{pIdx,2},1) - cVar(codes{pIdx,2},2);
    CI = cVar(codes{pIdx,2},3:4) - cVar(codes{pIdx,2},2);
    
    xAxis = (plotIdx):(plotIdx + length(dat) - 1);
    bar(xAxis, dat, 'FaceColor', colors(colorIdx,:), 'LineWidth', 1);
    %for x=1:length(dat)
    %    plot([plotIdx+x-1, plotIdx+x-1], CI(x,:), '-k','LineWidth',1);
    %end
    errorbar(xAxis, dat, dat-CI(:,1), CI(:,2)-dat, '.k','LineWidth',1);
    
    plotIdx = plotIdx + length(dat);
    colorIdx = colorIdx + 1;
end
set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabels,'XTickLabelRotation',45);

axis tight;
xlim([0.5, 33.5]);
ylabel('\Delta Neural Activity\newlinein Separating Dimensions\newline(a.u.)','FontSize',22);
set(gca,'TickLength',[0 0]);

saveas(gcf,[outDir filesep 'bar_dPCA.png'],'png');
saveas(gcf,[outDir filesep 'bar_dPCA.svg'],'svg');
saveas(gcf,[outDir filesep 'bar_dPCA.pdf'],'pdf');

%%
for pIdx=[2 5 1 3 4]
    dat = cVar(codes{pIdx,2},1) - cVar(codes{pIdx,2},2);
    disp(mean(dat));
end

%%
timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
yLims = [];
axHandles=[];
plotIdx = 1;

movTypeText = {'Face','Tongue','Neck','Arm','Leg'};

figure('Position',[272         833        1551         272]);
for pIdx=[2 5 1 3 4]
    cdIdx = find(all_dPCA{pIdx}.whichMarg==1);
    axHandles(plotIdx) = subtightplot(1,length(movTypes),plotIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
    hold on

    colors = jet(size(all_dPCA{pIdx}.Z,2))*0.8;
    for conIdx=1:size(all_dPCA{pIdx}.Z,2)
        plot(timeAxis, squeeze(all_dPCA{pIdx}.Z(cdIdx(1),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
    end

    axis tight;
    yLims = [yLims; get(gca,'YLim')];
    
    plot(get(gca,'XLim'),[0 0],'k');
    plot([0, 0],[-100, 100],'--k','LineWidth',2);
    if ismember(pIdx,[3 4])
        plot([2.5, 2.5],[-100, 100],'--k','LineWidth',2);
        text(0.95,0.8,'Return','Units','Normalized','FontSize',16);
    elseif ismember(pIdx,[1 2 5 6])
        plot([1.5, 1.5],[-100, 100],'--k','LineWidth',2);
        text(0.7,0.8,'Return','Units','Normalized','FontSize',16);
    end
    set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

    if pIdx==length(movTypes)
        xlabel('Time (s)');
    else
        set(gca,'XTickLabels',[]);
    end
    text(0.3,0.8,'Go','Units','Normalized','FontSize',16);
    
    
    plot([0,0.5]+0.2,[-1,-1],'-k','LineWidth',2);

    title(movTypeText{plotIdx},'FontSize',22);
    lHandle = legend(movLegends{plotIdx},'Location','West','box','off','FontSize',16);
    lPos = get(lHandle,'Position');
    lPos(1) = lPos(1)+0.05;
    set(lHandle,'Position',lPos);
    axis off;
    plotIdx = plotIdx + 1;
end

finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
for p=1:length(axHandles)
    set(axHandles(p), 'YLim', finalLimits);
end

saveas(gcf,[outDir filesep 'dPCA_oneDim.png'],'png');
saveas(gcf,[outDir filesep 'dPCA_oneDim.svg'],'svg');

%%
%raw data test
movWindow = 20:100;
baselineWindow = -140:-100;

cVar = zeros(length(trlCodeList),1);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
codes = cell(size(movTypes,1),2);
all_dPCA = cell(size(movTypes,1),2);

allP = [];
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    trlIdx = find(trlIdx);
    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
    tmpCodes = trlCodesRemap(trlIdx);
    
    dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
    close(gcf);
    
    all_dPCA{pIdx} = dPCA_out;
    
    cdIdx = find(dPCA_out.whichMarg==1);
    cdIdx = cdIdx(1:8);
    
    cLoopIdx = expandEpochIdx([ eventIdx(trlIdx)', eventIdx(trlIdx)'+75]);
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(dPCA_out.featureAverages(:,:)');
    reducedSnippetMatrix = snippetMatrix*COEFF(:,1:5);
    %reducedSnippetMatrix = snippetMatrix;

    for codeIdx=1:length(codes{pIdx,2})
        dataLabels = [];
        dataMatrix = [];
        trlIdxForThisCode = trlIdx(tmpCodes==codes{pIdx,2}(codeIdx));
        for x=1:length(trlIdxForThisCode)
            loopIdxWindow = eventIdx(trlIdxForThisCode(x))+movWindow;
            loopIdxBaseline = eventIdx(trlIdxForThisCode(x))+baselineWindow;
            if any(loopIdxBaseline<=0) || any(loopIdxWindow<=0)
                continue;
            end
            
            dataMatrix = [dataMatrix; mean(reducedSnippetMatrix(loopIdxBaseline,:)); mean(reducedSnippetMatrix(loopIdxWindow,:))];
            dataLabels = [dataLabels; 1; 2];
        end
        
        [D,P,STATS]=manova1(dataMatrix, dataLabels);
        allP = [allP; P];
        
%         nResample = 10000;
%         testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
%         resampleVec = zeros(nResample,1);
%         for resampleIdx=1:nResample
%             shuffLabels = dataLabels(randperm(length(dataLabels)));
%             resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
%         end
%         
%         cVar(codes{pIdx,2}(codeIdx),1) = testStat;
%         cVar(codes{pIdx,2}(codeIdx),2) = prctile(resampleVec,99);
%         
%         resampleVec = zeros(nResample,1);
%         for resampleIdx=1:nResample
%             class2 = dataMatrix(dataLabels==2,:);
%             class2 = class2(randi(size(class2,1), size(class2,1), 1),:);
%             
%             class1 = dataMatrix(dataLabels==1,:);
%             class1 = class1(randi(size(class1,1), size(class1,1), 1),:);
%             
%             testStat = norm(mean(class2) - mean(class1));
%             resampleVec(resampleIdx) = testStat;
%         end
%         cVar(codes{pIdx,2}(codeIdx),3:4) = prctile(resampleVec,[2.5,97.5]);    
    end
end    