function [ simMatrix ] = plotDistMat_cv( featureVals, cWindow, movLabels, boxSets )

    if nargin<4
        boxSets = [];
    end
    
    nCon = size(featureVals,2);

    simMatrix = zeros(nCon, nCon);
    for x=1:nCon
        for y=1:nCon
            mn1 = squeeze(mean(featureVals(:,x,cWindow(1):cWindow(2),:),3))';
            mn2 = squeeze(mean(featureVals(:,y,cWindow(1):cWindow(2),:),3))';
            simMatrix(x,y) = lessBiasedDistance(mn1, mn2);
        end
    end
 
    cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

    figure
    imagesc(simMatrix);
    colormap(parula);
    set(gca,'XTick',1:nCon,'XTickLabel',movLabels,'XTickLabelRotation',45);
    set(gca,'YTick',1:nCon,'YTickLabel',movLabels);
    set(gca,'FontSize',16);
    set(gca,'YDir','normal');
    colorbar;

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

