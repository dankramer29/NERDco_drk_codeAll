function allTargets = splitRByTrajectory(R)
% SPLITRBYTRAJECTORY    
% 
% Rspl = splitRByTrajectory(R)
%
% splits by both target and source


    %% split R by target
    [trialInds, targets] = getTargetInds(R);
    inwardTarget = find(~abs(targets));

    [inwardTrialInds, prevTargets] = getPreviousTargetInds(R);
    outwardTarget = find(~abs(prevTargets));
    outwardTrials = find(inwardTrialInds ~= outwardTarget);

    allTargets = struct();
    nkeep = 0;

    for nn = 1:numel(targets)
        if nn == inwardTarget
            continue
        end
        nkeep = nkeep+1;
        allTargets(nkeep).target = targets(nn);
        allTargets(nkeep).prevTarget = 0;
        allTargets(nkeep).trials = find(trialInds == nn);
    end

    for nn = 1:numel(prevTargets)
        if nn == outwardTarget
            continue
        end
        nkeep = nkeep+1;
        allTargets(nkeep).target = 0;
        allTargets(nkeep).prevTarget = prevTargets(nn);
        allTargets(nkeep).trials = find(inwardTrialInds == nn);
    end
