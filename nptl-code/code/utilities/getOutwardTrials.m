function trialInds=getOutwardTrials(R)
% GETOUTWARDTRIALS    
% 
% trialInds=getOutwardTrials(R)

targets = [R.posTarget];
if size(targets,2) ~= length(R)
    error('posTarget does not match length(R)');
end
trialInds = find(sum(abs(targets)));


