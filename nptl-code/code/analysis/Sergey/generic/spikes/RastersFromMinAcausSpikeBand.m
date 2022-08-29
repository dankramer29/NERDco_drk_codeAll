% RastersFromMinAcausSpikeBand.m
%
% (Adds a .spikeRaster field to a trial based on its minAcausSpikeBand data
% and threhsolds provided.
%
% USAGE: [ R ] = RastersFromMinAcausSpikeBand( R, thresholds, varargin )
%
% EXAMPLE: Rgrid = RastersFromMinAcausSpikeBand( Rgrid, thresholds );
%
% INPUTS:
%     R                         NPTL R struct that's been loaded with
%                               'minAcausSpikeBand'. 
%     thresholds                either Ex1 vector of thresholds for each electrode,
%                               or a scalar (universal threshold)
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R                         R struct with .(newFieldName), typically 
%                               .spikeRaster, added.
%
% Created by Sergey Stavisky on 11 Nov 2016

function [ R ] = RastersFromMinAcausSpikeBand( R, thresholds, varargin )
    def.newFieldName = 'spikeRaster';
    assignargs( def, varargin );
    
    %% Input checking
    if ~isfield( R, 'minAcausSpikeBand' )
        error('no .minAcausSpikeBand field found. Are you sure this R struct was loaded with appropiate addons?')
    end
    numElecs = size( R(1).minAcausSpikeBand, 1 );
    if size( thresholds,1 ) == 1
        thresholds = thresholds'; %forcecol
    end

    if numel( thresholds ) ~= numElecs && numel( thresholds ) ~= 1
       error('thresholds has %i elements, should be 1 or %i (the inferred number of electrodes).', ...
           numel( thresholds ), numElecs )
    end
    if numel( thresholds ) == 1
        thresholds = repmat( thresholds, numElecs, 1 );   % scalar expand
    end

    %% Rasterize each trial
     for iTrial = 1 : numel( R )
         R(iTrial).(newFieldName) = R(iTrial).minAcausSpikeBand < repmat( thresholds, 1, size(  R(iTrial).minAcausSpikeBand, 2 ) );
     end

end