global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants;
end

open_system('taskBlock');
open_system('allTasks');
replace_block('taskBlock','Name','taskInterface','allTasks/movementCueTask','noprompt');
if bdIsLoaded('movementCue')
    close_system('movementCue')
end
%% save the generic task (with replaced task block) to a task-specific file
save_system('taskBlock',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/movementCue/movementCue.slx']);
close_system('allTasks');

xpcNICConfig = xpcNICConfigWest();
runMovementCueBuildScripts

%% take the task file generated above, and put it into the model framework.
open_system('framework')
set_param('framework/Task','ModelName','movementCue');
close_system('movementCue')
movementCue_updateParameters;

if bdIsLoaded('movementCueComplete')
    close_system('movementCueComplete')
end
%% save the framework into a task-specific file, compile that thing.
save_system('framework',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/movementCue/movementCueComplete.slx']);

rtwbuild('movementCue');
rtwbuild('movementCueComplete');
