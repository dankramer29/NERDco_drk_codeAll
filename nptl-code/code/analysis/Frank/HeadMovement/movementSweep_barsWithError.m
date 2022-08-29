%%
%TODO:

%decoding methods for excluding dimensions of variation in other datasets
%exclude trial-averaged modulation? sample-by-sample modulation? variable
%penalty strength term? Rigid orothongalization?

%simulation - how many channels are needed to reliably separate how many
%dimensions?

%contralateral vs. ipsilateral, directional arm imagery

%combine leg & arm to boost signal? 

%show real-time increase in independence and ability to separate

%%
%see movementTypes.m for code definitions
movTypes = {[5 6],'head'
    [8 9],'face'
    [12 13],'arm'
    [16 17],'leg'
    [20 21],'tongue'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

burstChans = [67, 68, 69, 73, 77, 78, 82];
smallBurstChans = [2, 46, 66, 76, 83, 85, 86, 94, 95, 96]; %  to be super careful
excludeChannels = sort( [burstChans, smallBurstChans ] );

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
allSpikes = gaussSmooth_fast(allSpikes, 30);

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

%%
%load cursor dataset
R_curs = getSTanfordBG_RStruct( sessionPath, [2 3], model.model );

R_curs(1) = [];
opts.filter = false;
opts.useDecodeSpeed = true;
data = unrollR_1ms(R_curs, opts);

trlCodes_curs = data.targCodes;
centerIdx = find(trlCodes_curs==5);
trlCodes_curs(centerIdx) = trlCodes_curs(centerIdx-1)+9;

allBlockNum_curs = [R_curs.blockNum]';
alignField = 'timeGoCue';

allSpikes_curs = [[R_curs.spikeRaster]', [R_curs.spikeRaster2]'];
allSpikes_curs(:,tooLow) = [];
allSpikes_curs = gaussSmooth_fast(allSpikes_curs, 30);

globalIdx = 0;
alignEvents_curs = zeros(length(R_curs),2);
allBlocks_curs = zeros(size(allSpikes_curs,1),1);
for t=1:length(R_curs)
    loopIdx = (globalIdx+1):(globalIdx + length(R_curs(t).spikeRaster));
    allBlocks_curs(loopIdx) = R_curs(t).blockNum;
    alignEvents_curs(t,1) = globalIdx + R_curs(t).(alignField);
    alignEvents_curs(t,2) = globalIdx - 300;
    globalIdx = globalIdx + size(R_curs(t).spikeRaster,2);
end

cursPosErr = data.targetPos(:,1:4) - data.cursorPos(:,1:4);

%%
%combine cursor & cued movement conditions
trlCodes = [trlCodes_curs', trlCodes];
[trlCodeList,~,trlCodesRemap] = unique(trlCodes);
alignEvents = [alignEvents_curs; alignEvents+size(allSpikes_curs,1)];
allSpikes = [allSpikes_curs; allSpikes];
allBlocks = [allBlocks_curs; allBlocks];
allPosErr = [cursPosErr; zeros(size(allSpikes,1),4)];

%%
nBins = (timeWindow(2)-timeWindow(1))/binMS;
posErrMatrix = zeros(nBins, size(allPosErr,2));
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
    newPosErrRow = zeros(nBins, 4);
    binIdx = 1:binMS;
    for b=1:nBins
        if binIdx(end)>length(loopIdx)
            continue;
        end
        newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
        newPosErrRow(b,:) = mean(allPosErr(loopIdx(binIdx),:));
        binIdx = binIdx + binMS;
    end

    newIdx = (globalIdx):(globalIdx+nBins-1);
    globalIdx = globalIdx+nBins;
    blockRows(newIdx) = repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1);
    posErrMatrix(newIdx,:) = newPosErrRow;
    snippetMatrix(newIdx,:) = newRow;
end

%%
bNumPerTrial = [[R_curs.blockNum],[R.blockNum]];
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

%%
baselineWindow = 1:20;
windows = {150:170, 80:120};
windowNames = {'Move','Prep'};

%%
%shuffle control
if exist([outDir filesep 'shuffleControl.mat'],'file')
    load([outDir filesep 'shuffleControl.mat']);
else
    nShuffle = 10;
    shuffModIdx = zeros(nShuffle, length(trlCodeList), length(windows));

    for n=1:nShuffle
        disp(n);
        dPCA_out = cell(size(movTypes,1),1);
        eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
        codes = cell(size(movTypes,1),2);
        for pIdx = 1:size(movTypes,1)
            trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
            if strcmp(movTypes{pIdx,2},'cursor_CL')
                %ignore return
                trlIdx(trlCodes(trlIdx)>9)=false;
            end

            codes{pIdx,1} = unique(trlCodes(trlIdx));
            codes{pIdx,2} = unique(trlCodesRemap(trlIdx));

            %shuffle
            tmpCodes = trlCodesRemap(trlIdx);
            shuffIdx = randperm(length(tmpCodes));
            tmpCodes = tmpCodes(shuffIdx);

            dPCA_out{pIdx} = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
                tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
            close(gcf);
        end    

        for windowIdx = 1:length(windows)
            for pIdx = 1:size(movTypes,1)
                cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
                for x=1:size(dPCA_out{pIdx}.Z,2)
                    tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,windows{windowIdx}))';
                    baseline = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,baselineWindow))';
                    shuffModIdx(n,codes{pIdx,2}(x),windowIdx) = norm(mean(tmp)-mean(baseline));
                end
            end    
        end
    end
    save([outDir filesep 'shuffleControl.mat'],'shuffModIdx','windows');
