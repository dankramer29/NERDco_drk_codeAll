global modelConstants
if isempty(modelConstants)
	modelConstants = modelDefinedConstants();
end

%% load the generic taskBlock, replace its taskInterface subsystem with the specific task
open_system('taskBlock');
open_system('allTasks');
replace_block('taskBlock','Name','taskInterface','allTasks/fittsTask','noprompt');
if bdIsLoaded('fittsTask')
    close_system('fittsTask')
end
%% save the generic task (with replaced task block) to a task-specific file
save_system('taskBlock',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/fittsTask/fittsTask.slx']);
close_system('allTasks');

xpcNICConfig = xpcNICConfigWest();
runFittsBuildScripts

modelName = ['fittsTask'];
modelCompleteName = ['fittsTaskComplete_' modelConstants.rig];

%% take the task file generated above, and put it into the model framework.
open_system('framework')
%% set filtering appropriately for this rig
adaptFrameworkToRig(); 
set_param('framework/Task', 'ModelName', modelName);
close_system(modelName)
fittsTask_updateParameters;


if bdIsLoaded(modelCompleteName)
    close_system(modelCompleteName)
end

%% save the framework into a task-specific file, compile that thing.
save_system('framework',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/fittsTask/' modelCompleteName '.slx']);
rtwbuild(modelName)
rtwbuild(modelCompleteName);