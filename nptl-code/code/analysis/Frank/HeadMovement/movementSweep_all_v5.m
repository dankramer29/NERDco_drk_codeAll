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
    [18 19],'eyes'
    [20 21],'tongue'
    [2 3],'cursor_CL'};
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
pcaMode = 'pca';

%%
%shuffle control
if exist([outDir filesep 'shuffleControl.mat'],'file')
    load([outDir filesep 'shuffleControl.mat']);
else
    nShuffle = 100;
    windows = {150:170, 80:120};
    shuffModIdx = zeros(nShuffle, length(trlCodeList), length(windows));
    shuffModIdx_sq = zeros(nShuffle, length(trlCodeList), length(windows));
    shuffModIdx_ma = zeros(nShuffle, length(trlCodeList), length(windows));
    shuffModIdx_ma_all = zeros(nShuffle, length(trlCodeList), length(windows));
    
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
            if strcmp(pcaMode,'pca')
                dPCA_out{pIdx} = dPCA_out{pIdx}.pca_result;
            end
            close(gcf);
        end    

        for windowIdx = 1:length(windows)
            for pIdx = 1:size(movTypes,1)
                cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
                for x=1:size(dPCA_out{pIdx}.Z,2)
                    tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,windows{windowIdx}))';
                    shuffModIdx(n,codes{pIdx,2}(x),windowIdx) = norm(mean(tmp));
                    shuffModIdx_sq(n,codes{pIdx,2}(x),windowIdx) = mean(tmp(:).^2);
                    shuffModIdx_ma(n,codes{pIdx,2}(x),windowIdx) = mean(abs(tmp(:)));
                    
                    reconActivity = dPCA_out{1}.V(:,cdIdx(1:8)) * squeeze(dPCA_out{1}.Z(cdIdx(1:8),x,:));
                    shuffModIdx_ma_all(n,codes{pIdx,2}(x),windowIdx) = mean(abs(reconActivity(:)));
                end
            end    
        end
    end
    save([outDir filesep 'shuffleControl.mat'],'shuffModIdx','shuffModIdx_sq','shuffModIdx_ma','shuffModIdx_ma_all','windows');
end
shuffCutoff = squeeze(shuffModIdx(1,:,:));
shuffCutoff_sq = squeeze(shuffModIdx_sq(1,:,:));
shuffCutoff_ma = squeeze(shuffModIdx_ma(1,:,:));
shuffCutoff_ma_all = squeeze(shuffModIdx_ma_all(1,:,:));

%%
%summary plots
shuffPostfix = {'','_shuff'};
for doShuff = 1:2
    
    %do dPCA on everything
    dPCA_every = apply_dPCA_simple( snippetMatrix, eventIdx, ...
        trlCodesRemap, timeWindow/binMS, binMS/1000, {'CI','CD'}, 40 );
    
    figure
    plot(dPCA_every.explVar.cumulativePCA,'-o','LineWidth',2);
    xlabel('# of PCs');
    ylabel('Cumulative Variance Explained (%)');
    set(gca,'FontSize',14);
    saveas(gcf,[outDir filesep 'PCA_varExpl' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'PCA_varExpl' shuffPostfix{doShuff} '.svg'],'svg');

    figure
    plot(diff([0, dPCA_every.explVar.cumulativePCA]),'-o','LineWidth',2);
    xlabel('PC #');
    ylabel('Variance Explained (%)');
    set(gca,'FontSize',14);
    saveas(gcf,[outDir filesep 'PCA_varExpl2' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'PCA_varExpl2' shuffPostfix{doShuff} '.svg'],'svg');
