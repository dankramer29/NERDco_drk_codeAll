function [ out ] = getFRWPaths( )
    [~, compName] = system('hostname');
    compName = compName(1:(end-1));
    if strcmp(compName, 'Franks-MacBook-Pro.local')
        out.codePath = '/Users/frankwillett/nptlBrainGateRig';
        out.dataPath = '/Users/frankwillett/Data';
        out.ajiboyeCodePath = '/Users/frankwillett/Documents/AjiboyeLab/';
        out.bgPath = '';
    elseif strcmp(compName, 'nptl-cpu')
        out.codePath = '/net/home/fwillett/nptlBrainGateRig';
        out.dataPath = '/net/home/fwillett/Data';        
        out.ajiboyeCodePath = '';
        out.bgPath = '/net/experiments/';
    else
        out.codePath = '/Users/frankwillett/nptlBrainGateRig';
        out.dataPath = '/Users/frankwillett/Data';
        out.ajiboyeCodePath = '/Users/frankwillett/Documents/AjiboyeLab/';
        out.bgPath = '';
    end
end

