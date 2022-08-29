% PlotTTTeachTarget.m
%
% Calculates and plots the mean TTT for each unique target in the provided R struct.
% Useful for assessing if certain dimensions or targets are giving the participant the
% most trouble.
%
% USAGE: [ figh, axh, h ] = PlotTTTeachTarget( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                         NPTL R struct
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     figh          figure handle            
%     axh           axis handle            
%     stat          structure with TTT statistics for each target             
%     h             handle of scatter object created
%
% Created by Sergey Stavisky on 28 Jan 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ figh, axh, stat, h ] = PlotTTTeachTarget( R, varargin )
 
    % Default arguments
    def.axh = []; % can be instructed to plot into a specific axis
    def.MarkerSize = 8^2;
    def.Marker = 'o';
    def.CLim = []; % Color limits (in ms)
    def.showColorbar = true; % whether to show colorbar
    assignargs( def, varargin );
    
    %% Calculate mean/median TTT
    [targetIdx, uniqueTargets] = SortTrialsBy3Dtarget( R );
    for iTarget = 1 : size( uniqueTargets, 1 )
        stat.TTT{iTarget,1} = [R(targetIdx==iTarget).trialLength] - [R(targetIdx==iTarget).timeGoCue];
        stat.meanEachTarget(iTarget,1) = mean( stat.TTT{iTarget} );
        stat.medianEachTarget(iTarget,1) = median( stat.TTT{iTarget} );
    end
    
    %% Plotting
    if isempty( axh )
        figh = figure;
        figh.Color = 'w';
        axh = axes;
        axh = SetAxesToNPTLconventions( axh ); % convert this axes into NPTL coordinate conventions
        hold on;
    else
        % an axis was fed in, so we'll use that.
        figh = get( axh, 'Parent');
        axh = SetAxesToNPTLconventions( axh );
    end
    
    % Draw the workspace. This also sets the camera angle
    workspaceh = Draw3Dworkspace('axh', axh, ...
        'workspaceX', R(1).startTrialParams.workspaceX, ...
        'workspaceY', R(1).startTrialParams.workspacey, ... % due to stupid typo..
        'workspaceZ', R(1).startTrialParams.workspaceZ);
    
    hClick = scatter3( uniqueTargets(:,1), uniqueTargets(:,2), uniqueTargets(:,3), MarkerSize, stat.meanEachTarget, ...
        Marker, 'filled');
    
    % rescale so small differences don't look huge
    if isempty( CLim )
        axh.CLim = [0.5*min(stat.meanEachTarget)  max(stat.meanEachTarget) ];
    end
    if showColorbar
        cbarh = colorbar;
        cbarh.Label.String = 'Time to Target (ms)';
    end   

    % good camera for this
    axh.CameraUpVector = [0 0 1];
    axh.CameraPosition = [0.1771    0.2448    2.4947];

end