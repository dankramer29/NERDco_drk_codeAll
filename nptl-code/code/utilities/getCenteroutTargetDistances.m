function [d, numTargets, targets]=getTargetDistances(R)
% GETTARGETDISTANCES    
% 
% d=getTargetDistances(R)

if isfield(R,'posTarget')
    pos = [R.posTarget]';
else
    pos = getTargetPositions(R)';
end
targets = double(unique(pos,'rows'));

di = sqrt(sum(targets'.^2));
di = di(di>0);

assert(all(abs(di-di(1))<0.02*di(1)), 'variable target distances??');

d = di(1);
numTargets = length(di);