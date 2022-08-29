function blocks = queryExpRBlocks(runID)
% blocks = queryExpRBlocks(runID)
% assumes properly formatted runID as returned by parseRunID()

	setAnalysisConstants;

	blocks = dir(fullfile(analysisConstants.RPath, runID(1:2), runID, 'R_*'));
	numBlocks = numel(blocks);
	blockMask = logical(ones(1, numBlocks));
	for i = 1 : numel(blocks)
		if ~blocks(i).isdir
			blockMask(i) = 0;
		end
	end
	blocks = blocks(blockMask);

	numBlocks = numel(blocks);

	if ~numBlocks 
		   error('queryExpRBlocks:noRunID', 'runID data not found, check path/data');
   end

end
