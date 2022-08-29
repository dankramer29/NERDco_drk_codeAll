function startExpt

%% delayed parameter updates - commented out by CP, 2014-10-15
% global remoteParamTimerObj
% remoteParamTimerObj = timer('BusyMode','drop','ExecutionMode','fixedRate','Period',1,'TasksToExecute',inf,...
%     'TimerFcn',@checkForNewModelParams);

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

%% kill ANY rsync or                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       cmd.exe processes that may be running
%[s1 s2] = system('taskkill /f /im rsyncBatchToNptl2.bat ');
[s1 s2] = system('taskkill /f /im rsync.exe');
pause(0.1);                                                                                                                                                                                                                             
[s1 s2] = system('taskkill /f /im rsync.exe');
pause(0.1);
[s1 s2] = system('taskkill /f /im rsync.exe');
[s1 s2] = system('taskkill /f /im cmd.exe');

%% initialize the runtime logger
try
    initializeRuntimeLogger()
    modelConstants.runtimeLoggerActive = true;
catch
    warning('startExpt: couldn''t initialize the runtime logger');
    modelConstants.runtimeLoggerActive = false;
end

if strcmp(modelConstants.rig,'t7')
    runLocalViz;
end

% reply = input('Do you want to adapt a filter first? (y/n) [n]:', 's');
% if ~isempty(reply) && strcmpi(reply,'y')
%     adaptBaselinesDialog
% end

targetName = 'Q77-production';

global tg;
tg = xpc(targetName);
if ~strcmp(tg.Connected, 'Yes')
    tg
%     xpctargetping(targetName);
    disp('Connecting to xPC machine...');
    tg = xpc(targetName);
end

runMe = 1;

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

clear modelName paramDir;
reply = input('Which model? (2) movementCue, (4) fitts, (5) cursor, (6) linux, (7) keyboard, (8) robot, (9) sequence, (10) symbol (11) decision (12) yang (13) rsg:', 's');

reply2 = str2double(reply);
isRigSpecific = true;
switch reply2
    case 1
        modelName = 'dualArrayTestComplete_noTrigger';
        %modelName = 'dualArrayTestComplete';
        isRigSpecific = false;
    case 2
        modelName = 'movementCueTask_Complete_%s_bld';
        paramDir = 'movementParamScripts';
    case 4
        modelName = 'fittsTask_Complete_%s_bld';
        paramDir = 'fittsParamScripts';
    case 5
        modelName = 'cursorTask_Complete_%s_bld';
        paramDir = 'cursorParamScripts';
    case 6
        modelName = 'linuxTask_Complete_%s_bld';
        paramDir = 'linuxParamScripts';
    case 7
        modelName = 'keyboardTask_Complete_%s_bld';
        paramDir = 'keyboardParamScripts';
    case 8
        modelName = 'robotTask_Complete_%s_bld';
        paramDir = 'robotParamScripts';
    case 9
        modelName = 'sequenceTask_Complete_%s_bld';
        paramDir = 'sequenceParamScripts';
    case 10
        modelName = 'symbolTask_Complete_%s_bld';
        paramDir = 'symbolParamScripts';
    case 11
        modelName = 'decisionTask_Complete_%s_bld';
        paramDir = 'decisionParamScripts';
    case 12
        modelName = 'yangTask_Complete_%s_bld';
        paramDir = 'yangParamScripts';
    case 13
        modelName = 'rsgTask_Complete_%s_bld';
        paramDir = 'rsgParamScripts';
    otherwise
        error('incorrect choice %s', reply);
end
clear reply reply2


if isRigSpecific
    %% adjust model for this specific rig
    modelName = sprintf(modelName, modelConstants.rig);
end
    
global CURRENT_BLOCK_NUMBER
if isempty(CURRENT_BLOCK_NUMBER)
    CURRENT_BLOCK_NUMBER = 0;
else
    CURRENT_BLOCK_NUMBER = CURRENT_BLOCK_NUMBER + 1;
end

%% prompt for block number
reply = input(sprintf('Block number? [%d]: ', CURRENT_BLOCK_NUMBER), 's');
if ~isempty(reply)
    CURRENT_BLOCK_NUMBER = str2double(reply);
    if isempty(CURRENT_BLOCK_NUMBER)
        estr = 'Couldnt understand that number';
        warndlg(estr);
        error(estr);
    end
end

% do we want to us central and log ns5s ?
do_nsp_filerecord = true; %% TEMP HACK TO AVOID NSP FILERECORD 
if modelConstants.isSim % don't try filerecorder for simulator
    do_nsp_filerecord = false;
end


%% see if NSP data already exists with this name
% note that names need to be set differently for single array (t6) vs
% others
switch modelConstants.rig
    case 't6'
        outdir{1} = [modelConstants.sessionRoot modelConstants.dataDir modelConstants.nevDir];
        fileout{1} = [outdir{1} num2str(CURRENT_BLOCK_NUMBER) '_' modelName '(' sprintf('%03g',CURRENT_BLOCK_NUMBER) ')'];
    case {'t5','t7','t8','t9'}
        outdir{1} = [modelConstants.sessionRoot modelConstants.dataDir modelConstants.arrayNevDirs{1} modelConstants.nevDir];
        outdir{2} = [modelConstants.sessionRoot modelConstants.dataDir modelConstants.arrayNevDirs{2} modelConstants.nevDir];
        fileout{1} = [outdir{1} num2str(CURRENT_BLOCK_NUMBER) '_' modelName '(' sprintf('%03g',CURRENT_BLOCK_NUMBER) ')'];
        fileout{2} = [outdir{2} num2str(CURRENT_BLOCK_NUMBER) '_' modelName '(' sprintf('%03g',CURRENT_BLOCK_NUMBER) ')'];
