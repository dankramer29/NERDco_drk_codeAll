function [whichTarget targets] = getTargetInds(R)
% SPLITRBYTARGET    
% 
% Rout = splitRByTarget(R)

    %% get targets
    targets = double([R.posTarget]);
    targetsi = targets(1,:)+sqrt(-1)*targets(2,:);
    centerOut = abs(targetsi)>0;

    if length(targets) ~= length(R)
        error('error with targets/Rs');
    end
    [whichT,Tinds,Rinds]=unique(targetsi);

    whichTarget = Rinds;
    targets = whichT;