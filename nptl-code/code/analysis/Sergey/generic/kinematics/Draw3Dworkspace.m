% Draw3Dworkspace.m
%
% Draws the workspace boundaries as a bunch of 3D lines. Mostly just calls
% DrawBoxOutline.m.
%
% USAGE: [ lineh ] = Draw3Dworkspace( varargin )
%
% EXAMPLE: workspaceh = Draw3Dworkspace('axh', axh, ...
%        'workspaceX', R(1).startTrialParams.workspaceX, ...
%        'workspaceY', R(1).startTrialParams.workspacey, ... 
%        'workspaceZ', R(1).startTrialParams.workspaceZ);
%
% INPUTS:
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     lineh                     
%
% Created by Sergey Stavisky on 27 Jan 2017

function [ lineh ] = Draw3Dworkspace( varargin )
    % default NPTL workspace
    def.workspaceX = [-0.1200 0.1200];
    def.workspaceY = [-0.1200 0.1200];
    def.workspaceZ = [-0.1200 0.1200];
    def.axh = gca;
    def.LineWidth = 1;
    def.Color = [0 0 0];
    
    % nice camera angle
    def.CameraPosition = [0.3 .35 -.6]; % makes positive Z towards the viewer
    def.CameraUpVector = [0 -1 0]; % makes XY the frontoparallel plane
    
    assignargs( def, varargin );
    axes( axh ); hold on;
    
    
    X = [workspaceX(1);
        workspaceX(2);
        workspaceX(2);
        workspaceX(1);
        workspaceX(1);
        workspaceX(2);
        workspaceX(2);
        workspaceX(1)];
    Y = [workspaceY(1);
        workspaceY(1);
        workspaceY(1);
        workspaceY(1);
        workspaceY(2);
        workspaceY(2);
        workspaceY(2);
        workspaceY(2)];
    Z = [workspaceZ(1);
        workspaceZ(1);
        workspaceZ(2);
        workspaceZ(2);
        workspaceZ(1);
        workspaceZ(1);
        workspaceZ(2);
        workspaceZ(2)];
    lineh = DrawBoxOutine( X, Y, Z, 'Color', Color, 'LineWidth', LineWidth, 'axh', axh );
    
    axh.CameraPosition = CameraPosition;
    axh.CameraUpVector = CameraUpVector;
    axis equal
    box off;

    % Also label axes
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');

end