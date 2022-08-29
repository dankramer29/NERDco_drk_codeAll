function R = loadR(runID, blockNum)
% R = loadR(runID, blockNum)
%
% loads R struct

	setAnalysisConstants;
    
    [runID runIDtrim] = parseRunID(runID);

	R = splitLoad(fullfile(analysisConstants.RPath, runID(1:2), runID, sprintf('R_%03i',blockNum) ));

end
