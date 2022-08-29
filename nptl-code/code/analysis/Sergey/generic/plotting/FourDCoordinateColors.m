% ThreeDCoordinateColors.m
%
% Takes in a bunch of x,y,z,r1 coordinates, where each row is a point, and converts them an RGB
% color based on where the fall along the full range of values. The four coordinates get
% mapped to cmyk, which then gets converted to RGB.
%
% USAGE: [ RGB ] = ThreeDCoordinateColors( target )
%
% EXAMPLE:
%
% INPUTS:
%     target                       X,Y,Z,R1 coordinates for each point (each point is a row)
%
% OUTPUTS:
%     RGB                       RGB (0 to 1) for each point (row)
%
% Created by Sergey Stavisky on 17 Jul 2017

function [ RGB ] = FourDCoordinateColors( target, varargin )
    def.maxVal = 0.9; % prevents returning the color white, which wouldn't be visble
    def.minVal = 0;
    assignargs( def, varargin );

    assert( size(target,2) == 4 );
    N = size( target, 1 );
    RGB = nan( N, 3 ); % preallocate
    CMYK = nan( N, 4 );
    % range of each dimension
    for iDim = 1 : 4
        minEachDim(iDim) = min( target(:,iDim) );
        maxEachDim(iDim) = max( target(:,iDim) );
    end
    
    % Convert trial by trial
    for i = 1 : N
        for iDim = 1 : 4
            CMYK(i,iDim) = (target(i,iDim) - minEachDim(iDim)) / (maxEachDim(iDim)-minEachDim(iDim)) * (maxVal-minVal) + minVal;
        end
        % now convert to rgb
        RGB(i,:) = cmyk2rgb( 100.*CMYK(i,:) );
    end
    % convert RGB down to 0 to 1
    RGB = RGB./255;
end