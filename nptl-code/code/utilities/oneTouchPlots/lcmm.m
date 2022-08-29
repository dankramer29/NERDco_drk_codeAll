function least = lcmm(varargin);

%LCMM finds the least common multiples for many numbers.
%   LEAST = LCMM(A,B,...) finds the least common multiple for the inputs,
%   of which there can be arbitrarily many.  It is a wrapper around the
%   MATLAB function LCM (which is shocking they don't have this
%   capability...)
%
%   Copyright (c) by Jonathan C. Kao

    %%% Input checking
    assert(length(varargin) > 0, 'You have not provided enough inputs');
    
    %%% Actual multiple LCM calculation.
    elems = [varargin{:}];
    least = 1;
    
    for i = 1:length(elems)
        least = lcm(elems(i), least);
    end
    
end