end

if do_nsp_filerecord
    for nfout = 1:numel(fileout)
        if ~isdir(outdir{nfout}), mkdir(outdir{nfout}); end

        existing = dir([fileout{nfout} '*']);
        if numel(existing)
            estr = 'NSP data with this name already exists - please choose a different block number';
            warndlg(estr);
            error(estr);
        end
    end
end

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

%% delayed parameter updates - commented out by CP, 2014-10-15
% %%% grab all model parameters
% global xPCParams;
% xPCParams = pullAllXPCParams(tg);
% saveCurParams();
% start(remoteParamTimerObj);

fcomment = sprintf('file recording started at %s', datestr(now));
%%% pull up NSP
switch modelConstants.cerebus.cbmexVer
    case '601'
        cbmexfun = @cbmex_601;
    case '603'
        cbmexfun = @cbmex_603;
    case '605'
        cbmexfun = @cbmex_605;
    case '60502'
        cbmexfun = @cbmex_605; % UBER HACK FOR REASONS WE DON'T understand
end

if do_nsp_filerecord
    if modelConstants.isSim
         try % need a try/catch or else it won't work on rigH which has no NSPs
            % black, nsp 1
            cbmexfun('open',0,'central-addr','192.168.137.1','instance',1);
            pause(1);
            cbmexfun('fileconfig','','',0,'instance',1);
            fprintf('Attempting NSP 1 recording to file: %s\n', fileout{1});
            pause(1);
            cbmexfun('fileconfig',fileout{1},fcomment,1,'instance',1);
            pause(2);
            % white, nsp 2
            cbmexfun('open',0,'central-addr','192.168.137.17','instance',2);
            pause(1);
            cbmexfun('fileconfig','','',0,'instance',2);
            fprintf('Attempting NSP 2 recording to file: %s\n', fileout{2});
            pause(1);
            cbmexfun('fileconfig',fileout{2},fcomment,1,'instance',2);
            pause(2);
        catch
            
        end
    else
        switch modelConstants.rig
            case 't6'
                %% start first array recording
                cbmexfun('open')
                clear pause
                pause(1);
                cbmexfun('fileconfig','','',0);
                fprintf('Attempting NSP recording to file: %s\n', fileout{1});
                pause(1);
                cbmexfun('fileconfig',fileout{1},fcomment,1);
                pause(2);
            case 't9'
                %% start first array recording
                cbmexfun('open')
                clear pause
                pause(1);
                cbmexfun('fileconfig','','',0);
                fprintf('Attempting NSP recording to file: %s\n', fileout{1});
                pause(1);
                cbmexfun('fileconfig',fileout{1},fcomment,1);
                pause(2);
                %% start second array recording
                cbmexfun('open',0,'central-addr','192.168.137.17','instance',1);
                pause(1);
                cbmexfun('fileconfig','','',0,'instance',1);
                fprintf('Attempting NSP recording to file: %s\n', fileout{2});
                pause(1);
                cbmexfun('fileconfig',fileout{2},fcomment,1,'instance',1);
                pause(2);
            case 't5'
                cbmexfun('open',0,'central-addr','192.168.137.1','instance',1);
                pause(1);
                cbmexfun('fileconfig','','',0,'instance',1);
                fprintf('Attempting NSP 1 recording to file: %s\n', fileout{1});
                pause(1);
                cbmexfun('fileconfig',fileout{1},fcomment,1,'instance',1);
                pause(2);
                % white, nsp 2
                cbmexfun('open',0,'central-addr','192.168.137.17','instance',2);
                pause(1);
                cbmexfun('fileconfig','','',0,'instance',2);
                fprintf('Attempting NSP 2 recording to file: %s\n', fileout{2});
                pause(1);
                cbmexfun('fileconfig',fileout{2},fcomment,1,'instance',2);
                pause(2);     
        end
    end
end

%% start the filelogger
udpFileWriter('Start', dirname);
pause(2); % make sure file logger is up and running!

%% set the block number parameter (to be output to cerebus)
setModelParam('blockNumber', CURRENT_BLOCK_NUMBER, tg);

+tg;
cd(currentDir);

%% if this model has an associated parameter script directory, prompt the user to pick one of those
%%   -CP, 20130901
if exist('paramDir','var')
    pBaseDir = [modelConstants.projectRoot '\' modelConstants.paramScriptsDir paramDir];
    pBaseDir = [pBaseDir '\' modelConstants.rig];

    paramFiles = dir([pBaseDir '\*.m']);
    [selection, ok] = listdlg('PromptString', 'Select a parameter file:', 'ListString', {paramFiles.name}, ...
        'SelectionMode', 'Single','ListSize', [400 300]);
    
    if (ok)
        selectedFileName= paramFiles(selection).name(1:end-2);
        fprintf('\n\nrunning parameter script %s\n\n', selectedFileName);
        run([pBaseDir '\' selectedFileName]);
    end
end

if modelConstants.runtimeLoggerActive
    %% log that the current block has started
    block.blockNum = CURRENT_BLOCK_NUMBER;
    block.systemStartTime = now();
    if exist('selectedFileName','var')
        block.parameterScript = selectedFileName;
    end
    addBlockToLog(block);
end


fprintf('--------- Block %i ----------\n', CURRENT_BLOCK_NUMBER )
fprintf('Block started at %s. Be sure to "stopExpt" before starting the next block\n', datestr(now,13));
