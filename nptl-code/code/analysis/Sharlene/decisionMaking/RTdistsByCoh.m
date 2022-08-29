% reaction time by coherence
figure;
cohCount = 0;
for cohI = unique(binnedR_All.uCoh)
    cohCount = cohCount + 1;
    subplot(length(unique(binnedR_All.uCoh)), 1, cohCount)
    h = histogram(binnedR_All.speedRT(1,binnedR_All.uCoh == cohI))
    h.BinEdges = 0:5:250
    ax = gca;
    ax.XTick = 0:25:250;            % bins
    ax.XTickLabel = ax.XTick .* 20; % 20 ms per bin
   % meanRT(cohCount, session) = nanmean(binnedR_All.speedRT(binnedR_All.uCoh == cohI)); 
   % stdRT(cohCount, session) = nanstd(binnedR_All.speedRT(binnedR_All.uCoh == cohI)); 
end

