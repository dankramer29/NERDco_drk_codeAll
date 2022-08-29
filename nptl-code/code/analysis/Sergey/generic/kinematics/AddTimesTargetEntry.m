% AddTimesTargetEntry.m
%
% Reports times when the cursor first enters the target, which here is calculated based on
% when the state entered STATE_ACQUIRE (for nonclick mode) or STATE_HOVER (for click mode).
%
% USAGE: [ R ] = AddTimesTargetEntry( R, varargin )
%
% EXAMPLE:  R = AddTimesTargetEntry( R );
%
% INPUTS:
%     R                         NPTL R Struct
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R                         NPTL R struct with new field .timesTargetEntry. Also
%                               creates a .timeFirstTargetEntry field (which is the firsdt
%                               of these or otherwise a nan if no target entries).
%
% Created by Sergey Stavisky on 02 Feb 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ R ] = AddTimesTargetEntry( R, varargin )
    % Define which states will count as being over the target
    def.overTargetStates = uint16( [CursorStates.STATE_ACQUIRE, CursorStates.STATE_HOVER] ); % relies on state definitions from cart code
    assignargs( def, varargin );

    for i = 1 : numel( R ) % loop over trials
        timesOverTarget = ismember( R(i).state, overTargetStates );
        % rising of above are when we enter target
        R(i).timesTargetEntry = find( diff(timesOverTarget)==1 )+1;
        % create .timeFirstTargetEntry
        if isempty( R(i).timesTargetEntry )
            R(i).timeFirstTargetEntry = nan;
        else
            R(i).timeFirstTargetEntry = R(i).timesTargetEntry(1);
        end
    end
   
end