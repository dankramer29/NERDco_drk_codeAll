% Wipes out everything except .dlm in the hard-coded directory below.
% This is useful for doing a clean compile, because MATLAB sucks at make 
% and doesn't actually recompile cleanly, which leads to issues.
%
% Sergey Stavisky August 9 2016


wipeDir = 'E:\Session\Software\nptlBrainGateRig\bin\';


originDir = pwd; % return here later
cd( wipeDir );
files = dir;

deleteMeFiles = {}; % list of stuff to delete
deleteMeDirs = {};
for i = 3 : numel( files ) % first two are . and ..
   if isempty( strfind( files(i).name, '.dlm' ) )
       if files(i).isdir
           deleteMeDirs{end+1} = files(i).name;
           fprintf('Will delete dir %s\n', files(i).name)
       else
           deleteMeFiles{end+1} = files(i).name;
           fprintf('Will delete file %s\n', files(i).name)
       end
   end
end

% Delete the files using built-in commands
for i = 1 : numel( deleteMeFiles )
    delete( deleteMeFiles{i} );
end
for i = 1 : numel( deleteMeDirs )
    [status, message, messageid] = rmdir( deleteMeDirs{i}, 's' );
end