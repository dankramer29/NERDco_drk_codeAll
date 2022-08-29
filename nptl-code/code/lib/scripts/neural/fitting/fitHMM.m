function [discretemodel, figh] = fitHMM(D, discretemodel, options, figh)
% FITHMM
%
% [discretemodel] = fitHMM(D, discretemodel, options, figh)
%
% figh input/output is to keep track of generated figure.
% if figh is input, it'll plot on that figure
if nargin < 4
    figh = figure;
end
% builds a gaussian HMM with observed discrete states
%% hide low-dimensional plots by default
options = setDefault(options,'showLowD',false, true);
options = setDefault(options,'lowDColors','brgmky', true);
options = setDefault(options,'maxClickLength',0);
%% concatenate the neural data
observ = [D.Z];
%% build the correct state model
checkOption(options,'stateModel','must specify which state model to use');
discretemodel.stateModel = uint8(options.stateModel);

switch options.stateModel
%% % Two state model (move vs. click)
    case DiscreteStates.STATE_MODEL_MOVECLICK
        checkOption(options,'clickSource','must specify a click source for MOVECLICK');
        checkOption(options,'clickStateThreshold','must specify a click source for MOVECLICK');
        % two states for this model
        states = uint8([DiscreteStates.MOVECLICK_STATE_MOVE DiscreteStates.MOVECLICK_STATE_CLICK]);
        discretemodel.numStates	= numel(states);				% total number of states
        
        % BJ: if excludeAmbiguousData, chop out datapoints indsToChop 
        % from both clickSource AND observ:
        if options.excludeAmbiguousData
            [clickSource, binsToChop] = findClickTimes(D, options); %BJ/TODO: generalize this function so can also be used for MOVEIDLECLICK
            clickSource(binsToChop) = []; % remove data points identified as ambiguous or above click threshold for too long
            observ(:,binsToChop) = [];    % also remove corresponding bits of neural data
        end
        % create the state sequence, making default state be STATE_MOVE
        stateSeq = zeros([1 size(observ,2)],'uint8') + uint8(DiscreteStates.MOVECLICK_STATE_MOVE);
        % apply "click" codes to stateSeq where clickSource is currently 
        % labeled 1 (i.e. the spots that we determined above correspond to intended click)
        stateSeq(clickSource) = uint8(DiscreteStates.MOVECLICK_STATE_CLICK);    
%% % Three state model (move, idle, click)
    case DiscreteStates.STATE_MODEL_MOVEIDLECLICK
        if options.excludeAmbiguousData,
            warning('3-state model does not yet work with excludeAmbiguousData. Using all data!')
        end
        checkOption(options,'clickSource','must specify a click source for MOVEIDLECLICK');
        checkOption(options,'idleSource','must specify a click source for MOVEIDLECLICK');
        % two states for this model
        states = uint8([DiscreteStates.MOVEIDLECLICK_STATE_MOVE DiscreteStates.MOVEIDLECLICK_STATE_IDLE DiscreteStates.MOVEIDLECLICK_STATE_CLICK]);
        discretemodel.numStates	= numel(states);				% total number of states
        % create the state sequence. default state is STATE_MOVE
        stateSeq = zeros([1 size(observ,2)],'uint8') + uint8(DiscreteStates.MOVEIDLECLICK_STATE_MOVE);
        % pick the the field in the D-struct that matches the click source
        switch options.clickSource
            case DiscreteStates.STATE_SOURCE_CLICK
                clickSource = [D.clickState];
            case DiscreteStates.STATE_SOURCE_DWELL
                clickSource = [D.dwellState];
            otherwise %SNF thinks this "otherwise" was missing. Also, where's hover over target? 
                error('dont understand the source for the click state');
        end
        switch options.idleSource
            case DiscreteStates.STATE_SOURCE_REST
                idleSource = [D.restState];
            case DiscreteStates.STATE_SOURCE_DWELL
                idleSource = [D.dwellState];
            otherwise
                error('dont understand the source for the idle state');
        end
        if options.maxClickLength
            % maximum number of continguous BINS a click can occur for 
            maxClickBins = ceil(options.maxClickLength / options.binSize);

            clickStateChanges = diff([0;clickSource(:);0]);
            clickStarts = find(clickStateChanges==1);
            clickEnds = find(clickStateChanges==-1);
            if clickEnds(end)>length(clickSource)
                clickEnds(end) = length(clickSource);
            end
            longClicks = clickEnds-clickStarts>maxClickBins;
            clickEnds(longClicks) = clickStarts(longClicks)+maxClickBins;
            
            clickSource(1:end)=0;
            for nc = 1:length(clickStarts)
                clickSource(clickStarts(nc):clickEnds(nc))=1;
            end
        end
        % assign labels to click data points
        stateSeq(clickSource>0) = uint8(DiscreteStates.MOVEIDLECLICK_STATE_CLICK);
        % assign labels to idle data points
        stateSeq(idleSource>0) = uint8(DiscreteStates.MOVEIDLECLICK_STATE_IDLE);
