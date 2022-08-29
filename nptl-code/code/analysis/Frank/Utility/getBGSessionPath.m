function [ path ] = getBGSessionPath( sessionName )
    [~, compName] = system('hostname');
    compName = compName(1:(end-1));
    if strcmp(compName, 'Franks-MacBook-Pro.local')
        path = ['/Users/frankwillett/Data/BG Datasets/' sessionName];
    elseif strcmp(compName, 'nptl-cpu')
        path = ['/net/experiments/' sessionName(1:2) '/' sessionName];
    end
end

