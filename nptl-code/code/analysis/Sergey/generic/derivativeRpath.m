% derivativeRpath.m
%
% Given an runID and block number, provides the path to where the derived R struct
% for this block (if were already generated) would be.
%
% USAGE: [ Rpath ] = derivativeRpath( runID, blockNum )
%
% EXAMPLE: myFile = derivativeRpath( 't6.2014.07.25', 9 );
%
% INPUTS:
%     runID                     participant.yyyy.mm.dd 
%     blockNum                  block number, e.g. 5
%
% OUTPUTS:
%     Rpath                     e.g. 
%
% Created by Sergey Stavisky on 01 Dec 2016

function [ Rpath ] = derivativeRpath( runID, blockNum, varargin )
    def.rootPath = '/net/derivative/R/t6/';    
    assignargs( def, varargin );
    Rpath = sprintf('%s%s/R_%03i', rootPath, runID, blockNum );
end