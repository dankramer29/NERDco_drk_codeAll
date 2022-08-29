figure; 
targColor = lines(4); 
for i = 1:length(binnedR_All.stimOnset)-1
    if ~isnan(binnedR_All.stimOnset(i)) 
        plot(binnedR_All.effPosX(binnedR_All.stimOnset(i):binnedR_All.trialStart(i+1)),...
            binnedR_All.effPosY(binnedR_All.stimOnset(i):binnedR_All.trialStart(i+1)),...
            '.', 'Color', targColor(binnedR_All.tgt(i),:));
        hold on;
    end
end