for nblock = 1:200


% check connection to xPC

targetName = 'Q77-production';

global tg;
tg = xpc(targetName);
if ~strcmp(tg.Connected, 'Yes')
    tg
%     xpctargetping(targetName);
    disp('Connecting to xPC machine...');
    tg = xpc(targetName);
end


%% if there was some connection error, xpctargetping seems to reset the connection well, so, try it.
try
    if ~strcmp(tg.Connected, 'Yes')
        pause(1)
        xpctargetping(targetName)
    end
catch
    disp('warning: problem with xpctargetping')
end

try
    if ~strcmp(tg.Connected, 'Yes')
        estr = ['Couldn''t connect to xPC target machine: ' targetName];
        warndlg(estr);
        error(estr);
    elseif ~strcmp(tg.status, 'stopped') % Check if a model is running
        estr = 'The xPC box is running! Stop the task first!!';
        warndlg(estr);
        error(estr);
    end
catch
    e= lasterror;
    if ~strcmp(e.identifier,'xpctarget:clrapi:eloadappfirst')
        disp(e.identifier);
        error(e);
    end
end



%% load the model onto xpc

modelName = 'keyboardTask_Complete_%s_bld';
% adjust model for this specific rig
modelName = sprintf(modelName, modelConstants.rig);

currentDir = pwd();
cd([modelConstants.projectRoot '\' modelConstants.binDir]);
try
    xpcLoaded = load(tg, modelName);
catch
    e = lasterror;
    cd(currentDir);
    error(e);
end
    
if ~strcmp(xpcLoaded.Connected, 'Yes')
    estr = 'startExpt: Couldn''t load model onto xPC';
    warndlg(estr);
    cd(currentDir);
    error(estr);
end


global CURRENT_BLOCK_NUMBER
if isempty(CURRENT_BLOCK_NUMBER)
    CURRENT_BLOCK_NUMBER = 0;
else
    CURRENT_BLOCK_NUMBER = CURRENT_BLOCK_NUMBER + 1;
end

% set the block number parameter (to be output to cerebus)
setModelParam('blockNumber', CURRENT_BLOCK_NUMBER, tg);


%% create a new filelogger directory
dirname = [modelConstants.sessionRoot modelConstants.filelogging.outputDirectory num2str(CURRENT_BLOCK_NUMBER)];
fprintf('Starting experiment in directory: %s\n', dirname);
if ~isdir(dirname)
    dirMade = mkdir(dirname);
    if ~dirMade
        estr = ['startExpt: Couldnt create directory ' dirname];
        warndlg(estr);
        error(estr);
    end
end
if(exist([dirname '\fnum.txt'], 'file')) % check for existing files
    estr = 'startExpt: Filelogger data exists in this directory. Aborting!';
    warndlg(estr);
    error(estr);
end



%% start the filelogger
udpFileWriter('Start', dirname);
pause(2); % make sure file logger is up and running!


+tg;
cd(currentDir);

paramDir = 'keyboardParamScripts';
pBaseDir = [modelConstants.projectRoot '\' modelConstants.paramScriptsDir paramDir];
pBaseDir = [pBaseDir '\' modelConstants.rig];
selectedFileName = 'psychophysics_auto.m';
run(fullfile(pBaseDir, selectedFileName));


pause(20);


udpFileWriter('Stop');
if isempty(tg)
    error('dont know what machine is the target');
end
-tg;

% reboot xpc because of xpc model loading / starting / resetting
% weirdness,  2016-08-24
pause(2);
tg.reboot;


pause(20);
end