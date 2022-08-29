% TrimScreenText.m
%
% Takes in a formatted text as saved by the simple in-session text presentation script,
% and unpacks it into simple text.
%
% USAGE: [ simpletext ] = TrimScreenText.m( textcell, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     textcell                  cell list with text in each cell.
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     simpletext                char vector
%     passageNumber             The last line reports passage number; extracts this as a
%                               double.
%
% Created by Sergey Stavisky on 17 Jul 2019 using MATLAB version 9.3.0.948333 (R2017b) Update 9

function [ simpletext, passageNum ] = TrimScreenText( textcell, varargin )
    simpletext = [];
    for i = 1 : numel( textcell )-1
        if ~isempty( textcell{i} )
           simpletext = [simpletext,  ' ', strtrim( textcell{i} )];
        end
    end
    simpletext(1) = ''; % remove first space.
    simpletext = deblank( simpletext );
    
    passageNum = str2num( cell2mat( regexp( textcell{end}, '\d', 'match') ) );
end