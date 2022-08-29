global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end


%% load the generic taskBlock, replace its taskInterface subsystem with the specific task
open_system('taskBlock');
open_system('allTasks');
replace_block('taskBlock','Name','taskInterface','allTasks/linuxTask','noprompt');
if bdIsLoaded('linuxTask')
    close_system('linuxTask')
end
%% save the generic task (with replaced task block) to a task-specific file
save_system('taskBlock',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/linuxTask/linuxTask.slx']);
close_system('allTasks');

xpcNICConfig = xpcNICConfigWest();
runLinuxBuildScripts

% %% take the task file generated above, and put it into the model framework.
% open_system('framework')
% set_param('framework/Task','ModelName','linuxTask');
% close_system('linuxTask')
% linuxTask_updateParameters;
% 
% if bdIsLoaded('linuxTaskComplete')
%     close_system('linuxTaskComplete')
% end
% %% save the framework into a task-specific file, compile that thing.
% save_system('framework',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/linuxTask/linuxTaskComplete.slx']);
% slbuild('decoder');
% rtwbuild('linuxTaskComplete');
% 
% % runLinuxBuildScripts
% % rtwbuild('linuxTaskComplete');




modelName = ['linuxTask'];
modelCompleteName = ['linuxTaskComplete_' modelConstants.rig];

%% take the task file generated above, and put it into the model framework.
open_system('framework')
%% set filtering appropriately for this rig
adaptFrameworkToRig(); 
set_param('framework/Task', 'ModelName', modelName);
close_system(modelName)
linuxTask_updateParameters;

if bdIsLoaded(modelCompleteName)
    close_system(modelCompleteName)
end
%% save the framework into a task-specific file, compile that thing.
save_system('framework',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/linuxTask/' modelCompleteName '.slx']);
rtwbuild(modelName)
rtwbuild(modelCompleteName);