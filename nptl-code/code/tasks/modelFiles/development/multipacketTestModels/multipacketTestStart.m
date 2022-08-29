function multipacketTestStart(modelNum)

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end



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

switch modelNum
    case 0
        modelName = 'multipacketTest';
    case 1
        modelName = 'multipacketControl';
end
disp(['Using ' modelName ' model']);

global CURRENT_BLOCK_NUMBER

if ~exist('CURRENT_BLOCK_NUMBER', 'var') || isempty(CURRENT_BLOCK_NUMBER)
    CURRENT_BLOCK_NUMBER = 0;
else
    CURRENT_BLOCK_NUMBER = CURRENT_BLOCK_NUMBER + 1;
end

reply = input(sprintf('Block number? [%d]: ', CURRENT_BLOCK_NUMBER), 's');
if ~isempty(reply)
    CURRENT_BLOCK_NUMBER = str2num(reply);
    if ~~isempty(CURRENT_BLOCK_NUMBER)
        estr = 'Couldnt understand that number';
        warndlg(estr);
        error(estr);
    end
end

dirname = [modelConstants.sessionRoot modelConstants.filelogging.outputDirectory num2str(CURRENT_BLOCK_NUMBER)];
disp('Starting experiment in directory: ')
disp(['   ' dirname]);
if(dirname ~= 0)  % Check if directory selected
    if ~isdir(dirname)
        dirMade = mkdir(dirname);
        if ~dirMade
            estr = ['Couldnt create directory ' dirname];
            warndlg(estr);
            error(estr);
        end
    end
    if(exist([dirname '\fnum.txt'], 'file')) % check for existing files
        estr = 'Filelogger data exists in this directory!! Aborting!';
        warndlg(estr);
        error(estr);
    end
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
    estr = 'Couldnt load model onto xPC';
    warndlg(estr);
    cd(currentDir);
    error(estr);
end

fcomment = sprintf('file recording started at %s', datestr(now));


%% start the filelogger
udpFileWriter('Start', dirname);
pause(1); % make sure file logger is up and running!


+tg;
cd(currentDir);

disp('Block started. Be sure to "stopExpt" before starting the next block');
