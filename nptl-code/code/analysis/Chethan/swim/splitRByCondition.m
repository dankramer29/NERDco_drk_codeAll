function [Rmov, moveNames]=splitRByCondition(R, taskConstants)

    stp = [R.startTrialParams];
    moveIds = unique([stp.currentMovement]);
    if ~exist('taskConstants','var')
        taskConstants = R(1).taskConstants;
    end
    allMovementNames = fields(taskConstants);
    allMovementNames = allMovementNames(cellfun(@(x) strcmp(x(1:4),'MOVE'),allMovementNames));
    for nn = 1:length(allMovementNames)
        tc.(allMovementNames{nn}) = taskConstants.(allMovementNames{nn});
    end

    % get all the movementTypes from the movementTypes enumeration
    
    [~,allTypes] = enumeration('movementTypes');

        for nn = 1:length(allTypes)
            if ~isfield(tc,['MOVE_' allTypes{nn}])
                tc.(['MOVE_' allTypes{nn}]) = movementTypes.(allTypes{nn})+0;
            end
        end

    allMovementNames = fields(tc);
    for nn = 1:length(moveIds)
        moveNames{nn} = allMovementNames{struct2array(tc) == moveIds(nn)};
        if isempty(moveNames{nn})
            warning(['couldnt find ' num2str(moveIds(nn)) ' loading from constant file']);
            
        end
    end

    %moveNames = {'MOVE_ELBOWFLEX','MOVE_INDEX','MOVE_THUMB','MOVE_WRISTFLEX'};
    % for nn =1:length(moveNames)
    %     moveIds(nn) = getfield(R(1).taskConstants,moveNames{nn});
    % end
   
    %% iterate over all trials
    for nt=1:length(R)
        % identify which movement this is
        movement = R(nt).startTrialParams.currentMovement;
        nbucket = find(moveIds==movement);
        if ~exist('Rmov','var') || length(Rmov) < nbucket || isempty(Rmov(nbucket))
            Rmov(nbucket).R(1) = R(nt);
        else
            Rmov(nbucket).R(end+1) = R(nt);
        end
        Rmov(nbucket).R = Rmov(nbucket).R(:);
        Rmov(nbucket).moveName = moveNames{nbucket};
        Rmov(nbucket).moveId = moveIds(nbucket);
    end        
    