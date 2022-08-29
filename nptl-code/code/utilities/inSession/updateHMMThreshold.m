function updateHMMThreshold(hmmQ, recalcQuantiles, discreteModel)
% updateHMMThreshold(hmmQ, recalcQuantiles)
%
% pushes the modelConstant params used for setting HMM threshold
% hmmQ - quantile for hmm. 
% recalcQuantiles - prompts for a block to use to set the new likelihoods
%                   if 0, then will base off the data in the most recently
%                   loaded hmm decoder loaded.
% discreteModel    - discrete decoder that's been loaded into MATLAB
%                   memory. Used if recalcQuantiles is 0 and there's not a
%                   hmmLikelihoods in the modelConstants.sessioNParams.
%
% Written by Paul Nuyujukian
% Modified by Sergey Stavisky
    global modelConstants;
    
    %% check to see if recalc is needed
    if ~exist('recalcQuantiles', 'var') 
        recalcQuantiles = 0;
    end
    if recalcQuantiles
        [likelihoods, clickSource] = calcBlockHMMQuantiles();
    end
    
    % neural click data block
    if all(recalcQuantiles) && all(clickSource == clickConstants.CLICK_TYPE_NEURAL)
        % SDS Feb 10 2017: I hate the use of thsi modelConstants
        % pseudo-global to move these hmmLikelihoods around. I think it
        % shoud always be done mroe explicitly. We'll keep writing them
        % here for now so as to not risk breaking things, but will try not
        % to use them
        modelConstants.sessionParams.hmmLikelihoods = likelihoods;
    else
        % Note: this used to come from modelConstants.sessionParams.hmmLikelihoods
        % which is terrible practice. Instead pull it directly from a model
        
        % pull likelihoods from the input discrete model
        % SDS Jan 2017
        fprintf('Loading likelihoods from %s.\n', ...
            char( discreteModel.discretemodel.filterName )' );
        likelihoods = discreteModel.likelihoods;
        
    end

    
    modelConstants.sessionParams.hmmQ = hmmQ; % set gobal hmmQ
    
    curThresh = quantile(likelihoods, hmmQ);
    fprintf(1, 'Setting HMM quantile to q%01.2f ...', hmmQ);
    modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
    
    setHMMThreshold(curThresh); % push variables

end
