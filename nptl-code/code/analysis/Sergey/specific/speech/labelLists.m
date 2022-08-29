% labelLists.m
%
% Hard coded labels in a specific order that groups things more logically, which is good
% for presentation.
%
% USAGE: [ includeLabels ] = labelLists( Rfile )
%
% EXAMPLE:
%
% INPUTS:
%     Rfile                     
%
% OUTPUTS:
%     includeLabels             
%
% Created by Sergey Stavisky on 29 Nov 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ includeLabels ] = labelLists( Rfile )

 
     if strfind( Rfile, 't5.2018.12.17' ) 
         includeLabels = {'silence', 'seal', 'shot', 'more', 'bat', 'beet'};
       
     elseif strfind( Rfile, 't5.2018.12.12' ) 
         includeLabels = {'silence', 'seal', 'shot', 'more', 'bat', 'beet', 'bot'}; % note it has BOT because that's what was used for CL blocks, but NOT during the 5-words astandlone
         
     elseif strfind( Rfile, 'phonemes')
         if ~isempty( strfind( Rfile, 't5.2017.09.20') ) | ~isempty( strfind( Rfile, 'T5_2017_09_20') )
             % pilot day
             includeLabels = {'silence', 'ba', 'ga', 'da', 'sh', 'oo'};
         elseif strfind( Rfile, 't5.2017.10.23' )
             includeLabels = {'silence', 'i', 'u', 'ae', 'a', 'ba', 'ga', 'k', 'p', 'sh'}; % da is excluded because only 9 trials due to his having trouble hearing it
         else
             % main days
             includeLabels = {'silence', 'i', 'u', 'ae', 'a', 'ba', 'ga', 'da', 'k', 'p', 'sh'};
         end
     elseif strfind( Rfile, 'words' )
         if strfind( Rfile, 't5.2017.09.20')
             % pilot day
             includeLabels = {'silence', 'arm', 'push', 'pull', 'beach', 'tree'};
         else
             % main days
             includeLabels = {'silence', 'beet', 'bat', 'bot', 'boot', 'dot', 'got', 'shot', 'keep', 'seal', 'more'};
         end
     elseif strfind( Rfile, 'movements' )
         includeLabels = {'stayStill', 'tongueLeft', 'tongueRight', 'tongueDown', 'tongueUp', 'lipsForward', 'lipsBack', 'mouthOpen'};
     end





end