global modelConstants
if isempty(modelConstants)
	modelConstants = modelDefinedConstants();
end
% updated SNF July 2018 to include YangTask
modelNames = {'movementCueTask','fittsTask','cursorTask','linuxTask', ...
    'keyboardTask','robotTask','sequenceTask','symbolTask','decisionTask','yangTask','rsgTask'};

disp('Which model?');
txt = '';
for nn=1:numel(modelNames)
    txt = [txt sprintf('%g) %s, ', nn+2, modelNames{nn})];
end
reply = str2double(input(txt, 's'))-2;
modelName = modelNames{reply};

%if reply == 7
%    fprintf('You''ve chosen keyboardTask. Don''t forget to first all keyboardTask_buildWorkspace(1) if keyboards were updated\n')
%end

% choose which task to build
fprintf('[%s] Building framework with task model %s (currently hardcoded in script)\n', ...
    mfilename, modelName);

% set global parameters (workspace variables) needed to build different components of the model
% 'hardware' components
rigHardware_buildWorkspace;
% FYI: DecoderConstants is coming from who-knows-where, maybe build
% include, maybe automatically on apth. Regardless, be aware there exists
% DecoderConstants.m and xkConstants.m

% decoder components
decoderSplit_buildWorkspace;
decoderSplit_updateParameters; % actually updates decoder/decoderParameters  
% behavior-related components
behaviorPacketBus_buildWorkspace;
% click components
clickParameters_buildWorkspace;
% bias correction and means tracking, etc
postProcessing_buildWorkspace;
% the bus that is output by the task
taskOutput_buildWorkspace


% creates a structure called taskParams task specific params
% SDS 9 March 2017. Given that our late2016 architecture forces all the
% tasks to have most of the same parameters (since they go through shared
% updateXk), I'm making there be just a single allTasks_buildWorkspace.
% buildFunction = str2func(sprintf('%s_buildWorkspace', modelName));
% taskParamsStruct = buildFunction();
taskParamsStruct = allTasks_buildWorkspace();

% update the "taskParameters" block within the specific task
% this will actually edit the task-specific .slx file
updateParametersBlock(modelName,'taskParameters', 'taskParamsBus',...
    taskParamsStruct);


% load the generic taskBlock, replace its taskInterface subsystem with the specific task
open_system('taskBlock');
set_param('taskBlock/specificTask', 'ModelName', modelName);
specificTaskBlockSLXName = sprintf('taskBlock_%s_bld',...
    modelName);

% close the (temporary, overwritten) model if it's open
if bdIsLoaded(specificTaskBlockSLXName)
    close_system(specificTaskBlockSLXName);
end


save_system('taskBlock', sprintf('%s%s%s.slx', ...
    modelConstants.sessionRoot, modelConstants.bldDir, specificTaskBlockSLXName));

% 'framework' is the top level model
% open it up, switch out the reference to the specific task block that was just
% saved
% save that as a new file for compilation
open_system('framework');
% TODO - improve the participant-specific customization of signal
% processing
adaptFrameworkToRig(); 
set_param('framework/Task', 'ModelName', specificTaskBlockSLXName);
% set_param('framework','TLCOptions','-axPCMaxOverloads=10000 -axPCOverLoadLen=5 -axPCStartupFlag=200')
% modelConstants.rig is the participant name (e.g., T6)
specificFullModelSLXName = sprintf('%s_Complete_%s_bld',...
    modelName, modelConstants.rig);

% close the (temporary, overwritten) model if it's open
if bdIsLoaded(specificFullModelSLXName)
    close_system(specificFullModelSLXName);
end

save_system('framework',sprintf('%s%s%s',...
    modelConstants.sessionRoot, modelConstants.bldDir, specificFullModelSLXName));

% sometimes you have to build 'decoder' first. magic.
rtwbuild('decoder');
rtwbuild(specificFullModelSLXName);

% open_system('allTasks');
% replace_block('taskBlock','Name','taskInterface','allTasks/cursorTaskSplit','noprompt');
% %% save the generic task (with replaced task block) to a task-specific file
% save_system('taskBlock',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/cursorTask/cursorTaskSplit.slx']);
% close_system('allTasks');
% 
% runCursorSplitBuildScripts
% 
% modelName = ['cursorTaskSplit'];
% modelCompleteName = ['cursorTaskSplitComplete_' modelConstants.rig];
% 
% %% take the task file generated above, and put it into the model framework.
% open_system('framework')
% %% set filtering appropriately for this rig
% adaptFrameworkToRig(); 
% set_param('framework/Task', 'ModelName', modelName);
% close_system(modelName)
% cursorTaskSplit_updateParameters;
% 
% if bdIsLoaded(modelCompleteName)
%     close_system(modelCompleteName)
% end
% %% save the framework into a task-specific file, compile that thing.
% save_system('framework',[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/tasks/modelFiles/cursorTask/' modelCompleteName '.slx']);
% rtwbuild(modelName)
% rtwbuild(modelCompleteName);