% Lookup of datasets/blocks used for 5D decoding analysis.
%
% Sergey Stavisky April 24 2017 

% <query> is either a specific dataset or a name of a set of datasets e.g.
% 't5_3D_early2017'.
% <dataset> returns information about the dataset. Can either be the name of
% a specific dataset, e.g. 't5.2017.02.15', or a list of these.
%
% condition returns information about the dataset of interest, such as what
% savetags should be analyzed.
function [dataset, condition] = datasets_5D( query, varargin )
   

switch query
    
    case 't5_5_0D_earlySpherical'
        % Collected using vertical bar and spherical coordinates. There's a separate dims1,2,3 and
        % dims 4,5 targer radii in the Euclidian vector space. 
        dataset = {...
            't5.2017.04.03';
            };
        
     case 't5_5_1D_earlySpherical'
        % Thor's Hammer. There's a separate dims1,2,3 and
        % dims 4,5 targer radii in the Euclidian vector space. 
        dataset = {...
            't5.2017.03.20';
            };   
        
        
        %----------------------------------------------
        %        T5 Early 2017 (first starting 5D)
        %----------------------------------------------
    % TASK lookup (same as in cursorConstants.m)
    % 1: TASK_CENTER_OUT
    % 7: TASK_RANDOM

    case 't5.2017.04.03'  % 5.0D, Vertical Rod, Vertical Hand Imagery, Spherical Coordinates
        dataset = query;
        condition.blocks = [4, 5, 6,   11, 12, 13,     15, 16];
        condition.task =   [1, 1, 1,    1,  1,  1,      7,  7]; 
        condition.examplePlotBlock = 4;
        condition.radiusCounts = false;
        
        
        
    case 't5.2017.03.20'  % 5,1D, Thor Hammer, Spherical Coordinates
        dataset = query;
        condition.blocks = [5, 6, 7,    12, 13, 14, 15];
        condition.task =   [1, 1, 1,     7,  7,  7,  7]; 
        condition.examplePlotBlock = 5;
        condition.radiusCounts = false;
        
    otherwise
        error('%s is not a valid dataset or list name')
end