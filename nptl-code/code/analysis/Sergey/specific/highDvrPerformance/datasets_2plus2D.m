% Lookup of datasets/blocks used for 2 + 2D decoding analysis.
%
% Sergey Stavisky May 18 2018

% <query> is either a specific dataset or a name of a set of datasets e.g.
% 't5_4_0'.
% <dataset> returns information about the dataset. Can either be the name of
% a specific dataset, e.g. 't5.2017.08.02', or a list of these.
%
% condition returns information about the dataset of interest, such as what
% savetags should be analyzed.
function [dataset, condition] = datasets_2plus2D( query, varargin )
   

switch query
    
    case 't5_2plus2D'
        % Collected using vertical bar.
        dataset = {...            
            't5.2017.08.02';
            't5.2017.07.10';
            };

        
    %----------------------------------------------
    %        T5 2017 2 + 2 D
    %----------------------------------------------
    % TASK lookup (same as in cursorConstants.m)
    % 1: TASK_CENTER_OUT ( 4 DOF )
    % 2: TASK_2PLUS2 ( 2 + 2 DOF )

    case 't5.2017.08.02'  
        dataset = query;
        condition.blocks = [ 7,   10, 11, 12,   15,    16];
        condition.task =   [ 1,    2,  2,  2,    1,     2]; 
        condition.conditionName = {'4D', '2+2D'};
        condition.radiusCounts = false;
        
      case 't5.2017.07.10'  
        dataset = query;
        condition.blocks = [ 5,    6,  7,  8,   10,    11, 12];
        condition.task =   [ 1,    2,  2,  2,    1,     2   2]; 
        condition.conditionName = {'4D', '2+2D'};
        condition.radiusCounts = false;
        
         
    otherwise
        error('%s is not a valid dataset or list name')
end