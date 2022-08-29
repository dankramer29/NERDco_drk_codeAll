function retVal = freeDiskSpaceCheck(drive, minFree)
%
% retVal = freeDiskSpaceCheck(drive, minFree)
%
%       drive - string path to drive/folder
%       minFree - value in GB required to be free
% 
% checks for free disk space on path/drive specified
% prints a bunch of debugging information to stdOut
% retVal is 1 if minFree not met, 0 otherwise


retVal = 0;
if strcmp(computer, 'PCWIN64')
    fprintf(1, 'Checking free disk space....');
    fprintf(1, 'need at least %i GB free.\n', minFree);
    freeSpace = disk_free(drive);
    freeSpaceGB = freeSpace / (1024*1024*1024);
    fprintf(1, 'Have %i GB free...', floor(freeSpaceGB));
   
    if freeSpaceGB < minFree
        cprintf('*r', '\nERROR: Hard drive full! Not enough free disk space.\n');
        retVal = 1;
    else
        fprintf(1, 'Yay, that''s plenty!\n');
    end
        
else
    fprintf(1, 'Warning: System is unix, skipping free disk space check\n');
end