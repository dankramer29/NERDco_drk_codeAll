%% setVizExecutePermissions.m

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end


RELATIVE_PATH = '\Session\Software\nptlBrainGateRig';
CYG_SESSION_PATH = ['/cygdrive/e' RELATIVE_PATH];

sshPrgPath = 'C:\cygwin\bin\ssh.exe';

lip = modelConstants.peripheral.ip;
sshPrgOptions = sprintf('-i %s/%s/id_rsa nptl@%g.%g.%g.%g',CYG_SESSION_PATH,modelConstants.sshKeysDir,lip(1),lip(2),lip(3),lip(4));
commandTxt = sprintf('%s %s chmod a+x /home/nptl/%s/*.out',sshPrgPath, sshPrgOptions, modelConstants.peripheralsDir);

disp(commandTxt);
system(commandTxt);

%% repeat the same thing for python scripts
commandTxt = sprintf('%s %s chmod a+x /home/nptl/%s/*.py',sshPrgPath, sshPrgOptions, modelConstants.peripheralsDir);

disp(commandTxt);
system(commandTxt);


%% do this again for the hidclient scripts
commandTxt = sprintf('%s %s chmod a+x /home/nptl/%s/*',sshPrgPath, sshPrgOptions, modelConstants.hidClientDir);

disp(commandTxt);
system(commandTxt);