function [ simMatrix, fVectors_subtract, fVectors_raw ] = plotCorrMat( featureAverages, cWindow, movLabels, effSets, boxSets )

    if nargin<5
        boxSets = [];
    end
    if nargin<4
        effSets = [];
    end
    fa = featureAverages(:,:,cWindow);
    fa = fa(:,:)';
    fa = mean(fa);
    nCon = size(featureAverages,2);

    subtractEffMean = ~isempty(effSets);
    if subtractEffMean
        effMeans = zeros(length(fa), length(effSets));
        setMemberships = zeros(nCon,1);

        for s=1:length(effSets)
            tmp = featureAverages(:,effSets{s},cWindow);
            tmp = tmp(:,:);

            effMeans(:,s) = mean(tmp');
            setMemberships(effSets{s}) = s;
        end
    end

    simMatrix = zeros(nCon, nCon);
    fVectors_subtract = zeros(nCon, size(featureAverages,1));
    fVectors_raw = zeros(nCon, size(featureAverages,1));
    for x=1:nCon
        %get the top dimensions this movement lives in
        avgTraj = squeeze(featureAverages(:,x,:))';
        avgTraj = mean(avgTraj(cWindow,:));
        fVectors_raw(x,:) = avgTraj - fa;
        
        if subtractEffMean
            avgTraj = avgTraj - effMeans(:,setMemberships(x))';
        else
            avgTraj = avgTraj - fa;
        end

        for y=1:nCon
            avgTraj_y = squeeze(featureAverages(:,y,:))';
            avgTraj_y = mean(avgTraj_y(cWindow,:));
            if subtractEffMean
                avgTraj_y = avgTraj_y - effMeans(:,setMemberships(y))';
            else
                avgTraj_y = avgTraj_y - fa;
            end

            %simMatrix(x,y) = dot(avgTraj', avgTraj_y')/(norm(avgTraj)*norm(avgTraj_y));
            simMatrix(x,y) = corr(avgTraj', avgTraj_y');
        end
        
        fVectors_subtract(x,:) = avgTraj;
    end

    cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

    figure
    imagesc(simMatrix,[-1 1]);
    colormap(cMap);
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

