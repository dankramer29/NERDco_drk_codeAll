function runCommandOnViz(commandToRun)

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end


RELATIVE_PATH = '\Session\Software\nptlBrainGateRig';
CYG_SESSION_PATH = ['/cygdrive/e' RELATIVE_PATH];

sshPrgPath = 'C:\cygwin\bin\ssh.exe';

lip = modelConstants.peripheral.ip;
sshPrgOptions = sprintf('-i %s/%s/id_rsa nptl@%g.%g.%g.%g -f ',CYG_SESSION_PATH,modelConstants.sshKeysDir,lip(1),lip(2),lip(3),lip(4));
commandTxt = sprintf('%s %s "export DISPLAY=:0;%s"',sshPrgPath, sshPrgOptions, commandToRun);

disp(commandTxt);
system(commandTxt);


end