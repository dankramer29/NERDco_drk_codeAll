function s = sem(y)
%% calculates the standard error of the mean for vector input
if ~isvector(y)
    error('sem: only works for vector inputs');
end

s = std(y(:)) / sqrt(numel(y));