end
shuffCutoff = squeeze(shuffModIdx(1,:,:));

%%
%bootstrapped magnitude
if exist([outDir filesep 'bootstrapMagnitudes.mat'],'file')
    load([outDir filesep 'bootstrapMagnitudes.mat']);
else
    nBoot = 10;
    cVar = zeros(nBoot,length(trlCodeList),length(windows));

    for bootIdx = 1:nBoot
        disp(bootIdx);
        dPCA_out = cell(size(movTypes,1),1);
        eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
        codes = cell(size(movTypes,1),2);
        for pIdx = 1:size(movTypes,1)
            trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
            if strcmp(movTypes{pIdx,2},'cursor_CL')
                %ignore return
                trlIdx(trlCodes(trlIdx)>9)=false;
            end
            trlIdx = find(trlIdx);

            codeList = unique(trlCodes(trlIdx));
            for codeIdx=1:length(codeList)
                tmpIdx = find(trlCodes(trlIdx)==codeList(codeIdx));
                shuffIdx = randi(length(tmpIdx),length(tmpIdx),1);
                trlIdx(tmpIdx) = trlIdx(tmpIdx(shuffIdx));
            end

            codes{pIdx,1} = unique(trlCodes(trlIdx));
            codes{pIdx,2} = unique(trlCodesRemap(trlIdx));

            tmpCodes = trlCodesRemap(trlIdx);
            shuffIdx = randperm(length(tmpCodes));
            if doShuff == 2
                tmpCodes = tmpCodes(shuffIdx);
            end

            dPCA_out{pIdx} = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
                tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
            close(gcf);
        end    

        for windowIdx = 1:length(windows)
            for pIdx = 1:size(movTypes,1)
                cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
                for x=1:size(dPCA_out{pIdx}.Z,2)
                    tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,windows{windowIdx}))';
                    baseline = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,baselineWindow))';
                    cVar(bootIdx,codes{pIdx,2}(x),windowIdx) = norm(mean(tmp)-mean(baseline));
                end
            end    
        end
    end
    save([outDir filesep 'bootstrapMagnitudes.mat'],'cVar','windows');
end

%%
%hotelling's T2 test
%baselineWindow = 1:20;
%windows = {150:170, 80:120};
movWindow = 50:70;
baselineWindow = -120:-100;

