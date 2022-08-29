function [discretemodel] = fitGaussianHMM_MC(observ, stateSeq, states, discretemodel, options,figh)
% FITGAUSSIANHMM    
% [discretemodel] = fitGaussianHMM(observ, stateSeq, discretemodel, options)
%  builds a gaussian HMM with observed discrete states
%	and continuous, single mixture, multivariate gaussian observations
    %% hide low-dimensional plots by default
    options = setDefault(options,'showLowD',false, true);
    options = setDefault(options,'lowDColors','brgmky', true);
    options = setDefault(options,'maxClickLength',0);
   % dim			= size(observ, 1);				% dimensions of observation
    % initialize the output variables to the right sizes
    discretemodel.trans = zeros(DecoderConstants.MAX_DISCRETE_STATES);
    discretemodel.emisMean = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);
    discretemodel.emisCovarDet = zeros([DecoderConstants.MAX_DISCRETE_STATES 1]);
    discretemodel.emisCovar = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);
    discretemodel.emisCovarInv = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);

    discretemodel.numDimensionsToUse = options.numDimensionsToUse;
    numDimensionsToUse = options.numDimensionsToUse;
    if isfield(options,'trans')
        discretemodel.trans(1:discretemodel.numStates,1:discretemodel.numStates) = options.trans;
    end

    if options.showLowD
        % Make figure;
        if nargin < 6
            figh = figure;
        else
            figure( figh )
        end
    end
    stateLabels = {};
    stateColors = [];
    for i = 1 : discretemodel.numStates
        %% find the indices for this state
        stateIdx = find( stateSeq(1 : end - 1) == states(i) );
        
        %% if no transition matrix was specified, calculate the transition probabilities from this state
        if ~isfield(options,'trans')  
            disp('no transition matrix was specified, so calculating the transition probabilities from the data.')
            %BJ: if discardAmbiguousData is true, transition probabilities
            %may be a bit off from what they'd be using the contiguous
            %data (assuming that labels were "correct"). Could either pipe
            %the continuous data here for this part of the process, or just
            %use the chopped data anyway and it shouldn't be too far off,
            %according to Jonathan Kao.  
            if options.excludeAmbiguousData,
                warning('Computing transition probabilities from data whose "ambiguous" datapoints have been chopped. This part may not give same transition probabilities as the original continuous data!')
            %    keyboard
            end
            statesTotal = numel(stateIdx);
            for j = 1 : discretemodel.numStates
                trans(j, i) = sum(stateSeq( stateIdx + 1) == states(j))/statesTotal; 
                %SNF: are we just ignoring the fact that trans is never
                %sent back to the discretemodel? ugh. Assuming this code
                %was never actually used or else someone would have caught
                %this
            end
            
        end

        %% fit emission matrices for this state
        stateObserv = observ(:, stateIdx);
        discretemodel.emisMean(i, :) = mean(stateObserv');
        discretemodel.emisCovar(i, :, :) = cov(stateObserv').*eye(size(stateObserv,1)); %make this diagonal - more matchy to NB bc assumes features are independent
        %alternatively, we could only calc cov for all states instead of
        %each individually 
        blankChannels = find(diag(squeeze(discretemodel.emisCovar(i, :, :)))==0);
        for j = blankChannels
            discretemodel.emisCovar(i, j, j) = 1;
        end
        
        %% plot the low dimensional projection (if desired)
        if options.showLowD
            switch i
                case 1
                    stateLabels{i} = sprintf('Move');
                case 2
                    stateLabels{i} = sprintf('Click');
                otherwise
                    stateLabels{i} = sprintf('State%i', i);                                
            end
            stateColors{i} =  options.lowDColors(i);
            plot3(observ(1,stateIdx),observ(2,stateIdx),observ(3,stateIdx),...
                  ['o' options.lowDColors(i)]);
            hold on;
            xlabel('PC1');
            ylabel('PC2');
            zlabel('PC3');
            if i ==discretemodel.numStates
               % last state , so make legend
               legend(stateLabels)
            end
        end
    end
    if ~isfield(options,'trans')  
        discretemodel.trans(1:discretemodel.numStates,1:discretemodel.numStates) = trans; %SNF
    end
    %% now save the emisCovarDeterminant and emisCovarInverse
    for i = 1 : discretemodel.numStates
        emisCovarCur = squeeze(discretemodel.emisCovar(i, :, :));
        %emisCovarCur(i,options.numDimensionsToUse+1:end,options.numDimensionsToUse+1:end) = ...
        %    1e6*emisCovarCur(i,options.numDimensionsToUse+1:end,options.numDimensionsToUse+1:end);
        
        %discretemodel.emisCovarDet(i) = det(emisCovarCur);
        discretemodel.emisCovarDet(i) = det(emisCovarCur(1:numDimensionsToUse,1:numDimensionsToUse));
        discretemodel.emisCovarInv(i, :, :) = pinv(emisCovarCur);
    end
end

