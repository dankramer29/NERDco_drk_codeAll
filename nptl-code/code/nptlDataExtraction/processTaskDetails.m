function states = processTaskDetails(td)
    states = struct;
    names = {td.states.name};
    ids = [td.states.id];
    for nn = 1:length(names)
        states = setfield(states, names{nn}, ids(nn));
    end
    