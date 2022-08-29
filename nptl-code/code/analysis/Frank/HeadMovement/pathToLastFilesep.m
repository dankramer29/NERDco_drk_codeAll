% pathToLastFilesep.m
% 
% Takes in a path/file and returns the same path up to the last filesep.
% So if you give it a file's location, it'll given you the directory of this file
% if optinal last argument is true, then returns instead what comes AFTER the last filesep

function newPath = pathToLastFilesep( oldPath, inverse )
    if nargin < 2
        inverse = false;
    end
    filesepIdx = find( oldPath == filesep );
    if inverse
        newPath = oldPath(filesepIdx(end)+1:end);
    else
        newPath = oldPath( 1:filesepIdx(end) );
    end
end
