% SortTrialsBy4Dtarget.m
%
% 4-D analog of SortTrialsByTarget.m. Designed to work on NPTL R structs.
%
% USAGE: [ targetIdx, uniqueTargets, angle, distFromZero ] = SortTrialsBy4Dtarget( R, varargin )
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
%     angle                     Returned as empty, but kept here so usage is
%                               similar to 2D and 3D variants. Can be added later if there's some 
%                               angle scheme I like.
%     distFromZero              How far each target is from 0,0,0,0.
%
% Created by Sergey Stavisky on 25 Apr 2017
% based on SortTrialsBy3Dtarget

function [ targetIdx, uniqueTargets, angle, distFromZero ] = SortTrialsBy4Dtarget( R, varargin )
    
    allTargets = cell2mat( arrayfun( @(x) x.posTarget', R, 'UniformOutput', false )' );
    % keep only 4D coordinate
    allTargets = double( allTargets(:,1:4) );
    uniqueTargets = unique( allTargets, 'rows');

    angle = [];
    
    %% Assign each target an index based on which uniqueTargets it belongs to
    targetIdx = nan( numel( R ), 1 );
    for iTarget = 1 :  size( uniqueTargets, 1 )
        targetIdx(EqRow( allTargets, uniqueTargets(iTarget,:) )) = iTarget;
    end
    
    %% Additional Info
    distFromZero = sqrt( sum( uniqueTargets(:,1:4).^2, 2 ) );

end