cVar = zeros(length(trlCodeList),1);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
codes = cell(size(movTypes,1),2);
all_dPCA = cell(size(movTypes,1),2);

for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    if strcmp(movTypes{pIdx,2},'cursor_CL')
        %ignore return
        trlIdx(trlCodes(trlIdx)>9)=false;
    end
    trlIdx = find(trlIdx);
    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
    tmpCodes = trlCodesRemap(trlIdx);
    
    dPCA_out = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
        tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
    close(gcf);
    
    all_dPCA{pIdx} = dPCA_out;
    
    cdIdx = find(dPCA_out.whichMarg==1);
    cdIdx = cdIdx(1:8);
    reducedSnippedMatrix = snippetMatrix * dPCA_out.W(:,cdIdx);
    
%     dataDim = size(dPCA_out.featureAverages);
%     X = dPCA_out.featureAverages(:,:)';
%     Xcen = bsxfun(@minus, X, mean(X));
%     Z = Xcen * dPCA_out.pca_result.W;
%     Z = reshape(Z', [size(Z,2) dataDim(2:end)]);
%     dPCA_out.pca_result.Z = Z;
%     
%     colors = hsv(length(codes{pIdx,1}))*0.8;
%     lineArgs = cell(length(codes{pIdx,1}),1);
%     for c=1:size(colors,1)
%         lineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
%     end
%     oneFactor_dPCA_plot_pretty( dPCA_out.pca_result,  0.01*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), lineArgs, {'CD','CI'}, 'zoom');
%     oneFactor_dPCA_plot_pretty( dPCA_out,  0.01*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), lineArgs, {'CD','CI'}, 'zoom');
    
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
            
            dataMatrix = [dataMatrix; mean(reducedSnippedMatrix(loopIdxBaseline,:)); mean(reducedSnippedMatrix(loopIdxWindow,:))];
            dataLabels = [dataLabels; 1; 2];
        end
        
        nResample = 1000;
        testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
        end
        
        cVar(codes{pIdx,2}(codeIdx)) = testStat - prctile(resampleVec,99);
        
        %figure; 
        %hold on; 
        %hist(resampleVec,20); 
        %plot([testStat, testStat],get(gca,'YLim'),'--k','LineWidth',2);
    end
end    

%%
%bar plot
colors = hsv(length(movTypes))*0.8;
colors = colors(randperm(length(movTypes)),:);

figure('Position',[802         173        1197         897]);
movLabels = horzcat(movLegends{:});
plotIdx = 1;

hold on
for pIdx=1:size(movTypes,1)
    dat = cVar(codes{pIdx,2});
    
    bar((plotIdx):(plotIdx + length(dat) - 1), dat, 'FaceColor', colors(pIdx,:));
    plotIdx = plotIdx + length(dat);
end
set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabels,'XTickLabelRotation',45);

xlim([0.5, 45.5]);
ylabel('Neural Modulation');
set(gca,'TickLength',[0 0]);

%%
%raw HZ
movWindow = 50:90;
baselineWindow = -120:-80;

cVar = zeros(length(trlCodeList),4);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
codes = cell(size(movTypes,1),2);
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    if strcmp(movTypes{pIdx,2},'cursor_CL')
        %ignore return
        trlIdx(trlCodes(trlIdx)>9)=false;
    end
    trlIdx = find(trlIdx);
    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
    tmpCodes = trlCodesRemap(trlIdx);
    
    reducedSnippetMatrix = snippetMatrix;
    
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
        
        nResample = 1000;
        %testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        testStat = mean(abs(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:))));
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            %resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
            resampleVec(resampleIdx) = mean(abs((mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)))));
        end
        
        cVar(codes{pIdx,2}(codeIdx),1) = testStat;
        cVar(codes{pIdx,2}(codeIdx),2) = prctile(resampleVec,99);
        
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            class2 = dataMatrix(dataLabels==2,:);
            class2 = class2(randi(size(class2,1), size(class2,1), 1),:);
            
            class1 = dataMatrix(dataLabels==1,:);
            class1 = class1(randi(size(class1,1), size(class1,1), 1),:);
            
            %testStat = norm(mean(class2) - mean(class1));
            testStat = mean(abs(mean(class2) - mean(class1)));
            resampleVec(resampleIdx) = testStat;
        end
        cVar(codes{pIdx,2}(codeIdx),3:4) = prctile(resampleVec,[2.5,97.5]);        
    end
