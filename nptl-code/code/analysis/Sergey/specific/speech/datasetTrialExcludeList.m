% dataseTrialExcludeList.m
%
% Lookup table of trials to exclude for a given dataset. I'm using this for the speech
% analysis because there are two t8.2017.10.18 trials with wonky electrical noise.
%
% NOTE: For the speech datasets, trial numbers are *within a block*. So for a words
% dataset with 3 blcoks, there'll be 3 instances of most trial numbers. Hence, thhis
% lookup specifies both trial number and blok
%
% USAGE: [ trials ] = datasetTrialExcludeList( Rfile )
%
% EXAMPLE: params.excludeTrials = datasetTrialExcludeList( Rfile );
%
% INPUTS:
%     Rfile                   string name of an R file, it'll do a strfind within it
%
% OUTPUTS:
%     trials                  vector of trial numbers, which are indices into
%                              R(i).trialNumber
%
% Created by Sergey Stavisky on 16 Dec 2017 using MATLAB version 9.3.0.713579 (R2017b)

 function [ trials, blocks ] = datasetTrialExcludeList( Rfile )

    trials = [];
    if strfind( Rfile, 't8.2017.10.18-words' )
        trials = [91, 92];
        blocks = [ 1,  1];
    end
end