function [ simMatrix ] = plotCorrMat_cv( featureVals, cWindow, movLabels, effSets, boxSets )

    if nargin<5
        boxSets = [];
    end
    if nargin<4
        effSets = [];
    end
    
    nTrials = size(featureVals,4);
    nCon = size(featureVals,2);
    
    allNormEst = zeros(nTrials, nCon);
    for foldIdx=1:nTrials
        trainIdx = setdiff(1:nTrials, foldIdx);
        
        vecTrain = getAvgVectors(featureVals(:,:,:,trainIdx), effSets, cWindow);
        vecTest = getAvgVectors(featureVals(:,:,:,foldIdx), effSets, cWindow);
        allNormEst(foldIdx,:) = sum(vecTrain .* vecTest,2);
    end
    meanSquare = mean(allNormEst);
    normEst = sign(meanSquare).*sqrt(abs(meanSquare));
    
    vecFull = getAvgVectors(featureVals, effSets, cWindow);
    simMatrix = zeros(nCon, nCon);
    for x=1:nCon
        for y=1:nCon
           simMatrix(x,y) = vecFull(x,:)*vecFull(y,:)'/(normEst(x)*normEst(y));
           %simMatrix(x,y) = vecFull(x,:)*vecFull(y,:)'/(norm(vecFull(x,:))*norm(vecFull(y,:)));
        end
    end
 
    cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

    figure
    imagesc(simMatrix,[-1 1]);
    colormap(cMap);
    set(gca,'XTick',(1:nCon)-0.25,'XTickLabel',movLabels,'XTickLabelRotation',45);
    set(gca,'YTick',1:nCon,'YTickLabel',movLabels);
    set(gca,'FontSize',16);
    set(gca,'YDir','normal');
    colorbar;
    hold on;
    
    if isempty(boxSets)
        for x1=1:length(simMatrix)
            plot(get(gca,'XLim'),[x1 x1]-0.5,'k');
            plot([x1 x1]-0.5, get(gca,'YLim'),'k');
        end
    end

    if length(boxSets)<=5
        colors = [173,150,61;
        119,122,205;
        91,169,101;
        197,90,159;
        202,94,74]/255;
    else
        colors = hsv(length(boxSets))*0.8;
    end

    currentIdx = 0;
    currentColor = 1;
    if ~isempty(boxSets)
        for c=1:length(boxSets)
            newIdx = currentIdx + (1:length(boxSets{c}))';
            rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(currentColor,:));
            currentIdx = currentIdx + length(boxSets{c});
            currentColor = currentColor + 1;
        end
    end
    axis tight;
end

function fVectors_subtract = getAvgVectors(featureVals, effSets, cWindow)
    fa = nanmean(featureVals(:,:,cWindow,:),4);
    fa = fa(:,:)';
    fa = mean(fa);
    nCon = size(featureVals,2);

    subtractEffMean = ~isempty(effSets);
    if subtractEffMean
        effMeans = zeros(length(fa), length(effSets));
        setMemberships = zeros(nCon,1);

        for s=1:length(effSets)
            tmp = nanmean(featureVals(:,effSets{s},cWindow,:),4);
            tmp = tmp(:,:);

            effMeans(:,s) = mean(tmp');
            setMemberships(effSets{s}) = s;
        end
    end

    fVectors_subtract = zeros(nCon, size(featureVals,1));
    for x=1:nCon
        avgTraj = squeeze(nanmean(featureVals(:,x,:,:),4))';
        avgTraj = mean(avgTraj(cWindow,:));

        if subtractEffMean
            avgTraj = avgTraj - effMeans(:,setMemberships(x))';
        else
            avgTraj = avgTraj - fa;
        end

        fVectors_subtract(x,:) = avgTraj - mean(avgTraj);
    end
end

