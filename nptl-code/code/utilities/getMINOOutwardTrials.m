function trialInds=getMINOOutwardTrials(R, taskDetails, inputType)
% GETMINOOUTWARDTRIALS    
% 
% trialInds=getMINOOutwardTrials(R, taskDetails, <inputType>)

if ~exist('inputType','var')
    stateNames = {taskDetails.states.name};
    stateIds = [taskDetails.states.id];
    neuralInd = find(strcmp(stateNames,'INPUT_TYPE_DECODE_V'));
    neuralType = stateIds(neuralInd);
    inputType = neuralType;
end

trialInds = find(arrayfun(@(x) all(x.inputType == inputType), R));


