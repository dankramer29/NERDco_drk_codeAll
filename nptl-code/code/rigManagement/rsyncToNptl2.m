function rsyncToNptl2

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

RELATIVE_PATH = '/Session/';
CYG_SESSION_PATH = ['/cygdrive/e' RELATIVE_PATH];

currDate = datestr(now,'yyyy.mm.dd');
sessDate = [modelConstants.rig '.' currDate];


sshTarget = 'nptl_upload@nptl2.stanford.edu';
destPath1 = ['upload/' sessDate '/Data/'];
rsaKeyPath1 = [CYG_SESSION_PATH modelConstants.projectDir '/' modelConstants.sshKeysDir '/nptl_upload_id_rsa'];
sshPrgPath = 'C:\cygwin\bin\ssh.exe';
commandTxt = sprintf('%s -p 42314 -i %s %s mkdir -p %s', sshPrgPath, rsaKeyPath1, sshTarget, destPath1);

disp('creating target');
disp(commandTxt);
system(['start /min ' commandTxt '; exit']);

% %% do the transfer with no neural data
% srcPath = [CYG_SESSION_PATH 'Data/Filters ' CYG_SESSION_PATH 'Data/FileLogger'];
% destPath = ['nptl_upload@nptl2.stanford.edu:/jail/upload/' sessDate '/Data/'];
% copyPrgPath = 'C:\cygwin\bin\rsync.exe';
% rsaKeyPath = [CYG_SESSION_PATH modelConstants.projectDir '/' modelConstants.sshKeysDir '/nptl_upload_id_rsa'];
% copyPrgOptions = ['-avz --chmod=ugo=rwX -e "C:\cygwin\bin\ssh.exe -i ' rsaKeyPath '"' ...
%     ' --exclude="*neural*.dat"'];
% commandTxt1 = sprintf('%s %s %s %s ', copyPrgPath, copyPrgOptions, srcPath, destPath);
% 
% 
% %% do the transfer with neural data
% srcPath = [CYG_SESSION_PATH 'Data/'];
% destPath = ['nptl_upload@nptl2.stanford.edu:/jail/upload/' sessDate '/Data/'];
% copyPrgPath = 'C:\cygwin\bin\rsync.exe';
% rsaKeyPath = [CYG_SESSION_PATH modelConstants.projectDir '/' modelConstants.sshKeysDir '/nptl_upload_id_rsa'];
% copyPrgOptions = ['-avz --chmod=ugo=rwX -e "C:\cygwin\bin\ssh.exe -i ' rsaKeyPath '"' ...
%     ' --exclude="*neural*.dat"'];
% commandTxt2 = sprintf('%s %s %s %s', copyPrgPath, copyPrgOptions, srcPath, destPath);

disp('starting a background rsync to nptl2');
%disp(commandTxt1);
system(['start /min ' 'E:\Session\Software\nptlBrainGateRig\code\rigManagement\rsyncBatchToNptl2.bat ' sessDate '&; exit']);