%% for multiclick, need to know the click target in addition to when click was happening        
%%% Move + 4 click types model (like the 2-state model but with 4 click options instead of 1)
    case DiscreteStates.STATE_MODEL_MULTICLICK
        if options.excludeAmbiguousData
            warning('multiclick model does not yet work with excludeAmbiguousData. Using all data!')
        end
        checkOption(options,'clickSource','must specify a click source for MULTICLICK');
        % 5 states max for this model- move is 0, the rest are 2-5
        states = uint8([DiscreteStates.MULTICLICK_STATE_MOVE DiscreteStates.MULTICLICK_STATE_LCLICK,...
                 DiscreteStates.MULTICLICK_STATE_RCLICK DiscreteStates.MULTICLICK_STATE_2CLICK DiscreteStates.MULTICLICK_STATE_SCLICK]);
        discretemodel.numStates	= min(numel(states), options.statesToUse); %SNF sept 10				% total number of states
        % create the state sequence. default state is STATE_MOVE
%         stateSeq = zeros([1 size(observ,2)],'uint8') + uint8(DiscreteStates.MULTICLICK_STATE_MOVE);
        
        if options.excludeAmbiguousData %this is being read as a char array instead of bool, tontos who used false without setting it properly. 
            [clickSource, binsToChop] = findClickTimes(D, options); %SNF says this call is only needed if you're doing exclude
            clickSource(binsToChop) = []; % remove data points identified as ambiguous or above click threshold for too long
            observ(:,binsToChop) = [];    % also remove corresponding bits of neural data
        end
%         if options.maxClickLength
%            % maximum number of continguous BINS a click can occur for 
%             maxClickBins = ceil(options.maxClickLength / options.binSize);
%         %SNF: this is only working on CL data... we don't actually need it 
%             clickStateChanges = diff([0;clickSource(:);0]);
%             clickStarts = find(clickStateChanges==1);
%             clickEnds = find(clickStateChanges==-1);
%             if clickEnds(end)>length(clickSource)
%                 clickEnds(end) = length(clickSource);
%             end
%             longClicks = clickEnds-clickStarts>maxClickBins;
%             clickEnds(longClicks) = clickStarts(longClicks)+maxClickBins;
%             
%             clickSource(1:end)=0;
%             for nc = 1:length(clickStarts)
%                 clickSource(clickStarts(nc):clickEnds(nc))=1;
%             end
%         end
%SNF: this is only okay ish for OL: 
        tempvec = [D.clickTarget];
        tempvec(tempvec > 0) = tempvec(tempvec > 0) + 1; % + 1 because the states are incremented
        stateSeq = uint8(tempvec);   
%% % Three-state + 4 click types model (move, idle, click(x4))
%% SF: don't worry about this case yet. 
    case DiscreteStates.STATE_MODEL_MULTICLICK3
        if options.excludeAmbiguousData,
            warning('multiclick model does not yet work with excludeAmbiguousData. Using all data!')
        end
        
        checkOption(options,'clickSource','must specify a click source for MOVEIDLECLICK');
        checkOption(options,'idleSource','must specify a click source for MOVEIDLECLICK');
        % 6 states for this model
        states = uint8([DiscreteStates.MULTICLICK_STATE_MOVE DiscreteStates.MULTICLICK_STATE_IDLE   DiscreteStates.MULTICLICK_STATE_LCLICK,...
                      DiscreteStates.MULTICLICK_STATE_RCLICK DiscreteStates.MULTICLICK_STATE_2CLICK DiscreteStates.MULTICLICK_STATE_SCLICK]);
        discretemodel.numStates	= numel(states);				% total number of states
        
        % create the state sequence. default state is STATE_MOVE
        stateSeq = zeros([1 size(observ,2)],'uint8') + uint8(DiscreteStates.MULTICLICK_STATE_MOVE);
        % pick the the field in the D-struct that matches the click source
        switch options.clickSource
            case DiscreteStates.STATE_SOURCE_CLICK
                clickSource = [D.clickState];
            case DiscreteStates.STATE_SOURCE_DWELL
                clickSource = [D.dwellState];
            otherwise %SNF thinks this "otherwise" was missing in 3-state
                error('dont understand the source for the click state');
        end
        switch options.idleSource
            case DiscreteStates.STATE_SOURCE_REST
                idleSource = [D.restState];
            case DiscreteStates.STATE_SOURCE_DWELL
                idleSource = [D.dwellState];
            otherwise
                error('dont understand the source for the idle state');
        end
        if options.maxClickLength
           % maximum number of continguous BINS a click can occur for 
            maxClickBins = ceil(options.maxClickLength / options.binSize);

            clickStateChanges = diff([0;clickSource(:);0]);
            clickStarts = find(clickStateChanges==1);
            clickEnds = find(clickStateChanges==-1);
            if clickEnds(end)>length(clickSource)
                clickEnds(end) = length(clickSource);
            end
            longClicks = clickEnds-clickStarts>maxClickBins;
            clickEnds(longClicks) = clickStarts(longClicks)+maxClickBins;
            
            clickSource(1:end)=0;
            for nc = 1:length(clickStarts)
                clickSource(clickStarts(nc):clickEnds(nc))=1;
            end
        end
        % assign labels to click data points
        stateSeq(clickSource>0) = uint8(DiscreteStates.MULTICLICK_STATE_CLICK);
        % assign labels to idle data points
        stateSeq( idleSource>0) = uint8(DiscreteStates.MULTICLICK_STATE_IDLE);    
