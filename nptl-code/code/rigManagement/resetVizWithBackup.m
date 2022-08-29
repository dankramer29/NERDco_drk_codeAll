global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end


RELATIVE_PATH = '\Session\Software\nptlBrainGateRig';
CYG_SESSION_PATH = ['/cygdrive/e' RELATIVE_PATH];


copyPrgPath = 'C:\cygwin\bin\rsync.exe';
rsaKeyPath = [CYG_SESSION_PATH '/code/rigManagement/sshkeys/id_rsa'];
% copyPrgOptions = ['-avz --delete -e "ssh -i ' rsaKeyPath '"'];
copyPrgOptions = ['-avz --chmod=ugo=rwX -e "C:\cygwin\bin\ssh.exe -i ' rsaKeyPath '"'];

srcPath = [CYG_SESSION_PATH '/code/visualizationCode/initializeScreenNoSyncTests.m'];
tmp=modelConstants.screen.ip;
destPath = sprintf('nptl@%g.%g.%g.%g:code/visualizationCode/initializeScreen.m',tmp);clear tmp;
commandTxt = sprintf('%s %s %s %s', copyPrgPath, copyPrgOptions, srcPath, destPath);

disp(commandTxt);
system(commandTxt);

resetVizAndSound