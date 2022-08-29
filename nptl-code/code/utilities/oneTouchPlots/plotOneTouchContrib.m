function f = plotOneTouchContribError(runID, R, binWidth)
% function plotOneTouchContrib(runID, R, binWidth)
% 

[runID runIDtrim] = parseRunID(runID);

filterName = R(1).decoderD.filterName;

if size(filterName, 1) > 1
	filterName = filterName';
end
zeroNames = find(filterName == 0);
if ~isempty(zeroNames)
	filterName = filterName(1:zeroNames(1) -1);
end

setAnalysisConstants;

if strcmp(filterName(end-2:end), 'mat') % full filter path fit

	filter = load(fullfile(analysisConstants.experimentPath, runID(1:2), runID, 'Data', 'Filters', filterName));

	contrib = calcFilterContribErrorBlock(R, filter, binWidth);

	f = plotContrib(R, contrib, binWidth);

else
	fprintf(1, 'Filter name too long, gave up.\n');

	f = 0;

end

end
