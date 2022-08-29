taskModelDir = 'keyboardTask';
taskFilename = 'keyboardTask';

open_system('taskBlock');
open_system('allTasks');
replace_block('taskBlock','Name','taskInterface',['allTasks/' taskFilename],'noprompt');
if bdIsLoaded(taskFilename)
    close_system(taskFilename)
end
save_system('taskBlock',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/' taskModelDir '/' taskFilename '.slx']);
%close_system('allTasks');
runKeyboardBuildScripts

modelName = [taskFilename];
modelCompleteName = [modelName 'Complete_' modelConstants.rig];

%% take the task file generated above, and put it into the model framework.
open_system('framework')
%% set filtering appropriately for this rig
adaptFrameworkToRig(); 
set_param('framework/Task', 'ModelName', modelName);
close_system(modelName)
keyboardTask_updateParameters;

if bdIsLoaded(modelCompleteName)
    close_system(modelCompleteName)
end

rtwbuild('decoder')
%% save the framework into a task-specific file, compile that thing.
save_system('framework',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/cursorTask/' modelCompleteName '.slx']);
rtwbuild(modelName)
rtwbuild(modelCompleteName);