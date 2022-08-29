function [b, longest]=findcont(V)
% FINDCONT    
% 
% findcont(V)
%
% take a logical vector V and find the continuous regions
    
    D = diff(V);
    b.beg=[];
    if V(1)
        b.beg =1;
    end
    b.beg = [b.beg(:) 1+find(D==1)];
    b.end = find(D==-1);
    if V(end)
        b.end(end+1) = numel(V);
    end
    
    assert(length(b.beg) == length(b.end), 'contiguous regions dont match up?');
    
    b.length = 1 + b.end - b.beg;
    
    [longestLength, longestInd] = max(b.length);
    longest.beg = b.beg(longestInd);
    longest.end = b.end(longestInd);
    longest.length = longestLength;
    