% AddTimeSuccessfulClick.m
%
% Reports when in the trial a successful click happened. Will be empty if there was no
% successful click. Also reports times when a click happened and the cursor wasn't in the
% target.
%
% Based on looking at when the click happens and seeing if the state was such that the
% cursor is over the target OR success state
%
% USAGE: [ R ] = AddTimeSuccessfulClick( R, varargin )
%
% EXAMPLE:    R = AddTimeSuccessfulClick( R ); 
%
% INPUTS:
%     R                         NPTL R Struct
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R                         NPTL R struct with new field .timeSuccessfulClick and
%                               .timeIncorrectClick
%
% Created by Sergey Stavisky on 02 Feb 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ R ] = AddTimeSuccessfulClick( R, varargin )
    % Define which states will count as being over the target
    def.overTargetStates = uint16( [CursorStates.STATE_ACQUIRE, CursorStates.STATE_HOVER, CursorStates.STATE_SUCCESS] ); % relies on state definitions from cart code
    % include STATE_SUCCESS above since a click pver target leads immediately to STATE_SUCCESS
    assignargs( def, varargin );

    % I'll need click times.
    if ~isfield( R, 'clickTimes' )
        R = AddClickTimesToR( R );
    end

    
    for i = 1 : numel( R ) % loop over trials
        % Create these  fields. This way if this function is called again, it won't create
        % duplicates
        R(i).timeSuccessfulClick = [];
        R(i).timeIncorrectClick = [];
        
        if isempty( R(i).clickTimes )
            R(i).timeSuccessfulClick = []; % empty
            R(i).timeIncorrectClick = [];
        else
            % go through clicks and see if this was when over a target
            for iClick = 1 : numel( R(i).clickTimes )
                if ismember( R(i).state(R(i).clickTimes(iClick)), overTargetStates )
                    % it's correct!
                    R(i).timeSuccessfulClick(end+1) = R(i).clickTimes(iClick); % presumably there will be just one, but maybe in the future we can have tasks requiring multiple clicks
                else
                    % incorrect click
                    R(i).timeIncorrectClick(end+1) = R(i).clickTimes(iClick); % presumably there will be just one, but maybe in the future we can have tasks requiring multiple clicks
                end
            end
        end
    end



end