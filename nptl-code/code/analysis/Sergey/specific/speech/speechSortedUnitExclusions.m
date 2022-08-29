% speechSortedUnitExclusions.m
%
% Hand-specified unit exclusion list. I use this to remove duplicate units that are
% visible across multiple electrodes.
%
% USAGE: [ excludeList ] = speechSortedUnitExclusions( dataset )
%
% EXAMPLE:
%
% INPUTS:
%     dataset                   string which indicates what dataset
%
% OUTPUTS:
%     excludeList               list of indices into the sorted units that will be brought
%                               present in the speech R struct that sorted units
%                               (includes array 1 and 2 with continuously increasing indices)  
%
% Created by Sergey Stavisky on 18 Apr 2018 using MATLAB version 9.3.0.713579 (R2017b)

 function [ excludeList ] = speechSortedUnitExclusions( dataset )


switch dataset
    case {'t5.2017.10.23-phonemes', 't5.2017.10.23-movements'}
        excludeList = [1, 34, 35]; % these units are duplicates
    case {'t5.2017.10.25-words', 't5.2017.10.25-bci'}
        excludeList = []; % really none that are quality >=3
    case {'t8.2017.10.17-phonemes', 't8.2017.10.17-movements'}
        excludeList = [19, 25, 43, 31, 37, 42 ];
    case {'t8.2017.10.18-words', 't8.2017.10.18-bci'}
        excludeList = [11, 19, 26, 46, 32, 34];
    otherwise
        
        error('could not find a unit exclude lookup %s', dataset )
end




end