function f = plotContrib(R, contrib, bW);
% f = plotContrib(R, contrib);

contribChannels = find(sum(contrib, 2));

iH = imagesc(contrib(contribChannels, :));
ax = gca;
f = get(get(iH, 'parent'), 'parent');
set(ax, 'cLim', [-1 2]);
colormap(hot);
colorbar;

xlabel(sprintf('Bin Number (%ims bins)', bW));
ylabel(sprintf('Contributing Channel'));
title(sprintf('Block %i', R(1).startTrialParams.blockNumber));

set(ax, 'yTick', [1:numel(contribChannels)]);
set(ax, 'yTickLabel', contribChannels);
set(ax, 'fontSize', 8);

figWidth = 20;
figHeight = figWidth;
set(f, 'paperUnits', 'centimeters');
set(f, 'paperSize', [figWidth figHeight]);
set(f, 'paperPosition', [0 0 figWidth figHeight]);