end    

%%
%bar plot
colors = hsv(length(movTypes))*0.8;
colors = colors(randperm(length(movTypes)),:);

figure('Position',[802         173        1197         897]);
movLabels = horzcat(movLegends{:});
plotIdx = 1;

hold on
for pIdx=1:size(movTypes,1)
    dat = cVar(codes{pIdx,2},1) - cVar(codes{pIdx,2},2);
    CI = cVar(codes{pIdx,2},3:4) - cVar(codes{pIdx,2},2);
    
    bar((plotIdx):(plotIdx + length(dat) - 1), dat, 'FaceColor', colors(pIdx,:));
    for x=1:length(dat)
        plot([plotIdx+x-1, plotIdx+x-1], CI(x,:), '-k','LineWidth',2);
    end
    
    plotIdx = plotIdx + length(dat);
end
set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabels,'XTickLabelRotation',45);

xlim([0.5, 45.5]);
ylabel('Neural Modulation');
set(gca,'TickLength',[0 0]);

%%
%bar plot
colors = hsv(length(movTypes))*0.8;
colors = colors(randperm(length(movTypes)),:);
baselineWindow = 1:20;
windows = {150:170, 80:120};
windowNames = {'Move','Prep'};
cVar = zeros(length(trlCodeList),length(windows));

figure('Position',[802         173        1197         897]);
for windowIdx = 1:length(windows)

    for pIdx = 1:size(movTypes,1)
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        for x=1:size(dPCA_out{pIdx}.Z,2)
            %tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:5),x,:))';
            %cVar(codes{pIdx,2}(x)) = sqrt(sum(var(tmp)));
            %tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:10),x,windows{windowIdx}));
            %cVar(codes{pIdx,2}(x)) = (sum(tmp(:).^2));
            %tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,windows{windowIdx}))';
            %cVar(codes{pIdx,2}(x)) = (sum(abs(mean(tmp))));
            tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,windows{windowIdx}))';
            baseline = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,baselineWindow))';
            cVar(codes{pIdx,2}(x),windowIdx) = norm(mean(tmp)-mean(baseline));
        end
    end    

    if doShuff==1
        cVar(:,windowIdx) = cVar(:,windowIdx) - shuffCutoff(:,windowIdx);
    end
    if strcmp(windowNames{windowIdx},'Prep')
        cVar(1:16,windowIdx)=0;
    end
    movLabels = horzcat(movLegends{:});
    plotIdx = 1;

    subtightplot(2,1,windowIdx,[0.05 0.05],[0.15 0.05],[0.05 0.01]);
    hold on
    for pIdx=1:size(movTypes,1)
        dat = cVar(codes{pIdx,2},windowIdx);
        bar((plotIdx):(plotIdx + length(dat) - 1), dat, 'FaceColor', colors(pIdx,:));
        plotIdx = plotIdx + length(dat);
    end
    title(windowNames{windowIdx});
    set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
    if windowIdx==2
        set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabels,'XTickLabelRotation',45);
    end

    ylim([0 8]);
    xlim([0.5, 45.5]);
    ylabel('Neural Modulation');
    set(gca,'TickLength',[0 0]);
end

saveas(gcf,[outDir filesep 'bar_all_window' shuffPostfix{doShuff} '.png'],'png');
saveas(gcf,[outDir filesep 'bar_all_window' shuffPostfix{doShuff} '.svg'],'svg');