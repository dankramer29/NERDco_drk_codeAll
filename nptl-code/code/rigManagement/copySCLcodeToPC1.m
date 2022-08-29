% Copies SCL code back from Robox to PC1, so we have it saved down after
% each session.
%
% Sergey Stavisky Jan 30 2017


global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

RELATIVE_PATH = '/Session/Software/nptlBrainGateRig';
CYG_SESSION_PATH = ['/cygdrive/e' RELATIVE_PATH];
copyPrgPath = 'C:\cygwin\bin\rsync.exe';
rsaKeyPath = [CYG_SESSION_PATH '/code/rigManagement/sshkeys/id_rsa'];
% copyPrgOptions = ['-avz --delete -e "ssh -i ' rsaKeyPath '"'];
copyPrgOptions = ['-avz --chmod=ugo=rwX -e "C:\cygwin\bin\ssh.exe -i ' rsaKeyPath '"'];

destPath = ['/cygdrive/e' '/Session/Software/scl-bmi/'];
sourcePath = sprintf('nptl@%g.%g.%g.%g:scl-bmi/',modelConstants.screen.ip);
commandTxt = sprintf('%s %s %s %s', copyPrgPath, copyPrgOptions, sourcePath, destPath);
disp(commandTxt);
system(commandTxt);