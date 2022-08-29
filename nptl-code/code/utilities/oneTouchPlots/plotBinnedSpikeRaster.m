function f = plotBinnedSpikeRaster(R)
% f = plotBinnedSpikeRaster(R)
%
%

bW = 15; % binWidth, ms
maxFR = 200; % spikes / s

%f = figure;

%set(f, 'color', 'w');
%set(ax, 'visible', 'off');

%totalTime = numel([R.clock])/1000; % seconds
%figHeight = 10; % cm
%figWidth = totalTime/10;
%set(f, 'paperUnits', 'centimeters');
%set(f, 'paperSize', [figWidth figHeight]);
%set(f, 'paperPosition', [0 0 figWidth figHeight]);

%nC = size(R(1).spikeRaster, 1);

%set(ax, 'xLim', [0 totalTime]);
%set(ax, 'yLim', [0 nC]);

bS = bin([R.spikeRaster], bW, 'sum');

%nB = size(bS, 2);
%widthMultiple = bW/(figWidth*1000);
%for i = 0 : nC - 1
%	for j = 0 : nB - 1
%
%		binColor = min(1, bS(i+1, j+1)/5) * ones(1, 3);
%		rectangle('parent', ax, 'position', [i j*widthMultiple i+1 (j+1)*widthMultiple], 'faceColor', binColor, 'edgeColor', 'none');
%
%	end
%end

iH = imagesc(bS);
ax = gca;
set(ax, 'cLim', [0 maxFR/1000*bW]);

%set(ax, 'visible', 'off');

totalTime = numel([R.clock])/1000; % seconds
figHeight = 20; % cm
figWidth = totalTime/10;
xlabel(sprintf('Bin number (%ims bins)', bW));
ylabel('Channel number');
title(sprintf('Block %i', R(1).startTrialParams.blockNumber));

f = get(get(iH, 'parent'), 'parent');
set(f, 'paperUnits', 'centimeters');
set(f, 'paperSize', [figWidth figHeight]);
set(f, 'paperPosition', [0 0 figWidth figHeight]);
%set(f, 'position', [10 20 1200 600]);
