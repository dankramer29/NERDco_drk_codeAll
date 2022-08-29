% Lookup of datasets/blocks used for 4D decoding analysis.
%
% Sergey Stavisky April 25 2017 

% <query> is either a specific dataset or a name of a set of datasets e.g.
% 't5_4_0'.
% <dataset> returns information about the dataset. Can either be the name of
% a specific dataset, e.g. 't5.2017.04.05', or a list of these.
%
% condition returns information about the dataset of interest, such as what
% savetags should be analyzed.
function [dataset, condition] = datasets_4D( query, varargin )
   

switch query
    
    case 't5_4_0D'
        % Collected using vertical bar.
        dataset = {...            
            't5.2017.04.05';
            't5.2017.04.10';
            't5.2017.04.12';
            't5.2017.04.24';
            };

%   These are the 4.0 DOF blocks intermingled in 2+2 DOF days
%         't5.2017.07.12'; % prior to 2+2D
%         't5.2017.07.24'; % prior to 2+2D
%         't5.2017.07.26'; % prior to 2+2D
%         't5.2017.08.02'; % prior to 2+2D
     
    case 't5_RAYS_4D'
        % Collected using vertical bar, 4.0 D RAYS task. The exact parameters varied
        % from block to block.
        dataset = {...            
            't5.2017.06.14';
            't5.2017.06.21';
            't5.2017.06.26';
            't5.2017.06.28';
            };     
     
    case 't5_4D_lowGain'
        dataset = {...
            't5.2017.08.14';
            };
        
    case 't5_4_1D'
        dataset = {...
            't5.2017.04.26'; % 4 cm diameter
            't5.2017.05.01'; % 4 cm diameter
            't5.2017.05.08'; % false click fails, not great day  4 cm diameter
            't5.2017.05.15'; % false click fails 5 cm diameter
            't5.2017.06.02'; % R80 False Click Fails 4 cm diameter
            't5.2017.06.05'; % R80 and Random False Click 4 cm diameter
            't5.2017.06.07'; % R80 and Random False Click, short day, 4 cm diameter
            't5.2017.06.19'; %Robot pilot day 5 cm diameter
            't5.2017.10.18';  % 5 cm diameter
        };
        
    %----------------------------------------------
    %        T5 Early 2017 core data collection)
    %----------------------------------------------
    % TASK lookup (same as in cursorConstants.m)
    % 1: TASK_CENTER_OUT
    % 7: TASK_RANDOM
    % 8: RAYS

    case 't5.2017.04.24'  % 4.0D, Vertical Rod, Vertical Hand Imagery
        dataset = query;
        condition.blocks = [ 5, 6, 8,    9, 10, 11,   12, 13, 14 ];
        condition.task =   [ 1, 1, 1,    7,  7,  7,    1,  1,  1]; 
        condition.examplePlotBlock = 5;
        condition.radiusCounts = false;
        
    case 't5.2017.04.12'  % 4.0D, Vertical Rod, Vertical Hand Imagery
        dataset = query;
        condition.blocks = [ 5, 6, 7,    9, 10, 11,   12, 13, 14,   15, 16, 17  ];
        condition.task =   [ 1, 1, 1,    7,  7,  7,    1,  1,  1,    7,  7,  7 ]; 
        condition.examplePlotBlock = 5;
        condition.radiusCounts = false;
    
    case 't5.2017.04.10'  % 4.0D, Vertical Rod, Vertical Hand Imagery
        dataset = query;
        condition.blocks = [ 6, 7, 8,    9, 10,   13, 14, 15,   16, 17, 18, 19, 20  ];
        condition.task =   [ 1, 1, 1,    7,  7,    1,  1,  1,    7,  7,  7,  7,  7  ]; 
        condition.examplePlotBlock = 6;
        condition.radiusCounts = false;
    
    case 't5.2017.04.05'  % 4.0D, Vertical Rod, Vertical Hand Imagery
        dataset = query;
        condition.blocks = [ 11, 12,    13, 15, 16];
        condition.task =   [  7,  7,     1,  1,  1]; 
        condition.examplePlotBlock = 13;
        condition.radiusCounts = false;
        
   %----------------------------------------------
    %        T5 4.1 D 
    %----------------------------------------------
    
      case 't5.2017.04.26'  % False Click does not fail
        dataset = query;
        condition.blocks = [ 8  9, 10,  11, 12, 13,  14 ];
        condition.task =   [ 1, 1,  1,   7,  7,  7,   1];
        condition.examplePlotBlock = 10;
        condition.radiusCounts = false;
    
     case 't5.2017.05.01'  % False Click does not fail
        dataset = query;
        condition.blocks = [ 6, 7, 8  11, 12, 13,  14, 15, 16];
        condition.task =   [ 1, 1, 1,  7,  7,  7,   1,  1,  1];
        condition.examplePlotBlock = 8;
        condition.radiusCounts = false;
    
    case 't5.2017.05.08'  % False Click Fails. Refractory period didn't work for Random so not included
       % had a click speed amx and did adjust click by participant request
        dataset = query;
        condition.blocks = [ 9, 10,];
        condition.task =   [  1,  1];
        condition.examplePlotBlock = 10;
        condition.radiusCounts = false;    
    
    
    case 't5.2017.05.15'  % False Click Fails
        % looks like lots of hand-tuning click before it was reliable, in previous
        % blocks not included b/c of changing parameters. Not a great day?
        dataset = query;
        condition.blocks = [ 17];
        condition.task =   [  1];
        condition.examplePlotBlock = 17;
        condition.radiusCounts = false;
    
    case 't5.2017.06.02'  % False Click Fails. Refractory period didn't work for Random so not included
        dataset = query;
        condition.blocks = [ 15, 17, 20];
        condition.task =   [  1,  1, 1];
        condition.examplePlotBlock = 17;
        condition.radiusCounts = false;    
    
    case 't5.2017.06.05'  % False Click Fails
        dataset = query;
        condition.blocks = [ 7, 11, 13  16];
        condition.task =   [  1,  1, 1,  7];
        condition.examplePlotBlock = 13;
        condition.radiusCounts = false;
    
      case 't5.2017.06.07'  % False Click Fails
        dataset = query;
        condition.blocks = [ 11, 14];
        condition.task =   [  1,  7];
        condition.examplePlotBlock = 11;
        condition.radiusCounts = false;
    
     case 't5.2017.06.19'  % Robot day that had a complete 4.1 DOF block prior to robot
        dataset = query;
        condition.blocks = [ 16];
        condition.task =   [ 1];
        condition.examplePlotBlock = 16;
        condition.radiusCounts = false;
    
    case 't5.2017.10.18'  % Robot day that had a complete 4.1 DOF block prior to robot
        dataset = query;
        condition.blocks = [ 7];
        condition.task =   [ 1];
        condition.examplePlotBlock = 7;
        condition.radiusCounts = false;
        
            
    case 't5.2018.11.14'  % Robot day that had a complete 4.1 DOF block prior to robot
        dataset = query;
        condition.blocks = [ 6];
        condition.task =   [ 1];
        condition.examplePlotBlock = 6;
        condition.radiusCounts = false;
        
        
    %----------------------------------------------
    %        T5 Spring 2017 RAYS 4.0
    %---------------------------------------------- 
    % Task 1 is CENTER_OUT, this is the last CL R80 before starting RAYS on
    %        each day.
    % Task 8 is RAYS
     case 't5.2017.06.14'  % 4.0D, Vertical Rod, RAYS
         % also block 14 had no ghost
         dataset = query;
         condition.blocks = [ 5,     6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
         condition.task =   [ 1,     8, 8, 8, 8,  8,  8,  8,  8,  8,  8];
         condition.examplePlotBlock = 9;
         condition.radiusCounts = false;
         
    case 't5.2017.06.21'  % 4.0D, Vertical Rod, RAYS
         % also block 9 was just to explore, and block 15 is 2D rays
         dataset = query;
         condition.blocks = [ 4,    5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
         condition.task =   [ 1,    8, 8, 8, 8, 8,  8,  8,  8,  8,  8,  8];
         condition.examplePlotBlock = 6;
         condition.radiusCounts = false;     
         
    case 't5.2017.06.26'  % 4.0D, Vertical Rod, RAYS
         % also block 19 is 2D rays
         dataset = query;
         condition.blocks = [ 8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
         condition.task =   [ 1,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8];
         condition.examplePlotBlock = 17;
         condition.radiusCounts = false;     
         
    case 't5.2017.06.28'  % 4.0D, Vertical Rod, RAYS
         % also blocks 14, 15 are 2D rays
         dataset = query;
         condition.blocks = [ 20,   14, 15, 21, 22, 23];
         condition.task =   [  1,    8,  8,  8,  8,  8];
         condition.examplePlotBlock = 23;
         condition.radiusCounts = false;   
        
        
    %----------------------------------------------
    %        T5 Low Gain 4.0
    %---------------------------------------------- 
    case 't5.2017.08.14'
        dataset = query;
        condition.blocks = [  10,   11,   12,  15,   16]; % 3 low gain blocks
        condition.gain =   [ 0.33,   1  0.33,   1, 0.33];
        condition.examplePlotBlock = 12;
        condition.radiusCounts = false;        
         
    otherwise
        error('%s is not a valid dataset or list name')
end