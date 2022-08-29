function setup_rig(doDiskCheck)
% Set up the environment for the rig. 

[projectRoot, ~, ~] = fileparts( mfilename('fullpath'));
%make sure submodules is shadowed (i.e., takes secondary precedence to other definitions of the same files)
%addpath(genpath(fullfile(projectRoot, 'code/submodules'))); %SNF and FRW deleted submodules 2/14/19
addpath(genpath(fullfile(projectRoot, 'code/nptlDataExtraction'))); %SNF and FRW pulled this directory out of submodules 2/14/19
addpath(genpath(fullfile(projectRoot, 'bld')));

addpath(genpath_exclude(fullfile(projectRoot, 'code'), {'audacity files', 'Frank', 'Sergey'}));
 %SNF added 5/2019, no one's analysis code needs to be on rigH's path:
%addpath(genpath_exclude(fullfile(projectRoot, 'code'), {'analysis'}));
% SDS Feb 2017: add my  kinematics analysis functions, which I'll lean on for some
% in-session analysis.
addpath(genpath(fullfile(projectRoot, 'code','analysis','Sergey','generic','kinematics')));

% manually remove some old code -- really we should probably jsut delete
% these
rmpath('E:\Session\Software\nptlBrainGateRig\code\tasks\paramScripts\keyboardParamScripts\old');

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
    % Set the path for this project:
    modelConstants.projectRoot = projectRoot;
end

compileCacheFolder = fullfile(projectRoot, modelConstants.binDir);
Simulink.fileGenControl('set', 'CacheFolder', compileCacheFolder, ...
   'CodeGenFolder', compileCacheFolder);

clear projectRoot filename ext compileCacheFolder;


if ~exist('doDiskCheck','var'), doDiskCheck = true; end
if doDiskCheck && freeDiskSpaceCheck(modelConstants.projectRoot, 20) % check project drive for 50GB
    cprintf('r', 'Close matlab, free up disk space, and open matlab again.\n');
    return;
end

evalin('base','global modelConstants;');

setRig();

% set random seed
rng('shuffle');

% only copyCodeToViz on windows systems
if ~isunix
    reply = input('Should I copyCodeToViz (PC2.5 must be ready)? (y/n) [y]: ', 's');

    %% execute CCTV if reply is blank (default) or 'y'
    if isempty(reply) || lower(reply) == 'y'
        disp('running copyCodeToViz');
        copyCodeToViz;
        copySCLcodeToPC1 % new as of Jan 2017
        resetVizAndSound;
    else
        disp('   skipping - please execute manually if needed');
    end
end