function [tstr] = getTaskType(R,taskDetails)
    
    stateNames = {taskDetails.states.name};
    stateIds = [taskDetails.states.id];


    minoInd = find(strcmp(stateNames,'TASK_NEURAL_OUT_MOTOR_BACK'));
    minoType = stateIds(minoInd);
    
    neuralInd = find(strcmp(stateNames,'INPUT_TYPE_DECODE_V'));
    neuralType = stateIds(neuralInd);

    touchpadInd = find(strcmp(stateNames,'INPUT_TYPE_MOUSE_ABSOLUTE'));
    if isempty(touchpadInd)
        touchpadInd = find(strcmp(stateNames,'INPUT_TYPE_MOUSE_ABS'));
    end
    touchpadType = stateIds(touchpadInd);

    inputTypes = [R.inputType];
    if all(inputTypes==neuralType)
        tstr = 'TASK_FULL_NEURAL';
        return;
    end

    tp = [R.startTrialParams];
    
    if all([tp.taskType] == minoType)
        tstr = stateNames{minoInd};
        return
    end
    
    
    if all(inputTypes==touchpadType)
        tstr = 'TASK_MOUSE_ABS';
        return;
    end
    
    error('i have no clue!');