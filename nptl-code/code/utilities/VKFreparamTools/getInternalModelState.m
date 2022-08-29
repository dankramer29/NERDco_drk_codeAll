function [ internalStates ] = getInternalModelState( effectorStates, feedbackSteps, alpha, beta, timeStep, controlVectors, offsetConvention )
    internalStates = zeros(size(effectorStates));
    for s = 1:size(internalStates,1)
        knownStateIdx = s - feedbackSteps - offsetConvention;
        if knownStateIdx < 1
            knownStateIdx = 1;
        end
        
        knownState = effectorStates(knownStateIdx,:);
        if feedbackSteps > 0 && knownStateIdx > 1
            internalStates(s,:) = cursorForwardFcn(knownState, controlVectors((knownStateIdx+1):(s-1),:), alpha, beta, timeStep);
        else
            internalStates(s,:) = knownState;
        end
    end
end

function [ cursorState ] = cursorForwardFcn( startState, controlVectors, alpha, beta, timeStep )
    %first entries are position, latter entries are velocities
    cursorState = startState;
    for c=1:size(controlVectors,1)
        cursorState(((end/2)+1):end) = cursorState(((end/2)+1):end)*alpha + (1-alpha)*beta*controlVectors(c,:);
        cursorState(1:(end/2)) = cursorState(1:(end/2)) + cursorState(((end/2)+1):end)*timeStep;
    end
end

