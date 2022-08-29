function [T,modelInput]=RtoT(R,taskDetails,saveTag)


%% use the "MakeT" script to bin the R struct into something manageable?

modelInput.saveTag=saveTag;
modelInput.dt=50;
modelInput.realOrFakeSpikes=1;
% modelInput.kinematicSource='handSmooth';
modelInput.decodeModelType=10;
modelInput.neuralLag=0;
modelInput.history=0;
modelInput.numHoldRepeats=0;
modelInput.skipTime=0;
modelInput.binWidth=modelInput.dt;
modelInput.rmsMult = -2.5;

stateVars = {taskDetails.states.name};
stateIds = [taskDetails.states.id];

thisTask = R(1).startTrialParams.taskType;
switch thisTask
  case cursorConstants.TASK_NEURAL_OUT_MOTOR_BACK
    modelInput.isCenterOut = true;
  case cursorConstants.TASK_CENTER_OUT
    modelInput.isCenterOut = true;
  otherwise
    modelInput.isCenterOut = false;
end


% tmp=[R.startTrialParams];
% stIds=find([tmp.saveTag]==modelInput.saveTag);
% g=gameTypesBrown();
% switch R(stIds(1)).startTrialParams.taskId
%   case g.radialTrain 
%     modelInput.modelID='Presented Stimulus';
%     modelInput.isCenterOut=true;
%   case g.clickTrain
%     modelInput.modelID='Presented Stimulus';
%     modelInput.isCenterOut=true;
%   case g.radial8
%     modelInput.modelID='Online Decode';
%     modelInput.isCenterOut=true;
%   otherwise
%     modelInput.modelID='Online Decode';
%     % modelInput.isCenterOut=false;
%     modelInput.isCenterOut=true;
% end


%where handPos data is defined, set the cursorPos data to that
%handInds=arrayfun(@(x) any(x.handPos(:)),R);
%[R(handInds).cursorPos]=deal(R(handInds).handPos);

% T=makeT(R,modelInput);
T = processAndBin(R, modelInput);
% [T.posTarget] = deal(R.posTarget);
