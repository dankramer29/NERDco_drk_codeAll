global modelConstants
if isempty(modelConstants)
	modelConstants = modelDefinedConstants();
end

rigHardware_buildWorkspace;
modelName = ['dualArrayTest'];
modelCompleteName = [modelName 'Complete'];

%% take the task file generated above, and put it into the model framework.
open_system(modelName)

% set filtering appropriately for this rig
adaptFrameworkToRig(modelName);
%% save the framework into a task-specific file, compile that thing.
save_system(modelName,[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/' ...
    'development/' modelName '/' modelCompleteName '.slx']);
close_system(modelName)
rtwbuild(modelCompleteName);