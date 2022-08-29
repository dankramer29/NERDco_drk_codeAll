function resetVizAndSound()

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

% 
% RELATIVE_PATH = '\Session\Software\nptlBrainGateRig';
% CYG_SESSION_PATH = ['/cygdrive/e' RELATIVE_PATH];
% % 
% 
% copyPrgPath = 'C:\cygwin\bin\ssh.exe';
% rsaKeyPath = [CYG_SESSION_PATH '/code/rigManagement/sshkeys/id_rsa'];
% % copyPrgOptions = ['-avz --delete -e "ssh -i ' rsaKeyPath '"'];
% tmp=modelConstants.screen.ip;
% hostName = sprintf(' nptl@%g.%g.%g.%g',tmp);clear tmp;
% copyPrgOptions = [' -i ' rsaKeyPath hostName ' /home/nptl/resetVizAndSound'];
% 
% commandTxt = sprintf('%s %s', copyPrgPath, copyPrgOptions);
% 
% disp(commandTxt);
% system(commandTxt);
% 

disp('-- Resetting Viz and Sound --');

RELATIVE_PATH = '/Session/Software/nptlBrainGateRig';
CYG_SESSION_PATH = ['/cygdrive/e' RELATIVE_PATH];

sshPrgPath = 'C:\cygwin\bin\ssh.exe';

lip = modelConstants.peripheral.ip;
sshPrgOptions = sprintf('-i %s/%s/id_rsa nptl@%g.%g.%g.%g -f ',CYG_SESSION_PATH,modelConstants.sshKeysDir,lip(1),lip(2),lip(3),lip(4));
commandTxt = sprintf('%s %s "sh /home/nptl/code/visualizationCode/resetVizAndSound.sh"',sshPrgPath, sshPrgOptions);

disp(commandTxt);
system(commandTxt);


end