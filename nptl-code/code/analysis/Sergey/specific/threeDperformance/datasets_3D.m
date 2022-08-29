% Lookup of datasets/blocks used for 3D decoding analysis.
%
% Sergey Stavisky March 17 2017 

% <query> is either a specific dataset or a name of a set of datasets e.g.
% 't5_3D_early2017'.
% <dataset> returns information about the dataset. Can either be the name of
% a specific dataset, e.g. 't5.2017.02.15', or a list of these.
%
% condition returns information about the dataset of interest, such as what
% savetags should be analyzed.
function [dataset, condition] = datasets_3D( query, varargin )
   

switch query
    
    case 't5_3D_early2017'
        % Collected before we ever went to 4D. Note that these had the
        % cursor radius still counting towards acquiring targets in all
        % tasks except Gridlike. These are click to acquire
        dataset = {...
            't5.2017.01.25';
            't5.2017.02.01';
            't5.2017.02.08';
            't5.2017.02.13';
            't5.2017.02.15';
            't5.2017.02.27'
            };
        
    case 't5_3D_early2017_dwell'
        % Collected before we ever went to 4D. Note that these had the
        % cursor radius still counting towards acquiring targets in all
        % tasks except Gridlike. These are click to acquire
        dataset = {...
            't5.2017.02.27_dwell'
            };
        
    case 't5_3D_lowGain'
        dataset = {...
            't5.2017.03.22';
            };
        
        %----------------------------------------------
        %        T5 Early 2017 (first starting 3D)
        %----------------------------------------------
    case 't5.2017.01.25'
        dataset = query;
        condition.blocks = [9, 10, 11, 12, 13, 14];
        condition.removeFirstNtrials = [10,5]; % [block,#trials]
        condition.examplePlotBlock = 12; % nice for examples
        condition.radiusCounts = 0.10; % cursor radius counts for target acquisition (discontinued when we went to 4D)
    case 't5.2017.02.01'
        dataset = query;
        condition.blocks = [7, 8, 9, 10, 22];
        condition.examplePlotBlock = 10;
        condition.radiusCounts = 0.10;
    case 't5.2017.02.08'
        dataset = query;
        condition.blocks = [5, 6, 7, 8, 9];
        condition.examplePlotBlock = 5;
        condition.radiusCounts = 0.10;
    case 't5.2017.02.13'        
        dataset = query;
        condition.blocks = [5, 6, 8, 9, 10, 11, 12];
        condition.radiusCounts = 0.10;
    case 't5.2017.02.15'
        dataset = query;
        condition.blocks = [6, 7, 8,  9, 10, 11, 12, 13, 14];
        condition.examplePlotBlock = 6;
        condition.radiusCounts = 0.10;
    case 't5.2017.02.27'
        dataset = query;
        condition.blocks = [4, 5, 6, 7, 8, 11, 12, 16, 17, 18, 19,  27, 28, 29];
        condition.examplePlotBlock = 28;
        condition.radiusCounts = 0.10; % rather than true, I actually list the exact radius
        
    case 't5.2017.02.27_dwell'
        dataset = 't5.2017.02.27';
        condition.blocks = [13, 14, 15, 31, 32];
        condition.examplePlotBlock = 15;
        condition.radiusCounts = 0.10;
        

        
        
        %----------------------------------------------
        %        T5 Low Gain
        %----------------------------------------------
    case 't5.2017.03.22'
        % Note: normal gain blocks not listed here. These were:
        % 6, 7, 13, 16, 17
        % Some bias-y blocks not listed here (see notes file)
        dataset = query;
        condition.blocks = [6,    7,    8,  13,   14,     15,   16,  17,    18];
        condition.gain =   [1, 0.77,  0.5,   1,  0.33,  0.67,    1,  1.2,   0.6];
        condition.examplePlotBlock = 8;
        condition.radiusCounts = false;    
        
        
    otherwise
        error('%s is not a valid dataset or list name')
end