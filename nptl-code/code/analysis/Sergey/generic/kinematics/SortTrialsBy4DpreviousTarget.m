% SortTrialsBy4DpreviousTarget.m
%
% 4-D analog of SortTrialsByPreviousTarget.m. Designed to work on NPTL R structs.
% Looks at the previous target. If it doesnt exist (can happen for first trial of a block)
%returns a nan.
%
% USAGE: [ targetIdx, uniqueTargets, angle, distFromZero ] = SortTrialsBy4DpreviousTarget( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                         NPTL R struct to operate on. Contains N trials.
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     targetIdx                 Nx1 vector giving the target index for each trial
%     uniqueTargets              Matrix where each row contains one of the unique targets.
%                               The row index corresponds to a target index that <targetIdx>
%                               refers to.
%     angle                      Returned as empty, but kept here so usage is
%                               similar to 2D and 3D variants. Can be added later if there's some 
%                               angle scheme I like.
%     distFromZero              How far each target is from 0,0,0,0.
%
% Created by Sergey Stavisky on 25 Apr 2017
% based on SortTrialsBy3DpreviousTarget

function [ targetIdx, uniqueTargets, angle, distFromZero ] = SortTrialsBy4DpreviousTarget( R, varargin )
    
    allTargets = arrayfun( @(x) x.lastPosTarget', R, 'UniformOutput', false )';
    invalidTrials = cellfun(@(x) size(x,2), allTargets ) < 4;

    % keep only 4D coordinate
    allTargetsTmp = cell2mat( allTargets(~invalidTrials) );
    allTargetsTmp = double( allTargetsTmp(:,1:4) );
    uniqueTargets = unique( allTargetsTmp, 'rows');
    
    % Put back in the invalid trial
    allTargets = nan( numel( R ), 4 );
    allTargets(~invalidTrials,:) = allTargetsTmp;
    %% Re-order sensibly
    % It's also convenient to order the targets by their direction (makes
    % for meaningful order in radial tasks). Do this:
    theta = [];
    
    
    %% Assign each target an index based on which uniqueTargets it belongs to
    targetIdx = nan( numel( R ), 1 );
    for iTarget = 1 :  size( uniqueTargets, 1 )
        targetIdx(EqRow( allTargets, uniqueTargets(iTarget,:) )) = iTarget;
    end
    
    %% Additional Info
    distFromZero = sqrt( sum( uniqueTargets(:,1:4).^2, 2 ) );
   
    

end