RELATIVE_PATH = '\npbr';
CYG_SESSION_PATH = ['/cygdrive/e' RELATIVE_PATH];

copyPrgPath = 'C:\cygwin\bin\rsync.exe';
rsaKeyPath = [CYG_SESSION_PATH '/code/rigManagement/sshkeys/id_rsa'];
% copyPrgOptions = ['-avz --delete -e "ssh -i ' rsaKeyPath '"'];
copyPrgOptions = ['-avz --chmod=ugo=rwX -e "C:\cygwin\bin\ssh.exe -i ' rsaKeyPath '"'];

srcPath = [CYG_SESSION_PATH '/code'];
destPath = 'nptl@192.168.30.2:';
commandTxt = sprintf('%s %s %s %s', copyPrgPath, copyPrgOptions, srcPath, destPath);

disp(commandTxt);
system(commandTxt);
