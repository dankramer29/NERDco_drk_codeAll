function [discretemodel] = fitLDAHMM(observ, stateSeq, states, discretemodel, options, figh) %SF: this is missing figh
% FITLDAHMM
%
% [discretemodel] = fitLDAHMM(observ, stateSeq, states, discretemodel, options)

%
% builds a gaussian HMM with observed discrete states
%	and continuous, single mixture, multivariate gaussian observations
%% hide low-dimensional plots by default
options = setDefault(options,'showLowD',false, true);
options = setDefault(options,'lowDColors','brgmky', true);
options = setDefault(options,'maxClickLength',0);
% states		= unique(stateSeq);				% array of states in system
%    dim			= size(observ, 1);				% dimensions of observation
% initialize the output variables to the right sizes
discretemodel.trans         = zeros(DecoderConstants.MAX_DISCRETE_STATES);
discretemodel.emisMean      = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);
discretemodel.emisCovarDet  = zeros([DecoderConstants.MAX_DISCRETE_STATES 1]);
discretemodel.emisCovar     = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);
discretemodel.emisCovarInv  = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);
discretemodel.projector     = zeros(DecoderConstants.NUM_CONTINUOUS_CHANNELS, DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS);

discretemodel.numDimensionsToUse = options.numDimensionsToUse;

if isfield(options,'trans')
    discretemodel.trans(1:discretemodel.numStates,1:discretemodel.numStates) = options.trans;
else % SNF copied from GaussianHMM if no transition matrix was specified, calculate the transition probabilities from this state
    disp('no transition matrix was specified, so calculating the transition probabilities from the data.')
    if options.excludeAmbiguousData
        warning('Computing transition probabilities from data whose "ambiguous" datapoints have been chopped. This part may not give same transition probabilities as the original continuous data!')
    %    keyboard
    end
    for i = 1 : discretemodel.numStates
        % find the indices for this state
        stateIdx = find( stateSeq(1 : end - 1) == states(i) );
        statesTotal = numel(stateIdx);
        for j = 1 : discretemodel.numStates
            trans(j, i) = sum(stateSeq( stateIdx + 1) == states(j))/statesTotal;
        end
    end
    discretemodel.trans(1:discretemodel.numStates,1:discretemodel.numStates) = trans; 
end

osum = sum(observ,2);
usech = find(osum);
fprintf('fitLDAHMM: using %g channels\n',numel(usech));
projector=LDA(observ(usech,:)',stateSeq');
%L=[ones(size(observ,2),1) observ(find(osum),:)']*y';

for i = 1:discretemodel.numStates
    %% the neural part of 'projector' goes into projector
    discretemodel.projector(usech,i) = projector(i,2:end);
    %% there is also the offset term, assign that to emisMeans(:,1)
    discretemodel.emisMean(i,1) = projector(i,1);
end
end

