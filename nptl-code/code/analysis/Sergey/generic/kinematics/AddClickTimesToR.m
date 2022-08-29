% AddClickTimesToR.m
%
% Adds a .clickTimes field to each R struct element, which records when clicks
% happened. IMPORTANT: It reports only clicks that lasted the required .clickHoldTime,
% and it reports the click time as once that duration condition was satisfied (so, for
% example, it'll report the click 30 ms after it was initiatied if .clickHoldTime==30).
%
%
% NOTE: Since we don't reset .clickTimer on new trials (which we could, I've just chosen
% not to), it makes sense to tun through all the samples in an R struct continuously so
% that clicks across trial borders can be remembered. This function DOES NOT DO THAT. It
% just looks one trial at a time. This will be fine in most cases (epsecially sicne a
% start of trial click in some tasks, like Gridlike and Grid, are ignored due to grace
% time). However, it would be better to rely on the .clickTimes I'm adding to
% cursor_streamParser.m instead.
% 
%
% USAGE: [ R ] = AddClickTimesToR( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                         
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R                         
%
% Created by Sergey Stavisky on 28 Jan 2017

function [ R ] = AddClickTimesToR( R, varargin )
    for iTrial = 1 : numel( R )
        % run through the trial click state and see when clicks happen
        runningClickSamples = 0;
        keyboard % TODO: not finished
        for t = 1 : R(iTrial).clickState
            R(iTrial).clickState
        end
        
    end




% clickHoldTime

end