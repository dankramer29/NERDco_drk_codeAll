function plot1and2factorDPCA(binnedR, binsBefore, binsAfter)
% INPUT: binnedR = R struct in 20 ms bins
%        binsBefore/After = number of bins on either side of move onset to
%        use in dPCA
%        moveBins = the window to calculate target on (3 ish for head
%        movement, maybe 10 for BCI)

out = apply_dPCA_simple(binnedR.zSpikes, binnedR.speedMO, binnedR.uCoh, [(-1*binsBefore), binsAfter], 0.02, {'CohD', 'CohI'});
%% plot it
nBins = length(unique(unsignedCoh))
lineArgs = cell(nBins,1);
colors = parula(nBins)*0.8;
for l=1:nBins
    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2,'LineStyle','-'};
end
yAx = oneFactor_dPCA_plot(out, -binsBefore:binsAfter, lineArgs, {'Coherence Dependent', 'Coherence Independent'}, 'sameAxes');

%% 2-factor dPCA:
% unsignedCoh(tgt >= 3) = [];
% moveOnset(tgt >= 3) = [];
% tgt(tgt>=3) = [];
nBins1 = length(unique(unsignedCoh));
nBins2 = length(unique(tgt));
lineArgs = cell(nBins1, nBins2);
colors = parula(nBins1)*0.8;
lineStyles = {'-', '--', ':', '.-'};
for f1 = 1:nBins1 %factors
for f2=1:nBins2
    lineArgs{f1,f2} = {'Color',colors(f1,:),'LineWidth',2,'LineStyle',lineStyles{f2}};
end
end
out2 = apply_dPCA_simple(binnedR.zSpikes, binnedR.speedMO, [binnedR.uCoh, binnedR.tgt'], [(-1*binsBefore), binsAfter], 0.02, {'Coh', 'Targ', 'CI', 'Inter'});
yAx2 = twoFactor_dPCA_plot(out2, (-1*binsBefore):binsAfter, lineArgs, {'Coherence', 'Target', 'CI', 'Interaction'}, 'sameAxes');

