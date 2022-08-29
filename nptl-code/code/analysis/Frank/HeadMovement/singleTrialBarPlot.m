function singleTrialBarPlot( codeSets, rawProjPoints, cVar, movLabelsSets, plotMeanBars )
    %%
    %bar plot
    if length(codeSets)<5
        colors = [173,150,61;
        119,122,205;
        91,169,101;
        197,90,159;
        202,94,74]/255;
    else
        colors = lines(length(codeSets));
    end
    
    if nargin<5
        plotMeanBars = true;
    end

    figure('Position',[164   751   989   338]);
    plotIdx = 1;
    colorIdx = 1;
    setHeights = cell(length(codeSets),1);
    
    xDivisions = cell(length(codeSets),1);
    jitterWidth = 0.1;
    
    signedPP = rawProjPoints;
    for x=1:size(rawProjPoints,1)
        for y=1:2
            signedPP{x,y} = rawProjPoints{x,y}*sign(cVar(x,1));
        end
    end
    
    hold on
    for pIdx=1:length(codeSets)
        lightColor = colors(pIdx,:)*0.7 + ones(1,3)*0.3;
        darkColor = colors(pIdx,:)*0.7 + zeros(1,3)*0.3;
        
        setHeights{pIdx} = zeros(length(codeSets{pIdx}), 1);
        startIdx = plotIdx;
        
        for movIdx=1:length(codeSets{pIdx})
            mIdx = codeSets{pIdx}(movIdx);

            base = mean(signedPP{mIdx,1});

            bar(plotIdx, mean(signedPP{mIdx,2})-base, 'FaceColor', colors(colorIdx,:), 'LineWidth', 1);

            jitterX = rand(length(signedPP{mIdx,1}),1)*jitterWidth-jitterWidth/2;
            plot(plotIdx+jitterX, signedPP{mIdx,1}-base, 's', 'Color', lightColor, 'MarkerSize', 2);            

            jitterX = rand(length(signedPP{mIdx,2}),1)*jitterWidth-jitterWidth/2;
            plot(plotIdx+jitterX, signedPP{mIdx,2}-base, 'o', 'Color', darkColor, 'MarkerSize', 2);

            height = mean(signedPP{mIdx,2})-base;
            CI = (cVar(mIdx,3:4)-cVar(mIdx,1))*sign(cVar(mIdx,1));
            errorbar(plotIdx, height, CI(1), CI(2), '.k','LineWidth',2);

            setHeights{pIdx}(movIdx) = height;
            %plot([plotIdx-0.4, plotIdx+0.4],[cVar_proj(mIdx,2), cVar_proj(mIdx,2)],':k','LineWidth',2);

            %plot([plotIdx, plotIdx],[-cVar_proj(mIdx,5)/2, -cVar_proj(mIdx,4)/2]-base,...
            % 'Color',colors(pIdx,:),'LineWidth',20);
            %plot([plotIdx, plotIdx],[cVar_proj(mIdx,4)/2, cVar_proj(mIdx,5)/2]-base,...
            % 'Color',colors(pIdx,:),'LineWidth',20);

            %plot([plotIdx, plotIdx],[mean(rawProjPoints{mIdx,1}), mean(rawProjPoints{mIdx,2})]-base,...
            %'Color',colors(pIdx,:),'LineWidth',5);

            plotIdx = plotIdx + 1;
        end
        
        xDivisions{pIdx} = [startIdx-0.5, plotIdx-0.5]';
        colorIdx = colorIdx + 1;
    end

    set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
    
    axis tight;
    xlim([0.5, length(movLabelsSets)+0.5]);
    ylabel('\Delta Firing Rate (SD)','FontSize',22);
    set(gca,'TickLength',[0 0]);
    set(gca,'XTick',1:length(movLabelsSets),'XTickLabel',movLabelsSets,'XTickLabelRotation',45);
    
    %add mean bars
    if plotMeanBars
        finalYLimit = get(gca,'YLim');
        regionSize = diff(finalYLimit)*0.025;
        for pIdx=1:length(codeSets)
            darkColor = colors(pIdx,:)*0.7 + zeros(1,3)*0.3;

            regionY = zeros(2,2);
            regionY(1,:) = [mean(setHeights{pIdx})-regionSize, mean(setHeights{pIdx})+regionSize];
            regionY(2,:) = [mean(setHeights{pIdx})-regionSize, mean(setHeights{pIdx})+regionSize];

            errorPatch(xDivisions{pIdx}, regionY, darkColor, 0.8);
        end
    end
end

