function [currentState, logP] = hmmViterbiLanguageModel(oProb,startProb,stateLabels,stateTransP,spaceEndStateIdx,...
    stateWordIdx,unigram_logP,newWordStayProb_logP)

    numStates = length(stateLabels);
    L = size(oProb,1);

    % allocate space
    pTR = zeros(numStates,L);

    % assumption is that model is in state 1 at step 0
    v = startProb;
    vOld = v;

    % loop through the model
    for count = 1:L
        disp(count);

        for state = 1:numStates
            % for each state we calculate
            % v(state) = e(state,seq(count))* max_k(vOld(:)*tr(k,state));
            if stateTransP{state}==-1
                %new word state: consider the space state and all end-of-word
                %states (in case skipping space)
                %weight by the probability of this word
                
                %no space skipping
                st = [spaceEndStateIdx, -0.7144+unigram_logP(stateWordIdx(state));
                    state, newWordStayProb_logP(stateWordIdx(state))];
                    
                %with space skipping (slower)
                %st = newWordAcceptor;
                %st(end,:) = [state, newWordStayProb_logP(stateWordIdx(state))];
                %st(1:(end-1),2) = st(1:(end-1),2) + unigram_logP(stateWordIdx(state));
            else
                st = stateTransP{state};
            end

            tmpV = vOld(st(:,1)) + st(:,2);
            [maxVal, maxIdx] = max(tmpV);
            pTR(state, count) = st(maxIdx,1);

            % update v
            v(state) = oProb(count, stateLabels(state)) + maxVal;
        end
        vOld = v;
    end

    % decide which of the final states is most probable
    [logP, finalState] = max(v);

    % Now back trace through the model
    currentState = zeros(1,L);
    currentState(L) = finalState;

    for count = L-1:-1:1
        currentState(count) = pTR(currentState(count+1),count+1);
        if currentState(count) == 0
            error(message('stats:hmmviterbi:ZeroTransitionProbability', currentState( count + 1 )));
        end
    end
end




