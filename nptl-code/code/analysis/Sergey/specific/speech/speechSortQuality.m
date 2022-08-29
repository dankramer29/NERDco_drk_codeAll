% speechSortQuality.m
%
% Hand-entered sort quality because I forgot to include this in the R struct and it's
% faster to hand-enter it like this than regenerate those.
% Note: these cover both Array 1 and Array 2 of these datasets. These all come from my
% note, 'Plexon Sorting Notes Speech Data'.
%
% USAGE: [ sortQuality ] = speechSortQuality( datasetName )
%
% EXAMPLE:
%
% INPUTS:
%     datasetName               string specifying the dataset
%
% OUTPUTS:
%     sortQuality             N x 1 vector of scores, each 0 to 4, for the N sorted units expected for this   
%
% Created by Sergey Stavisky on 18 Apr 2018 using MATLAB version 9.3.0.713579 (R2017b)

 function [ sortQuality ] = speechSortQuality( datasetName )

switch datasetName
    case {'t5.2017.10.23-phonemes', 't5.2017.10.23-movements'}
        sortQuality = [...
            3;
            3;
            3.5;
            3;
            3.5;
            2.5;
            3;
            2.5;
            3.5;
            3;
            3.5;
            2.5;
            3;
            2.5;
            4;
            3;
            3.5;
            2.5;
            2.5;
            3;
            2.5;
            3.5;
            3.5;
            4;
            2.5;
            3;
            3;
            3;
            2.5;
            4;
            3;
            3;
            2.5;
            2.5;
            3;
            2.5;
        ];
    
       case {'t5.2017.10.25-words', 't5.2017.10.25-bmi'}
        sortQuality = [...
            3;
            4;
            2.5;
            3.5;
            4;
            3.5;
            4;
            4;
            3.5;
            3;
            2.5;
            3;
            4;
            3.5;
            3.5;
            3;
            2.5;
            2.5;
            3;
            2.5;
            2.5;
            2.5;
            3.5;
            3;
            2.5;
            2.5;
            2.5;      
        ];
    
    case {'t8.2017.10.17-phonemes', 't8.2017.10.17-movements'}
        sortQuality = [...
            2.5;
            2;
            3;
            3;
            3;
            3;
            2.5;
            2;
            3;
            4;
            3.5;
            3.5;
            3.5;
            2.5;
            3.5;
            2.5;
            2.5;
            2.5;
            4;
            4;
            4;
            3;
            4;
            4;
            4;
            2.5;
            2.5;
            2.5;
            2.5;
            2.5;
            3;
            4;
            4;
            4;
            4;
            3;
            3;
            2.5;
            2.5;
            3.5;
            3;
            3;
            3.5;
            3.5;
            2;
            2;
            3.5;
            3;
        ];
    
    
    case {'t8.2017.10.18-words', 't8.2017.10.18-movements', 't8.2017.10.18-BCI'}
        sortQuality = [...
            2.5;
            2.5;
            3;
            2.5;
            3;
            3;
            2.5;
            3;
            4;
            3.5;
            3;
            3.5;
            3;
            4;
            2.5;
            3.5;
            3;
            2.5;
            4;
            4;
            4;
            3.5;
            3;
            2.5;
            2.5;
            3;
            3;
            3.5;
            3;
            4;
            3;
            3.5;
            3;
            3;
            3.5;
            4;
            4;
            4;
            3.5;
            3;
            2.5;
            3;
            3;
            4;
            3;
            4;
            4;
            3;
            4;
            4;
            4;
            2.5;
            2.5;
        ];
    
    otherwise
        
        error('could not find a unit exclude lookup %s', dataset )
end





end