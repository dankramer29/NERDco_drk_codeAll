function R1 = removeMINO(R1,taskDetails)
    states = {taskDetails.states.name};
    sids = [taskDetails.states.id];
    dvind = strcmp(states,'INPUT_TYPE_DECODE_V');
    dvid = sids(dvind);

    %% if there are any closed loop trials, keep only the closed loop trials    
    keepers = false(size(R1));
    for ntrial = 1:length(R1)
        if any(find(R1(ntrial).inputType)==dvid)
            keepers(ntrial) = true;
        end
    end
    if any(keepers)
        R1 = R1(keepers);
    end
