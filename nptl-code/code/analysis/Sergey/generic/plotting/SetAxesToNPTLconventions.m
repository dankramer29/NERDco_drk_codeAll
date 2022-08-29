% SetAxesToNPTLconventions.m
%
% Takes a standard MATLAB axes and changes the directions of the x,y,z
% axes to match NPTL conventions.
%
% USAGE:   axh = SetAxesToNPTLconventions( axh ); 
%
% EXAMPLE:  axh = SetAxesToNPTLconventions( axh ); % convert this axes into NPTL coordinate conventions
%
% INPUTS:
%     axh                     MATLAB axis handle  
%
% OUTPUTS:
%     axh                     same axis handle, now updated
%
% Created by Sergey Stavisky on 27 Jan 2017

function [ axh ] = SetAxesToNPTLconventions( axh )
    set( axh, 'XDir', 'normal' );
    set( axh, 'YDir', 'reverse' );
    set( axh, 'ZDir', 'reverse' );
end