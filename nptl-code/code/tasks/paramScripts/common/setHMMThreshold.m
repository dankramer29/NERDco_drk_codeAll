function setHMMThreshold(inThreshold)

	global modelConstants;

    if exist('inThreshold', 'var')
		modelConstants.sessionParams.hmmClickLikelihoodThreshold = inThreshold;
    end
    
    if ~isfield(modelConstants.sessionParams, 'hmmClickLikelihoodThreshold')
		error('setHMMThreshold:noLikelihood', 'modelConstants.sessionParams.hmmClickLikelihoodThreshold not found!');
    end

    setModelParam('hmmClickLikelihoodThreshold',    modelConstants.sessionParams.hmmClickLikelihoodThreshold);
    pause(0.2); disp('threshold set');
    fprintf(1, '... HMM threshold (''hmmClickLikelihoodThreshold'')set to %01.3f\n', modelConstants.sessionParams.hmmClickLikelihoodThreshold);
    
end