% SF: including idle state will require the state seq to be 0 = MOVE, 1 = IDLE, CLICK_TARGET = CLICK_TARGET + 1    
    otherwise
        error('fitHMM: dont know how to implement this model!');
end

if options.usePCA || options.useFA
    %fitGaussianHMM_MC
    discretemodel = fitGaussianHMM(observ,stateSeq,states, discretemodel,options, figh);
    %discretemodel = fitGaussianHMM_MC(observ,stateSeq,states, discretemodel,options, figh);
elseif options.useLDA
    discretemodel = fitLDAHMM(observ,stateSeq,states, discretemodel,options, figh);
else
    error('fitHMM: dont know how to implement this dim red technique!');
end
%     % states		= unique(stateSeq);				% array of states in system
%     dim			= size(observ, 1);				% dimensions of observation
%     % initialize the output variables to the right sizes
%     discretemodel.trans = zeros(DecoderConstants.MAX_DISCRETE_STATES);
%     discretemodel.emisMean = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);
%     discretemodel.emisCovarDet = zeros([DecoderConstants.MAX_DISCRETE_STATES 1]);
%     discretemodel.emisCovar = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);
%     discretemodel.emisCovarInv = zeros([DecoderConstants.MAX_DISCRETE_STATES DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS]);

%     discretemodel.numDimensionsToUse = options.numDimensionsToUse;
%     numDimensionsToUse = options.numDimensionsToUse;
%     if isfield(options,'trans')
%         discretemodel.trans(1:discretemodel.numStates,1:discretemodel.numStates) = options.trans;
%     end

%     for i = 1 : discretemodel.numStates
%         %% find the indices for this state
%         stateIdx = find( stateSeq(1 : end - 1) == states(i) );

%         %% if no transition matrix was specified, calculate the transition probabilities from this state
%         if ~isfield(options,'trans')
%             statesTotal = numel(stateIdx);
%             for j = 1 : discretemodel.numStates
%                 trans(j, i) = sum(stateSeq( stateIdx + 1) == states(j))/statesTotal;
%             end
%         end

%         %% fit emission matrices for this state
%         stateObserv = observ(:, stateIdx);
%         discretemodel.emisMean(i, :) = mean(stateObserv');
%         discretemodel.emisCovar(i, :, :) = cov(stateObserv');

%         blankChannels = find(diag(squeeze(discretemodel.emisCovar(i, :, :)))==0);
%         for j = blankChannels
%             discretemodel.emisCovar(i, j, j) = 1;
%         end

%         %% plot the low dimensional projection (if desired)
%         if options.showLowD
%             plot3(observ(1,stateIdx),observ(2,stateIdx),observ(3,stateIdx),...
%                   ['o' options.lowDColors(i)]);
%             hold on;
%             xlabel('PC1');
%             ylabel('PC2');
%             zlabel('PC3');
%         end
%     end


%     %% now save the emisCovarDeterminant and emisCovarInverse
%     for i = 1 : discretemodel.numStates
%         emisCovarCur = squeeze(discretemodel.emisCovar(i, :, :));
%         %emisCovarCur(i,options.numDimensionsToUse+1:end,options.numDimensionsToUse+1:end) = ...
%         %    1e6*emisCovarCur(i,options.numDimensionsToUse+1:end,options.numDimensionsToUse+1:end);

%         %discretemodel.emisCovarDet(i) = det(emisCovarCur);
%         discretemodel.emisCovarDet(i) = det(emisCovarCur(1:numDimensionsToUse,1:numDimensionsToUse));
%         discretemodel.emisCovarInv(i, :, :) = pinv(emisCovarCur);
%     end
% end