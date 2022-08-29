function Data = jpcaPrep(rota, keepTimes)
    Data = struct;
    Data(1).A = [];
    Data(1).cursorPosition=[];

    numBlocks = 0;
    for nb = 1:numel(rota.blocks)
        %% only care about center-out
        conds = find(any([rota.blocks(nb).conditions.posTarget]));
        for id = 1:numel(conds) %(rota.blocks(1).conditions)
            %% if this is new, add a Data() element
            if numel(Data) < id
                Data(id).A=[];
                Data(id).cursorPosition=[];
            end
            nd = conds(id);

            %% per-condition movement onset
            timeOffset = 0;
            if isfield(rota.blocks(nb).conditions(nd), 'moveOnset')
                timeOffset = -rota.blocks(nb).conditions(nd).moveOnset;
            end
            times = rota.blocks(nb).conditions(nd).times + floor(timeOffset);

            [~,timeInds,~] = intersect(times,keepTimes);

            if ~isfield(Data(id),'times') || isempty(Data(id).times)
                Data(id).times = times(timeInds);
            end
            if any(Data(id).times ~= times(timeInds));
                keyboard
            end
            Data(id).A = [Data(id).A'; rota.blocks(nb).conditions(nd).Data(:,timeInds)]';
            if isfield(rota.blocks(nb).conditions(nd), 'cursorPosition')
                if isempty(Data(id).cursorPosition)
                    Data(id).cursorPosition = rota.blocks(nb).conditions(nd).cursorPosition(:,timeInds);
                else
                    Data(id).cursorPosition = Data(id).cursorPosition+rota.blocks(nb).conditions(nd).cursorPosition(:,timeInds);
                end
            end
        end
        numBlocks = numBlocks+1;
    end


    for id = 1:numel(Data)
        Data(id).cursorPosition = Data(id).cursorPosition / numBlocks;
    end