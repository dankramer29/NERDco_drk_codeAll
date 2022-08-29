function [ C, L, obj ] = simpleClassify( features, trlCodes, eventIdx, conLabels, binWidth, nDecodeBins, startIdx, plotFig )

    if nargin<8
        plotFig = true;
    end
    
    dataIdxStart = startIdx+(1:(binWidth));
    allFeatures = [];
    for t=1:length(trlCodes)
        tmp = [];
        dataIdx = dataIdxStart;
        for binIdx=1:nDecodeBins
            loopIdx = dataIdx + eventIdx(t);
            tmp = [tmp, mean(features(loopIdx,:),1)];

            if binIdx<nDecodeBins
                dataIdx = dataIdx + binWidth;
            end
        end

        allFeatures = [allFeatures; tmp];
    end

    codeList = unique(trlCodes);
    
    obj = fitcdiscr(allFeatures,trlCodes,'DiscrimType','diaglinear','Prior',ones(length(codeList),1));
    cvmodel = crossval(obj);
    L = kfoldLoss(cvmodel);
    predLabels = kfoldPredict(cvmodel);

    C = confusionmat(trlCodes, predLabels);
    for rowIdx=1:size(C,1)
        C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
    end

    if plotFig
        figure('Position',[212   524   808   567]);
        hold on;

        imagesc(C);
        set(gca,'XTick',1:length(conLabels),'XTickLabel',conLabels,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(conLabels),'YTickLabel',conLabels);
        set(gca,'FontSize',16);
        set(gca,'LineWidth',2);
        colorbar;
        title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
        axis tight;
    end
end

