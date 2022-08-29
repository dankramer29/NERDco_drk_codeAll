% AddRigCfieldEquivalents.m
%
% Takes an NPTL R struct and copies information from certain fields to
% similar fields with NPSL RigC names. This lets me use my existing
% analysis code.
% This is a work in progress.
%
% USAGE: [ R ] = AddRigCfieldEquivalents( R, varargin )
%
% EXAMPLE: R = AddRigCfieldEquivalents( R )
%
% INPUTS:
%     R     NPTL R struct                         
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R     Same R struct with rigC fields added.                         
%
% Created by Sergey Stavisky on 10 Nov 2016

function [ R ] = AddRigCfieldEquivalents( R, varargin )
for i = 1 : numel(R )
    % 1.) copy R(i).posTarget to startTrialParams.
    R(i).startTrialParams.posTarget = R(i).posTarget;
    
    
    
    
    
    
end
end