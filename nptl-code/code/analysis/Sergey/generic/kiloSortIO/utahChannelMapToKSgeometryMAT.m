% utahChannelMapToKSgeometryMAT.m
%
% Takes a BlackRock Utah array channel-to-array-location map of the kind NPL often uses,
% and converts it to an array geometry file used by Kilosort.
% See https://github.com/cortex-lab/neuropixels/blob/master/neuropixPhase3_kilosortChanMap.mat
%
% USAGE: [ filename ] = utahChannelMapToKSgeometryMAT( emap, filename, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     emap                      10x10 array map, e.g. from arrayMapHumans.m
%     filename                  filename where the .mat should be saved to.
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     filename                  Same as input; where file went.
%
% Created by Sergey Stavisky on 25 Mar 2018 using MATLAB version 8.5.0.197613 (R2015a)

 function [ filename ] = utahChannelMapToKSgeometryMAT( emap, filename, varargin )
    if ~strcmp( filename(end-3:end), '.mat' )
        filename(end+1:end+4) = '.mat';
    end
        
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
    
    chanMap = [1:size( M,1 )]';
    chanMap0ind = chanMap-1;
    connected = logical( ones( size( chanMap ) ) );
    shankInd = ones( size( chanMap ) ); % not sure if this makes sense but seems worth doing.
    xcoords = M(:,1);
    ycoords = M(:,2);
    % Write
    save(filename, 'chanMap', 'chanMap0ind','connected','shankInd','xcoords','ycoords')

 end