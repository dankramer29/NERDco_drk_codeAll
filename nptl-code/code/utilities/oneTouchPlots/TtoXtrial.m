function xt=TtoXtrial(T,modelInput)
% TTOXTRIAL    
% 
% xt=TtoXtrial(T,modelInput)
%   OUTPUTS: xTrial with fields:
%       decodeX     - the decoded sequence
%       trueX       - the true sequence
%       condition   - the condition number
%       isCenterOut - is the trial center out?
%       trialNum    - the absolute trial number
%       trialNumRel - the relative trial number (lowest is 1)
%       xSeqIndices - indices in xSeqInfo with same information
%       numElems    - the number of decoded bins in this trial
%       modelInput  - information for offline decode

    % g=gameTypesBrown();
    
    SCALE_FACTOR=1;

    for nTrial=1:length(T)
        xt(nTrial).trialNum=nTrial;
        xt(nTrial).trialNumRel=nTrial;

        xt(nTrial).trueX=[T(nTrial).X(1:4,:)]*SCALE_FACTOR;
        xt(nTrial).decodeX=xt(nTrial).trueX;
        xt(nTrial).posTarget = T(nTrial).posTarget; %bsxfun(@plus,T(nTrial).posTarget,zeros(2,
                                                    %size(xt(nTrial).trueX,2)));
        if isfield(T,'Z')
            xt(nTrial).neuralBin=[T(nTrial).Z];
        end


        if isfield(T,'cuedTarget') %% for keyboard data
            xt(nTrial).cuedTarget=T(nTrial).cuedTarget;
        end
        if isfield(T,'clickState') %% for keyboard data
            xt(nTrial).clickState=T(nTrial).clickState;
        end
        if isfield(T,'clicked') %% for keyboard data
            xt(nTrial).clicked=T(nTrial).clicked;
        end
        if isfield(T,'discreteStateLikelihoods') %% for keyboard data
            xt(nTrial).discreteStateLikelihoods=T(nTrial).discreteStateLikelihoods;
        end

        if isfield(T,'xSingleChannel') %% for single channel decodes
            xt(nTrial).xSingleChannel=T(nTrial).xSingleChannel;
        end
        if isfield(T,'ySingleChannel') %% for single channel decodes
            xt(nTrial).ySingleChannel=T(nTrial).ySingleChannel;
        end

        xt(nTrial).modelInput = modelInput;

        xt(nTrial).isCenterOut = modelInput.isCenterOut;
        
    end
