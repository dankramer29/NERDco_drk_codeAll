% ThreeDCoordinateColors.m
%
% Takes in a bunch of x,y,z coordinates, where each row is a point, and converts them an RGB
% color based on where the fall along the full range of values. X gets mapped to Red, Y to
% Green, and Z to Blue
%
% USAGE: [ RGB ] = ThreeDCoordinateColors( XYZ )
%
% EXAMPLE:
%
% INPUTS:
%     XYZ                       X,Y,Z coordinates for each point (each point is a row)
%
% OUTPUTS:
%     RGB                       RGB (0 to 1) for each point (row)
%
% Created by Sergey Stavisky on 27 Jan 2017

function [ RGB ] = ThreeDCoordinateColors( XYZ, varargin )
    def.maxVal = 0.9; % prevents returning the color white, which wouldn't be visble
    def.minVal = 0;
    assignargs( def, varargin );

    assert( size(XYZ,2) == 3 );
    N = size( XYZ, 1 );
    RGB = nan( N, 3 ); % preallocate
    for iDim = 1 : 3
        minThisDim = min( XYZ(:,iDim) );
        maxThisDim = max( XYZ(:,iDim) );
        for i = 1 : N
            RGB(i,iDim) = (XYZ(i,iDim) - minThisDim)/(maxThisDim-minThisDim)*(maxVal-minVal)+minVal;
        end
    end
end