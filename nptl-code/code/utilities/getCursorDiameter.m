function cursorDiameter=getCursorSize(R)

% function to infer the size of the cursor based on target size, target position,
%  cursor position, and task state

numTrials = 0;
for nt = 1:numel(R)
    % times when over target
    otinds = find(R(nt).state==CursorStates.STATE_ACQUIRE | ...
                  R(nt).state==CursorStates.STATE_HOVER);

    if isempty(otinds)
        % failure trial? skip
        continue
    end
    
    numTrials = numTrials+1;
    % get distance to target at each timestep
    dtt = sqrt(sum(bsxfun(@minus,double(R(nt).cursorPosition),...
                          double(R(nt).posTarget)).^2));
    maxOnTarget(numTrials) = max(dtt(otinds));
end

cursorSize = ceil(max(maxOnTarget) - double(R(1).startTrialParams.targetDiameter)/2);

cursorDiameter = cursorSize*2;