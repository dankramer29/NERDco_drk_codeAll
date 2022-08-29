function singleTrialBarPlot_v2( codeSets, rawProjPoints, cVar, movLabelsSets )
    %%
    %bar plot
    colors = [173,150,61;
    119,122,205;
    91,169,101;
    197,90,159;
    202,94,74]/255;

    figure('Position',[164   751   989   338]);
    plotIdx = 1;
    colorIdx = 1;
    
    meanMod = zeros(length(codeSets),1);

    hold on
    for pIdx=1:length(codeSets)
        lightColor = colors(pIdx,:)*0.7 + ones(1,3)*0.3;
        darkColor = colors(pIdx,:)*0.7 + zeros(1,3)*0.3;
        for movIdx=1:length(codeSets{pIdx})
            mIdx = codeSets{pIdx}(movIdx);

            base = mean(rawProjPoints{mIdx,1});

            bar(plotIdx, mean(rawProjPoints{mIdx,2})-base, 'FaceColor', colors(colorIdx,:), 'LineWidth', 1);

            jitterX = rand(length(rawProjPoints{mIdx,1}),1)*0.3-0.15;
            plot(plotIdx+jitterX, rawProjPoints{mIdx,1}-base, 's', 'Color', lightColor, 'MarkerSize', 2);            

            jitterX = rand(length(rawProjPoints{mIdx,2}),1)*0.3-0.15;
            plot(plotIdx+jitterX, rawProjPoints{mIdx,2}-base, 'o', 'Color', darkColor, 'MarkerSize', 2);

            height = mean(rawProjPoints{mIdx,2})-base;
            CI = cVar(mIdx,3:4)-cVar(mIdx,1);
            errorbar(plotIdx, height, CI(1), CI(2), '.k','LineWidth',1);

            plotIdx = plotIdx + 1;
        end
        colorIdx = colorIdx + 1;
    end
    set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
    set(gca,'XTick',1:length(movLabelsSets),'XTickLabel',movLabelsSets,'XTickLabelRotation',45);

    axis tight;
    xlim([0.5, length(movLabelsSets)+0.5]);
    ylabel('\Delta Neural Activity (SD)','FontSize',22);
    set(gca,'TickLength',[0 0]);
    %plot(get(gca,'XLim'),[0,0],'-k','LineWidth',1);

end

