function f = plotOneTouchContribError(blockNum, binWidth)
% function plotOneTouchContrib(blockNum, binWidth)
% 

R = onlineR(parseDataDirectoryBlock(fullfile('Data', 'FileLogger', num2str(blockNum))));
R=addRSpikeRasterT7(R);
filterName = R(1).decoderD.filterName;

if size(filterName, 1) > 1
	filterName = filterName';
end
zeroNames = find(filterName == 0);
filterName = filterName(1:zeroNames(1) -1);

filter = load(fullfile('Data', 'Filters', filterName));

contrib = calcFilterContribErrorBlock(R, filter, binWidth);

f = plotContrib(R, contrib, binWidth);

end
