% RMSfromMinAcausSpikeBand.m
%
% Calculates RMS value of the MinAcausSpikeBand.m field. Note that since this itself
% is the smallest value in each 1 ms (30 Cerebus samples), this will give a different RMS
% value than applying it directly to the Cerebus-derived spikes data. 
% IT IS HIGHLY NOT RECOMMENDED TO USE THIS FUNCTION FOR THIS REASON.
%
% USAGE: [ thresholds ] = RMSfromMinAcausSpikeBand( R, varargin )
%
% EXAMPLE: thresholds = RMSfromMinAcausSpikeBand( R ); 
%
% INPUTS:
%     R                         R struct with .minAcausSpikeBand
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     thresholds                Ex1 vector of 1 RMS for each of E electrodes
%
% Created by Sergey Stavisky on 16 Oct 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ thresholds ] = RMSfromMinAcausSpikeBand( R, varargin )
    error('DO NOT USE THIS! Use channelRMS.m instead'); 

    E = size( R(1).minAcausSpikeBand, 1 );
    numSamples = 1;
    sumSquared = zeros( E, 1 ); % will count up
    for iTrial = 1 : numel( R )
        numSamples = numSamples + size( R(iTrial).minAcausSpikeBand, 2 );
        sumSquared = sumSquared + sum( R(iTrial).minAcausSpikeBand.^2, 2 );
    end
    

    thresholds = sqrt( sumSquared./numSamples );
end