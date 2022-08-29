% utahChannelMapToMSgeometryCSV.m
%
% Takes a BlackRock Utah array channel-to-array-location map of the kind NPL often uses,
% and converts it to an array geometry file 
% See MountainSort documentation at https://mountainsort.readthedocs.io/en/latest/first_sort.html
%
% USAGE: [ filename ] = utahChannelMapToMSgeometryCSV( emap, filename, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     emap                      10x10 array map, e.g. from arrayMapHumans.m
%     filename                  filename where the .csv should be saved to. Include .csv.
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     filename                  Same as input; where file went.
%
% Created by Sergey Stavisky on 19 Mar 2018 using MATLAB version 8.5.0.197613 (R2015a)

 function [ filename ] = utahChannelMapToMSgeometryCSV( emap, filename, varargin )
    def.ignoreChannelInds = [0]; % these are not real channels, should not be written
    def.pitch = 400; % distance bin micrometers
    assignargs( def, varargin );

     
    M = []; % will fill in a matrix that then gets written to a csv
    for row = 1 : size( emap, 1 )
        for col = 1 : size( emap, 2 )
            if ~ismember( emap(row,col),ignoreChannelInds )
               M(emap(row,col),1:2) = [col, row]; 
            end
        end
    end
    
    % scale to microns
    M = M.*pitch;
    
    % Write
    csvwrite( filename, M );
    
 end