%     cdIdx = find(dPCA_every.whichMarg==2);
%     figure
%     for x=1:length(cdIdx)
%         axIdx = cdIdx(x);
%         
%         subplot(1,6,x);
%         hold on
%         for y=1:size(dPCA_every.Z,2)
%             plot(squeeze(dPCA_every.Z(axIdx,y,:)));
%         end
%     end
    
    %on subsets of data
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

        tmpCodes = trlCodesRemap(trlIdx);
        shuffIdx = randperm(length(tmpCodes));
        if doShuff == 2
            tmpCodes = tmpCodes(shuffIdx);
        end

        dPCA_out{pIdx} = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
            tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
        if strcmp(pcaMode,'pca')
            dPCA_out{pIdx} = dPCA_out{pIdx}.pca_result;
        end
        close(gcf);
    end    

    timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
    yLims = [];
    axHandles=[];
    plotIdx = 1;
    topN = 8;
    
    movTypeText = {'Head','Mouth &\newlineFace','Arm','Leg','Eyes','Tongue','4D Cursor'};
    movLegends = {{'Right','Left','Up','Down','TiltRight','TiltLeft','Forward','Backward'}
        {'Ba','Ga','MouthOpen','JawClench','Pucker','Eyebrows','NoseWrinkle'}
        {'Shrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','Index','Thumb'}
        {'AnkleUp','AnkleDown','KneeExtend','LegUp','ToeCurl','ToeOpen'}
        {'EyesUp','EyesDown','EyesLeft','EyesRight'}
        {'TongueUp','TongueDown','TongueLeft','TongueRight'}
        {'Cursor -X','Cursor -Y','Cursor -Z','Cursor -R','Cursor R','Cursor Z','Cursor Y','Cursor X'}};

    figure('Position',[272         108        1551         997]);
    for pIdx=1:length(movTypes)
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        for c=1:topN
            axHandles(plotIdx) = subtightplot(length(movTypes),topN,(pIdx-1)*topN+c);
            hold on

            colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
            for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
            end

            axis tight;
            yLims = [yLims; get(gca,'YLim')];
            plotIdx = plotIdx + 1;

            plot(get(gca,'XLim'),[0 0],'k');
            plot([0, 0],[-100, 100],'--k');
            if ismember(pIdx,[3 4])
                plot([2.5, 2.5],[-100, 100],'--k');
            elseif ismember(pIdx,[1 2 5 6])
                plot([1.5, 1.5],[-100, 100],'--k');
            end
            set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);
            
            if pIdx==length(movTypes)
                xlabel('Time (s)');
            else
                set(gca,'XTickLabels',[]);
            end
            if pIdx==1
                text(0.025,0.8,'Prep','Units','Normalized','FontSize',12);
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);
                text(0.7,0.8,'Return','Units','Normalized','FontSize',12);
                title(['Dim ' num2str(c)],'FontSize',11)
            elseif pIdx==7
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);
            end

            if c==1
                text(-0.45,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
            end
            if c==topN
                lHandle = legend(movLegends{pIdx});
                lPos = get(lHandle,'Position');
                lPos(1) = lPos(1)+0.05;
                set(lHandle,'Position',lPos);
            end
            set(gca,'FontSize',14);
        end
    end

    if doShuff == 1
        finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
    end
    for p=1:length(axHandles)
        set(axHandles(p), 'YLim', finalLimits);
    end

    saveas(gcf,[outDir filesep 'dPCA_all' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_all' shuffPostfix{doShuff} '.svg'],'svg');

    %%
    colors = hsv(length(movTypes))*0.8;
    colors = colors(randperm(length(movTypes)),:);
    windows = {150:170, 80:120};
    windowNames = {'Move','Prep'};
    cVar = zeros(length(trlCodeList),length(windows));
    cVarSquared = zeros(length(trlCodeList),length(windows));
    cVarMA = zeros(length(trlCodeList),length(windows));
    cVarMA_all = zeros(length(trlCodeList),length(windows));
    
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
                cVar(codes{pIdx,2}(x),windowIdx) = norm(mean(tmp));
                cVarSquared(codes{pIdx,2}(x),windowIdx) = mean(tmp(:).^2);
                cVarMA(codes{pIdx,2}(x),windowIdx) = mean(abs(tmp(:)));
                
                reconActivity = dPCA_out{1}.V(:,cdIdx(1:8)) * squeeze(dPCA_out{1}.Z(cdIdx(1:8),x,:));
                cVarMA_all(codes{pIdx,2}(x),windowIdx) = mean(abs(reconActivity(:)));
            end
        end    

        if doShuff==1
            cVarSquared(:,windowIdx) = cVarSquared(:,windowIdx) - shuffCutoff_sq(:,windowIdx);
        end
        if strcmp(windowNames{windowIdx},'Prep')
            cVarSquared(1:16,windowIdx)=0;
        end
        movLabels = horzcat(movLegends{:});
        plotIdx = 1;

        subtightplot(2,1,windowIdx,[0.05 0.05],[0.15 0.05],[0.05 0.01]);
        hold on
        for pIdx=1:size(movTypes,1)
            dat = sqrt(cVarSquared(codes{pIdx,2},windowIdx));
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
    
    %neck, face, arm, leg
    for pIdx=1:size(movTypes,1)
        dat = cVarSquared(codes{pIdx,2},1) - shuffCutoff_sq(codes{pIdx,2},1);
        disp([movTypes{pIdx,2} '  ' num2str(sqrt(mean(dat)))]);
    end
    
    for pIdx=1:size(movTypes,1)
        dat = cVarMA(codes{pIdx,2},1) - shuffCutoff_ma(codes{pIdx,2},1);
        disp([movTypes{pIdx,2} '  ' num2str((mean(dat)))]);
    end
    
    %%
    %prep ratio
    PR = cVar(:,2) ./ cVar(:,1);
        
    %bar plot
    figure('Position',[724         660        1197         410]);
    movLabels = horzcat(movLegends{:});
    plotIdx = 1;
    hold on
    for pIdx=1:size(movTypes,1)
        dat = PR(codes{pIdx,2});
        bar((plotIdx):(plotIdx + length(dat) - 1), dat, 'FaceColor', colors(pIdx,:));
        plotIdx = plotIdx + length(dat);
    end
    title('Prep Ratio');
    set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
    set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabels,'XTickLabelRotation',45);

    ylim([0 1]);
    xlim([0.5, 45.5]);
    ylabel('Prep Ratio');
    set(gca,'TickLength',[0 0]);
    
    saveas(gcf,[outDir filesep 'prepRatioBar' shuffPostfix{doShuff} '.fig'],'fig');
    saveas(gcf,[outDir filesep 'prepRatioBar' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'prepRatioBar' shuffPostfix{doShuff} '.svg'],'svg');
    
    %boxplot
    PR(isnan(PR) | PR==0) = [];
    figure
    hold on
    plot(ones(size(PR))+(rand(size(PR))-0.5)*0.05, PR,'o');
    boxplot(PR);
    saveas(gcf,[outDir filesep 'prepRatioBox' shuffPostfix{doShuff} '.fig'],'fig');
    saveas(gcf,[outDir filesep 'prepRatioBox' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'prepRatioBox' shuffPostfix{doShuff} '.svg'],'svg');

    %%
    %cross dPCA application
    for pIdx = 1:size(movTypes,1)
        cross_dPCA = cell(size(dPCA_out));
        for pInner = 1:size(movTypes,1)
            cross_dPCA{pInner} = do_dPCA_cross( dPCA_out{pIdx}, dPCA_out{pInner} );
        end
        dPCA_sweep_plot( cross_dPCA, timeAxis, movTypeText, movLegends );
        
        saveas(gcf,[outDir filesep 'dPCA_cross_' movTypes{pIdx,2} shuffPostfix{doShuff} '.png'],'png');
        saveas(gcf,[outDir filesep 'dPCA_cross_' movTypes{pIdx,2} shuffPostfix{doShuff} '.svg'],'svg');
    end
    
    %%
    %measure trial-averaged result of applying cursor decoder to other
    %conditions
    cursorLoopIdx = 1:106973;
    nonCursorIdx = setdiff(1:size(rawSnippetMatrix,1), cursorLoopIdx);
    
    decoder = model.model.K([2 4 6 8],1:192);
    decoder = bsxfun(@times, decoder, model.model.invSoftNormVals(1:192)');
    decoder = decoder(:,~tooLow)';
    decOut = rawSnippetMatrix * decoder;
    decOut(nonCursorIdx,2) = -decOut(nonCursorIdx,2);
    
    decoder_cross_plot( decOut, bNumPerTrial, trlCodes, trlCodesRemap, eventIdx, ...
        timeAxis, movTypes, movLegends, movTypeText, timeWindow, binMS )
    
    saveas(gcf,[outDir filesep 'decoder_cross' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'decoder_cross' shuffPostfix{doShuff} '.svg'],'svg');
    
    %%
    
    %%
    %make cursor decoder with additional requirement of zero tuning for
    %head movement; 
    cursorTrl = find(ismember(bNumPerTrial, movTypes{7,1}));
    headTrl = find(ismember(bNumPerTrial, movTypes{1,1}));
    cursorIdx = expandEpochIdx([eventIdx(cursorTrl(1:(end-1)))'+10, eventIdx(cursorTrl(2:end))']);
    headIdx = expandEpochIdx([eventIdx(headTrl(1)), eventIdx(headTrl(end))]);
    
    %direct regression with weighted zeroing requirement for head movement
    %data
    allIdx = [cursorIdx, headIdx];
    dataRatio = length(cursorIdx) / length(headIdx);
    zeroWeights = linspace(0,2,5);
    decCorr = zeros(length(zeroWeights),4);
    for x=1:length(zeroWeights)
        weightVec = ones(length(allIdx),1);
        weightVec((length(cursorIdx)+1):end) = zeroWeights(x) * dataRatio;
        orthoDec = buildLinFilts(posErrMatrix(allIdx,:), rawSnippetMatrix(allIdx,:), 'weight', [], weightVec);
        
        decOut = rawSnippetMatrix * orthoDec;
        decOut(nonCursorIdx,2) = -decOut(nonCursorIdx,2);
        decoder_cross_plot( decOut, bNumPerTrial, trlCodes, trlCodesRemap, eventIdx, ...
            timeAxis, movTypes, movLegends, movTypeText, timeWindow, binMS );
        decCorr(x,:) = diag(corr(decOut(cursorIdx,:), posErrMatrix(cursorIdx,:)));
        
        saveas(gcf,[outDir filesep 'direct_ortho_' num2str(x) '.png'],'png');
        saveas(gcf,[outDir filesep 'direct_ortho_' num2str(x) '.svg'],'svg');
    end
        
    %OLE + orthoganlize to PCA dimensions
    orthoCorr = zeros(length(zeroWeights),4);
    alphaCoeff = linspace(0,1,5);
    for x=1:length(alphaCoeff)
        orthoDec = buildLinFilts(posErrMatrix(cursorIdx,:), rawSnippetMatrix(cursorIdx,:), 'inverseLinear');

        expFeature = dPCA_out{1}.featureAverages(:,:)';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(expFeature);
        projValues = orthoDec' * COEFF(:,1:8);
        orthoDec = orthoDec - alphaCoeff(x) * (COEFF(:,1:8) * projValues');     

        decOut = rawSnippetMatrix * orthoDec;
        decOut(nonCursorIdx,2) = -decOut(nonCursorIdx,2);
        decoder_cross_plot( decOut, bNumPerTrial, trlCodes, trlCodesRemap, eventIdx, ...
            timeAxis, movTypes, movLegends, movTypeText, timeWindow, binMS );
        orthoCorr(x,:) = diag(corr(decOut(cursorIdx,:), posErrMatrix(cursorIdx,:)));
        
        saveas(gcf,[outDir filesep 'ole_ortho_' num2str(x) '.png'],'png');
        saveas(gcf,[outDir filesep 'ole_ortho_' num2str(x) '.svg'],'svg');
    end
    
end

%%
%linear classifier
movLegends = {{'Right','Left','Up','Down','TiltRight','TiltLeft','Forward','Backward'}
    {'Ba','Ga','MouthOpen','JawClench','Pucker','Eyebrows','NoseWrinkle'}
    {'Shrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','Index','Thumb'}
    {'AnkleUp','AnkleDown','KneeExtend','LegUp','ToeCurl','ToeOpen'}
    {'EyesUp','EyesDown','EyesLeft','EyesRight'}
    {'TongueUp','TongueDown','TongueLeft','TongueRight'}
    {'Cursor -X','Cursor -Y','Cursor -Z','Cursor -R','Cursor R','Cursor Z','Cursor Y','Cursor X'}};
movLabels = horzcat(movLegends{:});

codes = cell(size(movTypes,1),2);
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    if strcmp(movTypes{pIdx,2},'cursor_CL')
        %ignore return
        trlIdx(trlCodes(trlIdx)>9)=false;
    end

    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
end 

remapTable = [];
currentIdx = 0;
for c=1:length(codes)
    newIdx = currentIdx + (1:length(codes{c,2}))';
    remapTable = [remapTable; [newIdx, codes{c,2}]];
    currentIdx = currentIdx + length(codes{c,2});
end
    
allFeatures = [];
allCodes = [];
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
for pIdx = [1,2,4,6]
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    if strcmp(movTypes{pIdx,2},'cursor_CL')
        %ignore return
        trlIdx(trlCodes(trlIdx)>9)=false;
    end
    trlIdx = find(trlIdx);
    
    newCodes = trlCodesRemap(trlIdx);
    newData = [];
    for n=1:length(newCodes)
        tmp = [];
        dataIdx = 0:10;
        for binIdx=1:7
            loopIdx = dataIdx + eventIdx(trlIdx(n));
            tmp = [tmp, mean(snippetMatrix(loopIdx,:))];
            dataIdx = dataIdx + length(dataIdx);
        end
        newData = [newData; tmp];
    end
    
    allFeatures = [allFeatures; newData];
    allCodes = [allCodes; newCodes];
end

allCodesRemap = zeros(size(allCodes));
for x=1:length(remapTable)
    replaceIdx = find(allCodes==remapTable(x,2));
    allCodesRemap(replaceIdx) = x;
end

obj = fitcdiscr(allFeatures,allCodesRemap,'DiscrimType','diaglinear');
cvmodel = crossval(obj);
L = kfoldLoss(cvmodel);
predLabels = kfoldPredict(cvmodel);

C = confusionmat(allCodesRemap, predLabels);

figure('Position',[680         275        1112         823]);
imagesc(C);
set(gca,'XTick',1:length(allCodesRemap),'XTickLabel',movLabels,'XTickLabelRotation',45);
set(gca,'YTick',1:length(allCodesRemap),'YTickLabel',movLabels);
set(gca,'FontSize',14);
colorbar;
title(['X-Validated Accuracy: ' num2str(1-L,3)]);

saveas(gcf,[outDir filesep 'linearClassifier.png'],'png');
saveas(gcf,[outDir filesep 'linearClassifier.svg'],'svg');

%%
%similarities in tuning across movements
allFeatures = [];
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    if strcmp(movTypes{pIdx,2},'cursor_CL')
        %ignore return
        trlIdx(trlCodes(trlIdx)>9)=false;
    end
    trlIdx = find(trlIdx);
    
    newCodes = trlCodesRemap(trlIdx);
    newData = [];
    dataIdx = 30:50;
    for n=1:length(newCodes)
        loopIdx = dataIdx + eventIdx(trlIdx(n));
        newData = [newData; mean(snippetMatrix(loopIdx,:))];
    end
    
    allFeatures = [allFeatures; newData];
end    

mnFeat = [];
codeList = unique(allCodesRemap);
for c=1:length(codeList)
    trlIdx = find(allCodesRemap==codeList(c));
    mnFeat = [mnFeat; mean(allFeatures(trlIdx,:))];
end
mnFeat = abs(mnFeat);

distMat = corr(mnFeat');
distMat(1:(length(distMat)+1):end)=0;
figure
imagesc(distMat);
set(gca,'XTick',1:length(allCodesRemap),'XTickLabel',movLabels,'XTickLabelRotation',45);
set(gca,'YTick',1:length(allCodesRemap),'YTickLabel',movLabels);
set(gca,'FontSize',14);
colorbar;

saveas(gcf,[outDir filesep 'neuralSimilarity.png'],'png');
saveas(gcf,[outDir filesep 'neuralSimilarity.svg'],'svg');

Z = linkage(mnFeat,'ward','euclidean');
dendrogram(Z,0,'Labels',movLabels);
set(gca,'XTickLabelRotation',45);
set(gca,'FontSize',14);

nClust = 7;
clustIdx = cluster(Z,'maxclust',nClust);
reorderIdx = [];
for x = 1:nClust
    reorderIdx = [reorderIdx; find(clustIdx==x)];
end
distMat = corr(mnFeat(reorderIdx,:)');
distMat(1:(length(distMat)+1):end)=0;

figure
imagesc(distMat);
set(gca,'XTick',1:length(allCodes),'XTickLabel',movLabels(reorderIdx),'XTickLabelRotation',45);
set(gca,'YTick',1:length(allCodes),'YTickLabel',movLabels(reorderIdx));
set(gca,'FontSize',14);
colorbar;

%%
%PSTHs for each feature
%get code sets for each movement type
codes = cell(size(movTypes,1),2);
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    if strcmp(movTypes{pIdx,2},'cursor_CL')
        %ignore return
        trlIdx(trlCodes(trlIdx)>9)=false;
    end

    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
end    

%PSTHS
lineArgs = cell(length(trlCodeList),1);
for pIdx = 1:size(movTypes,1)
    colors = hsv(length(codes{pIdx,2}))*0.8;
    for x=1:length(codes{pIdx,2})
        lineArgs{codes{pIdx,2}(x)} = {'LineWidth',1,'Color',colors(x,:)};
    end
end

psthOpts = makePSTHOpts();
psthOpts.gaussSmoothWidth = 0;
psthOpts.neuralData = {snippetMatrix};
psthOpts.timeWindow = timeWindow/binMS;
psthOpts.trialEvents = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
psthOpts.trialConditions = trlCodesRemap;
psthOpts.conditionGrouping = codes(:,2);
psthOpts.lineArgs = lineArgs;

psthOpts.plotsPerPage = 10;
psthOpts.plotDir = outDir;

featLabels = cell(192,1);
chanIdx = find(~tooLow);
for f=1:length(chanIdx)
    featLabels{f} = num2str(chanIdx(f));
end
psthOpts.featLabels = featLabels;

tooLowChans = find(tooLow);
usedChans = setdiff(1:192, tooLowChans);

in = psthOpts;
in.neuralData{1} = psthOpts.neuralData{1}(:,~ismember(usedChans, excludeChannels));
in.prefix = 'clean';
makePSTH_simple(in);
close all;

in = psthOpts;
in.neuralData{1} = psthOpts.neuralData{1}(:,ismember(usedChans, excludeChannels));
in.prefix = 'excluded';
makePSTH_simple(in);
close all;

%%
%refined codes
% movLegends = {{'Right','Left','Up','Down'},{'TiltRight','TiltLeft','Forward','Backward'}
%     {'Ba','Ga','MouthOpen','JawClench','Pucker','Eyebrows','NoseWrinkle'}
%     {'Shrug','ArmRaise','ElbowFlex'},{'WristExt','CloseHand','OpenHand','Index','Thumb'}
%     {'AnkleUp','AnkleDown','KneeExtend','LegUp','ToeCurl','ToeOpen'}
%     {'EyesUp','EyesDown','EyesLeft','EyesRight'}
%     {'TongueUp','TongueDown','TongueLeft','TongueRight'}
%     {'Cursor -X','Cursor -Y','Cursor -Z','Cursor -R','Cursor R','Cursor Z','Cursor Y','Cursor X'}};

codesRefined = {[19 20 21 22],[23 24 25 26],...
    [17 18 35 36 37 38 39],...
    [40 41 42],[43 44 45 52 53],...
    [48 49],[46 47 50 51],...
    [31 32 33 34],...
    [27 28 29 30],...
    [1 2 3 4 5 6 7 8]};
movLegendsRefined = {{'Right','Left','Up','Down'},{'TiltRight','TiltLeft','Forward','Backward'},...
    {'Ba','Ga','MouthOpen','JawClench','Pucker','Eyebrows','NoseWrinkle'},...
    {'Shrug','ArmRaise','ElbowFlex'},{'WristExt','CloseHand','OpenHand','Index','Thumb'},...
    {'KneeExtend','LegUp'},{'AnkleUp','AnkleDown','ToeCurl','ToeOpen'},...
    {'EyesUp','EyesDown','EyesLeft','EyesRight'},...
    {'TongueUp','TongueDown','TongueLeft','TongueRight'},...
    {'Cursor -X','Cursor -Y','Cursor -Z','Cursor -R','Cursor R','Cursor Z','Cursor Y','Cursor X'}};

%%
%SNR of each movement type
nCon = length(codesRefined);
nChan = size(snippetMatrix,2);
binWindows = {[30:50],[-20:0]};
cSNR = zeros(nChan, nCon, length(binWindows));

for winIdx=1:length(binWindows)
    for setIdx=1:nCon
        for chanIdx = 1:nChan
            allConcat = [];
            for x=1:length(codesRefined{setIdx})
                trlIdx = find(trlCodesRemap==codesRefined{setIdx}(x));

                binIdx = [];
                for t=1:length(trlIdx)
                    binIdx = [binIdx, eventIdx(trlIdx(t)) + binWindows{winIdx}];
                end
                mn = mean(snippetMatrix(binIdx,chanIdx));
                allConcat = [allConcat; [snippetMatrix(binIdx,chanIdx), snippetMatrix(binIdx,chanIdx)-mn]];
            end
            cSNR(chanIdx, setIdx, winIdx) = 1 - var(allConcat(:,2))/var(allConcat(:,1));
        end
    end
end

allSNR = zeros(nChan, length(binWindows));
for winIdx=1:length(binWindows)
    for chanIdx = 1:nChan
        allConcat = [];
        for x=1:53
            trlIdx = find(trlCodesRemap==x);

            binIdx = [];
            for t=1:length(trlIdx)
                binIdx = [binIdx, eventIdx(trlIdx(t)) + binWindows{winIdx}];
            end
            mn = mean(snippetMatrix(binIdx,chanIdx));
            allConcat = [allConcat; [snippetMatrix(binIdx,chanIdx), snippetMatrix(binIdx,chanIdx)-mn]];
        end
        allSNR(chanIdx, winIdx) = 1 - var(allConcat(:,2))/var(allConcat(:,1));
    end
end

figure
for x=1:nCon
    for y=1:nCon
        %if x<y
        %    continue;
        %end
        subtightplot(nCon,nCon,(y-1)*nCon + x);
        hold on;
        plot(cSNR(:,y), cSNR(:, x), 'o', 'MarkerSize', 4);
        plot([0 1],[0 1],'--k');
        xlim([0 0.8]);
        ylim([0 0.8]);
    end
end

usedChanIdx = find(~tooLow);

%%
%heatmaps!
movTypeTextRefined = {'HeadXY','HeadTF','Mouth &\newlineFace','ArmProx','ArmDist','LegProx','LegDist',...
    'Eyes','Tongue','4D Cursor'};
    
latArray = [nan  2  1  3 4  6  8 10 14 nan;...
             65 66 33 34 7  9 11 12 16 18;...
             67 68 35 36 5 17 13 23 20 22;...
             69 70 37 38 48 15 19 25 27 24;...
             71 72 39 40 42 50 54 21 29 26;...
             73 74 41 43 44 46 52 62 31 28;...
             75 76 45 47 51 56 58 60 64 30;...
             77 78 82 49 53 55 57 59 61 32;...
             79 80 84 86 87 89 91 94 63 95;...
             nan 81 83 85 88 90 92 93 96 nan];

medArray = [nan  2  1  3 4  6  8 10 14 nan;...
             65 66 33 34 7  9 11 12 16 18;...
             67 68 35 36 5 17 13 23 20 22;...
             69 70 37 38 48 15 19 25 27 24;...
             71 72 39 40 42 50 54 21 29 26;...
             73 74 41 43 44 46 52 62 31 28;...
             75 76 45 47 51 56 58 60 64 30;...
             77 78 82 49 53 55 57 59 61 32;...
             79 80 84 86 87 89 91 94 63 95;...
             nan 81 83 85 88 90 92 93 96 nan];
         
% nirArray = [nan  88 78 68 58 48 38 28 18 nan;...
%              96 87 77 67 57 47 37 27 17 8;...
%              95 86 76 66 56 46 36 26 16 7;...
%              94 85 75 65 55 45 35 25 15 6;...
%              93 84 74 64 54 44 34 24 14 5;...
%              92 83 73 63 53 43 33 23 13 4;...
%              91 82 72 62 52 42 32 22 12 3;...
%              90 81 71 61 51 41 31 21 11 2;...
%              89 80 70 60 50 40 30 20 10 1;...
%              nan 79 69 59 49 39 29 19 9 nan];

cSNR_expand = nan(192,7);
for c=1:length(codesRefined)
    cSNR_expand(usedChanIdx,c) = cSNR(:,c);
end
chanSets = {97:192,1:96};
cMap = parula(256);
cMap(1,:) = [0 0 0];

figure('Position',[680         753        1165         345]);
for c=1:length(codesRefined)
    for arrIdx=1:length(chanSets)
        subtightplot(2,length(codesRefined),(arrIdx-1)*length(codesRefined) + c);
        tmp = cSNR_expand(chanSets{arrIdx},c);

        arrMat = zeros(10);
        for rowIdx=1:10
           for colIdx=1:10
               if ~isnan(latArray(rowIdx,colIdx))
                   arrMat(rowIdx,colIdx) = tmp(latArray(rowIdx,colIdx));
               end
           end
        end

        imagesc(arrMat,[0 0.5]);
        colormap(cMap);
        axis equal;
        axis off;
        if arrIdx==1
            title(movTypeTextRefined{c},'FontSize',16);
        end
    end
end

saveas(gcf,[outDir filesep 'tuningHeatmap_specific.png'],'png');
saveas(gcf,[outDir filesep 'tuningHeatmap_specific.svg'],'svg');

%%
%prep gradient?
PR_expand = zeros(192,1);
PR_expand(usedChanIdx,:) = allSNR(:,2) ./ allSNR(:,1);

chanSets = {97:192,1:96};
cMap = parula(256);
cMap(1,:) = [0 0 0];

figure('Position',[680   478   415   620]);
for arrIdx=1:length(chanSets)
    subtightplot(2,1,arrIdx);
    tmp = PR_expand(chanSets{arrIdx});

    arrMat = zeros(10);
    for rowIdx=1:10
       for colIdx=1:10
           if ~isnan(latArray(rowIdx,colIdx))
               arrMat(rowIdx,colIdx) = tmp(latArray(rowIdx,colIdx));
           end
       end
    end

    imagesc(arrMat,[0.2 0.5]);
    colormap(cMap);
    axis equal;
    axis off;
end


%%

% %%
% nCon = length(trlCodeList);
% nChan = size(snippetMatrix,2);
% cSNR = zeros(nChan, nCon);
% 
% binWindow = [20:40];
% for t=1:length(trlCodeList)
%     trlIdx = find(trlCodes==trlCodeList(t));
%     binIdx = [];
%     for x=1:length(trlIdx)
%         binIdx = [binIdx, eventIdx(trlIdx(x)) + binWindow];
%     end
%     
%     mnMod = mean(snippetMatrix(binIdx,:));
%     sdMod = std(snippetMatrix(binIdx,:))+0.1;
%     cSNR(:,t) = abs(mnMod)./sdMod;
% end

%%
%      TURN_HEAD_RIGHT(67)
%       
%       %FRW - head movement experiment 2017-09-23
%       TURN_HEAD_LEFT(71)
%       TURN_HEAD_UP(72)
%       TURN_HEAD_DOWN(73)
%       
%       %FRW broad movement sweep for 2017-10-15
%       HEAD_TILT_RIGHT(74)
%       HEAD_TILT_LEFT(75)
%       HEAD_FORWARD(76)
%       HEAD_BACKWARD(77)
%       
%       TONGUE_UP(78)
%       TONGUE_DOWN(79)
%       TONGUE_LEFT(80)
%       TONGUE_RIGHT(81)
%       
%       EYES_UP(82)
%       EYES_DOWN(83)
%       EYES_LEFT(84)
%       EYES_RIGHT(85)
%       
%       MOUTH_OPEN(86)
%       JAW_CLENCH(87)
%       PUCKER_LIPS(88)
%       RAISE_EYEBROWS(89)
%       NOSE_WRINKLE(90)
%       
%       SHO_SHRUG(91)
%       ARM_RAISE(92)
%       ARM_LOWER(93)
%       ELBOW_FLEX(94)
%       ELBOW_EXT(95)
%       WRIST_EXT(96)
%       WRIST_FLEX(97)
%       CLOSE_HAND(98)
%       OPEN_HAND(99)
%       
%       THUMB_JOY_FORWARD(100)
%       THUMB_JOY_BACK(101)
%       THUMB_JOY_RIGHT(102)
%       THUMB_JOY_LEFT(103)
%       
%       ANKLE_UP(104)
%       ANKLE_DOWN(105)
%       KNEE_EXTEND(106)
%       KNEE_FLEX(107)
%       LEG_UP(108)
%       LEG_DOWN(109)
%       TOE_CURL(110)
%       TOE_OPEN(111)
%       
%       TORSO_UP(112)
%       TORSO_DOWN(113)
%       TORSO_TWIST_RIGHT(114)
%       TORSO_TWIST_LEFT(115)
% 
%       INDEX_RAISE(116)
%       THUMB_UP(117)