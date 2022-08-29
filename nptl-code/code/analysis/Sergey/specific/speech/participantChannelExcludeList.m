% participantChannelExcludeList.m
%
% Simple lookup table of which channels to exclude from analysis for each participant.
% Useful for centralizing this in my speech analysis functions.
%
% USAGE: [ excludeChannels ] = participantChannelExcludeList( participant, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     participant               
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     excludeChannels                      
%
% Created by Sergey Stavisky on 19 Oct 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ excludeChannels ] = participantChannelExcludeList( participant, varargin )

    switch participant 
        
        case 't5'
            % below is what it was for EMBC:
            burstChans = [67, 68, 69, 73, 77, 78, 82];
            smallBurstChans = [2, 46, 66, 76, 83, 85, 86, 94, 95, 96]; %  to be super careful
            excludeChannels = sort( [burstChans, smallBurstChans ] );
            % TODO: 161 has crazy LFP...  [yes it does, including for high gammma. No spikes
            
            
        case 't8'
            excludeChannels = setdiff(12:60,[26 28 30 33 34 42 44 48 50 54]); % provided by Brian

        otherwise
            error( '%s is not a recognized participant', participant )

    end

end