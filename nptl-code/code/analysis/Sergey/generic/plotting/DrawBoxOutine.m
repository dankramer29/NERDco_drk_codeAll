% DrawBoxOutine.m
%
% Low-level box drawing. Inputs are each 8x1 coordinates, and it's 
% important is how the vertices connect to each other:
%
%   face1:
%   1    2          1<-->5, 2<--->6, 3<--->7, 4<--->8
%   4    3         
%
%   face2:
%   5    6
%   7    8
%
% USAGE: [ lineh ] = DrawBoxOutine( X, Y, Z, varargin )
%
% EXAMPLE:     lineh = DrawBoxOutine( X, Y, Z, 'Color', Color, 'LineWidth', LineWidth, 'axh', axh );
%
% INPUTS:
%     X                         8x1 X coordinates
%     Y                         8x1 Y coordinates
%     Z                         8x1 Z coordinates
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%      axh             axis to plot in
%      Color           line color
%      LineWidth       line width
%
% OUTPUTS:
%     lineh                     handles to the lines created
%
% Created by Sergey Stavisky on 27 Jan 2017

function [ lineh ] = DrawBoxOutine( X, Y, Z, varargin )

def.LineWidth = 1;
def.Color = [0 0 0];
def.axh = gca;
assignargs( def, varargin );


% this is written for 8 points
assert( numel(X) == 8 );
assert( numel(Y) == 8 );
assert( numel(Z) == 8 );

lineh = [];

connectLine = @(a,b) line( [X(a),X(b)], [Y(a),Y(b)], [Z(a),Z(b)]);

lineh(end+1) = connectLine(1,2);
lineh(end+1) = connectLine(1,5);
lineh(end+1) = connectLine(1,4);
lineh(end+1) = connectLine(2,6);
lineh(end+1) = connectLine(2,3);
lineh(end+1) = connectLine(3,4);
lineh(end+1) = connectLine(3,7);
lineh(end+1) = connectLine(4,8);
lineh(end+1) = connectLine(7,8);
lineh(end+1) = connectLine(7,6);
lineh(end+1) = connectLine(8,5);
lineh(end+1) = connectLine(5,6);

% set colors and widths
set( lineh, 'Color', Color );
set( lineh, 'LineWidth', LineWidth );


end