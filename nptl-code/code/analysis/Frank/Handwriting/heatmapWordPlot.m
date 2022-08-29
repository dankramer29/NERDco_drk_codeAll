function heatmapWordPlot( heatmaps, startTimes, stretchFactors, word, letterStarts, letterStretches, filePrefix )    
    nSquaresPerPage = 16;
    nPages = ceil(length(word)/nSquaresPerPage);
    currIdx = 1:nSquaresPerPage;
    
    for pageIdx=1:nPages
        figure('Position',[20 20 1500 1000]);
        for forLoopIdx=1:length(currIdx)
            if currIdx(forLoopIdx)>length(word)
                continue;
            end
            c = currIdx(forLoopIdx);
            
            subplot(4,4,forLoopIdx);
            hold on;
            imagesc(startTimes, stretchFactors, heatmaps{c});
            axis tight;
                        
            plot(letterStarts(c),letterStretches(c),'kx','MarkerSize',18,'LineWidth',5); 
            title([word(c) ' (' num2str(letterStarts(c)) ')'],'FontSize',14);
            xlabel('Time (s)');
            ylabel('Stretch Factor');
            set(gca,'FontSize',24);
            
            xLimits = [letterStarts(c)-8, letterStarts(c)+8];
            xlim(xLimits);
        end
        currIdx = currIdx + length(currIdx);
        saveas(gcf,[filePrefix '_page' num2str(pageIdx) '.png'],'png');
    end
end

