function d=getDwellTime(R,taskDetails)
% GETDWELLTIME    
% 
% d=getDwellTime(R,taskDetails)
%
% get the dwell time
    
%% get all successful trials
    succ = find([R.isSuccessful]);
    
    stateNames = {taskDetails.states.name};
    stateIds = [taskDetails.states.id];
    acqId = stateIds(strcmp(stateNames,'STATE_ACQUIRE'));
    for nn = 1:length(succ)
        ni = succ(nn);
        [a,longest] = findcont(R(ni).state == acqId);
        ds(nn).length = longest.length;
    end
    
    if length(ds)
        assert(all([ds.length]==ds(1).length)),'variable dwell times??';
        
        d = ds(1).length;
    else
        d = [];
    end
    