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
rmsThresh = [2.5 3.5 4.5 5.5 6.5 7.5];

for threshIdx = 1:length(rmsThresh)
    %%
    %load cued movement dataset
    R = getSTanfordBG_RStruct( sessionPath, setdiff(blockList,[1 2 3]), [], rmsThresh(threshIdx) );

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
    R_curs = getSTanfordBG_RStruct( sessionPath, [2 3], [], rmsThresh(threshIdx) );

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
    %SNR of each movement type
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
    end    
        
    nCon = length(movTypes);
    nChan = size(snippetMatrix,2);
    binWindows = {[30:50],[-20:0]};
    cSNR = zeros(nChan, nCon, length(binWindows));

    for winIdx=1:length(binWindows)
        for setIdx=1:nCon
            for chanIdx = 1:nChan
                allConcat = [];
                for x=1:length(codes{setIdx,2})
                    trlIdx = find(trlCodesRemap==codes{setIdx,2}(x));

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
    movTypeText = {'Head','Mouth &\newlineFace','Arm','Leg','Eyes','Tongue','4D Cursor'};

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
    for c=1:7
        cSNR_expand(usedChanIdx,c) = cSNR(:,c);
    end
    chanSets = {97:192,1:96};
    cMap = parula(256);
    cMap(1,:) = [0 0 0];

    figure('Position',[680         753        1165         345]);
    for c=1:7
        for arrIdx=1:length(chanSets)
            subtightplot(2,7,(arrIdx-1)*7 + c);
            tmp = cSNR_expand(chanSets{arrIdx},c);

            arrMat = zeros(10);
            for rowIdx=1:10
               for colIdx=1:10
                   if ~isnan(latArray(rowIdx,colIdx))
                       arrMat(rowIdx,colIdx) = tmp(latArray(rowIdx,colIdx));
                   end
               end
            end

            imagesc(arrMat,[0 0.7]);
            colormap(cMap);
            axis equal;
            axis off;
            if arrIdx==1
                title(movTypeText{c},'FontSize',16);
            end
        end
    end

    saveas(gcf,[outDir filesep 'tuningHeatmap_' num2str(rmsThresh(threshIdx)) '.png'],'png');
    saveas(gcf,[outDir filesep 'tuningHeatmap_' num2str(rmsThresh(threshIdx)) '.svg'],'svg');

    close all;
end

