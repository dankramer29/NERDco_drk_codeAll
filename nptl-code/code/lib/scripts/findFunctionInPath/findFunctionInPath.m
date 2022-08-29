function [names, folders]=findFunctionInPath(pattern, caseSensitive)
% FINDFUNCTIONINPATH    
% 
% [names, folders]=findFunctionInPath(pattern, caseSensitive)
%
% find all functions in the current matlab path that match (via regexp) a certain pattern
%   caseSensitive is boolean (true/false) and determines whether to use a case sensitive search
%
% returns both the function names, and the folders that contain those functions, as cell arrays
% 
%
%
% AUTHOR    : Chethan Pandarinath 

%

if ~exist('caseSensitive','var')
    caseSensitive = false;
end

% split path into folder names
%   ( taken from Jan Simon's post here: http://www.mathworks.com/matlabcentral/newsreader/view_thread/277697 )
C = dataread('string', path, '%s', 'delimiter', pathsep);

names = cell(0,0);
folders = cell(0,0);
numFound = 0;

% iterate over each of these folders, 
% look for .m files in those directories
for nd = 1:numel(C)
    f = what(C{nd});
    
    % sometimes what returns multiple sets of responses... (don't understand why, or care)
    for nf = 1:numel(f)
        % iterate over all .m files
        for nm = 1:numel(f(nf).m)
            if caseSensitive
                tf = regexp(f(nf).m{nm},pattern);
            else
                tf = regexpi(f(nf).m{nm},pattern);
            end
            % add this to the list of found functions
            if any(tf)
                numFound = numFound+1;
                names{numFound} = f(nf).m{nm};
                folders{numFound} = C{nd};
            end
        end
    end
end


